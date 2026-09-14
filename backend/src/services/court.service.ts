// Court-records client for US dockets via the CourtListener REST API v4
// (free RECAP/PACER data from the Free Law Project).
//
// The /search/ endpoint is used throughout because it answers anonymously —
// the attorney can look up and link a docket without a token. A free token
// (COURTLISTENER_API_TOKEN) raises the rate limit and is sent when present.
//
// State courts have no unified API, so manual entry remains the fallback
// for them: a case without a docket link is simply never synced.
import { COURTLISTENER_API_TOKEN } from '../config';

const BASE = 'https://www.courtlistener.com';
const SEARCH = `${BASE}/api/rest/v4/search/`;
const TIMEOUT_MS = 15_000;
/** Cap on parties kept per docket. */
const MAX_PARTIES = 20;

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

/**
 * Finds dockets by docket number (exact field match first, then a free-text
 * search so a case name also works). Up to 10 matches, most relevant first.
 */
export async function lookupDocket(
  query: string,
): Promise<{ available: boolean; results: CourtDocketMatch[] }> {
  const q = query.trim();
  let hits = await search<SearchDocketHit>({
    type: 'd',
    q: `docketNumber:${quote(q)}`,
    order_by: 'dateFiled desc',
  });
  if (hits.length === 0) {
    hits = await search<SearchDocketHit>({ type: 'd', q, order_by: 'score desc' });
  }
  const results = hits
    .map(toMatch)
    .filter((m): m is CourtDocketMatch => m !== null)
    .slice(0, 10);
  return { available: true, results };
}

/** Current header data for one docket, or null when the provider no longer has it. */
export async function fetchDocket(docketId: number): Promise<CourtDocketMatch | null> {
  const hits = await search<SearchDocketHit>({ type: 'd', q: `docket_id:${docketId}` });
  const hit = hits.find((h) => h.docket_id === docketId) ?? hits[0];
  return hit ? toMatch(hit) : null;
}

/**
 * Most recent docket entries (newest first, one per entry — attachments are
 * collapsed into their parent entry). `limit` caps the number returned.
 */
export async function fetchDocketEntries(
  docketId: number,
  limit = 25,
): Promise<CourtDocketEntry[]> {
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
    };
    byEntry.set(entryId, candidate);
    if (byEntry.size > limit) break;
  }
  return [...byEntry.values()].sort((a, b) => b.date.localeCompare(a.date));
}
