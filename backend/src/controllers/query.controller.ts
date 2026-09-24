import type { Request, Response } from 'express';
import type { AuthedRequest } from '../middlewares/auth.middleware';
import type { DbShape, LawStudentProfile, LegalQueryRecord, LegalQueryStatus } from '../models';
import { createId, getDb, saveDb } from '../services/db.service';
import { pushNotification } from '../services/notify.service';
import { publishToAdmins, publishToAll, publishToUser, publishToUsers } from '../services/realtime.service';
import { pushAdminNotification } from '../services/admin-notify.service';

const MAX_QUESTION = 500;
const MAX_RESPONSE = 4000;
const STATUSES: LegalQueryStatus[] = ['pending', 'answered'];
const DEFAULT_RESPONDER = 'ADVOK Legal Team';

function queries(db: DbShape): LegalQueryRecord[] {
  db.legalQueries ??= [];
  return db.legalQueries;
}

const str = (v: unknown, max: number) => (typeof v === 'string' ? v.trim().slice(0, max) : '');

function studentDisplay(db: DbShape, studentId: string) {
  const user = db.users.find((u) => u.id === studentId);
  const p = user?.profile as LawStudentProfile | undefined;
  return {
    studentName: p?.fullName?.trim() || user?.name || user?.phone || 'Law student',
    studentCollege: p?.college ?? null,
    studentPhoto: p?.photo ?? null,
    studentPhone: user?.phone ?? null,
    studentEmail: user?.email ?? null,
  };
}

// ------------------------------------------------------------- app (students)

/** GET /queries — my queries, newest first. */
export function listMyQueries(req: AuthedRequest, res: Response) {
  const me = req.user!;
  const mine = queries(getDb())
    .filter((q) => q.studentId === me.id)
    .sort((a, b) => b.createdAt.localeCompare(a.createdAt));
  return res.json({ queries: mine });
}

/** POST /queries — body { category, question }. */
export function createQuery(req: AuthedRequest, res: Response) {
  const me = req.user!;
  const body = (req.body ?? {}) as { category?: unknown; question?: unknown };
  const category = str(body.category, 60);
  const question = str(body.question, MAX_QUESTION + 1);
  if (!category || !question) {
    return res.status(400).json({ error: 'category and question are required' });
  }
  if (question.length > MAX_QUESTION) {
    return res.status(400).json({ error: `Questions must be ${MAX_QUESTION} characters or fewer` });
  }
  const db = getDb();
  const now = new Date().toISOString();
  const record: LegalQueryRecord = {
    id: createId(),
    studentId: me.id,
    category,
    question,
    status: 'pending',
    createdAt: now,
    updatedAt: now,
  };
  queries(db).push(record);
  pushAdminNotification(db, 'legal_query', 'New legal query', `${studentDisplay(db, me.id).studentName} · ${category}: ${question.length > 100 ? `${question.slice(0, 97)}…` : question}`, '/legal-queries');
  saveDb();
  publishToAdmins('queries', { queryId: record.id, status: record.status });
  publishToUser(me.id, 'queries', { queryId: record.id });
  return res.json({ query: record });
}

// ------------------------------------------------------------------ admin

/** GET /admin/queries?status=&category= — every query with student details. */
export function adminList(req: Request, res: Response) {
  const db = getDb();
  const status = str(req.query.status, 20) as LegalQueryStatus | '';
  const category = str(req.query.category, 60);
  let list = queries(db);
  if (STATUSES.includes(status as LegalQueryStatus)) list = list.filter((q) => q.status === status);
  if (category) list = list.filter((q) => q.category === category);
  const sorted = [...list].sort((a, b) => {
    // Pending first, then newest.
    if (a.status !== b.status) return a.status === 'pending' ? -1 : 1;
    return b.createdAt.localeCompare(a.createdAt);
  });
  return res.json({
    queries: sorted.map((q) => ({ ...q, ...studentDisplay(db, q.studentId) })),
    counts: {
      total: queries(db).length,
      pending: queries(db).filter((q) => q.status === 'pending').length,
      answered: queries(db).filter((q) => q.status === 'answered').length,
    },
  });
}

/** POST /admin/queries/:id/answer — body { response, responderName? }. Re-answering updates the reply. */
export function adminAnswer(req: AuthedRequest, res: Response) {
  const db = getDb();
  const q = queries(db).find((x) => x.id === req.params.id);
  if (!q) return res.status(404).json({ error: 'Query not found' });
  const body = (req.body ?? {}) as { response?: unknown; responderName?: unknown };
  const response = str(body.response, MAX_RESPONSE);
  if (!response) return res.status(400).json({ error: 'response is required' });
  const now = new Date().toISOString();
  const firstAnswer = q.status !== 'answered';
  q.response = response;
  q.responderName = str(body.responderName, 80) || q.responderName || DEFAULT_RESPONDER;
  q.responderId = req.user?.id;
  q.status = 'answered';
  q.answeredAt = now;
  q.updatedAt = now;
  pushNotification(
    db,
    q.studentId,
    'query_answered',
    firstAnswer ? 'Your legal query was answered' : 'Your legal query reply was updated',
    `${q.responderName} replied to "${q.question.slice(0, 80)}${q.question.length > 80 ? '…' : ''}". Open Legal Queries to read it.`,
    { queryId: q.id },
  );
  saveDb();
  publishToAdmins('queries', { queryId: q.id, status: q.status });
  return res.json({ query: { ...q, ...studentDisplay(db, q.studentId) } });
}

/** DELETE /admin/queries/:id */
export function adminDelete(req: Request, res: Response) {
  const db = getDb();
  const list = queries(db);
  const idx = list.findIndex((x) => x.id === req.params.id);
  if (idx === -1) return res.status(404).json({ error: 'Query not found' });
  const removed = list[idx];
  list.splice(idx, 1);
  db.notifications = (db.notifications ?? []).filter((n) => n.queryId !== req.params.id);
  saveDb();
  publishToUser(removed.studentId, 'queries', { queryId: removed.id, deleted: true });
  publishToUser(removed.studentId, 'notifications');
  publishToAdmins('queries', { queryId: removed.id, deleted: true });
  return res.json({ ok: true });
}
