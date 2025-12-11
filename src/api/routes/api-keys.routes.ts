import { authenticateEither } from '../middlewares/authenticateEither';
import { Router } from 'express';
import { ApiKeyController } from '../controllers/api-key/ApiKeyController';
import { authenticate } from '../middlewares/authenticate';
import { validateRequest } from '../middlewares/validateRequest';
import { trackUsage } from '../middlewares/trackUsage';
import {
  createApiKeySchema,
  apiKeyIdSchema
} from '../validators/api-key.validator';

const router = Router();

// POST /api/v1/keys
router.post(
  '/',
  authenticate,
  validateRequest(createApiKeySchema, 'body'),  // ✅ CORRIGIDO
  trackUsage,
  ApiKeyController.create
);

// GET /api/v1/keys
router.get(
  '/',
  authenticateEither,
  trackUsage,
  ApiKeyController.list
);

// GET /api/v1/keys/:id
router.get(
  '/:id',
  authenticateEither,
  validateRequest(apiKeyIdSchema, 'params'),  // ✅ CORRIGIDO
  trackUsage,
  ApiKeyController.getOne
);

// GET /api/v1/keys/:id/usage
router.get(
  '/:id/usage',
  authenticateEither,
  validateRequest(apiKeyIdSchema, 'params'),  // ✅ CORRIGIDO
  trackUsage,
  ApiKeyController.getUsage
);

// POST /api/v1/keys/:id/rotate
router.post(
  '/:id/rotate',
  authenticate,
  validateRequest(apiKeyIdSchema, 'params'),  // ✅ CORRIGIDO
  trackUsage,
  ApiKeyController.rotate
);

// DELETE /api/v1/keys/:id
router.delete(
  '/:id',
  authenticate,
  validateRequest(apiKeyIdSchema, 'params'),  // ✅ CORRIGIDO
  trackUsage,
  ApiKeyController.revoke
);

// DELETE /api/v1/keys/:id/permanent
router.delete(
  '/:id/permanent',
  authenticate,
  validateRequest(apiKeyIdSchema, 'params'),  // ✅ CORRIGIDO
  trackUsage,
  ApiKeyController.deletePermanent
);

export default router;
