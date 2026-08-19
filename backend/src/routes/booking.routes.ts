import { Router } from 'express';
import * as bookings from '../controllers/booking.controller';
import { requireRole } from '../middlewares/auth.middleware';

const router = Router();

router.post('/', requireRole('client'), bookings.createBooking);
router.get('/', requireRole('client', 'advocate'), bookings.listMyBookings);
router.post('/:id/accept', requireRole('advocate'), bookings.respondToBooking('accept'));
router.post('/:id/decline', requireRole('advocate'), bookings.respondToBooking('decline'));
router.post('/:id/cancel', requireRole('client'), bookings.cancelBooking);

export default router;
