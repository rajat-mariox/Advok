import type { Request, Response } from 'express';
import type { AuthedRequest } from '../middlewares/auth.middleware';
import { getDb, saveDb } from '../services/db.service';
import { publishToAll } from '../services/realtime.service';
import {
  dictionaryStats,
  explainTerm,
  getTerm,
  letterCounts,
  removeTerm,
  searchTerms,
  slugify,
  upsertOverride,
} from '../services/dictionary.service';

const str = (v: unknown, max = 200) => (typeof v === 'string' ? v.trim().slice(0, max) : '');
const int = (v: unknown, fallback: number) => {
  const n = Number(v);
  return Number.isFinite(n) ? Math.trunc(n) : fallback;
};

// ------------------------------------------------------------- app (students)

/** GET /learning/dictionary?q=&letter=&limit=&offset= */
export function search(req: AuthedRequest, res: Response) {
  const result = searchTerms(getDb(), str(req.query.q, 80), {
    letter: str(req.query.letter, 1),
    limit: int(req.query.limit, 50),
    offset: int(req.query.offset, 0),
  });
  return res.json(result);
}

/** GET /learning/dictionary/letters */
export function letters(_req: AuthedRequest, res: Response) {
  return res.json({ letters: letterCounts(getDb()) });
}

/** GET /learning/dictionary/:slug */
export function get(req: AuthedRequest, res: Response) {
  const term = getTerm(getDb(), req.params.slug);
  if (!term || term.hidden) return res.status(404).json({ error: 'Term not found' });
  return res.json({ term });
}

/**
 * POST /learning/dictionary/explain — body { slug?, term?, regenerate? }.
 * Plain-English explanation from ADVOK AI (cached). `term` alone works for
 * words the dictionary lacks.
 */
export async function explain(req: AuthedRequest, res: Response) {
  const body = (req.body ?? {}) as { slug?: unknown; term?: unknown; regenerate?: unknown };
  const slug = str(body.slug, 120);
  const term = str(body.term, 80);
  if (!slug && !term) return res.status(400).json({ error: 'slug or term is required' });
  try {
    const result = await explainTerm(
      getDb(),
      { slug: slug || undefined, term: term || undefined },
      { country: req.user?.country, regenerate: body.regenerate === true },
    );
    return res.json(result);
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Explanation failed';
    const status = /not found/i.test(message) ? 404 : /not connected/i.test(message) ? 503 : 502;
    return res.status(status).json({ error: message });
  }
}

// ------------------------------------------------------------------ admin

/** GET /admin/learning/dictionary?q=&letter=&limit=&offset= — includes hidden/AI-only. */
export function adminSearch(req: Request, res: Response) {
  const result = searchTerms(getDb(), str(req.query.q, 80), {
    letter: str(req.query.letter, 1),
    limit: int(req.query.limit, 50),
    offset: int(req.query.offset, 0),
    includeHidden: true,
  });
  return res.json(result);
}

/** GET /admin/learning/dictionary/stats */
export function adminStats(_req: Request, res: Response) {
  return res.json({ stats: dictionaryStats(getDb()) });
}

/** GET /admin/learning/dictionary/:slug */
export function adminGet(req: Request, res: Response) {
  const term = getTerm(getDb(), req.params.slug);
  if (!term) return res.status(404).json({ error: 'Term not found' });
  return res.json({ term });
}

/** POST /admin/learning/dictionary — body { term, definition } adds a custom term. */
export function adminCreate(req: Request, res: Response) {
  const body = (req.body ?? {}) as { term?: unknown; definition?: unknown };
  const term = str(body.term, 80);
  const definition = str(body.definition, 4000);
  if (!term || !definition) return res.status(400).json({ error: 'term and definition are required' });
  const db = getDb();
  const slug = slugify(term);
  if (!slug) return res.status(400).json({ error: 'term must contain letters or digits' });
  const existing = getTerm(db, slug);
  if (existing && !existing.aiOnly && !existing.hidden) {
    return res.status(409).json({ error: `"${existing.term}" already exists — edit it instead` });
  }
  upsertOverride(db, slug, { term, definition, hidden: false });
  saveDb();
  publishToAll('content');
  return res.json({ term: getTerm(db, slug) });
}

/** PATCH /admin/learning/dictionary/:slug — body { term?, definition?, hidden? }. */
export function adminUpdate(req: Request, res: Response) {
  const body = (req.body ?? {}) as { term?: unknown; definition?: unknown; hidden?: unknown };
  const db = getDb();
  const slug = req.params.slug;
  if (!getTerm(db, slug)) return res.status(404).json({ error: 'Term not found' });
  const patch: { term?: string; definition?: string; hidden?: boolean } = {};
  if (typeof body.term === 'string') patch.term = str(body.term, 80);
  if (typeof body.definition === 'string') patch.definition = str(body.definition, 4000);
  if (typeof body.hidden === 'boolean') patch.hidden = body.hidden;
  upsertOverride(db, slug, patch);
  saveDb();
  publishToAll('content');
  return res.json({ term: getTerm(db, slug) });
}

/** DELETE /admin/learning/dictionary/:slug — custom terms are removed, base terms hidden. */
export function adminDelete(req: Request, res: Response) {
  const db = getDb();
  const outcome = removeTerm(db, req.params.slug);
  if (outcome === 'missing') return res.status(404).json({ error: 'Term not found' });
  saveDb();
  publishToAll('content');
  return res.json({ ok: true, outcome });
}
