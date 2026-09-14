/**
 * Legal Dictionary.
 *
 * The base dictionary is Black's Law Dictionary, 2nd edition (1910, public
 * domain), parsed from the archive.org OCR into data/legal_terms.json and
 * loaded read-only at boot — ~11k entries that never touch the database.
 *
 * This record holds everything that *does* change: terms the admin adds,
 * definitions the admin rewrites, entries hidden because the OCR was bad,
 * and the cached plain-English explanation ADVOK AI produced for a term.
 */
export interface LegalTermOverride {
  /** URL-safe key, e.g. 'habeas-corpus'. Matches the base entry when editing one. */
  slug: string;
  term: string;
  /** Admin-written definition; replaces the base text when set. */
  definition?: string;
  /** True when the term is not in the base dictionary (admin- or AI-added). */
  custom: boolean;
  /**
   * Set on custom entries that only exist because a student asked ADVOK AI
   * about an unknown term: they are searchable but not listed under A–Z.
   */
  aiOnly?: boolean;
  /** Hidden from students (bad OCR entry the admin removed). */
  hidden?: boolean;
  /** Cached ADVOK AI explanation and when it was produced. */
  plainEnglish?: string;
  plainEnglishAt?: string;
  createdAt: string;
  updatedAt: string;
}
