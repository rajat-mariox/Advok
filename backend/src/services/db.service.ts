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
import type { DbShape, User } from '../models';
import { DEFAULT_CMS_PAGES } from '../models/cms.seed';

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
  persist();
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
