import type { Request, Response } from 'express';
import jwt from 'jsonwebtoken';
import { JWT_SECRET } from '../config';
import { findUserById } from '../services/db.service';
import { ADMIN_CHANNEL, connectionCount, subscribe } from '../services/realtime.service';

/**
 * GET /api/events — Server-Sent Events stream of "something changed" events
 * for the signed-in user (plus the admin channel for admin sessions).
 *
 * The token comes from the Authorization header (mobile app) or, because the
 * browser's EventSource cannot set headers, from `?token=` (admin panel).
 */
export function stream(req: Request, res: Response) {
  const header = req.headers.authorization ?? '';
  const token =
    (header.startsWith('Bearer ') ? header.slice(7) : '') ||
    (typeof req.query.token === 'string' ? req.query.token : '');
  if (!token) return res.status(401).json({ error: 'Missing token' });
  let userId: string;
  try {
    userId = (jwt.verify(token, JWT_SECRET) as { sub: string }).sub;
  } catch {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
  const user = findUserById(userId);
  if (!user) return res.status(401).json({ error: 'User no longer exists' });
  if (user.status === 'suspended' && user.role !== 'admin') {
    // Suspended accounts still get 'account' events so the app can react to
    // an unsuspend; nothing else is published to them.
  }
  const channels = [user.id];
  if (user.role === 'admin') channels.push(ADMIN_CHANNEL);
  subscribe(res, channels);
  return undefined;
}

/** GET /api/events/status — how many live streams are open (diagnostics). */
export function status(_req: Request, res: Response) {
  return res.json({ connections: connectionCount() });
}
