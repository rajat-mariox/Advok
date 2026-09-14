import type { Role } from './user.model';

export type SupportTicketStatus = 'open' | 'in_progress' | 'resolved';

export type SupportCategory =
  | 'account'
  | 'booking'
  | 'payment'
  | 'case'
  | 'technical'
  | 'other';

export const SUPPORT_CATEGORIES: SupportCategory[] = [
  'account',
  'booking',
  'payment',
  'case',
  'technical',
  'other',
];

/** One message on a ticket — the user's follow-up or an admin reply. */
export interface SupportReply {
  id: string;
  fromAdmin: boolean;
  text: string;
  createdAt: string;
}

/** A help request raised from the app's Help & Support screen. */
export interface SupportTicket {
  id: string;
  userId: string;
  role: Role | null;
  category: SupportCategory;
  subject: string;
  message: string;
  status: SupportTicketStatus;
  replies: SupportReply[];
  createdAt: string;
  updatedAt: string;
  resolvedAt?: string;
  /** Set when the user has unread admin replies (cleared when they open it). */
  userUnread: number;
  /** Set when the admin has unread user messages (cleared when opened). */
  adminUnread: number;
}

/** Contact details shown on the app's Help & Support screen. */
export interface SupportContact {
  email: string;
  phone: string;
  hours: string;
  /** Shown under "Chat/Contact Support", e.g. "Response within 2 hours". */
  responseNote: string;
}

export const DEFAULT_SUPPORT_CONTACT: SupportContact = {
  email: 'support@advok.app',
  phone: '+1 800 238 6543',
  hours: 'Available Mon–Sat · 9AM–8PM EST',
  responseNote: 'Response within 2 hours',
};
