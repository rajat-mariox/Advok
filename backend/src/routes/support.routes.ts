import { Router } from 'express';
import * as support from '../controllers/support.controller';
import { requireAuth } from '../middlewares/auth.middleware';

const router = Router();

router.use(requireAuth);

router.get('/tickets', support.listMyTickets);
router.post('/tickets', support.createTicket);
router.get('/tickets/:id', support.getMyTicket);
router.post('/tickets/:id/reply', support.replyToMyTicket);

export default router;
