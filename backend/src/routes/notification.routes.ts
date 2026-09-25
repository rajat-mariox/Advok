import { Router } from 'express';
import * as msg from '../controllers/message.controller';
import { requireAuth } from '../middlewares/auth.middleware';

const router = Router();

router.use(requireAuth);

router.get('/', msg.listNotifications);
router.post('/read', msg.markNotificationsRead);
router.post('/:id/read', msg.markNotificationRead);

export default router;
