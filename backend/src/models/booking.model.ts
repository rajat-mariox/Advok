export type BookingStatus =
  | 'pending' // waiting for the advocate to accept
  | 'confirmed' // accepted by the advocate
  | 'completed' // consultation happened (marked by either side, or auto once the slot passed)
  | 'declined' // advocate turned the request down
  | 'cancelled'; // client cancelled

export type ConsultationKind = 'video_call' | 'phone_call' | 'office_visit';

/**
 * A consultation booked by a client with a provider — an individual attorney
 * (role 'advocate') or a law firm (role 'law_firm'). `advocateId` is the
 * provider's user id for both; `providerRole` says which kind it is.
 */
export interface Booking {
  id: string;
  clientId: string;
  advocateId: string;
  providerRole?: 'advocate' | 'law_firm';
  /**
   * For law-firm bookings: the attorney the firm assigned when accepting.
   * Copied from the firm's team entry; `userId` set when that attorney has
   * an ADVOK account linked to the firm.
   */
  assignedAttorney?: {
    name: string;
    designation: string;
    phone: string;
    email: string;
    userId?: string;
  };
  /**
   * When the client picked a firm's attorney from the attorney list, the
   * request goes to the firm with this attorney pre-selected for assignment.
   */
  requestedAttorney?: {
    userId: string;
    name: string;
    designation: string;
    /** Index in the firm's team list (for the accept call). */
    index: number;
  };
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
  completedAt?: string;
}
