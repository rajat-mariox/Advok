export type CaseStatus = 'active' | 'discovery' | 'hearing' | 'closed';

export type CasePriority = 'high' | 'medium' | 'low';

/** One entry on a case's timeline — an attorney note or a court-records update. */
export interface CaseEvent {
  id: string;
  /** Calendar day of the event, 'YYYY-MM-DD'. */
  date: string;
  title: string;
  description?: string;
  /** Where the update came from. */
  source: 'attorney' | 'client' | 'court_api';
  /**
   * Stable id of the court-records entry this event mirrors (e.g.
   * 'cl-entry-<docketEntryId>'), so repeated syncs never duplicate it.
   */
  externalId?: string;
  createdAt: string;
}

/**
 * Link between a case and its docket on the court-records provider
 * (CourtListener / RECAP). Set when the attorney picks a docket-lookup match
 * on Add Case; the sync job refreshes status and timeline from it.
 */
export interface CourtRecordLink {
  provider: 'courtlistener';
  docketId: number;
  /** Public docket page on the provider. */
  url: string;
  /** Court name as reported by the provider, e.g. 'District Court, S.D. New York'. */
  courtName?: string;
  courtId?: string;
  judge?: string;
  dateFiled?: string;
  /** Set once the court has terminated (closed) the docket. */
  dateTerminated?: string;
  /** Most recent filing date the court recorded (even when the filing itself is not public). */
  lastFilingDate?: string;
  /** PACER nature of suit, e.g. '410 Anti-Trust'. */
  natureOfSuit?: string;
  /** Statutory cause of action, e.g. '15:1 Antitrust Litigation'. */
  cause?: string;
  jurisdictionType?: string;
  /** Named parties as the court lists them. */
  parties?: string[];
  lastSyncedAt?: string;
  /** Message from the most recent failed sync, cleared on success. */
  lastSyncError?: string;
}

/** A file attached to a case (PDF, image, …). */
export interface CaseDocument {
  id: string;
  /** Original file name shown in the app. */
  name: string;
  /** Data URL (local dev) or S3 URL of the file content. */
  url: string;
  sizeBytes?: number;
  /** Who added the file (absent on older records = attorney). */
  uploadedBy?: 'attorney' | 'client';
  uploadedAt: string;
}

/**
 * A document the attorney asked the client to provide. The request lands in
 * the chat thread as a card; the client's upload fulfils it and attaches the
 * file to the case.
 */
export interface DocumentRequest {
  id: string;
  /** What the attorney asked for, e.g. "Signed retainer agreement". */
  name: string;
  note?: string;
  status: 'pending' | 'uploaded';
  requestedAt: string;
  /** Set when the client uploads: when and which case document fulfilled it. */
  uploadedAt?: string;
  documentId?: string;
}

/** A legal matter an attorney manages for one of their Advok clients. */
export interface CaseRecord {
  id: string;
  advocateId: string;
  clientId: string;
  title: string;
  /** Case / docket number as filed with the court. */
  caseNumber: string;
  court: string;
  practiceArea?: string;
  status: CaseStatus;
  priority?: CasePriority;
  /** 'YYYY-MM-DD' of the filing, when known. */
  filedDate?: string;
  /** 'YYYY-MM-DD' of the next scheduled court event, if any. */
  nextHearing?: string;
  timeline: CaseEvent[];
  /** Files attached to the case (absent on older records). */
  documents?: CaseDocument[];
  /** Documents the attorney asked the client for (absent on older records). */
  documentRequests?: DocumentRequest[];
  /** Court-records docket this case is linked to (absent for manual cases). */
  courtRecord?: CourtRecordLink;
  createdAt: string;
  updatedAt: string;
}
