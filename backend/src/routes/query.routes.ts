import { Router } from 'express';
import * as queries from '../controllers/query.controller';
import { requireRole } from '../middlewares/auth.middleware';

const router = Router();

// Law students ask; the ADVOK team answers from the admin panel.
router.get('/', requireRole('law_student'), queries.listMyQueries);
router.post('/', requireRole('law_student'), queries.createQuery);

export default router;
