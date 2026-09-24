// Data store. All controllers work on an in-memory DbShape and call saveDb()
// after mutating it. Persistence backend depends on MONGODB_URI:
//  - set   -> data lives in MongoDB; every saveDb() syncs the changed state
//             (users/bookings/cmsPages/otps) to the collections in background.
//  - unset -> data lives in backend/data/db.json, exactly as before (local dev).
// On first boot with an empty MongoDB, an existing db.json is migrated into it.
import bcrypt from 'bcryptjs';
import fs from 'fs';
import path from 'path';
import { randomUUID } from 'crypto';
import { MongoClient, type Db } from 'mongodb';
import {
  MONGODB_DB,
  MONGODB_URI,
  SEED_ADMIN_EMAIL,
  SEED_ADMIN_NAME,
  SEED_ADMIN_PASSWORD,
} from '../config';
import type { AdvocateProfile, AppSettings, DbShape, User } from '../models';
import { DEFAULT_CMS_PAGES } from '../models/cms.seed';
import { DEFAULT_CONSULTATION_PRICING } from '../models/settings.model';
import { DEFAULT_SUPPORT_CONTACT } from '../models/support.model';
import { DEFAULT_AI_SUGGESTIONS } from '../models/settings.model';

const DATA_DIR = path.join(__dirname, '..', '..', 'data');
const DB_FILE = path.join(DATA_DIR, 'db.json');

let db: DbShape | null = null;
let mongo: Db | null = null;

/** How each collection maps to a DbShape array and its unique key field. */
const COLLECTIONS = [
  { name: 'users', field: 'users', key: 'id' },
  { name: 'otps', field: 'otps', key: 'phone' },
  { name: 'cmsPages', field: 'cmsPages', key: 'slug' },
  { name: 'bookings', field: 'bookings', key: 'id' },
  { name: 'relationships', field: 'relationships', key: 'id' },
  { name: 'cases', field: 'cases', key: 'id' },
  { name: 'messages', field: 'messages', key: 'id' },
  { name: 'notifications', field: 'notifications', key: 'id' },
  { name: 'settings', field: 'settings', key: 'id' },
  { name: 'supportTickets', field: 'supportTickets', key: 'id' },
  { name: 'caseStudies', field: 'caseStudies', key: 'id' },
  { name: 'legalTerms', field: 'legalTerms', key: 'slug' },
  { name: 'legalQueries', field: 'legalQueries', key: 'id' },
  { name: 'adminNotifications', field: 'adminNotifications', key: 'id' },
] as const;

function loadFromFile(): DbShape {
  if (fs.existsSync(DB_FILE)) {
    return JSON.parse(fs.readFileSync(DB_FILE, 'utf-8')) as DbShape;
  }
  return { users: [], otps: [] };
}

/**
 * Connects the persistence backend and loads all data into memory.
 * Must complete before the HTTP server starts listening.
 */
export async function initDb(): Promise<void> {
  if (db) return;

  if (MONGODB_URI) {
    const client = new MongoClient(MONGODB_URI);
    await client.connect();
    mongo = client.db(MONGODB_DB);

    const state: DbShape = { users: [], otps: [] };
    for (const c of COLLECTIONS) {
      const docs = await mongo.collection(c.name).find({}, { projection: { _id: 0 } }).toArray();
      (state as unknown as Record<string, unknown>)[c.field] = docs;
    }

    // First run against an empty database: pull in any existing db.json data.
    if (state.users.length === 0 && fs.existsSync(DB_FILE)) {
      const fileData = loadFromFile();
      state.users = fileData.users ?? [];
      state.otps = fileData.otps ?? [];
      state.cmsPages = fileData.cmsPages;
      state.bookings = fileData.bookings;
      console.log(`Migrating db.json into MongoDB (${state.users.length} users)…`);
    }

    db = state;
    console.log(`MongoDB connected: ${MONGODB_DB} (${state.users.length} users)`);
  } else {
    db = loadFromFile();
    console.log('MONGODB_URI not set — storing data in data/db.json');
  }

  seedAdmin(db);
  seedCmsPages(db);
  seedSettings(db);
  migrateConsultationCards(db);
  dropFirmClientThreads(db);
  persist();
}

/** Creates the global settings record with default pricing when missing. */
function seedSettings(state: DbShape): void {
  state.settings ??= [];
  if (!state.settings.some((s) => s.id === 'global')) {
    state.settings.push({
      id: 'global',
      consultationPricing: { ...DEFAULT_CONSULTATION_PRICING },
      support: { ...DEFAULT_SUPPORT_CONTACT },
      updatedAt: new Date().toISOString(),
    });
  }
  // Older settings records predate the support block.
  for (const s of state.settings) {
    s.support ??= { ...DEFAULT_SUPPORT_CONTACT };
    s.consultationPricing = { ...DEFAULT_CONSULTATION_PRICING, ...s.consultationPricing };
    s.aiSuggestions ??= DEFAULT_AI_SUGGESTIONS.map((x) => ({ ...x }));
  }
}

/** The global settings record (seeded at boot, so always present). */
export function getSettings(): AppSettings {
  const state = getDb();
  state.settings ??= [];
  let settings = state.settings.find((s) => s.id === 'global');
  if (!settings) {
    settings = {
      id: 'global',
      consultationPricing: { ...DEFAULT_CONSULTATION_PRICING },
      support: { ...DEFAULT_SUPPORT_CONTACT },
      updatedAt: new Date().toISOString(),
    };
    state.settings.push(settings);
  }
  settings.support ??= { ...DEFAULT_SUPPORT_CONTACT };
  settings.consultationPricing = { ...DEFAULT_CONSULTATION_PRICING, ...settings.consultationPricing };
  settings.aiSuggestions ??= DEFAULT_AI_SUGGESTIONS.map((x) => ({ ...x }));
  return settings;
}

/**
 * Upgrades consultation-accepted chat cards written in the old
 * client-details format to the current attorney-contact format (the card
 * the client uses to call their attorney). One-time data fix for messages
 * created before the card was flipped; a no-op afterwards.
 */
/**
 * Firms never chat with clients (their assigned attorney does). Removes
 * system messages written between a law firm and a client before that rule
 * existed, so neither side sees a phantom thread.
 */
function dropFirmClientThreads(state: DbShape): void {
  if (!state.messages?.length) return;
  const role = new Map(state.users.map((u) => [u.id, u.role]));
  const before = state.messages.length;
  state.messages = state.messages.filter((m) => {
    const roles = new Set([role.get(m.fromId), role.get(m.toId)]);
    return !(roles.has('law_firm') && roles.has('client'));
  });
  const dropped = before - state.messages.length;
  if (dropped) console.log(`Removed ${dropped} firm↔client chat message(s)`);
}

function migrateConsultationCards(state: DbShape): void {
  for (const m of state.messages ?? []) {
    let meta = m.meta as Record<string, unknown> | undefined;
    if (!meta || meta.kind !== 'consultation_accepted') continue;

    if (!meta.attorneyName) {
      // Old cards were sent client → advocate, so the advocate is the
      // recipient. Flip the direction and swap in the attorney's details.
      const advocate = state.users.find(
        (u) => u.id === m.toId && u.role === 'advocate',
      );
      if (!advocate) continue;
      const ap = advocate.profile as AdvocateProfile | undefined;
      const name = ap?.professional.fullName ?? 'Your attorney';
      const clientId = m.fromId;
      m.fromId = advocate.id;
      m.toId = clientId;
      m.text =
        `Consultation confirmed — contact ${name}: ` +
        `${advocate.phone ?? 'in the app'}.`;
      m.meta = {
        kind: 'consultation_accepted',
        attorneyName: name,
        attorneyPhone: advocate.phone ?? '',
        attorneyEmail: ap?.professional.email ?? '',
        attorneyPhoto: ap?.photo ?? '',
        consultationType: meta.consultationType ?? '',
        date: meta.date ?? '',
        time: meta.time ?? '',
        amount: meta.amount ?? 0,
      };
      meta = m.meta as Record<string, unknown>;
      delete m.readAt;
      console.log(`Migrated consultation card ${m.id} to attorney-contact format`);
    }

    // Repair self-addressed cards (advocate → advocate): recover the client
    // from the matching booking, or the advocate's only relationship.
    if (m.fromId === m.toId) {
      const booking = (state.bookings ?? []).find(
        (b) =>
          b.advocateId === m.fromId &&
          b.date === meta!.date &&
          b.time === meta!.time,
      );
      const rels = (state.relationships ?? []).filter(
        (r) => r.advocateId === m.fromId,
      );
      const clientId = booking?.clientId ?? (rels.length === 1 ? rels[0].clientId : null);
      if (clientId) {
        m.toId = clientId;
        delete m.readAt;
        console.log(`Repaired self-addressed consultation card ${m.id}`);
      }
    }
  }
}

/** Adds any default CMS page missing from the store (older data sets). */
function seedCmsPages(state: DbShape): void {
  state.cmsPages ??= [];
  for (const page of DEFAULT_CMS_PAGES) {
    if (!state.cmsPages.some((p) => p.slug === page.slug)) {
      state.cmsPages.push(structuredClone(page));
    }
  }
}

function seedAdmin(state: DbShape): void {
  const exists = state.users.some((u) => u.role === 'admin' && u.email === SEED_ADMIN_EMAIL);
  if (exists) return;
  state.users.push({
    id: randomUUID(),
    role: 'admin',
    status: 'active',
    email: SEED_ADMIN_EMAIL,
    passwordHash: bcrypt.hashSync(SEED_ADMIN_PASSWORD, 10),
    name: SEED_ADMIN_NAME,
    createdAt: new Date().toISOString(),
  });
}

// Mongo writes run in the background, one at a time; while one is in flight
// the next saveDb() just marks the state dirty again.
let syncing = false;
let dirty = false;

async function syncToMongo(): Promise<void> {
  if (!mongo || !db) return;
  if (syncing) {
    dirty = true;
    return;
  }
  syncing = true;
  try {
    do {
      dirty = false;
      // Snapshot so route handlers can keep mutating while we write.
      const snapshot = structuredClone(db) as unknown as Record<string, unknown[]>;
      for (const c of COLLECTIONS) {
        const docs = (snapshot[c.field] ?? []) as Record<string, unknown>[];
        const col = mongo.collection(c.name);
        if (docs.length) {
          await col.bulkWrite(
            docs.map((doc) => ({
              replaceOne: { filter: { [c.key]: doc[c.key] }, replacement: doc, upsert: true },
            })),
          );
        }
        // Remove docs deleted from memory (consumed OTPs, removed pages…).
        await col.deleteMany({ [c.key]: { $nin: docs.map((d) => d[c.key]) } });
      }
    } while (dirty);
  } catch (err) {
    console.error('MongoDB sync failed:', err);
  } finally {
    syncing = false;
  }
}

function persist(): void {
  if (!db) return;
  if (mongo) {
    void syncToMongo();
  } else {
    fs.mkdirSync(DATA_DIR, { recursive: true });
    fs.writeFileSync(DB_FILE, JSON.stringify(db, null, 2), 'utf-8');
  }
}

export function getDb(): DbShape {
  if (!db) throw new Error('Database not initialized — call initDb() first');
  return db;
}

export function saveDb(): void {
  persist();
}

export function findUserById(id: string): User | undefined {
  return getDb().users.find((u) => u.id === id);
}

export function createId(): string {
  return randomUUID();
}
