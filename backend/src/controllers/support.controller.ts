import type { Request, Response } from 'express';
import type { AuthedRequest } from '../middlewares/auth.middleware';
import type {
  AdvocateProfile,
  ClientProfile,
  DbShape,
  LawFirmProfile,
  LawStudentProfile,
  SupportCategory,
  SupportTicket,
  SupportTicketStatus,
} from '../models';
import { SUPPORT_CATEGORIES } from '../models';
import { createId, getDb, saveDb } from '../services/db.service';
import { pushNotification } from '../services/notify.service';
import { publishToAdmins, publishToAll, publishToUser, publishToUsers } from '../services/realtime.service';
import { pushAdminNotification } from '../services/admin-notify.service';

const STATUSES: SupportTicketStatus[] = ['open', 'in_progress', 'resolved'];
const MAX_TEXT = 4000;

function tickets(db: DbShape): SupportTicket[] {
  db.supportTickets ??= [];
  return db.supportTickets;
}

/** Display name + contact for the admin panel, whatever the user's role. */
function userDisplay(db: DbShape, userId: string) {
  const user = db.users.find((u) => u.id === userId);
  const p = user?.profile;
  let name: string | undefined;
  let email: string | undefined;
  let photo: string | null = null;
  if (user?.role === 'advocate') {
    const ap = p as AdvocateProfile | undefined;
    name = ap?.professional.fullName;
    email = ap?.professional.email;
    photo = ap?.photo ?? null;
  } else if (user?.role === 'client') {
    const cp = p as ClientProfile | undefined;
    name = cp?.fullName;
    email = cp?.email;
    photo = cp?.photo ?? null;
  } else if (user?.role === 'law_student') {
    const sp = p as LawStudentProfile | undefined;
    name = sp?.fullName;
    photo = sp?.photo ?? null;
  } else if (user?.role === 'law_firm') {
    const fp = p as LawFirmProfile | undefined;
    name = fp?.firmName;
    email = fp?.officialEmail;
    photo = fp?.photo ?? null;
  }
  const trimmed = name?.trim();
  return {
    userName: trimmed && trimmed.length > 0 ? trimmed : (user?.phone ?? 'User'),
    userEmail: email ?? null,
    userPhone: user ? `${user.countryCode ?? ''} ${user.phone ?? ''}`.trim() : null,
    userPhoto: photo,
    userRole: user?.role ?? null,
  };
}

function toApi(db: DbShape, t: SupportTicket) {
  return { ...t, ...userDisplay(db, t.userId) };
}

function cleanText(value: unknown, max = MAX_TEXT): string | null {
  if (typeof value !== 'string') return null;
  const trimmed = value.trim();
  if (!trimmed || trimmed.length > max) return null;
  return trimmed;
}

// ---------------------------------------------------------------- app side

/** User raises a ticket from Help & Support. */
export function createTicket(req: AuthedRequest, res: Response) {
  const me = req.user!;
  const { category, subject, message } = req.body ?? {};

  const cat = SUPPORT_CATEGORIES.includes(category) ? (category as SupportCategory) : null;
  const subj = cleanText(subject, 120);
  const msg = cleanText(message);
  if (!cat) return res.status(400).json({ error: 'Pick a valid category' });
  if (!subj) return res.status(400).json({ error: 'Subject is required (max 120 chars)' });
  if (!msg) return res.status(400).json({ error: 'Describe the issue (max 4000 chars)' });

  const db = getDb();
  const now = new Date().toISOString();
  const ticket: SupportTicket = {
    id: createId(),
    userId: me.id,
    role: me.role,
    category: cat,
    subject: subj,
    message: msg,
    status: 'open',
    replies: [],
    createdAt: now,
    updatedAt: now,
    userUnread: 0,
    adminUnread: 1,
  };
  tickets(db).push(ticket);
  pushAdminNotification(db, 'support_ticket', 'New support ticket', `${ticket.subject} (${ticket.category})`, '/support');
  saveDb();
  publishToUser(ticket.userId, 'support', { ticketId: ticket.id, status: ticket.status });
  publishToAdmins('support', { ticketId: ticket.id, status: ticket.status });
  return res.json({ ticket: toApi(db, ticket) });
}

/** The user's own tickets, newest activity first. */
export function listMyTickets(req: AuthedRequest, res: Response) {
  const me = req.user!;
  const db = getDb();
  const mine = tickets(db)
    .filter((t) => t.userId === me.id)
    .sort((a, b) => b.updatedAt.localeCompare(a.updatedAt));
  return res.json({
    tickets: mine.map((t) => toApi(db, t)),
    unread: mine.reduce((n, t) => n + t.userUnread, 0),
  });
}

/** One of the user's tickets; opening it clears their unread count. */
export function getMyTicket(req: AuthedRequest, res: Response) {
  const me = req.user!;
  const db = getDb();
  const ticket = tickets(db).find((t) => t.id === req.params.id && t.userId === me.id);
  if (!ticket) return res.status(404).json({ error: 'Ticket not found' });
  if (ticket.userUnread > 0) {
    ticket.userUnread = 0;
    saveDb();
  }
  return res.json({ ticket: toApi(db, ticket) });
}

/** User adds a follow-up message. Re-opens a resolved ticket. */
export function replyToMyTicket(req: AuthedRequest, res: Response) {
  const me = req.user!;
  const text = cleanText(req.body?.text);
  if (!text) return res.status(400).json({ error: 'Message is required' });

  const db = getDb();
  const ticket = tickets(db).find((t) => t.id === req.params.id && t.userId === me.id);
  if (!ticket) return res.status(404).json({ error: 'Ticket not found' });

  const now = new Date().toISOString();
  ticket.replies.push({ id: createId(), fromAdmin: false, text, createdAt: now });
  ticket.updatedAt = now;
  ticket.adminUnread += 1;
  pushAdminNotification(db, 'support_reply', 'Reply on a support ticket', `${ticket.subject}: ${text.length > 100 ? `${text.slice(0, 97)}…` : text}`, '/support');
  if (ticket.status === 'resolved') {
    ticket.status = 'open';
    delete ticket.resolvedAt;
  }
  saveDb();
  publishToUser(ticket.userId, 'support', { ticketId: ticket.id, status: ticket.status });
  publishToAdmins('support', { ticketId: ticket.id, status: ticket.status });
  return res.json({ ticket: toApi(db, ticket) });
}

// -------------------------------------------------------------- admin side

/** All tickets, optionally filtered by ?status=, newest activity first. */
export function adminListTickets(req: Request, res: Response) {
  const db = getDb();
  const status = req.query.status as string | undefined;
  const list = tickets(db)
    .filter((t) => !status || status === 'all' || t.status === status)
    .sort((a, b) => b.updatedAt.localeCompare(a.updatedAt));
  const all = tickets(db);
  return res.json({
    tickets: list.map((t) => toApi(db, t)),
    counts: {
      open: all.filter((t) => t.status === 'open').length,
      in_progress: all.filter((t) => t.status === 'in_progress').length,
      resolved: all.filter((t) => t.status === 'resolved').length,
      unread: all.reduce((n, t) => n + t.adminUnread, 0),
    },
  });
}

/** Opening a ticket in the admin panel clears its admin-unread count. */
export function adminGetTicket(req: Request, res: Response) {
  const db = getDb();
  const ticket = tickets(db).find((t) => t.id === req.params.id);
  if (!ticket) return res.status(404).json({ error: 'Ticket not found' });
  if (ticket.adminUnread > 0) {
    ticket.adminUnread = 0;
    saveDb();
  }
  return res.json({ ticket: toApi(db, ticket) });
}

/**
 * Admin replies. Moves an open ticket to in_progress and notifies the user
 * in-app. Body: { text, status? } — status lets the admin reply and resolve
 * in one step.
 */
export function adminReplyTicket(req: Request, res: Response) {
  const text = cleanText(req.body?.text);
  if (!text) return res.status(400).json({ error: 'Reply text is required' });
  const nextStatus = req.body?.status as string | undefined;
  if (nextStatus !== undefined && !STATUSES.includes(nextStatus as SupportTicketStatus)) {
    return res.status(400).json({ error: 'Invalid status' });
  }

  const db = getDb();
  const ticket = tickets(db).find((t) => t.id === req.params.id);
  if (!ticket) return res.status(404).json({ error: 'Ticket not found' });

  const now = new Date().toISOString();
  ticket.replies.push({ id: createId(), fromAdmin: true, text, createdAt: now });
  ticket.updatedAt = now;
  ticket.userUnread += 1;
  ticket.adminUnread = 0;
  // Replying moves a fresh ticket to in-progress and reopens a resolved one
  // (the admin is clearly still talking to the user).
  applyStatus(ticket, (nextStatus as SupportTicketStatus | undefined) ??
    (ticket.status === 'open' || ticket.status === 'resolved' ? 'in_progress' : ticket.status), now);

  pushNotification(
    db,
    ticket.userId,
    'support_reply',
    ticket.status === 'resolved' ? 'Your support ticket was resolved' : 'Support replied to your ticket',
    `${ticket.subject}: ${text.length > 120 ? `${text.slice(0, 117)}…` : text}`,
    { ticketId: ticket.id },
  );
  saveDb();
  publishToUser(ticket.userId, 'support', { ticketId: ticket.id, status: ticket.status });
  publishToAdmins('support', { ticketId: ticket.id, status: ticket.status });
  return res.json({ ticket: toApi(db, ticket) });
}

/** Admin changes the status without replying. Body: { status }. */
export function adminSetTicketStatus(req: Request, res: Response) {
  const status = req.body?.status as string | undefined;
  if (!status || !STATUSES.includes(status as SupportTicketStatus)) {
    return res.status(400).json({ error: 'Invalid status' });
  }
  const db = getDb();
  const ticket = tickets(db).find((t) => t.id === req.params.id);
  if (!ticket) return res.status(404).json({ error: 'Ticket not found' });

  const now = new Date().toISOString();
  const was = ticket.status;
  applyStatus(ticket, status as SupportTicketStatus, now);
  ticket.updatedAt = now;
  if (was !== 'resolved' && ticket.status === 'resolved') {
    ticket.userUnread += 1;
    pushNotification(
      db,
      ticket.userId,
      'support_reply',
      'Your support ticket was resolved',
      ticket.subject,
      { ticketId: ticket.id },
    );
  }
  saveDb();
  publishToUser(ticket.userId, 'support', { ticketId: ticket.id, status: ticket.status });
  publishToAdmins('support', { ticketId: ticket.id, status: ticket.status });
  return res.json({ ticket: toApi(db, ticket) });
}

function applyStatus(ticket: SupportTicket, status: SupportTicketStatus, now: string) {
  ticket.status = status;
  if (status === 'resolved') ticket.resolvedAt = now;
  else delete ticket.resolvedAt;
}
