import { Router } from 'express';
import * as settings from '../controllers/settings.controller';
import { requireAuth } from '../middlewares/auth.middleware';

const router = Router();

router.get('/pricing', requireAuth, settings.getPricing);
router.get('/support', requireAuth, settings.getSupportContact);

export default router;
