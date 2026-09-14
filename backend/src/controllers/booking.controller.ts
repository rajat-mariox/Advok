import type { Response } from 'express';
import type { AuthedRequest } from '../middlewares/auth.middleware';
import type {
  AdvocateProfile,
  Booking,
  ClientProfile,
  ConsultationKind,
  DbShape,
  LawFirmProfile,
  User,
} from '../models';
import { createId, getDb, saveDb } from '../services/db.service';
import { pushNotification, pushSystemMessage } from '../services/notify.service';
import { sendSms } from '../services/sms.service';
import { findLinkedAttorney, phoneKey } from '../services/firm.service';

const CONSULTATION_LABELS: Record<string, string> = {
  video_call: 'Video Call',
  phone_call: 'Phone Call',
  office_visit: 'Office Visit',
};
import { isBookingDate, isConsultationKind } from '../validators/booking.validator';
import { publishToAdmins, publishToAll, publishToUser, publishToUsers } from '../services/realtime.service';

function bookings(db: DbShape): Booking[] {
  db.bookings ??= [];
  return db.bookings;
}

/** Whoever can receive a consultation request: an attorney or a law firm. */
interface ProviderInfo {
  name: string;
  phone: string;
  email: string;
  photo: string | null;
  practiceArea: string | null;
  officeAddress: string | null;
  role: 'advocate' | 'law_firm';
}

function isProvider(u: User | undefined): u is User {
  return (
    !!u &&
    (u.role === 'advocate' || u.role === 'law_firm') &&
    (u.status === 'approved' || u.status === 'active')
  );
}

/** Display + contact details of a provider, whichever kind it is. */
function providerInfo(user: User | undefined): ProviderInfo {
  if (user?.role === 'law_firm') {
    const fp = user.profile as LawFirmProfile | undefined;
    const expertise = Array.from(
      new Set((fp?.lawyers ?? []).flatMap((l) => l.expertise ?? [])),
    );
    const address = [fp?.addressLine1, fp?.addressLine2, fp?.city, fp?.state, fp?.zip]
      .filter((x): x is string => !!x && x.trim().length > 0)
      .join(', ');
    return {
      name: fp?.firmName?.trim() || user.name || 'Law Firm',
      phone: fp?.mainPhone?.trim() || user.phone || '',
      email: fp?.officialEmail?.trim() || user.email || '',
      photo: fp?.photo ?? null,
      practiceArea: expertise.length ? expertise.slice(0, 3).join(', ') : 'Law Firm',
      officeAddress: address || null,
      role: 'law_firm',
    };
  }
  const ap = user?.profile as AdvocateProfile | undefined;
  return {
    name: ap?.professional.fullName?.trim() || user?.name || 'Attorney',
    phone: user?.phone ?? '',
    email: ap?.professional.email ?? '',
    photo: ap?.photo ?? null,
    practiceArea: ap?.professional.practiceArea ?? null,
    officeAddress: ap?.location.officeAddress ?? null,
    role: 'advocate',
  };
}

/** '10:00 AM' → minutes since midnight; null when unparseable. */
function slotMinutes(time: string): number | null {
  const match = /^(\d{1,2}):(\d{2})\s*(AM|PM)$/i.exec(time.trim());
  if (!match) return null;
  let h = Number(match[1]) % 12;
  if (match[3].toUpperCase() === 'PM') h += 12;
  return h * 60 + Number(match[2]);
}

/** A confirmed consultation counts as held this long after its start time. */
const AUTO_COMPLETE_GRACE_MINUTES = 15;

/**
 * Confirmed consultations auto-complete shortly after their slot starts —
 * the two sides talk directly by phone, so a 4:00 PM booking shows
 * Completed by 4:15 instead of sitting in Upcoming. Returns true when
 * anything changed (caller persists).
 */
export function autoCompletePastBookings(db: DbShape): boolean {
  const now = new Date();
  const today =
    `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-` +
    `${String(now.getDate()).padStart(2, '0')}`;
  const nowMinutes = now.getHours() * 60 + now.getMinutes();
  let changed = false;
  for (const b of bookings(db)) {
    if (b.status !== 'confirmed') continue;
    const start = slotMinutes(b.time);
    const held =
      b.date < today ||
      (b.date === today &&
        start !== null &&
        start + AUTO_COMPLETE_GRACE_MINUTES <= nowMinutes);
    if (held) {
      b.status = 'completed';
      b.completedAt = now.toISOString();
      changed = true;
    }
  }
  return changed;
}

/**
 * Records the client–advocate relationship an accepted consultation creates
 * (idempotent — a returning client keeps their original record) and sends the
 * advocate's contact details to the client by SMS so the two sides can talk
 * directly.
 */
function establishRelationship(db: DbShape, booking: Booking): void {
  db.relationships ??= [];
  const exists = db.relationships.some(
    (r) => r.advocateId === booking.advocateId && r.clientId === booking.clientId,
  );
  if (!exists) {
    db.relationships.push({
      id: createId(),
      advocateId: booking.advocateId,
      clientId: booking.clientId,
      bookingId: booking.id,
      createdAt: new Date().toISOString(),
    });
  }

  const client = db.users.find((u) => u.id === booking.clientId);
  const advocate = db.users.find((u) => u.id === booking.advocateId);
  const provider = providerInfo(advocate);
  // For a firm booking the client talks to the assigned attorney; fall back
  // to the firm's own contact when the entry has none.
  const assigned = booking.assignedAttorney;
  const contactName = assigned
    ? `${assigned.name}${assigned.designation ? ` (${assigned.designation})` : ''} at ${provider.name}`
    : provider.name;
  const contactPhone = assigned?.phone?.trim() || provider.phone;
  const contactEmail = assigned?.email?.trim() || provider.email;
  const contactPhoto = assigned?.userId
    ? (providerInfo(db.users.find((u) => u.id === assigned.userId)).photo ?? provider.photo)
    : provider.photo;

  // A linked attorney account gets its own relationship with the client, so
  // the attorney can chat with them and open a case from their own account.
  if (assigned?.userId) {
    const linked = db.relationships.some(
      (r) => r.advocateId === assigned.userId && r.clientId === booking.clientId,
    );
    if (!linked) {
      db.relationships.push({
        id: createId(),
        advocateId: assigned.userId,
        clientId: booking.clientId,
        bookingId: booking.id,
        createdAt: new Date().toISOString(),
      });
    }
  }

  if (client?.phone && advocate) {
    const contact = [contactPhone, contactEmail]
      .filter((c) => c.trim().length > 0)
      .join(' / ');
    sendSms(
      client.phone,
      `ADVOK: ${contactName} accepted your consultation on ${booking.date} at ` +
        `${booking.time}. Contact: ${contact || 'available in the app'}.`,
    );
  }

  // Drop the contact card into the chat thread so the client can call
  // directly once the consultation is confirmed. For a firm booking it is
  // sent from the assigned attorney's account (that thread opens); a firm
  // itself never chats with the client, so with no linked attorney account
  // the client relies on the booking card + SMS for the contact details.
  const advocateName = contactName;
  const typeLabel =
    CONSULTATION_LABELS[booking.consultationType] ?? booking.consultationType;
  if (provider.role === 'law_firm' && !assigned?.userId) return;
  pushSystemMessage(
    db,
    assigned?.userId ?? booking.advocateId,
    booking.clientId,
    `Consultation confirmed — ${typeLabel} on ${booking.date} at ` +
      `${booking.time}. Contact ${advocateName}: ` +
      `${contactPhone || 'in the app'}.`,
    {
      kind: 'consultation_accepted',
      attorneyName: assigned?.name ?? provider.name,
      firmName: assigned ? provider.name : (advocate?.firmName ?? ''),
      attorneyPhone: contactPhone,
      attorneyEmail: contactEmail,
      attorneyPhoto: contactPhoto ?? '',
      consultationType: typeLabel,
      date: booking.date,
      time: booking.time,
      amount: booking.amount,
    },
  );
}

/**
 * Display name of whoever booked the consultation — a client, or a law
 * student / law firm consulting an attorney through the same flow.
 */
function bookerName(user: User | undefined): string | undefined {
  if (!user) return undefined;
  const p = user.profile as Record<string, unknown> | undefined;
  const fromProfile =
    user.role === 'law_firm'
      ? (p?.firmName as string | undefined)
      : (p?.fullName as string | undefined);
  return fromProfile?.trim() || user.name;
}

/** Booking plus the display fields each side of the appointment needs. */
function toApi(booking: Booking, db: DbShape, viewerId?: string) {
  const client = db.users.find((u) => u.id === booking.clientId);
  const advocate = db.users.find((u) => u.id === booking.advocateId);
  const provider = providerInfo(advocate);
  const cp = client?.profile as ClientProfile | undefined;
  const clientName = bookerName(client);
  const accepted =
    booking.status === 'confirmed' || booking.status === 'completed';
  return {
    ...booking,
    providerRole: booking.providerRole ?? provider.role,
    // True when the viewer is the provider (a firm sees both directions) or
    // the attorney a firm assigned to this consultation.
    incoming: viewerId
      ? booking.advocateId === viewerId || booking.assignedAttorney?.userId === viewerId
      : false,
    advocateName: provider.name,
    advocatePhoto: provider.photo,
    practiceArea: provider.practiceArea,
    officeAddress: provider.officeAddress,
    firmName: provider.role === 'law_firm' ? provider.name : (advocate?.firmName ?? null),
    requestedAttorney: booking.requestedAttorney
      ? {
          name: booking.requestedAttorney.name,
          designation: booking.requestedAttorney.designation,
          userId: booking.requestedAttorney.userId,
          index: booking.requestedAttorney.index,
        }
      : null,
    assignedAttorney: booking.assignedAttorney
      ? {
          name: booking.assignedAttorney.name,
          designation: booking.assignedAttorney.designation,
          userId: booking.assignedAttorney.userId ?? null,
        }
      : null,
    // Contact details are shared only once the provider has accepted. For a
    // firm booking they are the assigned attorney's (fallback: the firm's).
    advocatePhone: accepted
      ? booking.assignedAttorney?.phone?.trim() || provider.phone || null
      : null,
    advocateEmail: accepted
      ? booking.assignedAttorney?.email?.trim() || provider.email || null
      : null,
    clientName:
      clientName && clientName.trim().length > 0
        ? clientName
        : (client?.phone ?? 'Client'),
    clientPhoto: cp?.photo ?? null,
  };
}

/**
 * Client books a consultation. Every request starts at 'pending' and waits
 * for the advocate to accept or decline it.
 */
export function createBooking(req: AuthedRequest, res: Response) {
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
  if (!isConsultationKind(consultationType)) {
    return res.status(400).json({ error: 'Unknown consultation type' });
  }
  // Clients consult by voice only — other types stay in the data model for
  // historical bookings but can no longer be booked.
  if (consultationType !== 'phone_call') {
    return res
      .status(400)
      .json({ error: 'Only voice consultations are available' });
  }
  if (!isBookingDate(date)) {
    return res.status(400).json({ error: 'date must be YYYY-MM-DD' });
  }

  const db = getDb();
  let advocate = db.users.find((u) => u.id === advocateId);
  if (!isProvider(advocate)) {
    return res.status(404).json({ error: 'Attorney or law firm not found' });
  }
  if (advocate.id === me.id) {
    return res.status(400).json({ error: 'You cannot book yourself' });
  }

  // A firm's attorney is booked through the firm: the request goes to the
  // firm with this attorney pre-selected, and the firm assigns them.
  let requestedAttorney: Booking['requestedAttorney'];
  if (advocate.role === 'advocate' && advocate.firmId) {
    const firm = db.users.find((u) => u.id === advocate!.firmId);
    if (isProvider(firm) && firm.role === 'law_firm') {
      const fp = firm.profile as LawFirmProfile;
      const key = phoneKey(advocate.phone);
      const index = (fp.lawyers ?? []).findIndex((l) => phoneKey(l.phone) === key);
      const ap = advocate.profile as AdvocateProfile | undefined;
      requestedAttorney = {
        userId: advocate.id,
        name: ap?.professional.fullName ?? advocate.name ?? 'Attorney',
        designation: ap?.firmRole ?? fp.lawyers?.[index]?.designation ?? '',
        index: index >= 0 ? index : 0,
      };
      advocate = firm;
    }
  }
  const providerId = advocate.id;

  const clash = bookings(db).some(
    (b) =>
      b.advocateId === providerId &&
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
    advocateId: providerId,
    providerRole: advocate.role === 'law_firm' ? 'law_firm' : 'advocate',
    requestedAttorney,
    consultationType: consultationType as ConsultationKind,
    date,
    time,
    durationMinutes:
      typeof durationMinutes === 'number' && durationMinutes > 0
        ? durationMinutes
        : 60,
    amount: typeof amount === 'number' && amount >= 0 ? amount : 0,
    status: 'pending',
    createdAt: new Date().toISOString(),
  };
  bookings(db).push(booking);
  const bookerLabel = bookerName(me)?.trim() || 'A client';
  pushNotification(
    db,
    providerId,
    'booking_request',
    'New consultation request',
    `${bookerLabel} requested a ` +
      `${booking.consultationType.replace('_', ' ')} on ${date} at ${time}` +
      (requestedAttorney ? ` with ${requestedAttorney.name}.` : '.'),
    { bookingId: booking.id },
  );
  // The requested attorney is not told yet — the firm accepts first, then
  // the assignment (and the attorney's notification) happens automatically.
  saveDb();
  publishToUsers([booking.clientId, booking.advocateId, booking.assignedAttorney?.userId], 'bookings', { bookingId: booking.id, status: booking.status });
  publishToUser(booking.advocateId, 'clients');
  publishToAdmins('bookings', { bookingId: booking.id, status: booking.status });
  return res.json({ booking: toApi(booking, db, me.id) });
}

/**
 * Bookings for the requesting user, newest first. Attorneys see requests
 * made with them; clients/students see the ones they made; a law firm sees
 * both (requests it received, and consultations it booked with attorneys).
 */
export function listMyBookings(req: AuthedRequest, res: Response) {
  const me = req.user!;
  const db = getDb();
  if (autoCompletePastBookings(db)) saveDb();
  const mine = bookings(db).filter((b) =>
    me.role === 'advocate'
      ? b.advocateId === me.id || b.assignedAttorney?.userId === me.id
      : me.role === 'law_firm'
        ? b.advocateId === me.id || b.clientId === me.id
        : b.clientId === me.id,
  );
  const sorted = [...mine].sort((a, b) => b.createdAt.localeCompare(a.createdAt));
  return res.json({ bookings: sorted.map((b) => toApi(b, db, me.id)) });
}

/**
 * Advocate accepts or declines a pending consultation request. Accepting
 * creates the client relationship and shares contact details with the client.
 */
export function respondToBooking(action: 'accept' | 'decline') {
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
    // A law firm picks which of its attorneys will handle the consultation.
    if (action === 'accept' && me.role === 'law_firm') {
      const fp = me.profile as LawFirmProfile | undefined;
      const team = fp?.lawyers ?? [];
      const rawIndex = (req.body as { attorneyIndex?: unknown } | undefined)?.attorneyIndex;
      let index = typeof rawIndex === 'number' ? rawIndex : Number(rawIndex);
      // The client booked a specific attorney of the firm: the firm only
      // accepts, and that attorney is assigned automatically.
      if (booking.requestedAttorney) {
        index = booking.requestedAttorney.index;
      }
      if (team.length > 0) {
        if (!Number.isInteger(index) || index < 0 || index >= team.length) {
          return res
            .status(400)
            .json({ error: 'Choose the attorney who will handle this consultation' });
        }
        const entry = team[index];
        const linked = findLinkedAttorney(db, me.id, entry);
        booking.assignedAttorney = {
          name: entry.fullName,
          designation: entry.designation ?? '',
          phone: entry.phone ?? '',
          email: entry.email ?? '',
          userId: linked?.id,
        };
      }
    }
    booking.status = action === 'accept' ? 'confirmed' : 'declined';
    booking.respondedAt = new Date().toISOString();
    const advocateName = providerInfo(db.users.find((u) => u.id === me.id)).name;
    if (action === 'accept') {
      establishRelationship(db, booking);
      const who = booking.assignedAttorney
        ? `${advocateName} assigned ${booking.assignedAttorney.name} to your consultation`
        : `${advocateName} accepted your consultation`;
      pushNotification(
        db,
        booking.clientId,
        'booking_accepted',
        'Consultation confirmed',
        `${who} on ${booking.date} at ${booking.time}. ` +
          'Their contact details are on your booking.',
        { bookingId: booking.id },
      );
      if (booking.assignedAttorney?.userId) {
        pushNotification(
          db,
          booking.assignedAttorney.userId,
          'booking_accepted',
          'New client assigned to you',
          `${advocateName} assigned you a consultation on ${booking.date} at ` +
            `${booking.time}. The client is now in My Clients.`,
          { bookingId: booking.id },
        );
      }
    } else {
      pushNotification(
        db,
        booking.clientId,
        'booking_declined',
        'Consultation declined',
        `${advocateName} couldn't take your consultation on ${booking.date}. ` +
          'You can book another attorney anytime.',
        { bookingId: booking.id },
      );
    }
    saveDb();
    publishToUsers([booking.clientId, booking.advocateId, booking.assignedAttorney?.userId], 'bookings', { bookingId: booking.id, status: booking.status });
    publishToUser(booking.advocateId, 'clients');
    publishToAdmins('bookings', { bookingId: booking.id, status: booking.status });
    return res.json({ booking: toApi(booking, db, me.id) });
  };
}

/**
 * Either side marks a confirmed consultation as held — the actual call
 * happens directly by phone, so the app just closes the appointment.
 */
export function completeBooking(req: AuthedRequest, res: Response) {
  const me = req.user!;
  const db = getDb();
  const booking = bookings(db).find((b) => b.id === req.params.id);
  if (!booking || (booking.clientId !== me.id && booking.advocateId !== me.id)) {
    return res.status(404).json({ error: 'Booking not found' });
  }
  if (booking.status !== 'confirmed') {
    return res
      .status(409)
      .json({ error: 'Only confirmed consultations can be completed' });
  }
  booking.status = 'completed';
  booking.completedAt = new Date().toISOString();
  saveDb();
  publishToUsers([booking.clientId, booking.advocateId, booking.assignedAttorney?.userId], 'bookings', { bookingId: booking.id, status: booking.status });
  publishToUser(booking.advocateId, 'clients');
  publishToAdmins('bookings', { bookingId: booking.id, status: booking.status });
  return res.json({ booking: toApi(booking, db, me.id) });
}

/** Client cancels an upcoming (pending or confirmed) booking. */
export function cancelBooking(req: AuthedRequest, res: Response) {
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
  publishToUsers([booking.clientId, booking.advocateId, booking.assignedAttorney?.userId], 'bookings', { bookingId: booking.id, status: booking.status });
  publishToUser(booking.advocateId, 'clients');
  publishToAdmins('bookings', { bookingId: booking.id, status: booking.status });
  return res.json({ booking: toApi(booking, db, me.id) });
}
