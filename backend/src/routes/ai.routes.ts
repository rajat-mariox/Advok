import { Router } from 'express';
import * as ai from '../controllers/ai.controller';
import { requireAuth } from '../middlewares/auth.middleware';

const router = Router();

router.use(requireAuth);

router.get('/status', ai.status);
router.get('/suggestions', ai.suggestions);
router.post('/chat', ai.chat);

export default router;
