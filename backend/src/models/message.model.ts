/** One chat message between two related users (client ↔ advocate). */
export interface ChatMessageRecord {
  id: string;
  fromId: string;
  toId: string;
  text: string;
  /** True for platform-generated messages (e.g. "case created"). */
  system?: boolean;
  /**
   * Structured payload for template messages the app renders as a card
   * (e.g. kind 'consultation_accepted' with the client's details). The
   * `text` stays as a plain fallback.
   */
  meta?: Record<string, unknown>;
  sentAt: string;
  /** Set when the recipient has opened the thread. */
  readAt?: string;
}

export type NotificationType =
  | 'case_assigned'
  | 'case_update'
  | 'booking_request'
  | 'booking_accepted'
  | 'booking_declined'
  | 'support_reply'
  | 'query_answered';

/** An in-app notification shown on the user's Notifications screen. */
export interface AppNotification {
  id: string;
  userId: string;
  type: NotificationType;
  title: string;
  body: string;
  caseId?: string;
  bookingId?: string;
  ticketId?: string;
  queryId?: string;
  createdAt: string;
  readAt?: string;
}
