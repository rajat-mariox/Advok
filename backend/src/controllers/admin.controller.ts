import type { Request, Response } from 'express';
import type { Role, UserStatus } from '../models';
import { getDb, saveDb } from '../services/db.service';
import { publicUser } from '../util/user.util';
import { isValidSections } from '../validators/cms.validator';

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
  saveDb();
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
