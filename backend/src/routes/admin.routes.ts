import { Router } from 'express';
import * as admin from '../controllers/admin.controller';
import * as ai from '../controllers/ai.controller';
import * as dictionary from '../controllers/dictionary.controller';
import * as learning from '../controllers/learning.controller';
import * as news from '../controllers/news.controller';
import * as queries from '../controllers/query.controller';
import * as settings from '../controllers/settings.controller';
import * as support from '../controllers/support.controller';
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
router.patch('/users/:id/firm-fee', admin.setFirmFee);

router.get('/bookings', admin.listBookings);
router.get('/cases', admin.listCases);
router.delete('/cases/:id', admin.deleteCase);
router.post('/operations/clear', admin.clearOperations);

router.get('/pricing', settings.getPricing);
router.put('/pricing', settings.updatePricing);

router.get('/support-contact', settings.getSupportContact);
router.put('/support-contact', settings.updateSupportContact);

router.get('/queries', queries.adminList);
router.post('/queries/:id/answer', queries.adminAnswer);
router.delete('/queries/:id', queries.adminDelete);

router.get('/support/tickets', support.adminListTickets);
router.get('/support/tickets/:id', support.adminGetTicket);
router.post('/support/tickets/:id/reply', support.adminReplyTicket);
router.patch('/support/tickets/:id/status', support.adminSetTicketStatus);

router.get('/ai/status', ai.status);
router.get('/ai/suggestions', ai.adminListSuggestions);
router.put('/ai/suggestions', ai.adminUpdateSuggestions);

router.get('/learning/search', learning.adminSearch);
router.get('/learning/news/sources', news.sources);
router.post('/learning/news/refresh', news.refresh);
router.get('/learning/cases', learning.adminList);
router.post('/learning/cases', learning.adminCreate);
router.put('/learning/cases/order', learning.adminReorder);
router.get('/learning/cases/:id', learning.adminGet);
router.patch('/learning/cases/:id', learning.adminUpdate);
router.post('/learning/cases/:id/refresh-text', learning.adminRefreshText);
router.delete('/learning/cases/:id', learning.adminDelete);
router.post('/learning/cases/:id/notes', learning.adminGenerateNotes);
router.put('/learning/cases/:id/notes', learning.adminUpdateNotes);

router.get('/learning/dictionary', dictionary.adminSearch);
router.get('/learning/dictionary/stats', dictionary.adminStats);
router.post('/learning/dictionary', dictionary.adminCreate);
router.get('/learning/dictionary/:slug', dictionary.adminGet);
router.patch('/learning/dictionary/:slug', dictionary.adminUpdate);
router.delete('/learning/dictionary/:slug', dictionary.adminDelete);

router.get('/cms', admin.listCmsPages);
router.put('/cms/:slug', admin.updateCmsPage);

export default router;
