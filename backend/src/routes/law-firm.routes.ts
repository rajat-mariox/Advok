import { Router } from 'express';
import * as lawFirms from '../controllers/law-firm.controller';
import { requireAuth } from '../middlewares/auth.middleware';

const router = Router();

router.get('/', requireAuth, lawFirms.listLawFirms);

export default router;
