import type { Request, Response } from 'express';
import { getNews, getNewsSources, NEWS_TAGS } from '../services/news.service';

/** GET /learning/news?tag= — US legal news for the student Legal News tab. */
export async function list(req: Request, res: Response) {
  const tag = typeof req.query.tag === 'string' ? req.query.tag : undefined;
  try {
    const items = await getNews(tag);
    return res.json({ news: items, tags: NEWS_TAGS });
  } catch (err) {
    return res.status(502).json({ error: err instanceof Error ? err.message : 'News unavailable' });
  }
}

/** GET /admin/learning/news/sources — per-feed health for the admin panel. */
export async function sources(_req: Request, res: Response) {
  const status = await getNewsSources();
  return res.json({ ...status, tags: NEWS_TAGS });
}

/** POST /admin/learning/news/refresh — bypass the 30-minute cache. */
export async function refresh(_req: Request, res: Response) {
  const status = await getNewsSources(true);
  const items = await getNews();
  return res.json({ ...status, news: items, tags: NEWS_TAGS });
}
