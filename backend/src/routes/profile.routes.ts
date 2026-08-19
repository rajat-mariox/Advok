import { Router } from 'express';
import * as profile from '../controllers/profile.controller';
import { requireAuth } from '../middlewares/auth.middleware';

const router = Router();

router.put('/', requireAuth, profile.updateProfile);

export default router;
