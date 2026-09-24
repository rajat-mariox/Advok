import type { Request, Response } from 'express';
import type { AdvocateProfile, ChatMessageRecord, DbShape, LawStudentProfile } from '../models';
import { getDb } from '../services/db.service';

/**
 * Admin view of law student ↔ attorney connections ("mentorships"): every
 * pair that has exchanged messages, with the conversation available for
 * review. A student connects simply by messaging an attorney from the
 * Attorneys tab; nothing else is required.
 */

function messages(db: DbShape): ChatMessageRecord[] {
  db.messages ??= [];
  return db.messages;
}

function roleOf(db: DbShape, id: string) {
  return db.users.find((u) => u.id === id)?.role ?? null;
}

function studentInfo(db: DbShape, id: string) {
  const u = db.users.find((x) => x.id === id);
  const p = u?.profile as LawStudentProfile | undefined;
  return {
    studentId: id,
    studentName: p?.fullName?.trim() || u?.name || u?.phone || 'Law student',
    studentCollege: p?.college ?? null,
    studentYear: p?.academicYear ?? null,
    studentPhone: u?.phone ?? null,
    studentPhoto: p?.photo ?? null,
  };
}

function attorneyInfo(db: DbShape, id: string) {
  const u = db.users.find((x) => x.id === id);
  const p = u?.profile as AdvocateProfile | undefined;
  return {
    attorneyId: id,
    attorneyName: p?.professional?.fullName ?? 'Attorney',
    attorneySpecialty: p?.professional?.practiceArea ?? '',
    attorneyFirm: u?.firmName ?? null,
    attorneyPhoto: p?.photo ?? null,
  };
}

interface Pair {
  studentId: string;
  attorneyId: string;
  first: ChatMessageRecord;
  last: ChatMessageRecord;
  count: number;
  fromStudent: number;
  fromAttorney: number;
}

function pairs(db: DbShape): Pair[] {
  const byKey = new Map<string, Pair>();
  for (const m of messages(db)) {
    const fromRole = roleOf(db, m.fromId);
    const toRole = roleOf(db, m.toId);
    let studentId: string | null = null;
    let attorneyId: string | null = null;
    if (fromRole === 'law_student' && toRole === 'advocate') {
      studentId = m.fromId;
      attorneyId = m.toId;
    } else if (fromRole === 'advocate' && toRole === 'law_student') {
      studentId = m.toId;
      attorneyId = m.fromId;
    }
    if (!studentId || !attorneyId) continue;
    const key = `${studentId}|${attorneyId}`;
    const p = byKey.get(key);
    const fromStudent = m.fromId === studentId && !m.system ? 1 : 0;
    const fromAttorney = m.fromId === attorneyId && !m.system ? 1 : 0;
    if (!p) {
      byKey.set(key, { studentId, attorneyId, first: m, last: m, count: 1, fromStudent, fromAttorney });
    } else {
      p.count += 1;
      p.fromStudent += fromStudent;
      p.fromAttorney += fromAttorney;
      if (m.sentAt.localeCompare(p.first.sentAt) < 0) p.first = m;
      if (m.sentAt.localeCompare(p.last.sentAt) > 0) p.last = m;
    }
  }
  return [...byKey.values()].sort((a, b) => b.last.sentAt.localeCompare(a.last.sentAt));
}

/** GET /admin/mentorships — every student–attorney conversation. */
export function adminList(_req: Request, res: Response) {
  const db = getDb();
  const list = pairs(db);
  const connections = list.map((p) => ({
    id: `${p.studentId}|${p.attorneyId}`,
    ...studentInfo(db, p.studentId),
    ...attorneyInfo(db, p.attorneyId),
    startedAt: p.first.sentAt,
    lastMessageAt: p.last.sentAt,
    lastMessage: p.last.text,
    lastFrom: p.last.fromId === p.studentId ? 'student' : 'attorney',
    messageCount: p.count,
    fromStudent: p.fromStudent,
    fromAttorney: p.fromAttorney,
    /** Attorney has replied at least once. */
    status: p.fromAttorney > 0 ? 'active' : 'awaiting_reply',
  }));
  const students = new Set(list.map((p) => p.studentId));
  const attorneys = new Set(list.map((p) => p.attorneyId));
  return res.json({
    connections,
    counts: {
      total: connections.length,
      active: connections.filter((c) => c.status === 'active').length,
      awaitingReply: connections.filter((c) => c.status === 'awaiting_reply').length,
      students: students.size,
      attorneys: attorneys.size,
    },
  });
}

/** GET /admin/mentorships/:studentId/:attorneyId/messages — the conversation, oldest first. */
export function adminThread(req: Request, res: Response) {
  const db = getDb();
  const { studentId, attorneyId } = req.params;
  const thread = messages(db)
    .filter(
      (m) =>
        (m.fromId === studentId && m.toId === attorneyId) ||
        (m.fromId === attorneyId && m.toId === studentId),
    )
    .sort((a, b) => a.sentAt.localeCompare(b.sentAt))
    .map((m) => ({
      id: m.id,
      from: m.fromId === studentId ? 'student' : 'attorney',
      text: m.text,
      system: m.system ?? false,
      sentAt: m.sentAt,
      readAt: m.readAt ?? null,
    }));
  return res.json({
    ...studentInfo(db, studentId),
    ...attorneyInfo(db, attorneyId),
    messages: thread,
  });
}
