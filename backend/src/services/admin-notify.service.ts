// Notifications for the admin panel's bell: new registrations to review,
// support tickets, legal queries, bookings and student–attorney
// conversations. Shared by every admin; read state is kept per record.
import type { AdminNotification, AdminNotificationType, DbShape } from '../models';
import { createId } from './db.service';
import { publishToAdmins } from './realtime.service';

const MAX_KEPT = 500;

/** Queues an admin notification and pings open admin tabs. Caller saves. */
export function pushAdminNotification(
  db: DbShape,
  type: AdminNotificationType,
  title: string,
  body: string,
  link: string,
): void {
  db.adminNotifications ??= [];
  const record: AdminNotification = {
    id: createId(),
    type,
    title,
    body,
    link,
    createdAt: new Date().toISOString(),
  };
  db.adminNotifications.push(record);
  if (db.adminNotifications.length > MAX_KEPT) {
    db.adminNotifications.splice(0, db.adminNotifications.length - MAX_KEPT);
  }
  publishToAdmins('adminNotifications', { type, id: record.id });
}
