import { Router } from 'express';
import * as cms from '../controllers/cms.controller';

const router = Router();

router.get('/', cms.listPages);
router.get('/:slug', cms.getPage);

export default router;
