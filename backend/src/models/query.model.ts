export type LegalQueryStatus = 'pending' | 'answered';

/**
 * A legal question a law student asked from the app's Legal Queries tab.
 * Answered by the ADVOK team from the admin panel; the student is notified
 * and sees the reply under "My Queries".
 */
export interface LegalQueryRecord {
  id: string;
  studentId: string;
  /** One of the app's query categories, e.g. 'Criminal Law'. */
  category: string;
  /** Max 500 characters (enforced in the app and the API). */
  question: string;
  status: LegalQueryStatus;
  response?: string;
  /** Display name shown to the student, e.g. 'ADVOK Legal Team'. */
  responderName?: string;
  /** Admin user id who answered. */
  responderId?: string;
  createdAt: string;
  answeredAt?: string;
  updatedAt: string;
}
