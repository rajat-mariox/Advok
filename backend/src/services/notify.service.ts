import type { AppNotification, DbShape, NotificationType } from '../models';
import { createId } from './db.service';
import { publishToUser, type RealtimeTopic } from './realtime.service';

/**
 * Queues an in-app notification for a user. The caller is responsible for
 * calling saveDb() afterwards (usually as part of a larger mutation).
 */
export function pushNotification(
  db: DbShape,
  userId: string,
  type: NotificationType,
  title: string,
  body: string,
  refs: { caseId?: string; bookingId?: string; ticketId?: string; queryId?: string } = {},
): void {
  db.notifications ??= [];
  const record: AppNotification = {
    id: createId(),
    userId,
    type,
    title,
    body,
    caseId: refs.caseId,
    bookingId: refs.bookingId,
    ticketId: refs.ticketId,
    createdAt: new Date().toISOString(),
  };
  db.notifications.push(record);  publishToUser(userId, 'notifications', { type });
  const topic: RealtimeTopic | null = type.startsWith('booking_')
    ? 'bookings'
    : type.startsWith('case_')
      ? 'cases'
      : type === 'support_reply'
        ? 'support'
        : type === 'query_answered'
          ? 'queries'
          : null;
  if (topic) publishToUser(userId, topic, refs);
}

/**
 * Drops a platform-generated message into the chat thread between two users,
 * so the conversation exists (and carries context) from the moment the
 * relationship becomes active. Caller saves the db.
 */
export function pushSystemMessage(
  db: DbShape,
  fromId: string,
  toId: string,
  text: string,
  meta?: Record<string, unknown>,
): void {
  db.messages ??= [];
  db.messages.push({
    id: createId(),
    fromId,
    toId,
    text,
    system: true,
    meta,
    sentAt: new Date().toISOString(),
  });  publishToUser(toId, 'messages', { peerId: fromId });
  publishToUser(fromId, 'messages', { peerId: toId });
}
