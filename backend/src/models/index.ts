// Single import point for all data types: `import { User, Booking } from '../models'`.
import type { Booking } from './booking.model';
import type { CaseRecord } from './case.model';
import type { CmsPage } from './cms.model';
import type { LegalTermOverride } from './dictionary.model';
import type { CaseStudyRecord } from './learning.model';
import type { AdminNotification, AppNotification, ChatMessageRecord } from './message.model';
import type { OtpRecord } from './otp.model';
import type { LegalQueryRecord } from './query.model';
import type { ClientRelationship } from './relationship.model';
import type { AppSettings } from './settings.model';
import type { SupportTicket } from './support.model';
import type { User } from './user.model';

export * from './booking.model';
export * from './case.model';
export * from './cms.model';
export * from './dictionary.model';
export * from './learning.model';
export * from './message.model';
export * from './otp.model';
export * from './query.model';
export * from './relationship.model';
export * from './settings.model';
export * from './support.model';
export * from './user.model';

/** Everything the store holds — one collection per field. */
export interface DbShape {
  users: User[];
  otps: OtpRecord[];
  cmsPages?: CmsPage[];
  bookings?: Booking[];
  relationships?: ClientRelationship[];
  cases?: CaseRecord[];
  messages?: ChatMessageRecord[];
  notifications?: AppNotification[];
  settings?: AppSettings[];
  supportTickets?: SupportTicket[];
  caseStudies?: CaseStudyRecord[];
  /** Legal Dictionary: admin edits/additions + cached AI explanations (base terms live in data/legal_terms.json). */
  legalTerms?: LegalTermOverride[];
  /** Law students' legal questions, answered from the admin panel. */
  legalQueries?: LegalQueryRecord[];
  /** Admin panel bell notifications. */
  adminNotifications?: AdminNotification[];
}
