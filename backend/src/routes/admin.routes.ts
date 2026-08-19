import { Router } from 'express';
import * as admin from '../controllers/admin.controller';
import { requireRole } from '../middlewares/auth.middleware';

const router = Router();

router.use(requireRole('admin'));

router.get('/registrations', admin.listRegistrations);
router.get('/registrations/counts', admin.registrationCounts);
router.post('/registrations/:id/approve', admin.approveRegistration);
router.post('/registrations/:id/reject', admin.rejectRegistration);
router.post('/registrations/:id/reopen', admin.reopenRegistration);

router.get('/users', admin.listUsers);
router.delete('/users/:id', admin.deleteUser);
router.post('/users/:id/suspend', admin.suspendUser);
router.post('/users/:id/unsuspend', admin.unsuspendUser);

router.get('/cms', admin.listCmsPages);
router.put('/cms/:slug', admin.updateCmsPage);

export default router;
