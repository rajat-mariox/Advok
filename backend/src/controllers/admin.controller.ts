import type { Request, Response } from 'express';
import type { AdvocateProfile, ClientProfile, DbShape, Role, UserStatus, LawFirmProfile } from '../models';
import { autoCompletePastBookings } from './booking.controller';
import { getDb, saveDb } from '../services/db.service';
import { pushNotification } from '../services/notify.service';
import { publicUser } from '../util/user.util';
import { isValidSections } from '../validators/cms.validator';
import { publishToAdmins, publishToAll, publishToUser, publishToUsers } from '../services/realtime.service';

/** Display names for both parties of a booking/case, for the admin tables. */
function partyNames(db: DbShape, clientId: string, advocateId: string) {
  const client = db.users.find((u) => u.id === clientId);
  const advocate = db.users.find((u) => u.id === advocateId);
  const cp = client?.profile as ClientProfile | undefined;
  const clientName = cp?.fullName?.trim();
  // The provider can be an advocate (name under `professional`) or a law
  // firm (name under `firmName`); guard both so one odd record can't 500 the list.
  let advocateName: string | undefined;
  if (advocate?.role === 'law_firm') {
    advocateName = (advocate.profile as LawFirmProfile | undefined)?.firmName?.trim();
  } else {
    advocateName = (advocate?.profile as AdvocateProfile | undefined)?.professional?.fullName?.trim();
  }
  return {
    clientName: clientName && clientName.length > 0 ? clientName : (client?.phone ?? 'Client'),
    advocateName: advocateName && advocateName.length > 0 ? advocateName : 'Attorney',
  };
}

const REVIEWABLE_ROLES: Role[] = ['advocate', 'law_student', 'law_firm'];

/**
 * List registrations for review.
 * Query params: role=advocate|law_student|law_firm, status=pending_approval|approved|rejected
 */
export function listRegistrations(req: Request, res: Response) {
  const { role, status } = req.query;
  const db = getDb();
  let list = db.users.filter((u) => u.role && REVIEWABLE_ROLES.includes(u.role));
  if (typeof role === 'string' && role) list = list.filter((u) => u.role === role);
  if (typeof status === 'string' && status) list = list.filter((u) => u.status === status);
  list = [...list].sort((a, b) => (b.onboardedAt ?? b.createdAt).localeCompare(a.onboardedAt ?? a.createdAt));
  return res.json({ registrations: list.map(publicUser) });
}

/** All app users (non-admin). Optional ?role= filter — includes clients. */
export function listUsers(req: Request, res: Response) {
  const { role } = req.query;
  const db = getDb();
  let list = db.users.filter((u) => u.role !== 'admin');
  if (typeof role === 'string' && role) list = list.filter((u) => u.role === role);
  list = [...list].sort((a, b) => b.createdAt.localeCompare(a.createdAt));
  return res.json({ users: list.map(publicUser) });
}

/** Permanently removes a (non-admin) user account, e.g. test registrations. */
export function deleteUser(req: Request, res: Response) {
  const db = getDb();
  const index = db.users.findIndex((u) => u.id === req.params.id && u.role !== 'admin');
  if (index === -1) return res.status(404).json({ error: 'User not found' });
  db.users.splice(index, 1);
  saveDb();
  publishToUser(req.params.id, 'account', { status: 'deleted' });
  publishToAdmins('users', { userId: req.params.id });
  publishToAdmins('registrations');
  return res.json({ ok: true });
}

/** Suspends any (non-admin) account. Body: { reason?: string }. */
export function suspendUser(req: Request, res: Response) {
  const db = getDb();
  const user = db.users.find((u) => u.id === req.params.id && u.role !== 'admin');
  if (!user) return res.status(404).json({ error: 'User not found' });
  if (user.status === 'suspended') return res.json({ user: publicUser(user) });
  user.statusBeforeSuspension = user.status;
  user.status = 'suspended';
  user.suspensionReason =
    typeof req.body?.reason === 'string' && req.body.reason.trim()
      ? req.body.reason.trim()
      : undefined;
  saveDb();
  publishToUser(user.id, 'account', { status: user.status });
  publishToAdmins('users', { userId: user.id });
  return res.json({ user: publicUser(user) });
}

/** Lifts a suspension, restoring the status the account had before it. */
export function unsuspendUser(req: Request, res: Response) {
  const db = getDb();
  const user = db.users.find((u) => u.id === req.params.id && u.role !== 'admin');
  if (!user) return res.status(404).json({ error: 'User not found' });
  if (user.status !== 'suspended') return res.json({ user: publicUser(user) });
  user.status =
    user.statusBeforeSuspension ?? (user.role === 'client' ? 'active' : 'approved');
  user.statusBeforeSuspension = undefined;
  user.suspensionReason = undefined;
  saveDb();
  publishToUser(user.id, 'account', { status: user.status });
  publishToAdmins('users', { userId: user.id });
  return res.json({ user: publicUser(user) });
}

/** Counts shown as badges in the admin panel. */
export function registrationCounts(_req: Request, res: Response) {
  const db = getDb();
  const pending = db.users.filter((u) => u.status === 'pending_approval');
  return res.json({
    advocate: pending.filter((u) => u.role === 'advocate').length,
    law_student: pending.filter((u) => u.role === 'law_student').length,
    law_firm: pending.filter((u) => u.role === 'law_firm').length,
    total: pending.length,
  });
}

function review(id: string, status: UserStatus, reason?: string) {
  const db = getDb();
  const user = db.users.find((u) => u.id === id && u.role && REVIEWABLE_ROLES.includes(u.role));
  if (!user) return null;
  user.status = status;
  user.rejectionReason = status === 'rejected' ? (reason ?? 'Not specified') : undefined;
  user.reviewedAt = new Date().toISOString();
  if (status === 'approved') {
    pushNotification(db, user.id, 'account_update', 'Your ADVOK account is approved', 'Your details were verified. You now have full access to ADVOK.');
  } else if (status === 'rejected') {
    pushNotification(db, user.id, 'account_update', 'Your ADVOK registration needs attention', `Reason: ${user.rejectionReason}. Update your details and submit again.`);
  }
  saveDb();
  publishToUser(user.id, 'account', { status: user.status });
  publishToAdmins('registrations', { userId: user.id });
  publishToAdmins('users', { userId: user.id });
  return user;
}

export function approveRegistration(req: Request, res: Response) {
  const user = review(req.params.id, 'approved');
  if (!user) return res.status(404).json({ error: 'Registration not found' });
  return res.json({ user: publicUser(user) });
}

export function rejectRegistration(req: Request, res: Response) {
  const reason = typeof req.body?.reason === 'string' ? req.body.reason : undefined;
  const user = review(req.params.id, 'rejected', reason);
  if (!user) return res.status(404).json({ error: 'Registration not found' });
  return res.json({ user: publicUser(user) });
}

/** Move an already-reviewed registration back to pending. */
export function reopenRegistration(req: Request, res: Response) {
  const user = review(req.params.id, 'pending_approval');
  if (!user) return res.status(404).json({ error: 'Registration not found' });
  return res.json({ user: publicUser(user) });
}

/** CMS pages (Terms, Privacy, ...) with full content, for the editor. */
/** Every consultation booked on the platform, newest first. */
export function listBookings(_req: Request, res: Response) {
  const db = getDb();
  if (autoCompletePastBookings(db)) saveDb();
  const list = [...(db.bookings ?? [])].sort((a, b) =>
    b.createdAt.localeCompare(a.createdAt),
  );
  return res.json({
    bookings: list.map((b) => ({
      ...b,
      ...partyNames(db, b.clientId, b.advocateId),
    })),
  });
}

/** Every case being managed on the platform, most recently updated first. */
export function listCases(_req: Request, res: Response) {
  const db = getDb();
  const list = [...(db.cases ?? [])].sort((a, b) =>
    b.updatedAt.localeCompare(a.updatedAt),
  );
  return res.json({
    cases: list.map((c) => ({
      ...c,
      ...partyNames(db, c.clientId, c.advocateId),
    })),
  });
}

/**
 * Removes one case along with the notifications and chat cards that point
 * at it. For cleaning up test or mistaken entries; users are untouched.
 */
export function deleteCase(req: Request, res: Response) {
  const db = getDb();
  const index = (db.cases ?? []).findIndex((c) => c.id === req.params.id);
  if (index === -1) return res.status(404).json({ error: 'Case not found' });
  const caseId = req.params.id;
  const removedCase = db.cases![index];
  db.cases!.splice(index, 1);
  db.notifications = (db.notifications ?? []).filter((n) => n.caseId !== caseId);
  db.messages = (db.messages ?? []).filter((m) => m.meta?.caseId !== caseId);
  saveDb();
  publishToUsers([removedCase.clientId, removedCase.advocateId], 'cases', { caseId });
  publishToUsers([removedCase.clientId, removedCase.advocateId], 'notifications');
  publishToAdmins('cases', { caseId });
  return res.json({ ok: true });
}

/**
 * Clears every booking, case, client relationship, chat message and
 * notification — an admin reset for wiping test data. User accounts are
 * untouched.
 */
export function clearOperations(_req: Request, res: Response) {
  const db = getDb();
  const removed = {
    bookings: db.bookings?.length ?? 0,
    cases: db.cases?.length ?? 0,
    relationships: db.relationships?.length ?? 0,
    messages: db.messages?.length ?? 0,
    notifications: db.notifications?.length ?? 0,
  };
  db.bookings = [];
  db.cases = [];
  db.relationships = [];
  db.messages = [];
  db.notifications = [];
  saveDb();
  for (const topic of ['bookings', 'cases', 'clients', 'messages', 'notifications'] as const) publishToAll(topic);
  return res.json({ ok: true, removed });
}

export function listCmsPages(_req: Request, res: Response) {
  return res.json({ pages: getDb().cmsPages ?? [] });
}

/** Save edits to one CMS page. Body: { title, sections, lastUpdatedLabel }. */
export function updateCmsPage(req: Request, res: Response) {
  const db = getDb();
  const page = (db.cmsPages ?? []).find((p) => p.slug === req.params.slug);
  if (!page) return res.status(404).json({ error: 'Page not found' });

  const { title, sections, lastUpdatedLabel } = req.body ?? {};
  if (typeof title !== 'string' || !title.trim()) {
    return res.status(400).json({ error: 'Title is required' });
  }
  if (!isValidSections(sections)) {
    return res.status(400).json({ error: 'Each section needs a title and a body' });
  }

  page.title = title.trim();
  page.sections = sections.map((s) => ({ title: s.title.trim(), body: s.body.trim() }));
  page.lastUpdatedLabel =
    typeof lastUpdatedLabel === 'string' && lastUpdatedLabel.trim()
      ? lastUpdatedLabel.trim()
      : `Last updated: ${new Date().toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' })}`;
  page.updatedAt = new Date().toISOString();
  saveDb();
  return res.json({ page });
}

/**
 * PATCH /admin/users/:id/firm-fee — body: { consultationFee: number | null }.
 * Sets (or clears) a law firm's own voice-consultation fee. Null falls back
 * to the platform-wide law-firm rate.
 */
export function setFirmFee(req: Request, res: Response) {
  const db = getDb();
  const user = db.users.find((u) => u.id === req.params.id && u.role === 'law_firm');
  if (!user || !user.profile) return res.status(404).json({ error: 'Law firm not found' });
  const raw = (req.body ?? {}).consultationFee;
  const profile = user.profile as LawFirmProfile;
  if (raw === null || raw === undefined || raw === '') {
    delete profile.consultationFee;
  } else {
    const fee = typeof raw === 'number' ? raw : Number(raw);
    if (!Number.isFinite(fee) || fee < 0 || fee > 100000) {
      return res.status(400).json({ error: 'consultationFee must be between 0 and 100000' });
    }
    profile.consultationFee = Math.round(fee * 100) / 100;
  }
  saveDb();
  publishToUser(user.id, 'account', { status: user.status });
  publishToAdmins('users', { userId: user.id });
  return res.json({ user: publicUser(user) });
}

/** GET /admin/notifications — newest first (last 100) + unread count. */
export function listAdminNotifications(_req: Request, res: Response) {
  const db = getDb();
  const all = [...(db.adminNotifications ?? [])].sort((a, b) => b.createdAt.localeCompare(a.createdAt));
  return res.json({
    notifications: all.slice(0, 100),
    unread: all.filter((n) => !n.readAt).length,
  });
}

/** POST /admin/notifications/read — body { ids? }; no ids marks everything read. */
export function markAdminNotificationsRead(req: Request, res: Response) {
  const db = getDb();
  const ids = Array.isArray(req.body?.ids) ? new Set((req.body.ids as unknown[]).map(String)) : null;
  const now = new Date().toISOString();
  let changed = 0;
  for (const n of db.adminNotifications ?? []) {
    if (!n.readAt && (!ids || ids.has(n.id))) {
      n.readAt = now;
      changed += 1;
    }
  }
  if (changed) {
    saveDb();
    publishToAdmins('adminNotifications', { read: changed });
  }
  return res.json({ ok: true, changed });
}
