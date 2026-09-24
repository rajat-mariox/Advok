// Court-records client for US dockets via the CourtListener REST API v4
// (free RECAP/PACER data from the Free Law Project).
//
// The /search/ endpoint is used throughout because it answers anonymously —
// the attorney can look up and link a docket without a token. A free token
// (COURTLISTENER_API_TOKEN) raises the rate limit and is sent when present.
//
// State courts have no unified API, so manual entry remains the fallback
// for them: a case without a docket link is simply never synced.
import fs from 'fs';
import path from 'path';
import { COURTLISTENER_API_TOKEN } from '../config';

const BASE = 'https://www.courtlistener.com';
const SEARCH = `${BASE}/api/rest/v4/search/`;
const TIMEOUT_MS = 15_000;
/** Cap on parties kept per docket. */
const MAX_PARTIES = 20;

/** A US federal district / bankruptcy court the attorney can narrow a search to. */
export interface UsCourt {
  /** CourtListener court id, e.g. 'txsd'. */
  id: string;
  name: string;
  short: string;
  state: string;
  kind: 'district' | 'bankruptcy';
}

let courtsCache: UsCourt[] | null = null;

/** Active federal district + bankruptcy courts (bundled from CourtListener). */
export function usCourts(): UsCourt[] {
  if (courtsCache) return courtsCache;
  try {
    const raw = JSON.parse(
      fs.readFileSync(path.join(__dirname, '..', '..', 'data', 'us_courts.json'), 'utf-8'),
    ) as { courts?: UsCourt[] };
    courtsCache = raw.courts ?? [];
  } catch {
    courtsCache = [];
  }
  return courtsCache;
}

export function courtsForState(state: string): UsCourt[] {
  const s = state.trim().toLowerCase();
  return usCourts().filter((c) => c.state.toLowerCase() === s);
}

/** Human name for a CourtListener court id, when we know it. */
export function courtName(id: string): string | undefined {
  return usCourts().find((c) => c.id === id)?.name;
}

/**
 * A pasted CourtListener docket link or bare numeric id identifies exactly
 * one docket: https://www.courtlistener.com/docket/18625524/united-states-v-google/
 */
export function parseDocketId(input: string): number | null {
  const q = input.trim();
  const m = /courtlistener\.com\/docket\/(\d+)/i.exec(q) ?? /^\s*#?(\d{5,})\s*$/.exec(q);
  return m ? Number(m[1]) : null;
}

/** One docket the attorney can link a case to. */
export interface CourtDocketMatch {
  docketId: number;
  caseName: string;
  docketNumber: string;
  /** Human court name, e.g. 'District Court, S.D. New York'. */
  court: string;
  /** Provider's short court id, e.g. 'nysd'. */
  courtId: string;
  judge?: string;
  dateFiled?: string;
  /** Present once the court closed the docket. */
  dateTerminated?: string;
  /** Day of the most recent filing the court recorded (token-only field). */
  lastFilingDate?: string;
  /** PACER "nature of suit", e.g. '410 Anti-Trust'. */
  natureOfSuit?: string;
  /** Statutory cause of action, e.g. '15:1 Antitrust Litigation'. */
  cause?: string;
  /** e.g. 'Federal question', 'Diversity', 'U.S. Government Plaintiff'. */
  jurisdictionType?: string;
  /** Named parties, in the order the court lists them. */
  parties: string[];
  /** Practice area suggested from the nature of suit / docket type. */
  practiceArea?: string;
  /** Public docket page. */
  url: string;
}

/** A single docket entry (filing / order / minute entry) on a docket. */
export interface CourtDocketEntry {
  /** Provider's docket-entry id — stable across syncs. */
  entryId: number;
  entryNumber?: number;
  /** 'YYYY-MM-DD' */
  date: string;
  title: string;
  description?: string;
  url: string;
  /** What the entry is, judged from its text: a decision, a court date, or a routine filing. */
  kind: 'judgment' | 'hearing' | 'filing';
}

/** Classifies a docket entry from its text so the timeline can call out decisions and court dates. */
export function classifyEntry(text: string): CourtDocketEntry['kind'] {
  const t = text.toLowerCase();
  // A party asking for something is a filing, not a decision — unless the
  // entry also records the court granting/denying it.
  if (
    /^\s*(joint |unopposed |emergency )?(motion|request|notice|memorandum in|reply|response|brief)\b/.test(t) &&
    !/\border (granting|denying)\b/.test(t)
  ) {
    return 'filing';
  }
  if (/\b(judgment|verdict|sentenc|memorandum opinion|opinion and order|findings of fact|dismiss(ed|al|ing) (the )?(case|action|complaint|indictment)|order granting|order denying|final order|decree|acquit|convict|plea agreement|guilty)\b/.test(t)) {
    return 'judgment';
  }
  if (/\b(minute entry|hearing|trial|proceedings held|arraignment|conference|oral argument|sentencing|status conference|pretrial|initial appearance|detention hearing)\b/.test(t)) {
    return 'hearing';
  }
  return 'filing';
}

interface SearchDocketHit {
  docket_id?: number;
  caseName?: string;
  docketNumber?: string;
  court?: string;
  court_id?: string;
  assignedTo?: string | null;
  dateFiled?: string | null;
  dateTerminated?: string | null;
  suitNature?: string | null;
  cause?: string | null;
  jurisdictionType?: string | null;
  party?: string[] | null;
  docket_absolute_url?: string;
}

/**
 * Maps a PACER nature-of-suit code / description (or a criminal or
 * bankruptcy docket number) to the app's US practice areas. Undefined when
 * nothing recognisable is present, so the attorney picks it manually.
 */
export function suggestPracticeArea(
  natureOfSuit: string | undefined,
  cause: string | undefined,
  docketNumber: string,
): string | undefined {
  const dn = docketNumber.toLowerCase();
  if (/-(cr|mj|po|tp)-/.test(dn)) return 'Criminal Defense';
  if (/-bk-|-ap-/.test(dn)) return 'Bankruptcy';

  const nos = (natureOfSuit ?? '').trim();
  const code = Number.parseInt(nos, 10);
  if (Number.isFinite(code)) {
    if (code >= 110 && code <= 196) return 'Corporate/Business Law';
    if (code >= 210 && code <= 290) return 'Real Estate';
    if (code >= 310 && code <= 368) return 'Personal Injury';
    if (code === 410) return 'Corporate/Business Law';
    if (code === 422 || code === 423) return 'Bankruptcy';
    if (code === 442 || code === 445) return 'Employment Law';
    if (code >= 460 && code <= 465) return 'Immigration';
    if (code >= 510 && code <= 560) return 'Criminal Defense';
    if (code >= 610 && code <= 690) return 'Criminal Defense';
    if (code >= 710 && code <= 791) return 'Employment Law';
    if (code === 820 || code === 830 || code === 835 || code === 840 || code === 880) {
      return 'Intellectual Property';
    }
    if (code === 850) return 'Corporate/Business Law';
    if (code === 870 || code === 871) return 'Tax Law';
    if (code >= 100 && code <= 999) return 'Civil Litigation';
  }

  const text = `${nos} ${cause ?? ''}`.toLowerCase();
  if (!text.trim()) return undefined;
  if (/immigra|deportation|naturaliz/.test(text)) return 'Immigration';
  if (/patent|copyright|trademark|trade secret/.test(text)) return 'Intellectual Property';
  if (/bankrupt/.test(text)) return 'Bankruptcy';
  if (/\btax/.test(text)) return 'Tax Law';
  if (/employ|labor|erisa|overtime|wage|ada /.test(text)) return 'Employment Law';
  if (/personal injury|malpractice|product liability|asbestos|motor vehicle/.test(text)) {
    return 'Personal Injury';
  }
  if (/real property|foreclos|land condemnation|rent|lease|eject/.test(text)) return 'Real Estate';
  if (/prisoner|habeas|vacate sentence|criminal|forfeiture|drug/.test(text)) {
    return 'Criminal Defense';
  }
  if (/computer|cyber|data breach|hacking/.test(text)) return 'Cyber Law';
  if (/contract|insurance|antitrust|securities|banks/.test(text)) return 'Corporate/Business Law';
  return 'Civil Litigation';
}

interface SearchDocumentHit {
  id?: number;
  docket_entry_id?: number;
  entry_number?: number | null;
  attachment_number?: number | null;
  entry_date_filed?: string | null;
  short_description?: string;
  description?: string;
  absolute_url?: string;
  docket_id?: number;
}

function headers(): Record<string, string> {
  const h: Record<string, string> = { Accept: 'application/json' };
  if (COURTLISTENER_API_TOKEN) h.Authorization = `Token ${COURTLISTENER_API_TOKEN}`;
  return h;
}

async function search<T>(params: Record<string, string>): Promise<T[]> {
  const url = `${SEARCH}?${new URLSearchParams(params).toString()}`;
  const res = await fetch(url, {
    headers: headers(),
    signal: AbortSignal.timeout(TIMEOUT_MS),
  });
  if (!res.ok) {
    throw new Error(`CourtListener request failed (${res.status})`);
  }
  const data = (await res.json()) as { results?: T[] };
  return data.results ?? [];
}

function toMatch(d: SearchDocketHit): CourtDocketMatch | null {
  if (!d.docket_id) return null;
  return {
    docketId: d.docket_id,
    caseName: d.caseName ?? '',
    docketNumber: d.docketNumber ?? '',
    court: d.court ?? '',
    courtId: d.court_id ?? '',
    judge: d.assignedTo || undefined,
    dateFiled: d.dateFiled || undefined,
    dateTerminated: d.dateTerminated || undefined,
    lastFilingDate: undefined,
    natureOfSuit: d.suitNature?.trim() || undefined,
    cause: d.cause?.trim() || undefined,
    jurisdictionType: d.jurisdictionType?.trim() || undefined,
    // Mass actions list hundreds of parties; keep the record readable.
    parties: (d.party ?? []).map((p) => p.trim()).filter(Boolean).slice(0, MAX_PARTIES),
    practiceArea: suggestPracticeArea(
      d.suitNature ?? undefined,
      d.cause ?? undefined,
      d.docketNumber ?? '',
    ),
    url: d.docket_absolute_url ? `${BASE}${d.docket_absolute_url}` : `${BASE}/docket/${d.docket_id}/`,
  };
}

/** Escapes the characters CourtListener's query parser treats specially. */
function quote(value: string): string {
  return `"${value.replace(/["\\]/g, ' ').trim()}"`;
}

export interface LookupOptions {
  /** Restrict to these CourtListener court ids (space-separated works too). */
  courtIds?: string[];
  /** Restrict to every federal court of this US state. */
  state?: string;
}

/**
 * Finds dockets for the attorney's Add Case flow.
 * - A CourtListener docket link / id returns exactly that docket.
 * - Otherwise: exact docket-number match (optionally within one state's or
 *   one court's dockets), then a free-text search so a case name works too.
 * The same docket number exists in many courts, and CourtListener sometimes
 * holds two copies of one docket, so results are de-duplicated per court.
 */
export async function lookupDocket(
  query: string,
  opts: LookupOptions = {},
): Promise<{ available: boolean; results: CourtDocketMatch[]; exact: boolean }> {
  const q = query.trim();

  const direct = parseDocketId(q);
  if (direct) {
    const one = await fetchDocket(direct);
    return { available: true, results: one ? [one] : [], exact: true };
  }

  const courtIds = [
    ...(opts.courtIds ?? []),
    ...(opts.state ? courtsForState(opts.state).map((c) => c.id) : []),
  ];
  const courtParam: Record<string, string> = courtIds.length ? { court: [...new Set(courtIds)].join(' ') } : {};

  let hits = await search<SearchDocketHit>({
    type: 'd',
    q: `docketNumber:${quote(q)}`,
    order_by: 'dateFiled desc',
    ...courtParam,
  });
  if (hits.length === 0) {
    hits = await search<SearchDocketHit>({ type: 'd', q, order_by: 'score desc', ...courtParam });
  }

  // One row per (court, docket number): keep the copy with the most
  // information (a filing date, a judge, parties).
  const byKey = new Map<string, CourtDocketMatch>();
  for (const hit of hits) {
    const m = toMatch(hit);
    if (!m) continue;
    const key = `${m.courtId}|${m.docketNumber.toLowerCase()}`;
    const score = (m.dateFiled ? 2 : 0) + (m.judge ? 1 : 0) + Math.min(m.parties.length, 5) + (m.natureOfSuit ? 1 : 0);
    const prev = byKey.get(key);
    const prevScore = prev ? (prev.dateFiled ? 2 : 0) + (prev.judge ? 1 : 0) + Math.min(prev.parties.length, 5) + (prev.natureOfSuit ? 1 : 0) : -1;
    if (!prev || score > prevScore) byKey.set(key, m);
  }
  const results = [...byKey.values()].slice(0, 10);
  return { available: true, results, exact: results.length === 1 };
}

/** Current header data for one docket, or null when the provider no longer has it. */
export async function fetchDocket(docketId: number): Promise<CourtDocketMatch | null> {
  const hits = await search<SearchDocketHit>({ type: 'd', q: `docket_id:${docketId}` });
  const hit = hits.find((h) => h.docket_id === docketId) ?? hits[0];
  const match = hit ? toMatch(hit) : null;
  if (!match || !COURTLISTENER_API_TOKEN) return match;
  // The docket record itself (token-only) knows the latest filing date and
  // the terminated date even when no filings are public.
  try {
    const res = await fetch(`${BASE}/api/rest/v4/dockets/${docketId}/`, {
      headers: headers(),
      signal: AbortSignal.timeout(TIMEOUT_MS),
    });
    if (res.ok) {
      const d = (await res.json()) as {
        date_last_filing?: string | null;
        date_terminated?: string | null;
        assigned_to_str?: string | null;
      };
      match.lastFilingDate = d.date_last_filing || undefined;
      match.dateTerminated = d.date_terminated || match.dateTerminated;
      if (!match.judge && d.assigned_to_str?.trim()) match.judge = d.assigned_to_str.trim();
    }
  } catch {
    // Header from search is enough.
  }
  return match;
}

interface DocketEntryRow {
  id?: number;
  entry_number?: number | null;
  date_filed?: string | null;
  description?: string | null;
  recap_documents?: { description?: string | null; absolute_url?: string | null }[];
}

/**
 * Token-only: the complete, ordered docket entries straight from the
 * docket (up to `limit`, newest first). Falls back to search without a token.
 */
async function fetchDocketEntriesDirect(docketId: number, limit: number): Promise<CourtDocketEntry[] | null> {
  if (!COURTLISTENER_API_TOKEN) return null;
  const params = new URLSearchParams({
    docket: String(docketId),
    order_by: '-date_filed',
    page_size: String(Math.min(limit, 100)),
  });
  const res = await fetch(`${BASE}/api/rest/v4/docket-entries/?${params}`, {
    headers: headers(),
    signal: AbortSignal.timeout(TIMEOUT_MS),
  });
  if (!res.ok) return null;
  const data = (await res.json()) as { results?: DocketEntryRow[] };
  const out: CourtDocketEntry[] = [];
  for (const r of data.results ?? []) {
    if (!r.id || !r.date_filed) continue;
    const description = (r.description ?? '').trim();
    const short = (r.recap_documents?.[0]?.description ?? '').trim();
    const text = description || short;
    if (!text) continue;
    const doc = r.recap_documents?.[0]?.absolute_url;
    out.push({
      entryId: r.id,
      entryNumber: r.entry_number ?? undefined,
      date: r.date_filed,
      title: (short && short.length < 90 ? short : text.split(/[.;\n]/)[0]).slice(0, 90),
      description,
      url: doc ? `${BASE}${doc}` : `${BASE}/docket/${docketId}/`,
      kind: classifyEntry(text),
    });
  }
  return out;
}

/**
 * Most recent docket entries (newest first, one per entry — attachments are
 * collapsed into their parent entry). `limit` caps the number returned.
 */
export async function fetchDocketEntries(
  docketId: number,
  limit = 25,
): Promise<CourtDocketEntry[]> {
  const direct = await fetchDocketEntriesDirect(docketId, limit).catch(() => null);
  if (direct) return direct;
  const hits = await search<SearchDocumentHit>({
    type: 'rd',
    q: `docket_id:${docketId}`,
    order_by: 'entry_date_filed desc',
  });
  const byEntry = new Map<number, CourtDocketEntry>();
  for (const h of hits) {
    const entryId = h.docket_entry_id;
    if (!entryId || !h.entry_date_filed) continue;
    const description = (h.description ?? '').trim();
    const short = (h.short_description ?? '').trim();
    const existing = byEntry.get(entryId);
    // Attachments (Exhibit A, …) share the entry's description; the main
    // document (no attachment number) carries the entry's own title, so it
    // wins over any attachment row of the same entry.
    const isMain = h.attachment_number == null;
    if (existing && !isMain) continue;
    const candidate: CourtDocketEntry = {
      entryId,
      entryNumber: h.entry_number ?? undefined,
      date: h.entry_date_filed,
      title:
        short ||
        (description ? description.split(/[.;\n]/)[0].slice(0, 80) : '') ||
        (h.entry_number ? `Docket entry #${h.entry_number}` : 'Docket entry'),
      description: description || undefined,
      url: h.absolute_url ? `${BASE}${h.absolute_url}` : `${BASE}/docket/${docketId}/`,
      kind: classifyEntry(`${short} ${description}`),
    };
    byEntry.set(entryId, candidate);
    if (byEntry.size > limit) break;
  }
  return [...byEntry.values()].sort((a, b) => b.date.localeCompare(a.date));
}
