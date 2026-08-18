import { Router, type Response } from 'express';
import { createId, getDb, saveDb } from '../db';
import { requireRole, type AuthedRequest } from '../middleware/auth';
import type {
  AdvocateProfile,
  Booking,
  ClientProfile,
  ConsultationKind,
  DbShape,
} from '../types';

const router = Router();

const CONSULTATION_KINDS: ConsultationKind[] = [
  'video_call',
  'phone_call',
  'office_visit',
];

function bookings(db: DbShape): Booking[] {
  db.bookings ??= [];
  return db.bookings;
}

/** Booking plus the display fields each side of the appointment needs. */
function toApi(booking: Booking, db: DbShape) {
  const client = db.users.find((u) => u.id === booking.clientId);
  const advocate = db.users.find((u) => u.id === booking.advocateId);
  const ap = advocate?.profile as AdvocateProfile | undefined;
  const cp = client?.profile as ClientProfile | undefined;
  const clientName = cp?.fullName ?? client?.name;
  return {
    ...booking,
    advocateName: ap?.professional.fullName ?? 'Advocate',
    advocatePhoto: ap?.photo ?? null,
    practiceArea: ap?.professional.practiceArea ?? null,
    officeAddress: ap?.location.officeAddress ?? null,
    clientName:
      clientName && clientName.trim().length > 0
        ? clientName
        : (client?.phone ?? 'Client'),
    clientPhoto: cp?.photo ?? null,
  };
}

/**
 * Client books a consultation. Office visits need the advocate to accept
 * (status starts at 'pending'); video/phone calls are confirmed right away.
 */
router.post('/', requireRole('client'), (req: AuthedRequest, res) => {
  const me = req.user!;
  const { advocateId, consultationType, date, time, durationMinutes, amount } =
    req.body as {
      advocateId?: string;
      consultationType?: string;
      date?: string;
      time?: string;
      durationMinutes?: number;
      amount?: number;
    };

  if (!advocateId || !consultationType || !date || !time) {
    return res
      .status(400)
      .json({ error: 'advocateId, consultationType, date and time are required' });
  }
  if (!CONSULTATION_KINDS.includes(consultationType as ConsultationKind)) {
    return res.status(400).json({ error: 'Unknown consultation type' });
  }
  if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) {
    return res.status(400).json({ error: 'date must be YYYY-MM-DD' });
  }

  const db = getDb();
  const advocate = db.users.find(
    (u) =>
      u.id === advocateId &&
      u.role === 'advocate' &&
      (u.status === 'approved' || u.status === 'active'),
  );
  if (!advocate) {
    return res.status(404).json({ error: 'Advocate not found' });
  }

  const clash = bookings(db).some(
    (b) =>
      b.advocateId === advocateId &&
      b.date === date &&
      b.time === time &&
      (b.status === 'pending' || b.status === 'confirmed'),
  );
  if (clash) {
    return res
      .status(409)
      .json({ error: 'That slot was just taken. Please pick another time.' });
  }

  const booking: Booking = {
    id: createId(),
    clientId: me.id,
    advocateId,
    consultationType: consultationType as ConsultationKind,
    date,
    time,
    durationMinutes:
      typeof durationMinutes === 'number' && durationMinutes > 0
        ? durationMinutes
        : 60,
    amount: typeof amount === 'number' && amount >= 0 ? amount : 0,
    status: consultationType === 'office_visit' ? 'pending' : 'confirmed',
    createdAt: new Date().toISOString(),
  };
  bookings(db).push(booking);
  saveDb();
  return res.json({ booking: toApi(booking, db) });
});

/** Bookings for the requesting user: their own side, newest first. */
router.get('/', requireRole('client', 'advocate'), (req: AuthedRequest, res) => {
  const me = req.user!;
  const db = getDb();
  const mine = bookings(db).filter((b) =>
    me.role === 'advocate' ? b.advocateId === me.id : b.clientId === me.id,
  );
  const sorted = [...mine].sort((a, b) => b.createdAt.localeCompare(a.createdAt));
  return res.json({ bookings: sorted.map((b) => toApi(b, db)) });
});

/** Advocate accepts or declines a pending visit request. */
function respond(action: 'accept' | 'decline') {
  return (req: AuthedRequest, res: Response) => {
    const me = req.user!;
    const db = getDb();
    const booking = bookings(db).find((b) => b.id === req.params.id);
    if (!booking || booking.advocateId !== me.id) {
      return res.status(404).json({ error: 'Booking not found' });
    }
    if (booking.status !== 'pending') {
      return res
        .status(409)
        .json({ error: `This request was already ${booking.status}` });
    }
    booking.status = action === 'accept' ? 'confirmed' : 'declined';
    booking.respondedAt = new Date().toISOString();
    saveDb();
    return res.json({ booking: toApi(booking, db) });
  };
}

router.post('/:id/accept', requireRole('advocate'), respond('accept'));
router.post('/:id/decline', requireRole('advocate'), respond('decline'));

/** Client cancels an upcoming (pending or confirmed) booking. */
router.post('/:id/cancel', requireRole('client'), (req: AuthedRequest, res) => {
  const me = req.user!;
  const db = getDb();
  const booking = bookings(db).find((b) => b.id === req.params.id);
  if (!booking || booking.clientId !== me.id) {
    return res.status(404).json({ error: 'Booking not found' });
  }
  if (booking.status !== 'pending' && booking.status !== 'confirmed') {
    return res
      .status(409)
      .json({ error: 'Only upcoming bookings can be cancelled' });
  }
  booking.status = 'cancelled';
  booking.cancelledAt = new Date().toISOString();
  saveDb();
  return res.json({ booking: toApi(booking, db) });
});

export default router;
