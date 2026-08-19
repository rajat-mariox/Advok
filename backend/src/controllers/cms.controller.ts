import type { Request, Response } from 'express';
import { getDb } from '../services/db.service';

/** Public list of app pages (slug + title only), no auth needed. */
export function listPages(_req: Request, res: Response) {
  const pages = getDb().cmsPages ?? [];
  return res.json({
    pages: pages.map(({ slug, title, updatedAt }) => ({ slug, title, updatedAt })),
  });
}

/** Full content of one page, shown inside the app. */
export function getPage(req: Request, res: Response) {
  const page = (getDb().cmsPages ?? []).find((p) => p.slug === req.params.slug);
  if (!page) return res.status(404).json({ error: 'Page not found' });
  return res.json({ page });
}
