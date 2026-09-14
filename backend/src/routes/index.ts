import { Router } from 'express';
import adminRoutes from './admin.routes';
import advocateRoutes from './advocate.routes';
import aiRoutes from './ai.routes';
import authRoutes from './auth.routes';
import bookingRoutes from './booking.routes';
import caseRoutes from './case.routes';
import clientRoutes from './client.routes';
import cmsRoutes from './cms.routes';
import * as events from '../controllers/events.controller';
import lawFirmRoutes from './law-firm.routes';
import learningRoutes from './learning.routes';
import messageRoutes from './message.routes';
import notificationRoutes from './notification.routes';
import onboardingRoutes from './onboarding.routes';
import profileRoutes from './profile.routes';
import queryRoutes from './query.routes';
import settingsRoutes from './settings.routes';
import supportRoutes from './support.routes';

const router = Router();

router.get('/health', (_req, res) => {
  res.json({ ok: true, service: 'advok-backend' });
});

// Live updates (SSE). Token via Authorization header or ?token= (browser EventSource).
router.get('/events', events.stream);
router.get('/events/status', events.status);

router.use('/auth', authRoutes);
router.use('/ai', aiRoutes);
router.use('/advocates', advocateRoutes);
router.use('/law-firms', lawFirmRoutes);
router.use('/learning', learningRoutes);
router.use('/bookings', bookingRoutes);
router.use('/cases', caseRoutes);
router.use('/clients', clientRoutes);
router.use('/messages', messageRoutes);
router.use('/notifications', notificationRoutes);
router.use('/profile', profileRoutes);
router.use('/queries', queryRoutes);
router.use('/settings', settingsRoutes);
router.use('/support', supportRoutes);
router.use('/onboarding', onboardingRoutes);
router.use('/admin', adminRoutes);
router.use('/cms', cmsRoutes);

export default router;
