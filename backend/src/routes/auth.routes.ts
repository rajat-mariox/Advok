import { Router } from 'express';
import * as auth from '../controllers/auth.controller';
import { requireAuth } from '../middlewares/auth.middleware';

const router = Router();

router.post('/admin/login', auth.adminLogin);
router.post('/send-otp', auth.sendOtp);
router.post('/verify-otp', auth.verifyOtp);
router.post('/google', auth.googleLogin);
router.post('/apple', auth.appleLogin);
router.post('/select-role', requireAuth, auth.selectRole);
router.get('/me', requireAuth, auth.me);

export default router;
