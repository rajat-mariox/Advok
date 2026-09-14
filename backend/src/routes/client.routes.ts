import { Router } from 'express';
import * as cases from '../controllers/case.controller';
import { requireRole } from '../middlewares/auth.middleware';

const router = Router();

router.get('/', requireRole('advocate'), cases.listMyClients);

export default router;
