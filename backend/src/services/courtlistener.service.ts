// CourtListener (Free Law Project) opinion search and fetch, used by the
// Learning Content admin page to curate "Cases to Read" for law students.
//
// - /search/ works without a token (lower rate limit); we send the token when
//   COURTLISTENER_API_TOKEN is set.
// - /clusters/ and /opinions/ require a token. Without one, cases are added
//   from search metadata only and the full opinion text stays empty.
import { COURTLISTENER_API_TOKEN } from '../config';

const BASE = 'https://www.courtlistener.com/api/rest/v4';

export interface OpinionSearchHit {
  clusterId: number;
  title: string;
  court: string;
  courtId: string;
  dateFiled: string;
  citation: string;
  citations: string[];
  docketNumber: string;
  judges: string;
  citeCount: number;
  snippet: string;
  syllabus: string;
  /** Lead opinion id (the majority / ordering_key 1), if listed. */
  opinionId?: number;
}

function headers(): Record<string, string> {
  return COURTLISTENER_API_TOKEN ? { Authorization: `Token ${COURTLISTENER_API_TOKEN}` } : {};
}

export function hasCourtListenerToken(): boolean {
  return COURTLISTENER_API_TOKEN.length > 0;
}

/** Picks the most readable citation: U.S. reporter first, then F.2d/F.3d, else the first. */
function bestCitation(list: unknown): string {
  const cites = Array.isArray(list) ? list.filter((c): c is string => typeof c === 'string') : [];
  return (
    cites.find((c) => /^\d+ U\.S\. \d+$/.test(c)) ??
    cites.find((c) => /^\d+ S\. Ct\. \d+$/.test(c)) ??
    cites.find((c) => /^\d+ F\.(2d|3d|4th)? \d+$/.test(c)) ??
    cites.find((c) => /^\d+ F\. Supp\.( \dd)? \d+$/.test(c)) ??
    cites.find((c) => !/LEXIS|\bWL\b|U\.S\.L\.W\.|L\. Ed\./.test(c)) ??
    cites[0] ??
    ''
  );
}

function stripHtml(html: string): string {
  return html
    .replace(/<script[\s\S]*?<\/script>/gi, '')
    .replace(/<style[\s\S]*?<\/style>/gi, '')
    .replace(/<\/(p|div|br|h\d|li|blockquote)>/gi, '\n')
    .replace(/<br\s*\/?>/gi, '\n')
    .replace(/<[^>]+>/g, '')
    .replace(/&nbsp;/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/\n{3,}/g, '\n\n')
    .trim();
}

/**
 * Searches published opinions. `court` is a CourtListener court id
 * ("scotus", "ca9"…) or empty for all courts. Sorted by citation count so
 * landmark cases surface first.
 */
export async function searchOpinions(
  query: string,
  court = '',
  orderBy: 'citeCount desc' | 'score desc' | 'dateFiled desc' = 'citeCount desc',
): Promise<OpinionSearchHit[]> {
  // A query that looks like a case name ("Brown v. Board") is matched on the
  // case-name field so the case itself surfaces, not every opinion that
  // quotes it. Anything else is a full-text keyword search.
  const bare = query.trim().replace(/^"+|"+$/g, '');
  const looksLikeCaseName = /\s(v\.?|vs\.?)\s/i.test(bare) || /^in re\b/i.test(bare);
  const q = looksLikeCaseName ? `caseName:"${bare.replace(/"/g, '')}"` : query;
  const params = new URLSearchParams({ type: 'o', q, order_by: orderBy });
  if (court) params.set('court', court);
  const res = await fetch(`${BASE}/search/?${params.toString()}`, {
    headers: headers(),
    signal: AbortSignal.timeout(15_000),
  });
  if (!res.ok) throw new Error(`CourtListener search failed (${res.status})`);
  const data = (await res.json()) as { results?: Record<string, unknown>[] };
  return (data.results ?? []).slice(0, 20).map((r) => {
    const opinions = Array.isArray(r.opinions) ? (r.opinions as Record<string, unknown>[]) : [];
    const lead =
      opinions.find((o) => String(o.ordering_key ?? '') === '1' || o.type === 'combined-opinion' || o.type === 'lead-opinion') ??
      opinions[0];
    const snippet = typeof lead?.snippet === 'string' ? lead.snippet : '';
    return {
      clusterId: Number(r.cluster_id),
      title: String(r.caseName ?? r.caseNameFull ?? 'Untitled case'),
      court: String(r.court ?? ''),
      courtId: String(r.court_id ?? ''),
      dateFiled: String(r.dateFiled ?? ''),
      citation: bestCitation(r.citation),
      citations: Array.isArray(r.citation) ? (r.citation as string[]) : [],
      docketNumber: String(r.docketNumber ?? ''),
      judges: String(r.judge ?? ''),
      citeCount: Number(r.citeCount ?? 0),
      snippet: snippet.replace(/\s+/g, ' ').trim().slice(0, 400),
      syllabus: typeof r.syllabus === 'string' ? stripHtml(r.syllabus) : '',
      opinionId: lead && lead.id != null ? Number(lead.id) : undefined,
    };
  });
}

export interface OpinionContent {
  syllabus: string;
  text: string;
}

/**
 * Loads the cluster syllabus and the lead opinion's plain text. Needs a
 * token; returns null when none is configured so callers can degrade.
 */
export async function fetchOpinionContent(
  clusterId: number,
  opinionId?: number,
): Promise<OpinionContent | null> {
  if (!hasCourtListenerToken()) return null;
  const cluster = (await (
    await fetch(`${BASE}/clusters/${clusterId}/`, {
      headers: headers(),
      signal: AbortSignal.timeout(15_000),
    })
  ).json()) as { syllabus?: string; sub_opinions?: string[] };

  // Prefer the opinion id from search; else the first sub-opinion URL.
  let id = opinionId;
  if (!id && Array.isArray(cluster.sub_opinions) && cluster.sub_opinions.length > 0) {
    const m = /\/opinions\/(\d+)\//.exec(cluster.sub_opinions[0]);
    if (m) id = Number(m[1]);
  }
  let text = '';
  if (id) {
    const res = await fetch(`${BASE}/opinions/${id}/`, {
      headers: headers(),
      signal: AbortSignal.timeout(20_000),
    });
    if (res.ok) {
      const op = (await res.json()) as {
        plain_text?: string;
        html_with_citations?: string;
        html?: string;
        html_lawbox?: string;
        html_columbia?: string;
        xml_harvard?: string;
      };
      const html =
        op.html_with_citations || op.html || op.html_lawbox || op.html_columbia || op.xml_harvard || '';
      text = (op.plain_text?.trim() || stripHtml(html)).slice(0, 400_000);
    }
  }
  return {
    syllabus: typeof cluster.syllabus === 'string' ? stripHtml(cluster.syllabus) : '',
    text,
  };
}

/** ~230 words per minute, minimum 3 minutes so short syllabi still read sensibly. */
export function estimateMinutes(text: string): number {
  const words = text.trim().split(/\s+/).filter(Boolean).length;
  return Math.max(3, Math.round(words / 230));
}
