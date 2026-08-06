import bcrypt from 'bcryptjs';
import fs from 'fs';
import path from 'path';
import { randomUUID } from 'crypto';
import { SEED_ADMIN_EMAIL, SEED_ADMIN_NAME, SEED_ADMIN_PASSWORD } from './config';
import { DEFAULT_CMS_PAGES } from './cmsSeed';
import type { DbShape, User } from './types';

const DATA_DIR = path.join(__dirname, '..', 'data');
const DB_FILE = path.join(DATA_DIR, 'db.json');

let db: DbShape | null = null;

function load(): DbShape {
  if (db) return db;
  if (fs.existsSync(DB_FILE)) {
    db = JSON.parse(fs.readFileSync(DB_FILE, 'utf-8')) as DbShape;
  } else {
    db = { users: [], otps: [] };
  }
  seedAdmin(db);
  seedCmsPages(db);
  return db;
}

/** Adds any default CMS page missing from the store (older db.json files). */
function seedCmsPages(state: DbShape): void {
  state.cmsPages ??= [];
  let added = false;
  for (const page of DEFAULT_CMS_PAGES) {
    if (!state.cmsPages.some((p) => p.slug === page.slug)) {
      state.cmsPages.push(structuredClone(page));
      added = true;
    }
  }
  if (added) persist(state);
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
  persist(state);
}

function persist(state: DbShape): void {
  fs.mkdirSync(DATA_DIR, { recursive: true });
  fs.writeFileSync(DB_FILE, JSON.stringify(state, null, 2), 'utf-8');
}

export function getDb(): DbShape {
  return load();
}

export function saveDb(): void {
  persist(load());
}

export function findUserById(id: string): User | undefined {
  return load().users.find((u) => u.id === id);
}

export function createId(): string {
  return randomUUID();
}

/** Strips secret fields before sending a user over the wire. */
export function publicUser(user: User): Omit<User, 'passwordHash'> {
  const { passwordHash: _passwordHash, ...rest } = user;
  return rest;
}
