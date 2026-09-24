// Phone push notifications through Firebase Cloud Messaging (FCM).
//
// Configured by FIREBASE_SERVICE_ACCOUNT in backend/.env: either the path to
// the service-account JSON (Firebase console > Project settings > Service
// accounts > Generate new private key) or the JSON itself on one line.
// Without it, push is simply skipped and in-app notifications still work.
import fs from 'fs';
import path from 'path';
import type { App } from 'firebase-admin/app';
import type { Messaging } from 'firebase-admin/messaging';
import { FIREBASE_SERVICE_ACCOUNT } from '../config';
import type { DbShape, User } from '../models';

let messaging: Messaging | null = null;
let initTried = false;

function loadServiceAccount(): Record<string, unknown> | null {
  const raw = FIREBASE_SERVICE_ACCOUNT;
  if (!raw) return null;
  try {
    if (raw.startsWith('{')) return JSON.parse(raw) as Record<string, unknown>;
    const file = path.isAbsolute(raw) ? raw : path.join(__dirname, '..', '..', raw);
    return JSON.parse(fs.readFileSync(file, 'utf-8')) as Record<string, unknown>;
  } catch (err) {
    console.error('Push: could not read FIREBASE_SERVICE_ACCOUNT:', err instanceof Error ? err.message : err);
    return null;
  }
}

async function getMessaging(): Promise<Messaging | null> {
  if (messaging || initTried) return messaging;
  initTried = true;
  const account = loadServiceAccount();
  if (!account) return null;
  try {
    const { cert, getApps, initializeApp } = await import('firebase-admin/app');
    const { getMessaging: gm } = await import('firebase-admin/messaging');
    const app: App =
      getApps()[0] ?? initializeApp({ credential: cert(account as Parameters<typeof cert>[0]) });
    messaging = gm(app);
    console.log(`Push notifications: FCM ready (project ${String(account.project_id ?? '?')})`);
  } catch (err) {
    console.error('Push: Firebase init failed:', err instanceof Error ? err.message : err);
    messaging = null;
  }
  return messaging;
}

export function isPushConfigured(): boolean {
  return FIREBASE_SERVICE_ACCOUNT.length > 0;
}

/** Registers (or refreshes) a device token on a user. Caller saves the db. */
export function addPushToken(user: User, token: string, platform: string): void {
  const now = new Date().toISOString();
  user.pushTokens ??= [];
  const existing = user.pushTokens.find((t) => t.token === token);
  if (existing) {
    existing.platform = platform;
    existing.updatedAt = now;
  } else {
    user.pushTokens.push({ token, platform, updatedAt: now });
  }
  // Keep the newest few devices per account.
  user.pushTokens = user.pushTokens.sort((a, b) => b.updatedAt.localeCompare(a.updatedAt)).slice(0, 5);
}

export function removePushToken(db: DbShape, token: string): void {
  for (const u of db.users) {
    if (u.pushTokens?.some((t) => t.token === token)) {
      u.pushTokens = u.pushTokens.filter((t) => t.token !== token);
    }
  }
}

/**
 * Sends a push to every registered device of the user. Fire-and-forget:
 * never throws, and tokens FCM reports as dead are dropped.
 */
export function sendPush(
  db: DbShape,
  userId: string,
  title: string,
  body: string,
  data: Record<string, string | undefined> = {},
): void {
  const user = db.users.find((u) => u.id === userId);
  const tokens = (user?.pushTokens ?? []).map((t) => t.token);
  if (!user || tokens.length === 0 || !isPushConfigured()) return;
  const payload: Record<string, string> = {};
  for (const [k, v] of Object.entries(data)) if (v) payload[k] = v;
  void (async () => {
    const m = await getMessaging();
    if (!m) return;
    try {
      const res = await m.sendEachForMulticast({
        tokens,
        notification: { title, body: body.length > 180 ? `${body.slice(0, 177)}…` : body },
        data: payload,
        android: { priority: 'high', notification: { sound: 'default' } },
        apns: { payload: { aps: { sound: 'default' } } },
      });
      const dead = res.responses
        .map((r, i) => (!r.success && /registration-token-not-registered|invalid-registration-token|invalid-argument/.test(r.error?.code ?? '') ? tokens[i] : null))
        .filter((t): t is string => !!t);
      if (dead.length) {
        user.pushTokens = (user.pushTokens ?? []).filter((t) => !dead.includes(t.token));
        // Persisted with the next saveDb(); stale tokens are harmless meanwhile.
      }
    } catch (err) {
      console.error('Push send failed:', err instanceof Error ? err.message : err);
    }
  })();
}
