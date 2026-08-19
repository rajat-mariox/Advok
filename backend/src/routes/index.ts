import { Router } from 'express';
import adminRoutes from './admin.routes';
import advocateRoutes from './advocate.routes';
import authRoutes from './auth.routes';
import bookingRoutes from './booking.routes';
import cmsRoutes from './cms.routes';
import onboardingRoutes from './onboarding.routes';
import profileRoutes from './profile.routes';

const router = Router();

router.get('/health', (_req, res) => {
  res.json({ ok: true, service: 'advok-backend' });
});

router.use('/auth', authRoutes);
router.use('/advocates', advocateRoutes);
router.use('/bookings', bookingRoutes);
router.use('/profile', profileRoutes);
router.use('/onboarding', onboardingRoutes);
router.use('/admin', adminRoutes);
router.use('/cms', cmsRoutes);

export default router;
