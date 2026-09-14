import { Router } from 'express';
import * as bookings from '../controllers/booking.controller';
import { requireRole } from '../middlewares/auth.middleware';

const router = Router();

// Anyone who books an attorney: clients, and law students / firms who
// consult attorneys through the same flow.
const BOOKER_ROLES = ['client', 'law_student', 'law_firm'] as const;

router.post('/', requireRole(...BOOKER_ROLES), bookings.createBooking);
router.get('/', requireRole(...BOOKER_ROLES, 'advocate'), bookings.listMyBookings);
// Providers who receive requests: individual attorneys and law firms.
const PROVIDER_ROLES = ['advocate', 'law_firm'] as const;

router.post('/:id/accept', requireRole(...PROVIDER_ROLES), bookings.respondToBooking('accept'));
router.post('/:id/decline', requireRole(...PROVIDER_ROLES), bookings.respondToBooking('decline'));
router.post('/:id/cancel', requireRole(...BOOKER_ROLES), bookings.cancelBooking);
router.post(
  '/:id/complete',
  requireRole(...BOOKER_ROLES, 'advocate'),
  bookings.completeBooking,
);

export default router;
