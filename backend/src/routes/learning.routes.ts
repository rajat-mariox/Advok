import { Router } from 'express';
import * as dictionary from '../controllers/dictionary.controller';
import * as learning from '../controllers/learning.controller';
import * as news from '../controllers/news.controller';
import { requireAuth } from '../middlewares/auth.middleware';

const router = Router();

// Any signed-in user can read the curated cases (students are the audience).
router.use(requireAuth);

router.get('/cases', learning.listPublished);
router.get('/cases/:id', learning.getPublished);
router.post('/cases/:id/notes', learning.getOrGenerateNotes);

// Legal Dictionary (Black's 2nd ed. + admin edits + ADVOK AI explanations).
router.get('/dictionary', dictionary.search);
router.get('/dictionary/letters', dictionary.letters);
router.post('/dictionary/explain', dictionary.explain);
router.get('/dictionary/:slug', dictionary.get);
router.get('/news', news.list);

export default router;
