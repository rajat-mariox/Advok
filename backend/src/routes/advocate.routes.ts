import { Router } from 'express';
import * as advocates from '../controllers/advocate.controller';
import { requireAuth } from '../middlewares/auth.middleware';

const router = Router();

router.get('/', requireAuth, advocates.listAdvocates);
router.get('/saved', requireAuth, advocates.listSaved);
router.post('/saved/:id', requireAuth, advocates.saveAdvocate);
router.delete('/saved/:id', requireAuth, advocates.unsaveAdvocate);

export default router;
