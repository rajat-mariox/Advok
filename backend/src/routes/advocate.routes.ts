import { Router } from 'express';
import * as advocates from '../controllers/advocate.controller';
import { requireAuth } from '../middlewares/auth.middleware';

const router = Router();

router.get('/', requireAuth, advocates.listAdvocates);

export default router;
