import { Router } from 'express';
import * as onboarding from '../controllers/onboarding.controller';
import { requireRole } from '../middlewares/auth.middleware';

const router = Router();

router.post('/advocate', requireRole('advocate'), onboarding.submitAdvocate);
router.post('/law-student', requireRole('law_student'), onboarding.submitLawStudent);
router.post('/law-firm', requireRole('law_firm'), onboarding.submitLawFirm);
router.get(
  '/status',
  requireRole('advocate', 'law_student', 'law_firm', 'client'),
  onboarding.onboardingStatus,
);

export default router;
