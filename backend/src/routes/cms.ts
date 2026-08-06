import { Router } from 'express';
import { getDb } from '../db';

const router = Router();

/** Public list of app pages (slug + title only), no auth needed. */
router.get('/', (_req, res) => {
  const pages = getDb().cmsPages ?? [];
  return res.json({
    pages: pages.map(({ slug, title, updatedAt }) => ({ slug, title, updatedAt })),
  });
});

/** Full content of one page, shown inside the app. */
router.get('/:slug', (req, res) => {
  const page = (getDb().cmsPages ?? []).find((p) => p.slug === req.params.slug);
  if (!page) return res.status(404).json({ error: 'Page not found' });
  return res.json({ page });
});

export default router;
