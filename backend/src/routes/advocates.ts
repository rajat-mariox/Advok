import { Router } from 'express';
import { getDb } from '../db';
import { requireAuth, type AuthedRequest } from '../middleware/auth';
import type { AdvocateProfile } from '../types';

const router = Router();

/**
 * Verified advocates/attorneys the requesting user can browse.
 *
 * Country-scoped: an Indian client only sees Indian advocates and a US client
 * only sees US attorneys. Accounts saved before country tracking (no country
 * on either side) are not filtered out, so old test data keeps working.
 */
router.get('/', requireAuth, (req: AuthedRequest, res) => {
  const me = req.user!;
  const db = getDb();
  const list = db.users.filter((u) => {
    if (u.role !== 'advocate' || !u.profile) return false;
    if (u.status !== 'approved' && u.status !== 'active') return false;
    if (me.country && u.country && u.country !== me.country) return false;
    return true;
  });
  return res.json({
    advocates: list.map((u) => {
      const p = u.profile as AdvocateProfile;
      return {
        id: u.id,
        country: u.country ?? null,
        photo: p.photo ?? null,
        name: p.professional.fullName,
        advocateType: p.advocateType,
        yearsInPractice: p.yearsInPractice ?? null,
        firmRole: p.firmRole ?? null,
        practiceArea: p.professional.practiceArea,
        primaryCourt: p.professional.primaryCourt,
        state: p.location.state,
        district: p.location.district,
        workingDays: p.schedule.workingDays,
        startTime: p.schedule.startTime,
        endTime: p.schedule.endTime,
      };
    }),
  });
});

export default router;
