import { Router } from 'express';
import { getDb, publicUser, saveDb } from '../db';
import { requireRole } from '../middleware/auth';
import type { CmsSection, Role, UserStatus } from '../types';

const router = Router();

const REVIEWABLE_ROLES: Role[] = ['advocate', 'law_student', 'law_firm'];

router.use(requireRole('admin'));

/**
 * List registrations for review.
 * Query params: role=advocate|law_student|law_firm, status=pending_approval|approved|rejected
 */
router.get('/registrations', (req, res) => {
  const { role, status } = req.query;
  const db = getDb();
  let list = db.users.filter((u) => u.role && REVIEWABLE_ROLES.includes(u.role));
  if (typeof role === 'string' && role) list = list.filter((u) => u.role === role);
  if (typeof status === 'string' && status) list = list.filter((u) => u.status === status);
  list = [...list].sort((a, b) => (b.onboardedAt ?? b.createdAt).localeCompare(a.onboardedAt ?? a.createdAt));
  return res.json({ registrations: list.map(publicUser) });
});

/** All app users (non-admin). Optional ?role= filter — includes clients. */
router.get('/users', (req, res) => {
  const { role } = req.query;
  const db = getDb();
  let list = db.users.filter((u) => u.role !== 'admin');
  if (typeof role === 'string' && role) list = list.filter((u) => u.role === role);
  list = [...list].sort((a, b) => b.createdAt.localeCompare(a.createdAt));
  return res.json({ users: list.map(publicUser) });
});

/** Permanently removes a (non-admin) user account, e.g. test registrations. */
router.delete('/users/:id', (req, res) => {
  const db = getDb();
  const index = db.users.findIndex((u) => u.id === req.params.id && u.role !== 'admin');
  if (index === -1) return res.status(404).json({ error: 'User not found' });
  db.users.splice(index, 1);
  saveDb();
  return res.json({ ok: true });
});

/** Counts shown as badges in the admin panel. */
router.get('/registrations/counts', (_req, res) => {
  const db = getDb();
  const pending = db.users.filter((u) => u.status === 'pending_approval');
  return res.json({
    advocate: pending.filter((u) => u.role === 'advocate').length,
    law_student: pending.filter((u) => u.role === 'law_student').length,
    law_firm: pending.filter((u) => u.role === 'law_firm').length,
    total: pending.length,
  });
});

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

router.post('/registrations/:id/approve', (req, res) => {
  const user = review(req.params.id, 'approved');
  if (!user) return res.status(404).json({ error: 'Registration not found' });
  return res.json({ user: publicUser(user) });
});

router.post('/registrations/:id/reject', (req, res) => {
  const reason = typeof req.body?.reason === 'string' ? req.body.reason : undefined;
  const user = review(req.params.id, 'rejected', reason);
  if (!user) return res.status(404).json({ error: 'Registration not found' });
  return res.json({ user: publicUser(user) });
});

/** Move an already-reviewed registration back to pending. */
router.post('/registrations/:id/reopen', (req, res) => {
  const user = review(req.params.id, 'pending_approval');
  if (!user) return res.status(404).json({ error: 'Registration not found' });
  return res.json({ user: publicUser(user) });
});

/** CMS pages (Terms, Privacy, ...) with full content, for the editor. */
router.get('/cms', (_req, res) => {
  return res.json({ pages: getDb().cmsPages ?? [] });
});

/** Save edits to one CMS page. Body: { title, sections, lastUpdatedLabel }. */
router.put('/cms/:slug', (req, res) => {
  const db = getDb();
  const page = (db.cmsPages ?? []).find((p) => p.slug === req.params.slug);
  if (!page) return res.status(404).json({ error: 'Page not found' });

  const { title, sections, lastUpdatedLabel } = req.body ?? {};
  if (typeof title !== 'string' || !title.trim()) {
    return res.status(400).json({ error: 'Title is required' });
  }
  if (
    !Array.isArray(sections) ||
    sections.length === 0 ||
    !sections.every(
      (s: CmsSection) =>
        s && typeof s.title === 'string' && typeof s.body === 'string' && s.title.trim() && s.body.trim(),
    )
  ) {
    return res.status(400).json({ error: 'Each section needs a title and a body' });
  }

  page.title = title.trim();
  page.sections = sections.map((s: CmsSection) => ({ title: s.title.trim(), body: s.body.trim() }));
  page.lastUpdatedLabel =
    typeof lastUpdatedLabel === 'string' && lastUpdatedLabel.trim()
      ? lastUpdatedLabel.trim()
      : `Last updated: ${new Date().toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' })}`;
  page.updatedAt = new Date().toISOString();
  saveDb();
  return res.json({ page });
});

export default router;
