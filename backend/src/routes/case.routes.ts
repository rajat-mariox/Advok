import { Router } from 'express';
import * as cases from '../controllers/case.controller';
import { requireRole } from '../middlewares/auth.middleware';

const router = Router();

router.get('/', requireRole('client', 'advocate', 'law_firm'), cases.listMyCases);
router.post('/', requireRole('advocate'), cases.createCase);
router.get('/docket-lookup', requireRole('advocate'), cases.docketLookup);
router.get('/:id', requireRole('client', 'advocate', 'law_firm'), cases.getCase);
router.post('/:id/updates', requireRole('advocate'), cases.addCaseUpdate);
router.post('/:id/sync', requireRole('advocate'), cases.syncCase);
router.post('/:id/documents', requireRole('advocate'), cases.addCaseDocument);
router.post(
  '/:id/document-requests',
  requireRole('advocate'),
  cases.requestCaseDocument,
);
router.post(
  '/:id/document-requests/:requestId/upload',
  requireRole('client'),
  cases.uploadRequestedDocument,
);
router.delete(
  '/:id/documents/:docId',
  requireRole('advocate'),
  cases.removeCaseDocument,
);

export default router;
