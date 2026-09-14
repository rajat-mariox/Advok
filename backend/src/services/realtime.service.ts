// Live updates over Server-Sent Events (SSE). No third-party service: each
// signed-in app user and each admin keeps one long-lived GET /api/events
// response open, and controllers publish small "something changed" events
// to it right after saveDb(). Clients react by re-fetching the affected
// list, so payloads stay tiny and every screen shows changes within a
// second instead of on the next manual refresh.
//
// Runs in-process, which is right for a single backend instance (local dev,
// EC2). On serverless / multi-instance deployments a shared bus (Redis
// pub/sub) would be needed to fan events out across instances.
import type { Response } from 'express';

/** What changed. Clients map topics to the lists they re-fetch. */
export type RealtimeTopic =
  | 'notifications'
  | 'messages'
  | 'bookings'
  | 'cases'
  | 'clients'
  | 'queries'
  | 'support'
  | 'account'
  | 'settings'
  | 'registrations'
  | 'users'
  | 'content';

export interface RealtimeEvent {
  topic: RealtimeTopic;
  /** Optional hint for the client (ids, status), never the full record. */
  data?: Record<string, unknown>;
  at: string;
}

/** Channel every admin session listens on, in addition to its own user id. */
export const ADMIN_CHANNEL = 'admin';

const HEARTBEAT_MS = 25_000;

interface Client {
  id: number;
  channels: Set<string>;
  res: Response;
}

let nextId = 1;
const clients = new Map<number, Client>();

function write(client: Client, payload: string): void {
  try {
    client.res.write(payload);
  } catch {
    detach(client.id);
  }
}

function detach(id: number): void {
  const c = clients.get(id);
  if (!c) return;
  clients.delete(id);
  try {
    c.res.end();
  } catch {
    // already closed
  }
}

/**
 * Turns `res` into an SSE stream subscribed to `channels` (the user's id,
 * plus 'admin' for admin sessions). Returns when the stream is set up; the
 * response stays open until the client disconnects.
 */
export function subscribe(res: Response, channels: string[]): void {
  res.status(200);
  res.setHeader('Content-Type', 'text/event-stream; charset=utf-8');
  res.setHeader('Cache-Control', 'no-cache, no-transform');
  res.setHeader('Connection', 'keep-alive');
  res.setHeader('X-Accel-Buffering', 'no'); // nginx: don't buffer the stream
  res.flushHeaders?.();

  const client: Client = { id: nextId++, channels: new Set(channels), res };
  clients.set(client.id, client);
  // Tell the client we're live (and let proxies see bytes right away).
  write(client, `retry: 3000\nevent: ready\ndata: ${JSON.stringify({ at: new Date().toISOString() })}\n\n`);

  const cleanup = () => detach(client.id);
  res.on('close', cleanup);
  res.on('error', cleanup);
}

function send(channel: string, event: RealtimeEvent): void {
  const payload = `event: change\ndata: ${JSON.stringify(event)}\n\n`;
  for (const c of clients.values()) {
    if (c.channels.has(channel)) write(c, payload);
  }
}

/** Notify one user (their open app sessions) that `topic` changed for them. */
export function publishToUser(userId: string | undefined, topic: RealtimeTopic, data?: Record<string, unknown>): void {
  if (!userId) return;
  send(userId, { topic, data, at: new Date().toISOString() });
}

/** Notify several users at once (de-duplicated). */
export function publishToUsers(userIds: (string | undefined)[], topic: RealtimeTopic, data?: Record<string, unknown>): void {
  for (const id of new Set(userIds.filter((x): x is string => !!x))) publishToUser(id, topic, data);
}

/** Notify every open admin panel session. */
export function publishToAdmins(topic: RealtimeTopic, data?: Record<string, unknown>): void {
  send(ADMIN_CHANNEL, { topic, data, at: new Date().toISOString() });
}

/** Notify everyone connected (e.g. pricing or support-contact changed). */
export function publishToAll(topic: RealtimeTopic, data?: Record<string, unknown>): void {
  const payload = `event: change\ndata: ${JSON.stringify({ topic, data, at: new Date().toISOString() } satisfies RealtimeEvent)}\n\n`;
  for (const c of clients.values()) write(c, payload);
}

export function connectionCount(): number {
  return clients.size;
}

// Keep proxies and mobile radios from dropping idle streams.
setInterval(() => {
  for (const c of clients.values()) write(c, ': ping\n\n');
}, HEARTBEAT_MS).unref();
