import type { Response } from 'express';
import type { AuthedRequest } from '../middlewares/auth.middleware';
import type {
  AdvocateProfile,
  CaseDocument,
  CaseEvent,
  CasePriority,
  CaseRecord,
  CaseStatus,
  ClientProfile,
  DbShape,
  DocumentRequest,
} from '../models';
import { syncCaseWithCourt, type CaseSyncResult } from '../services/case-sync.service';
import { courtsForState, lookupDocket, usCourts } from '../services/court.service';
import { createId, getDb, saveDb } from '../services/db.service';
import { pushNotification, pushSystemMessage } from '../services/notify.service';
import { storeFile } from '../services/storage.service';
import { publishToAdmins, publishToAll, publishToUser, publishToUsers } from '../services/realtime.service';

/** ~10MB of file content, before base64's ~4/3 overhead. */
const MAX_DOCUMENT_BASE64_LENGTH = 14 * 1024 * 1024;

const CASE_STATUSES: CaseStatus[] = ['active', 'discovery', 'hearing', 'closed'];
const CASE_PRIORITIES: CasePriority[] = ['high', 'medium', 'low'];

function cases(db: DbShape): CaseRecord[] {
  db.cases ??= [];
  return db.cases;
}

function isDay(value: unknown): value is string {
  return typeof value === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(value);
}

function clientDisplay(db: DbShape, clientId: string) {
  const client = db.users.find((u) => u.id === clientId);
  const cp = client?.profile as ClientProfile | undefined;
  const name = cp?.fullName ?? client?.name;
  return {
    clientName:
      name && name.trim().length > 0 ? name : (client?.phone ?? 'Client'),
    clientPhoto: cp?.photo ?? null,
    clientPhone: client?.phone ?? null,
  };
}

/** Case plus the display fields each side needs. */
function toApi(record: CaseRecord, db: DbShape) {
  const advocate = db.users.find((u) => u.id === record.advocateId);
  const ap = advocate?.profile as AdvocateProfile | undefined;
  return {
    ...record,
    ...clientDisplay(db, record.clientId),
    advocateName: ap?.professional.fullName ?? 'Attorney',
    advocatePhoto: ap?.photo ?? null,
    firmName: advocate?.firmName ?? null,
  };
}

/** True when the case belongs to an attorney on this firm's team. */
function firmOwnsCase(db: DbShape, firmId: string, record: CaseRecord): boolean {
  const advocate = db.users.find((u) => u.id === record.advocateId);
  return advocate?.firmId === firmId;
}

/**
 * The advocate's client directory: everyone whose consultation request they
 * have accepted, newest relationship first.
 */
export function listMyClients(req: AuthedRequest, res: Response) {
  const me = req.user!;
  const db = getDb();
  const mine = (db.relationships ?? []).filter((r) => r.advocateId === me.id);
  const sorted = [...mine].sort((a, b) => b.createdAt.localeCompare(a.createdAt));
  return res.json({
    clients: sorted.map((r) => {
      const booking = (db.bookings ?? []).find((b) => b.id === r.bookingId);
      const openCases = cases(db).filter(
        (c) =>
          c.advocateId === me.id &&
          c.clientId === r.clientId &&
          c.status !== 'closed',
      ).length;
      const sessions = (db.bookings ?? []).filter(
        (b) =>
          b.advocateId === me.id &&
          b.clientId === r.clientId &&
          (b.status === 'confirmed' || b.status === 'completed'),
      ).length;
      return {
        clientId: r.clientId,
        since: r.createdAt,
        consultationType: booking?.consultationType ?? null,
        openCases,
        sessions,
        ...clientDisplay(db, r.clientId),
      };
    }),
  });
}

/**
 * Attorney opens a case for an existing Advok client. The client must already
 * have a relationship with the attorney (i.e. an accepted consultation).
 * When the attorney picked a docket-lookup match, `courtDocketId` links the
 * case to that docket and the court records are pulled in right away.
 */
export async function createCase(req: AuthedRequest, res: Response) {
  const me = req.user!;
  const body = req.body as {
    clientId?: string;
    title?: string;
    caseNumber?: string;
    court?: string;
    practiceArea?: string;
    status?: string;
    priority?: string;
    filedDate?: string;
    nextHearing?: string;
    courtDocketId?: number | string;
  };

  if (!body.clientId || !body.title?.trim() || !body.caseNumber?.trim() || !body.court?.trim()) {
    return res
      .status(400)
      .json({ error: 'clientId, title, caseNumber and court are required' });
  }

  const db = getDb();
  const related = (db.relationships ?? []).some(
    (r) => r.advocateId === me.id && r.clientId === body.clientId,
  );
  if (!related) {
    return res.status(403).json({
      error: 'Cases can only be opened for your existing Advok clients',
    });
  }

  const now = new Date().toISOString();
  const record: CaseRecord = {
    id: createId(),
    advocateId: me.id,
    clientId: body.clientId,
    title: body.title.trim(),
    caseNumber: body.caseNumber.trim(),
    court: body.court.trim(),
    practiceArea: body.practiceArea?.trim() || undefined,
    status: CASE_STATUSES.includes(body.status as CaseStatus)
      ? (body.status as CaseStatus)
      : 'active',
    priority: CASE_PRIORITIES.includes(body.priority as CasePriority)
      ? (body.priority as CasePriority)
      : undefined,
    filedDate: isDay(body.filedDate) ? body.filedDate : undefined,
    nextHearing: isDay(body.nextHearing) ? body.nextHearing : undefined,
    timeline: [
      {
        id: createId(),
        date: now.slice(0, 10),
        title: 'Case created on ADVOK',
        source: 'attorney',
        createdAt: now,
      },
    ],
    createdAt: now,
    updatedAt: now,
  };
  const docketId = Number(body.courtDocketId);
  let sync: CaseSyncResult | undefined;
  if (Number.isInteger(docketId) && docketId > 0) {
    record.courtRecord = {
      provider: 'courtlistener',
      docketId,
      url: `https://www.courtlistener.com/docket/${docketId}/`,
    };
    // Initial pull: filing date, judge, existing docket entries and whether
    // the court has already closed it. A provider hiccup does not block
    // creating the case — the scheduled sync retries later.
    sync = await syncCaseWithCourt(db, record);
  }
  cases(db).push(record);

  // Tell the client their case is now on ADVOK, and open the chat thread
  // with a system message so both sides can start talking right away.
  const advocate = db.users.find((u) => u.id === me.id);
  const ap = advocate?.profile as AdvocateProfile | undefined;
  const advocateName = ap?.professional.fullName ?? 'Your attorney';
  pushNotification(
    db,
    record.clientId,
    'case_assigned',
    'Case assigned to you',
    `${advocateName} has taken your case "${record.title}" ` +
      `(${record.caseNumber}). Track updates in My Cases.`,
    { caseId: record.id },
  );
  pushSystemMessage(
    db,
    me.id,
    record.clientId,
    `Case created: "${record.title}" (${record.caseNumber}) — ${record.court}.`,
  );
  saveDb();
  publishToUsers([record.clientId, record.advocateId], 'cases', { caseId: record.id });
  publishToUser(record.advocateId, 'clients');
  publishToAdmins('cases', { caseId: record.id });
  return res.json({ case: toApi(record, db), sync });
}

/**
 * POST /cases/:id/link — body { courtDocketId }. Links a case that was
 * created manually (or with the wrong match) to a CourtListener docket and
 * pulls its records right away. Re-linking to a different docket drops the
 * old docket's timeline entries.
 */
export async function linkCase(req: AuthedRequest, res: Response) {
  const me = req.user!;
  const db = getDb();
  const record = cases(db).find((c) => c.id === req.params.id);
  if (!record || record.advocateId !== me.id) {
    return res.status(404).json({ error: 'Case not found' });
  }
  const docketId = Number((req.body as { courtDocketId?: unknown } | undefined)?.courtDocketId);
  if (!Number.isInteger(docketId) || docketId <= 0) {
    return res.status(400).json({ error: 'courtDocketId is required' });
  }
  if (record.courtRecord && record.courtRecord.docketId !== docketId) {
    record.timeline = record.timeline.filter((e) => e.source !== 'court_api');
  }
  record.courtRecord = {
    provider: 'courtlistener',
    docketId,
    url: `https://www.courtlistener.com/docket/${docketId}/`,
  };
  const sync = await syncCaseWithCourt(db, record);
  record.updatedAt = new Date().toISOString();
  saveDb();
  publishToUsers([record.clientId, record.advocateId], 'cases', { caseId: record.id });
  publishToAdmins('cases', { caseId: record.id });
  return res.json({ case: toApi(record, db), sync });
}

/**
 * Attorney pulls the latest court records for a linked case: new docket
 * entries join the timeline and a terminated docket closes the case.
 */
export async function syncCase(req: AuthedRequest, res: Response) {
  const me = req.user!;
  const db = getDb();
  const record = cases(db).find((c) => c.id === req.params.id);
  if (!record || record.advocateId !== me.id) {
    return res.status(404).json({ error: 'Case not found' });
  }
  if (!record.courtRecord) {
    return res.status(400).json({
      error: 'This case is not linked to court records. Cases added with a docket lookup match sync automatically.',
    });
  }
  const sync = await syncCaseWithCourt(db, record);
  saveDb();
  publishToUsers([record.clientId, record.advocateId], 'cases', { caseId: record.id });
  publishToUser(record.advocateId, 'clients');
  publishToAdmins('cases', { caseId: record.id });
  return res.json({ case: toApi(record, db), sync });
}

/** Cases for the requesting user: their own side, newest first. */
export function listMyCases(req: AuthedRequest, res: Response) {
  const me = req.user!;
  const db = getDb();
  const mine = cases(db).filter((c) =>
    me.role === 'advocate'
      ? c.advocateId === me.id
      : me.role === 'law_firm'
        ? firmOwnsCase(db, me.id, c)
        : c.clientId === me.id,
  );
  const sorted = [...mine].sort((a, b) => b.updatedAt.localeCompare(a.updatedAt));
  return res.json({ cases: sorted.map((c) => toApi(c, db)) });
}

/** One case with its full timeline — visible to either party. */
export function getCase(req: AuthedRequest, res: Response) {
  const me = req.user!;
  const db = getDb();
  const record = cases(db).find((c) => c.id === req.params.id);
  if (!record || (record.advocateId !== me.id && record.clientId !== me.id && !(me.role === 'law_firm' && firmOwnsCase(db, me.id, record)))) {
    return res.status(404).json({ error: 'Case not found' });
  }
  return res.json({ case: toApi(record, db) });
}

/**
 * Attorney posts an update: a timeline event and/or a status, priority or
 * next-hearing change. The client sees it on their case view.
 */
export function addCaseUpdate(req: AuthedRequest, res: Response) {
  const me = req.user!;
  const body = req.body as {
    title?: string;
    description?: string;
    date?: string;
    status?: string;
    priority?: string;
    nextHearing?: string;
  };

  const db = getDb();
  const record = cases(db).find((c) => c.id === req.params.id);
  if (!record || record.advocateId !== me.id) {
    return res.status(404).json({ error: 'Case not found' });
  }

  const hasStatus = CASE_STATUSES.includes(body.status as CaseStatus);
  const hasPriority = CASE_PRIORITIES.includes(body.priority as CasePriority);
  const hasHearing = isDay(body.nextHearing);
  if (!body.title?.trim() && !hasStatus && !hasPriority && !hasHearing) {
    return res.status(400).json({
      error: 'An update needs a title, status, priority or nextHearing',
    });
  }

  const now = new Date().toISOString();
  const label = (v: string) => v.charAt(0).toUpperCase() + v.slice(1);
  if (body.title?.trim()) {
    const event: CaseEvent = {
      id: createId(),
      date: isDay(body.date) ? body.date : now.slice(0, 10),
      title: body.title.trim(),
      description: body.description?.trim() || undefined,
      source: 'attorney',
      createdAt: now,
    };
    record.timeline.push(event);
  }
  // Field changes are recorded on the timeline too, so the history of a
  // case (Active → Discovery → Hearing …) stays visible to both sides.
  const changes: string[] = [];
  if (hasStatus && body.status !== record.status) {
    changes.push(`Status changed to ${label(body.status!)} (was ${label(record.status)})`);
    record.status = body.status as CaseStatus;
  }
  if (hasPriority && body.priority !== record.priority) {
    changes.push(`Priority set to ${label(body.priority!)}${record.priority ? ` (was ${label(record.priority)})` : ''}`);
    record.priority = body.priority as CasePriority;
  }
  if (hasHearing && body.nextHearing !== record.nextHearing) {
    changes.push(`Next court event set to ${body.nextHearing}${record.nextHearing ? ` (was ${record.nextHearing})` : ''}`);
    record.nextHearing = body.nextHearing;
  }
  if (changes.length > 0) {
    record.timeline.push({
      id: createId(),
      date: now.slice(0, 10),
      title: changes[0].split(' (was')[0],
      description: changes.length > 1 ? changes.join('. ') : changes[0].includes('(was') ? changes[0].slice(changes[0].indexOf('(') + 1, -1) : undefined,
      source: 'attorney',
      createdAt: now,
    });
  }
  record.updatedAt = now;

  const parts: string[] = [];
  if (body.title?.trim()) parts.push(body.title.trim());
  if (hasStatus) parts.push(`status changed to ${body.status}`);
  if (hasHearing) parts.push(`next court event ${body.nextHearing}`);
  pushNotification(
    db,
    record.clientId,
    'case_update',
    `Update on "${record.title}"`,
    parts.join(' · ') || 'Your case was updated.',
    { caseId: record.id },
  );
  saveDb();
  publishToUsers([record.clientId, record.advocateId], 'cases', { caseId: record.id });
  publishToUser(record.advocateId, 'clients');
  publishToAdmins('cases', { caseId: record.id });
  return res.json({ case: toApi(record, db) });
}

/**
 * Attorney attaches a file to a case. The file arrives as a base64 data URL
 * and is stored on S3 when configured, else kept inline. The client sees it
 * on their case view and gets a notification.
 */
export async function addCaseDocument(req: AuthedRequest, res: Response) {
  const me = req.user!;
  const body = req.body as { name?: string; file?: string };

  const db = getDb();
  const record = cases(db).find((c) => c.id === req.params.id);
  if (!record || record.advocateId !== me.id) {
    return res.status(404).json({ error: 'Case not found' });
  }

  const name = body.name?.trim();
  if (!name || !body.file?.startsWith('data:')) {
    return res
      .status(400)
      .json({ error: 'name and file (a base64 data URL) are required' });
  }
  if (body.file.length > MAX_DOCUMENT_BASE64_LENGTH) {
    return res.status(413).json({ error: 'File too large. Max size is 10MB.' });
  }

  let url: string;
  try {
    url = await storeFile(body.file, `case-documents/${record.id}`);
  } catch (err) {
    console.error('Document upload to S3 failed:', err);
    return res.status(502).json({ error: 'Document upload failed, try again' });
  }

  const now = new Date().toISOString();
  const doc: CaseDocument = {
    id: createId(),
    name,
    url,
    sizeBytes: Math.floor((body.file.length - body.file.indexOf(',') - 1) * 3 / 4),
    uploadedAt: now,
  };
  record.documents ??= [];
  record.documents.push(doc);
  record.timeline.push({
    id: createId(),
    date: now.slice(0, 10),
    title: `Document added: ${name}`,
    source: 'attorney',
    createdAt: now,
  });
  record.updatedAt = now;
  pushNotification(
    db,
    record.clientId,
    'case_update',
    `Update on "${record.title}"`,
    `Document added: ${name}`,
    { caseId: record.id },
  );
  saveDb();
  publishToUsers([record.clientId, record.advocateId], 'cases', { caseId: record.id });
  publishToUser(record.advocateId, 'clients');
  publishToAdmins('cases', { caseId: record.id });
  return res.json({ case: toApi(record, db) });
}

/**
 * Attorney asks the client for a document. The request is tracked on the
 * case and dropped into the chat thread as a card the client can upload
 * against; the timeline records it too.
 */
export function requestCaseDocument(req: AuthedRequest, res: Response) {
  const me = req.user!;
  const body = req.body as { name?: string; note?: string };

  const db = getDb();
  const record = cases(db).find((c) => c.id === req.params.id);
  if (!record || record.advocateId !== me.id) {
    return res.status(404).json({ error: 'Case not found' });
  }

  const name = body.name?.trim();
  if (!name) {
    return res.status(400).json({ error: 'name is required' });
  }
  const note = body.note?.trim() || undefined;

  const now = new Date().toISOString();
  const request: DocumentRequest = {
    id: createId(),
    name,
    note,
    status: 'pending',
    requestedAt: now,
  };
  record.documentRequests ??= [];
  record.documentRequests.push(request);
  record.timeline.push({
    id: createId(),
    date: now.slice(0, 10),
    title: `Document requested: ${name}`,
    description: note ?? 'Requested from the client',
    source: 'attorney',
    createdAt: now,
  });
  record.updatedAt = now;

  pushSystemMessage(
    db,
    me.id,
    record.clientId,
    `Document requested: ${name} (case ${record.caseNumber})`,
    {
      kind: 'document_request',
      requestId: request.id,
      caseId: record.id,
      caseNumber: record.caseNumber,
      caseTitle: record.title,
      docName: name,
      note: note ?? null,
      status: 'pending',
    },
  );
  pushNotification(
    db,
    record.clientId,
    'case_update',
    `Document needed for "${record.title}"`,
    `Your attorney requested: ${name}. Upload it from your Messages.`,
    { caseId: record.id },
  );
  saveDb();
  publishToUsers([record.clientId, record.advocateId], 'cases', { caseId: record.id });
  publishToUser(record.advocateId, 'clients');
  publishToAdmins('cases', { caseId: record.id });
  return res.json({ case: toApi(record, db) });
}

/**
 * Client uploads the document their attorney asked for. The file joins the
 * case documents, the request card in the chat flips to "uploaded", and the
 * timeline + attorney notification record it.
 */
export async function uploadRequestedDocument(req: AuthedRequest, res: Response) {
  const me = req.user!;
  const body = req.body as { name?: string; file?: string };

  const db = getDb();
  const record = cases(db).find((c) => c.id === req.params.id);
  if (!record || record.clientId !== me.id) {
    return res.status(404).json({ error: 'Case not found' });
  }
  const request = (record.documentRequests ?? []).find(
    (r) => r.id === req.params.requestId,
  );
  if (!request) {
    return res.status(404).json({ error: 'Document request not found' });
  }
  if (request.status === 'uploaded') {
    return res.status(409).json({ error: 'This document was already uploaded' });
  }

  const name = body.name?.trim() || request.name;
  if (!body.file?.startsWith('data:')) {
    return res
      .status(400)
      .json({ error: 'file (a base64 data URL) is required' });
  }
  if (body.file.length > MAX_DOCUMENT_BASE64_LENGTH) {
    return res.status(413).json({ error: 'File too large. Max size is 10MB.' });
  }

  let url: string;
  try {
    url = await storeFile(body.file, `case-documents/${record.id}`);
  } catch (err) {
    console.error('Document upload to S3 failed:', err);
    return res.status(502).json({ error: 'Document upload failed, try again' });
  }

  const now = new Date().toISOString();
  const doc: CaseDocument = {
    id: createId(),
    name,
    url,
    sizeBytes: Math.floor((body.file.length - body.file.indexOf(',') - 1) * 3 / 4),
    uploadedBy: 'client',
    uploadedAt: now,
  };
  record.documents ??= [];
  record.documents.push(doc);
  request.status = 'uploaded';
  request.uploadedAt = now;
  request.documentId = doc.id;
  record.timeline.push({
    id: createId(),
    date: now.slice(0, 10),
    title: `Document received: ${request.name}`,
    description: `Uploaded by the client (${name})`,
    source: 'client',
    createdAt: now,
  });
  record.updatedAt = now;

  // Flip the request card in the chat thread to "uploaded" so both sides
  // see the new state on their next poll.
  const card = (db.messages ?? []).find(
    (m) =>
      m.meta?.kind === 'document_request' && m.meta?.requestId === request.id,
  );
  if (card?.meta) {
    card.meta.status = 'uploaded';
    card.meta.docId = doc.id;
    card.meta.fileName = name;
    card.meta.uploadedAt = now;
  }
  pushSystemMessage(
    db,
    me.id,
    record.advocateId,
    `Document uploaded: ${name} (case ${record.caseNumber})`,
  );
  pushNotification(
    db,
    record.advocateId,
    'case_update',
    `Document received on "${record.title}"`,
    `The client uploaded: ${name}.`,
    { caseId: record.id },
  );
  saveDb();
  publishToUsers([record.clientId, record.advocateId], 'cases', { caseId: record.id });
  publishToUser(record.advocateId, 'clients');
  publishToAdmins('cases', { caseId: record.id });
  return res.json({ case: toApi(record, db) });
}

/** Attorney removes a document they attached to the case. */
export function removeCaseDocument(req: AuthedRequest, res: Response) {
  const me = req.user!;
  const db = getDb();
  const record = cases(db).find((c) => c.id === req.params.id);
  if (!record || record.advocateId !== me.id) {
    return res.status(404).json({ error: 'Case not found' });
  }
  const docs = record.documents ?? [];
  const index = docs.findIndex((d) => d.id === req.params.docId);
  if (index === -1) {
    return res.status(404).json({ error: 'Document not found' });
  }
  docs.splice(index, 1);
  record.updatedAt = new Date().toISOString();
  saveDb();
  publishToUsers([record.clientId, record.advocateId], 'cases', { caseId: record.id });
  publishToUser(record.advocateId, 'clients');
  publishToAdmins('cases', { caseId: record.id });
  return res.json({ case: toApi(record, db) });
}

/**
 * Court API search for the Add Case flow. Returns `available: false` when no
 * court-records provider is configured — the app then falls back to manual
 * entry, which is also the standard path for state courts.
 */
export async function docketLookup(req: AuthedRequest, res: Response) {
  const caseNumber = (req.query.caseNumber as string | undefined)?.trim();
  if (!caseNumber) {
    return res.status(400).json({ error: 'caseNumber is required' });
  }
  const state = (req.query.state as string | undefined)?.trim() || undefined;
  const court = (req.query.court as string | undefined)?.trim();
  try {
    const result = await lookupDocket(caseNumber, {
      state,
      courtIds: court ? court.split(/[\s,]+/).filter(Boolean) : undefined,
    });
    return res.json(result);
  } catch (err) {
    console.error('Docket lookup failed:', err);
    return res.json({ available: false, results: [], exact: false });
  }
}

/**
 * GET /cases/courts?state=Texas — federal district and bankruptcy courts the
 * attorney can narrow a docket search to. Without a state, every court.
 */
export function listCourts(req: AuthedRequest, res: Response) {
  const state = (req.query.state as string | undefined)?.trim();
  const courts = state ? courtsForState(state) : usCourts();
  return res.json({ courts });
}
