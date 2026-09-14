import { Router } from 'express';
import * as msg from '../controllers/message.controller';
import { requireAuth } from '../middlewares/auth.middleware';

const router = Router();

router.use(requireAuth);

router.get('/threads', msg.listThreads);
router.get('/with/:userId', msg.getThread);
router.post('/with/:userId', msg.sendMessage);

export default router;
