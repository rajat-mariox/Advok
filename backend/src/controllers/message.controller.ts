import type { Response } from 'express';
import type { AuthedRequest } from '../middlewares/auth.middleware';
import type {
  AdvocateProfile,
  ChatMessageRecord,
  ClientProfile,
  DbShape,
  LawFirmProfile,
  LawStudentProfile,
  User,
} from '../models';
import { createId, getDb, saveDb } from '../services/db.service';
import { publishToAdmins, publishToAll, publishToUser, publishToUsers } from '../services/realtime.service';
import { pushAdminNotification } from '../services/admin-notify.service';
import { sendPush } from '../services/push.service';

function messages(db: DbShape): ChatMessageRecord[] {
  db.messages ??= [];
  return db.messages;
}

/** Display name + photo for a chat peer, whatever their role. */
function peerDisplay(db: DbShape, userId: string) {
  const user = db.users.find((u) => u.id === userId);
  const p = user?.profile;
  let name: string | undefined;
  let photo: string | null = null;
  if (user?.role === 'advocate') {
    const ap = p as AdvocateProfile | undefined;
    name = ap?.professional.fullName;
    photo = ap?.photo ?? null;
  } else if (user?.role === 'client') {
    const cp = p as ClientProfile | undefined;
    name = cp?.fullName;
    photo = cp?.photo ?? null;
  } else if (user?.role === 'law_student') {
    const sp = p as LawStudentProfile | undefined;
    name = sp?.fullName;
    photo = sp?.photo ?? null;
  } else if (user?.role === 'law_firm') {
    const fp = p as LawFirmProfile | undefined;
    name = fp?.firmName;
    photo = fp?.photo ?? null;
  }
  const trimmed = name?.trim();
  return {
    peerId: userId,
    peerName:
      trimmed && trimmed.length > 0 ? trimmed : (user?.phone ?? 'User'),
    peerPhoto: photo,
    peerRole: user?.role ?? null,
  };
}

/**
 * What each side may see about the other inside a chat. Chat only exists
 * after an accepted consultation, so contact details are already shared.
 */
function peerDetails(db: DbShape, me: User, peerId: string) {
  const user = db.users.find((u) => u.id === peerId);
  if (!user) return null;
  const rows: { label: string; value: string }[] = [];
  const add = (label: string, value: string | undefined | null) => {
    const v = (value ?? '').toString().trim();
    if (v) rows.push({ label, value: v });
  };
  const phone = user.phone ? `${user.countryCode ?? ''} ${user.phone}`.trim() : '';
  let headline = '';
  let email = user.email ?? '';

  if (user.role === 'advocate') {
    const ap = user.profile as AdvocateProfile | undefined;
    const pro = ap?.professional;
    email = pro?.email || email;
    headline = [ap?.firmRole || (ap?.advocateType === 'senior' ? 'Senior Attorney' : 'Attorney'), pro?.practiceArea, user.firmName ? `at ${user.firmName}` : '']
      .filter(Boolean)
      .join(' · ');
    add('Practice Area', pro?.practiceArea);
    add('Firm Role', ap?.firmRole);
    add('Law Firm', user.firmName);
    add('Years in Practice', ap?.yearsInPractice);
    const bars = (pro?.barAdmissions ?? []).map((b) => `${b.state} #${b.barNumber}${b.licenseStatus ? ` (${b.licenseStatus})` : ''}`);
    add('Bar Admissions', bars.length ? bars.join(', ') : pro?.licenseNumber ? `#${pro.licenseNumber}` : '');
    add('Location', [ap?.location.district, ap?.location.state].filter(Boolean).join(', '));
    add('Office Address', ap?.location.officeAddress);
    add('Office Hours', ap?.schedule?.startTime ? `${(ap.schedule.workingDays ?? []).join(', ')} · ${ap.schedule.startTime} – ${ap.schedule.endTime}` : '');
  } else if (user.role === 'law_firm') {
    const fp = user.profile as LawFirmProfile | undefined;
    email = fp?.officialEmail || email;
    const expertise = Array.from(new Set((fp?.lawyers ?? []).flatMap((l) => l.expertise ?? [])));
    headline = ['Law Firm', fp?.city && fp?.state ? `${fp.city}, ${fp.state}` : ''].filter(Boolean).join(' · ');
    add('Managing Partner', fp?.contactPerson);
    add('Practice Areas', expertise.join(', '));
    add('Attorneys', fp?.totalLawyers ? `${fp.totalLawyers}` : `${(fp?.lawyers ?? []).length}`);
    add('Founded', fp?.foundedYear);
    add('Address', [fp?.addressLine1, fp?.addressLine2, fp?.city, fp?.state, fp?.zip].filter(Boolean).join(', '));
  } else if (user.role === 'law_student') {
    const sp = user.profile as LawStudentProfile | undefined;
    headline = ['Law Student', sp?.college].filter(Boolean).join(' · ');
    add('Law School', sp?.college);
    add('Degree Program', sp?.course);
    add('Year', sp?.academicYear);
  } else {
    // Client: what the attorney/firm needs — contact plus history with me.
    const cp = user.profile as ClientProfile | undefined;
    email = cp?.email || email;
    headline = ['Client', user.country].filter(Boolean).join(' · ');
    const bookings = (db.bookings ?? []).filter(
      (b) =>
        b.clientId === user.id &&
        (b.advocateId === me.id || b.assignedAttorney?.userId === me.id),
    );
    const held = bookings.filter((b) => b.status === 'confirmed' || b.status === 'completed');
    const upcoming = held
      .filter((b) => b.status === 'confirmed')
      .sort((a, b) => `${a.date} ${a.time}`.localeCompare(`${b.date} ${b.time}`))[0];
    const openCases = (db.cases ?? []).filter(
      (c) => c.clientId === user.id && c.advocateId === me.id && c.status !== 'closed',
    ).length;
    const since = (db.relationships ?? []).find(
      (r) => r.clientId === user.id && r.advocateId === me.id,
    )?.createdAt;
    add('Consultations with you', held.length ? `${held.length}` : '');
    add('Next consultation', upcoming ? `${upcoming.date} · ${upcoming.time}` : '');
    add('Open cases with you', openCases ? `${openCases}` : '');
    add('Client since', since ? since.slice(0, 10) : '');
    add('Country', user.country);
    add('Login', user.googleId ? 'Google' : user.appleId ? 'Apple' : 'Phone OTP');
  }

  return {
    id: user.id,
    role: user.role,
    name: peerDisplay(db, peerId).peerName,
    photo: peerDisplay(db, peerId).peerPhoto,
    headline,
    phone,
    email,
    rows,
  };
}

/**
 * Chat is allowed between a client and an advocate who have a relationship
 * (an accepted consultation). Messages already exchanged (e.g. the system
 * "case created" message) also keep a thread open.
 */
/**
 * A law firm never chats with a client directly — the attorney the firm
 * assigned does. Firms can still chat with attorneys they consult.
 */
function isFirmClientPair(db: DbShape, me: User, peerId: string): boolean {
  const peer = db.users.find((u) => u.id === peerId);
  if (!peer) return false;
  const roles = new Set([me.role, peer.role]);
  return roles.has('law_firm') && roles.has('client');
}

/** Display name for push titles / admin notifications. */
function senderName(u: User): string {
  const p = u.profile as
    | { fullName?: string; firmName?: string; professional?: { fullName?: string } }
    | undefined;
  return (
    p?.professional?.fullName?.trim() ||
    p?.fullName?.trim() ||
    p?.firmName?.trim() ||
    u.name?.trim() ||
    'ADVOK user'
  );
}

function canChat(db: DbShape, me: User, peerId: string): boolean {
  if (isFirmClientPair(db, me, peerId)) return false;
  const related = (db.relationships ?? []).some(
    (r) =>
      (r.advocateId === me.id && r.clientId === peerId) ||
      (r.clientId === me.id && r.advocateId === peerId),
  );
  if (related) return true;
  // Law students can reach out to any verified attorney (mentorship /
  // career guidance); the first message is the "connection".
  const peer = db.users.find((u) => u.id === peerId);
  const approved = (u: User | undefined) => !!u && (u.status === 'approved' || u.status === 'active');
  if (me.role === 'law_student' && peer?.role === 'advocate' && approved(peer)) return true;
  if (me.role === 'advocate' && peer?.role === 'law_student' && approved(peer)) return true;
  return messages(db).some(
    (m) =>
      (m.fromId === me.id && m.toId === peerId) ||
      (m.fromId === peerId && m.toId === me.id),
  );
}

function toApi(m: ChatMessageRecord) {
  return {
    id: m.id,
    fromId: m.fromId,
    toId: m.toId,
    text: m.text,
    system: m.system ?? false,
    meta: m.meta ?? null,
    sentAt: m.sentAt,
  };
}

/** The user's conversations: one row per peer, latest message first. */
export function listThreads(req: AuthedRequest, res: Response) {
  const me = req.user!;
  const db = getDb();

  const byPeer = new Map<string, { last: ChatMessageRecord; unread: number }>();
  for (const m of messages(db)) {
    const peerId =
      m.fromId === me.id ? m.toId : m.toId === me.id ? m.fromId : null;
    if (!peerId) continue;
    const entry = byPeer.get(peerId);
    const unreadDelta = m.toId === me.id && !m.readAt ? 1 : 0;
    if (!entry) {
      byPeer.set(peerId, { last: m, unread: unreadDelta });
    } else {
      if (m.sentAt.localeCompare(entry.last.sentAt) > 0) entry.last = m;
      entry.unread += unreadDelta;
    }
  }

  // Relationships without any messages yet still show as (empty) threads so
  // both sides can start the conversation.
  for (const r of db.relationships ?? []) {
    const peerId =
      r.advocateId === me.id ? r.clientId : r.clientId === me.id ? r.advocateId : null;
    if (peerId && !byPeer.has(peerId)) {
      byPeer.set(peerId, {
        last: {
          id: r.id,
          fromId: peerId,
          toId: me.id,
          text: 'You are now connected on ADVOK.',
          system: true,
          sentAt: r.createdAt,
          readAt: r.createdAt,
        },
        unread: 0,
      });
    }
  }

  const threads = [...byPeer.entries()]
    // Firm ↔ client threads don't exist (the assigned attorney chats).
    .filter(([peerId]) => !isFirmClientPair(db, me, peerId))
    .sort((a, b) => b[1].last.sentAt.localeCompare(a[1].last.sentAt))
    .map(([peerId, t]) => ({
      ...peerDisplay(db, peerId),
      lastMessage: t.last.text,
      lastAt: t.last.sentAt,
      lastFromMe: t.last.fromId === me.id,
      unread: t.unread,
    }));
  return res.json({ threads });
}

/**
 * The full thread with one peer, oldest first. Opening it marks the peer's
 * messages as read.
 */
export function getThread(req: AuthedRequest, res: Response) {
  const me = req.user!;
  const peerId = req.params.userId;
  const db = getDb();

  const thread = messages(db)
    .filter(
      (m) =>
        (m.fromId === me.id && m.toId === peerId) ||
        (m.fromId === peerId && m.toId === me.id),
    )
    .sort((a, b) => a.sentAt.localeCompare(b.sentAt));

  let changed = false;
  const now = new Date().toISOString();
  for (const m of thread) {
    if (m.toId === me.id && !m.readAt) {
      m.readAt = now;
      changed = true;
    }
  }
  if (changed) saveDb();
  if (changed && typeof peerId === 'string') publishToUser(peerId, 'messages', { peerId: me.id, read: true });

  return res.json({
    ...peerDisplay(db, peerId),
    peer: peerDetails(db, me, peerId),
    messages: thread.map(toApi),
  });
}

/** Sends a message to a related user. */
export function sendMessage(req: AuthedRequest, res: Response) {
  const me = req.user!;
  const peerId = req.params.userId;
  const { text } = req.body as { text?: string };

  const trimmed = text?.trim();
  if (!trimmed) {
    return res.status(400).json({ error: 'text is required' });
  }
  if (trimmed.length > 4000) {
    return res.status(400).json({ error: 'Message is too long' });
  }

  const db = getDb();
  const peer = db.users.find((u) => u.id === peerId);
  if (!peer || !canChat(db, me, peerId)) {
    return res
      .status(403)
      .json({ error: 'You can only message your ADVOK connections' });
  }

  const record: ChatMessageRecord = {
    id: createId(),
    fromId: me.id,
    toId: peerId,
    text: trimmed,
    sentAt: new Date().toISOString(),
  };
  messages(db).push(record);
  saveDb();
  publishToUser(peerId, 'messages', { peerId: me.id, messageId: record.id });
  publishToUser(me.id, 'messages', { peerId, messageId: record.id });
  // Phone push for the recipient (chat messages don't create in-app
  // notification rows — the Messages tab already shows them).
  sendPush(db, peerId, senderName(me), trimmed, { type: 'message', peerId: me.id });
  // Student ↔ attorney conversations are the admin's "mentorships" list.
  if (
    (me.role === 'law_student' && peer.role === 'advocate') ||
    (me.role === 'advocate' && peer.role === 'law_student')
  ) {
    const studentId = me.role === 'law_student' ? me.id : peerId;
    const attorneyId = me.role === 'law_student' ? peerId : me.id;
    const firstInPair =
      messages(db).filter(
        (m) =>
          (m.fromId === studentId && m.toId === attorneyId) ||
          (m.fromId === attorneyId && m.toId === studentId),
      ).length === 1;
    if (firstInPair && me.role === 'law_student') {
      pushAdminNotification(
        db,
        'mentorship',
        'New student–attorney conversation',
        `${senderName(me)} messaged ${senderName(peer)}.`,
        '/mentorships',
      );
      saveDb();
    }
    publishToAdmins('mentorships', { studentId });
  }
  return res.json({ message: toApi(record) });
}

/** The user's notifications, newest first, plus the unread count. */
export function listNotifications(req: AuthedRequest, res: Response) {
  const me = req.user!;
  const db = getDb();
  const mine = (db.notifications ?? [])
    .filter((n) => n.userId === me.id)
    .sort((a, b) => b.createdAt.localeCompare(a.createdAt));
  return res.json({
    notifications: mine,
    unread: mine.filter((n) => !n.readAt).length,
  });
}

/** Marks all of the user's notifications as read. */
export function markNotificationsRead(req: AuthedRequest, res: Response) {
  const me = req.user!;
  const db = getDb();
  const now = new Date().toISOString();
  let changed = false;
  for (const n of db.notifications ?? []) {
    if (n.userId === me.id && !n.readAt) {
      n.readAt = now;
      changed = true;
    }
  }
  if (changed) saveDb();
  return res.json({ ok: true });
}
