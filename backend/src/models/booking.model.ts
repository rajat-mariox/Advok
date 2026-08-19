export type BookingStatus =
  | 'pending' // waiting for the advocate to accept (office visits)
  | 'confirmed' // accepted by the advocate, or instantly confirmed types
  | 'declined' // advocate turned the request down
  | 'cancelled'; // client cancelled

export type ConsultationKind = 'video_call' | 'phone_call' | 'office_visit';

/** A consultation booked by a client with an advocate. */
export interface Booking {
  id: string;
  clientId: string;
  advocateId: string;
  consultationType: ConsultationKind;
  /** Calendar day of the appointment, 'YYYY-MM-DD'. */
  date: string;
  /** Slot label shown to both sides, e.g. '10:00 AM'. */
  time: string;
  durationMinutes: number;
  /** Total shown at checkout (consultation + platform fee + tax). */
  amount: number;
  status: BookingStatus;
  createdAt: string;
  /** When the advocate accepted/declined. */
  respondedAt?: string;
  cancelledAt?: string;
}
