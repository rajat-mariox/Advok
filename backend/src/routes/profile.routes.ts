import { Router } from 'express';
import * as profile from '../controllers/profile.controller';
import { requireAuth } from '../middlewares/auth.middleware';

const router = Router();

router.put('/', requireAuth, profile.updateProfile);
router.post('/push-token', requireAuth, profile.registerPushToken);
router.delete('/push-token', requireAuth, profile.unregisterPushToken);

export default router;
