// Keeps cases linked to a court docket in step with the court records:
// new docket entries land on the case timeline as 'court_api' events, and a
// docket the court has terminated closes the case. Runs on demand (the
// attorney's "Sync Now") and on a schedule for every open linked case.
import { COURT_SYNC_INTERVAL_MINUTES } from '../config';
import type { CaseEvent, CaseRecord, DbShape } from '../models';
import { fetchDocket, fetchDocketEntries } from './court.service';
import { createId, getDb, saveDb } from './db.service';
import { pushNotification } from './notify.service';
import { publishToAdmins, publishToUsers } from './realtime.service';

/** Entries older than this are not back-filled onto the timeline. */
const MAX_ENTRIES_PER_SYNC = 25;
/** Pause between cases in the scheduled run, to stay polite to the provider. */
const SCHEDULED_GAP_MS = 1_500;
/** First scheduled run after boot. */
const SCHEDULED_INITIAL_DELAY_MS = 2 * 60 * 1000;

export interface CaseSyncResult {
  /** Anything on the record changed (status, timeline, header fields). */
  changed: boolean;
  newEvents: number;
  statusChanged: boolean;
  status: CaseRecord['status'];
  /** Set when the provider could not be reached; the record keeps its data. */
  error?: string;
}

function eventDate(e: CaseEvent): string {
  return `${e.date}T${e.createdAt}`;
}

/**
 * Refreshes one case from its linked docket. Mutates `record` in place and
 * queues notifications on `db`; the caller saves. Never throws — provider
 * failures are reported through `error` and remembered on the link.
 */
export async function syncCaseWithCourt(
  db: DbShape,
  record: CaseRecord,
  options: { notifyAttorney?: boolean } = {},
): Promise<CaseSyncResult> {
  const link = record.courtRecord;
  const base: CaseSyncResult = {
    changed: false,
    newEvents: 0,
    statusChanged: false,
    status: record.status,
  };
  if (!link) return { ...base, error: 'This case is not linked to court records' };

  const now = new Date().toISOString();
  try {
    const [docket, entries] = await Promise.all([
      fetchDocket(link.docketId),
      fetchDocketEntries(link.docketId, MAX_ENTRIES_PER_SYNC),
    ]);
    if (!docket) {
      link.lastSyncError = 'Docket no longer available from the provider';
      link.lastSyncedAt = now;
      return { ...base, error: link.lastSyncError };
    }

    let changed = false;

    // Header fields the court controls.
    const header: Partial<typeof link> = {
      courtName: docket.court || link.courtName,
      courtId: docket.courtId || link.courtId,
      judge: docket.judge ?? link.judge,
      dateFiled: docket.dateFiled ?? link.dateFiled,
      dateTerminated: docket.dateTerminated,
      url: docket.url || link.url,
    };
    if (header.courtName !== link.courtName) { link.courtName = header.courtName; changed = true; }
    if (header.courtId !== link.courtId) { link.courtId = header.courtId; changed = true; }
    if (header.judge !== link.judge) { link.judge = header.judge; changed = true; }
    if (header.dateFiled !== link.dateFiled) { link.dateFiled = header.dateFiled; changed = true; }
    if (header.dateTerminated !== link.dateTerminated) { link.dateTerminated = header.dateTerminated; changed = true; }
    if (header.url && header.url !== link.url) { link.url = header.url; changed = true; }
    const natureOfSuit = docket.natureOfSuit ?? link.natureOfSuit;
    if (natureOfSuit !== link.natureOfSuit) { link.natureOfSuit = natureOfSuit; changed = true; }
    const cause = docket.cause ?? link.cause;
    if (cause !== link.cause) { link.cause = cause; changed = true; }
    const jurisdictionType = docket.jurisdictionType ?? link.jurisdictionType;
    if (jurisdictionType !== link.jurisdictionType) { link.jurisdictionType = jurisdictionType; changed = true; }
    if (docket.parties.length > 0 && docket.parties.join('|') !== (link.parties ?? []).join('|')) {
      link.parties = docket.parties;
      changed = true;
    }
    if (!record.filedDate && docket.dateFiled) {
      record.filedDate = docket.dateFiled;
      changed = true;
    }

    // Docket entries → timeline, skipping the ones already mirrored.
    const known = new Set(record.timeline.map((e) => e.externalId).filter(Boolean));
    let newEvents = 0;
    for (const entry of entries) {
      const externalId = `cl-entry-${entry.entryId}`;
      if (known.has(externalId)) continue;
      record.timeline.push({
        id: createId(),
        date: entry.date,
        title: entry.entryNumber ? `#${entry.entryNumber} ${entry.title}` : entry.title,
        description: entry.description,
        source: 'court_api',
        externalId,
        createdAt: now,
      });
      known.add(externalId);
      newEvents += 1;
    }
    if (newEvents > 0) {
      record.timeline.sort((a, b) => eventDate(a).localeCompare(eventDate(b)));
      changed = true;
    }

    // Terminated docket → case closed (once).
    let statusChanged = false;
    if (docket.dateTerminated && record.status !== 'closed') {
      record.status = 'closed';
      statusChanged = true;
      changed = true;
      if (!known.has('cl-terminated')) {
        record.timeline.push({
          id: createId(),
          date: docket.dateTerminated,
          title: 'Case terminated by the court',
          description: `The court closed this docket on ${docket.dateTerminated}. Status set to Closed.`,
          source: 'court_api',
          externalId: 'cl-terminated',
          createdAt: now,
        });
        record.timeline.sort((a, b) => eventDate(a).localeCompare(eventDate(b)));
      }
    }

    link.lastSyncedAt = now;
    if (link.lastSyncError) {
      delete link.lastSyncError;
      changed = true;
    }

    if (changed) record.updatedAt = now;

    if (newEvents > 0 || statusChanged) {
      const parts: string[] = [];
      if (newEvents > 0) parts.push(`${newEvents} new court record${newEvents === 1 ? '' : 's'}`);
      if (statusChanged) parts.push('case closed by the court');
      const body = `${parts.join(' · ')} on "${record.title}" (${record.caseNumber}).`;
      pushNotification(db, record.clientId, 'case_update', 'Court records updated', body, {
        caseId: record.id,
      });
      if (options.notifyAttorney) {
        pushNotification(db, record.advocateId, 'case_update', 'Court records updated', body, {
          caseId: record.id,
        });
      }
    }

    return { changed, newEvents, statusChanged, status: record.status };
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Court records sync failed';
    link.lastSyncError = message;
    link.lastSyncedAt = now;
    console.error(`Court sync failed for case ${record.id}:`, message);
    return { ...base, error: message };
  }
}

/** Syncs every open, linked case. Returns how many changed. */
export async function syncAllLinkedCases(): Promise<number> {
  const db = getDb();
  const targets = (db.cases ?? []).filter((c) => c.courtRecord && c.status !== 'closed');
  let changedCount = 0;
  for (const [i, record] of targets.entries()) {
    if (i > 0) await new Promise((r) => setTimeout(r, SCHEDULED_GAP_MS));
    const result = await syncCaseWithCourt(db, record, { notifyAttorney: true });
    if (result.changed) {
      changedCount += 1;
      publishToUsers([record.clientId, record.advocateId], 'cases', { caseId: record.id });
    }
  }
  // Persist even when nothing changed: lastSyncedAt / lastSyncError moved.
  if (targets.length > 0) saveDb();
  if (changedCount > 0) publishToAdmins('cases');
  return changedCount;
}

let timer: NodeJS.Timeout | null = null;

/** Starts the periodic court-records sync (no-op when disabled by config). */
export function startCourtSyncScheduler(): void {
  if (timer || !(COURT_SYNC_INTERVAL_MINUTES > 0)) return;
  const run = async () => {
    try {
      const changed = await syncAllLinkedCases();
      console.log(`Court records sync: ${changed} case(s) updated`);
    } catch (err) {
      console.error('Court records sync run failed:', err);
    }
  };
  const interval = COURT_SYNC_INTERVAL_MINUTES * 60 * 1000;
  timer = setTimeout(() => {
    void run();
    timer = setInterval(() => void run(), interval);
  }, SCHEDULED_INITIAL_DELAY_MS);
  console.log(`Court records sync every ${COURT_SYNC_INTERVAL_MINUTES} min`);
}
