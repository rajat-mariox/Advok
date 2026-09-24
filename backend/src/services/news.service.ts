// US legal news for the law-student Legal News tab, aggregated from public
// RSS feeds (no API keys). Fetched on demand and cached in memory for 30
// minutes so the app and admin panel never hammer the sources.

export type NewsTag = 'Supreme Court' | 'Federal Courts' | 'Legislation' | 'Bar Exam' | 'Legal News';

export interface NewsItem {
  id: string;
  title: string;
  source: string;
  url: string;
  publishedAt: string; // ISO
  tag: NewsTag;
  /** Plain-text excerpt (first ~600 chars of the article body). */
  excerpt: string;
  /** Plain-text paragraphs from the feed body (may be partial). */
  paragraphs: string[];
}

export interface NewsSourceStatus {
  key: string;
  name: string;
  url: string;
  defaultTag: NewsTag;
  ok: boolean;
  items: number;
  error?: string;
  fetchedAt?: string;
}

interface FeedDef {
  key: string;
  name: string;
  url: string;
  defaultTag: NewsTag;
  /** Congress.gov packs many bills into one item; split them out. */
  splitBills?: boolean;
}

const DEFAULT_FEEDS: FeedDef[] = [
  { key: 'scotusblog', name: 'SCOTUSblog', url: 'https://www.scotusblog.com/feed/', defaultTag: 'Supreme Court' },
  { key: 'abajournal', name: 'ABA Journal', url: 'https://www.abajournal.com/news/rss', defaultTag: 'Legal News' },
  {
    key: 'congress',
    name: 'Congress.gov',
    url: 'https://www.congress.gov/rss/most-viewed-bills.xml',
    defaultTag: 'Legislation',
    splitBills: true,
  },
];

const VALID_TAGS = ['Supreme Court', 'Federal Courts', 'Legislation', 'Bar Exam', 'Legal News'] as const;

/**
 * Feeds come from NEWS_FEEDS in backend/.env when set, so the client can
 * add or remove sources without a code change. Format, one feed per `;`:
 *   key|Display name|https://feed-url|Default tag
 * Tag must be one of: Supreme Court, Federal Courts, Legislation, Bar Exam,
 * Legal News (anything else falls back to Legal News). A feed whose key is
 * "congress" gets Congress.gov's bill splitting.
 */
function loadFeeds(): FeedDef[] {
  const raw = (process.env.NEWS_FEEDS ?? '').trim();
  if (!raw) return DEFAULT_FEEDS;
  const feeds: FeedDef[] = [];
  for (const entry of raw.split(';')) {
    const [key, name, url, tag] = entry.split('|').map((x) => (x ?? '').trim());
    if (!key || !url || !/^https?:\/\//i.test(url)) continue;
    const defaultTag = (VALID_TAGS as readonly string[]).includes(tag) ? (tag as NewsTag) : 'Legal News';
    feeds.push({ key, name: name || key, url, defaultTag, splitBills: key === 'congress' });
  }
  if (feeds.length === 0) {
    console.warn('NEWS_FEEDS is set but no valid entries were found; using the default feeds');
    return DEFAULT_FEEDS;
  }
  console.log(`Legal news: ${feeds.length} feed(s) from NEWS_FEEDS`);
  return feeds;
}

const FEEDS: FeedDef[] = loadFeeds();

export const NEWS_TAGS: NewsTag[] = ['Supreme Court', 'Federal Courts', 'Legislation', 'Bar Exam', 'Legal News'];

const CACHE_TTL_MS = 30 * 60 * 1000;
const UA = 'Mozilla/5.0 (compatible; ADVOK legal news reader)';

let cache: { items: NewsItem[]; sources: NewsSourceStatus[]; fetchedAt: number } | null = null;
let inflight: Promise<void> | null = null;

// ------------------------------------------------------------ parsing

function decodeEntities(s: string): string {
  return s
    .replace(/&nbsp;/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#39;|&apos;|&#8217;/g, "'")
    .replace(/&#8220;|&#8221;/g, '"')
    .replace(/&#8211;|&ndash;/g, '–')
    .replace(/&#8212;|&mdash;/g, '—')
    .replace(/&#(\d+);/g, (_, n) => String.fromCharCode(Number(n)));
}

function stripCdata(s: string): string {
  return s.replace(/<!\[CDATA\[([\s\S]*?)\]\]>/g, '$1');
}

function tagText(block: string, tag: string): string {
  const m = new RegExp(`<${tag}(?:\\s[^>]*)?>([\\s\\S]*?)</${tag}>`, 'i').exec(block);
  return m ? decodeEntities(stripCdata(m[1]).trim()) : '';
}

function htmlToParagraphs(html: string): string[] {
  const text = decodeEntities(stripCdata(html))
    .replace(/<script[\s\S]*?<\/script>/gi, '')
    .replace(/<style[\s\S]*?<\/style>/gi, '')
    .replace(/<\/(p|div|h\d|li|blockquote)>/gi, '\n')
    .replace(/<br\s*\/?>/gi, '\n')
    .replace(/<[^>]+>/g, '')
    .replace(/\r/g, '');
  return text
    .split(/\n+/)
    .map((p) => p.replace(/\s+/g, ' ').trim())
    .filter((p) => p.length > 30 && !/^(the post|read more|continue reading|photo|image)/i.test(p))
    .slice(0, 12);
}

function classify(title: string, body: string, fallback: NewsTag): NewsTag {
  const t = `${title} ${body.slice(0, 400)}`.toLowerCase();
  if (/\bbar exam\b|\bbar passage\b|\blaw school\b|\bncbe\b|\bnextgen bar\b/.test(t)) return 'Bar Exam';
  if (/\bsupreme court\b|\bscotus\b|\bjustice[s]? (alito|barrett|gorsuch|jackson|kagan|kavanaugh|roberts|sotomayor|thomas)\b|\bcertiorari\b/.test(t)) {
    return 'Supreme Court';
  }
  if (/\bcongress\b|\bsenate\b|\bhouse of representatives\b|\blegislation\b|\bbill\b|\bstatute\b|\bsigned into law\b/.test(t)) {
    return 'Legislation';
  }
  if (/\bcircuit\b|\bdistrict court\b|\bcourt of appeals\b|\bfederal judge\b|\bappeals court\b|\bruling\b/.test(t)) {
    return 'Federal Courts';
  }
  return fallback;
}

function parseDate(s: string): string {
  const d = new Date(s);
  return Number.isNaN(d.getTime()) ? new Date().toISOString() : d.toISOString();
}

function idFor(url: string, title: string): string {
  let h = 0;
  const s = url || title;
  for (let i = 0; i < s.length; i++) h = (h * 31 + s.charCodeAt(i)) | 0;
  return `news_${(h >>> 0).toString(36)}`;
}

function parseFeed(def: FeedDef, xml: string): NewsItem[] {
  const blocks = xml.match(/<item[\s>][\s\S]*?<\/item>/gi) ?? [];
  // Channel-level date, used when items carry none (Congress.gov).
  const channelHead = xml.split(/<item[\s>]/i)[0];
  const channelDate = tagText(channelHead, 'pubDate') || tagText(channelHead, 'lastBuildDate');
  const out: NewsItem[] = [];
  for (const block of blocks) {
    const title = tagText(block, 'title');
    const link = tagText(block, 'link') || (/<guid[^>]*>([^<]+)<\/guid>/i.exec(block)?.[1] ?? '');
    const pub = tagText(block, 'pubDate') || tagText(block, 'dc:date');
    const bodyHtml =
      (/<content:encoded(?:\s[^>]*)?>([\s\S]*?)<\/content:encoded>/i.exec(block)?.[1] ?? '') ||
      (/<description(?:\s[^>]*)?>([\s\S]*?)<\/description>/i.exec(block)?.[1] ?? '');

    if (def.splitBills) {
      // "<li><a href='…'>H.R.6509</a> [119th] - SAFE Drugs Act of 2025</li>"
      const bills = (decodeEntities(stripCdata(bodyHtml)).match(/<li>[\s\S]*?<\/li>/gi) ?? []).slice(0, 6);
      const billDate = parseDate(pub || channelDate);
      for (const li of bills) {
        const href = /href=['"]([^'"]+)['"]/i.exec(li)?.[1] ?? '';
        const text = li.replace(/<[^>]+>/g, '').replace(/\s+/g, ' ').trim();
        const m = /^([A-Z][A-Za-z.]*\s?\d+)\s*\[(\d+\w+)\]\s*-\s*(.+)$/.exec(text);
        const billTitle = m ? `${m[1]}: ${m[3]}` : text;
        if (!billTitle) continue;
        out.push({
          id: idFor(href, billTitle),
          title: billTitle,
          source: def.name,
          url: href,
          publishedAt: billDate,
          tag: 'Legislation',
          excerpt: m
            ? `${m[1]} in the ${m[2]} Congress. One of the most-viewed bills on congress.gov this week.`
            : text,
          paragraphs: [],
        });
      }
      continue;
    }

    if (!title) continue;
    const paragraphs = htmlToParagraphs(bodyHtml);
    const excerpt = paragraphs.join(' ').slice(0, 600);
    out.push({
      id: idFor(link, title),
      title,
      source: def.name,
      url: link,
      publishedAt: parseDate(pub),
      tag: classify(title, excerpt, def.defaultTag),
      excerpt,
      paragraphs,
    });
  }
  return out;
}

// ------------------------------------------------------------ fetching

async function fetchAll(): Promise<void> {
  const sources: NewsSourceStatus[] = [];
  const items: NewsItem[] = [];
  await Promise.all(
    FEEDS.map(async (def) => {
      const status: NewsSourceStatus = { key: def.key, name: def.name, url: def.url, defaultTag: def.defaultTag, ok: false, items: 0 };
      try {
        const res = await fetch(def.url, {
          headers: { 'User-Agent': UA, Accept: 'application/rss+xml, application/xml, text/xml, */*' },
          signal: AbortSignal.timeout(12_000),
        });
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        const parsed = parseFeed(def, await res.text());
        items.push(...parsed);
        status.ok = true;
        status.items = parsed.length;
        status.fetchedAt = new Date().toISOString();
      } catch (err) {
        status.error = err instanceof Error ? err.message : String(err);
      }
      sources.push(status);
    }),
  );
  items.sort((a, b) => b.publishedAt.localeCompare(a.publishedAt));
  // Keep the newest 60; dedupe by id.
  const seen = new Set<string>();
  const deduped = items.filter((i) => (seen.has(i.id) ? false : (seen.add(i.id), true))).slice(0, 60);
  cache = { items: deduped, sources: sources.sort((a, b) => a.name.localeCompare(b.name)), fetchedAt: Date.now() };
}

async function ensureFresh(force = false): Promise<void> {
  if (!force && cache && Date.now() - cache.fetchedAt < CACHE_TTL_MS) return;
  if (!inflight) inflight = fetchAll().finally(() => (inflight = null));
  await inflight;
}

export async function getNews(tag?: string, force = false): Promise<NewsItem[]> {
  await ensureFresh(force);
  const list = cache?.items ?? [];
  return tag && tag !== 'All' ? list.filter((i) => i.tag === tag) : list;
}

export async function getNewsSources(force = false): Promise<{ sources: NewsSourceStatus[]; fetchedAt: string | null; total: number }> {
  await ensureFresh(force);
  return {
    sources: cache?.sources ?? [],
    fetchedAt: cache ? new Date(cache.fetchedAt).toISOString() : null,
    total: cache?.items.length ?? 0,
  };
}
