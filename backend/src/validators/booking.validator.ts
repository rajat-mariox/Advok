import type { ConsultationKind } from '../models';

export const CONSULTATION_KINDS: ConsultationKind[] = [
  'video_call',
  'phone_call',
  'office_visit',
];

export function isConsultationKind(v: unknown): v is ConsultationKind {
  return CONSULTATION_KINDS.includes(v as ConsultationKind);
}

/** Booking date must be a calendar day, 'YYYY-MM-DD'. */
export function isBookingDate(v: unknown): v is string {
  return typeof v === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(v);
}
