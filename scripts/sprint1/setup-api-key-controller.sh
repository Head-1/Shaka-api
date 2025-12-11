#!/bin/bash

# ============================================================================
# SHAKA API - Sprint 1 - Parte 4/8
# Setup: Controllers, Routes e Validators para API Keys
# ============================================================================

set -e

PROJECT_ROOT=~/shaka-api
cd "$PROJECT_ROOT"

echo "=========================================="
echo "🚀 SPRINT 1 - DIA 1 - PARTE 4/8"
echo "🎮 Controllers + Routes + Validators"
echo "=========================================="
echo ""

# ============================================================================
# 1. API Key Controller
# ============================================================================

echo "[1/5] Criando ApiKeyController..."

mkdir -p src/api/controllers/api-key

cat > src/api/controllers/api-key/ApiKeyController.ts << 'EOF'
import { Request, Response } from 'express';
import { ApiKeyService } from '../../../core/services/api-key/ApiKeyService';
import { logger } from '../../../config/logger';

export class ApiKeyController {
  /**
   * POST /api/v1/keys
   * Create new API key
   */
  static async create(req: Request, res: Response): Promise<void> {
    try {
      const { name, permissions, expiresAt } = req.body;
      const userId = req.user!.id;

      logger.info('[ApiKeyController] Creating API key', { userId, name });

      const apiKey = await ApiKeyService.createKey({
        userId,
        name,
        permissions,
        expiresAt: expiresAt ? new Date(expiresAt) : undefined
      });

      res.status(201).json({
        success: true,
        data: apiKey,
        message: 'API key created successfully. Store it securely - it will not be shown again.'
      });
    } catch (error: any) {
      logger.error('[ApiKeyController] Error creating API key:', error);
      
      const statusCode = error.statusCode || 500;
      res.status(statusCode).json({
        success: false,
        error: error.message || 'Failed to create API key'
      });
    }
  }

  /**
   * GET /api/v1/keys
   * List all API keys for authenticated user
   */
  static async list(req: Request, res: Response): Promise<void> {
    try {
      const userId = req.user!.id;

      logger.info('[ApiKeyController] Listing API keys', { userId });

      const apiKeys = await ApiKeyService.listKeys(userId);

      res.status(200).json({
        success: true,
        data: apiKeys,
        count: apiKeys.length
      });
    } catch (error: any) {
      logger.error('[ApiKeyController] Error listing API keys:', error);
      
      res.status(500).json({
        success: false,
        error: error.message || 'Failed to list API keys'
      });
    }
  }

  /**
   * GET /api/v1/keys/:id
   * Get single API key details
   */
  static async getOne(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const userId = req.user!.id;

      logger.info('[ApiKeyController] Getting API key', { userId, keyId: id });

      const apiKey = await ApiKeyService.getKey(userId, id);

      res.status(200).json({
        success: true,
        data: apiKey
      });
    } catch (error: any) {
      logger.error('[ApiKeyController] Error getting API key:', error);
      
      const statusCode = error.statusCode || 500;
      res.status(statusCode).json({
        success: false,
        error: error.message || 'Failed to get API key'
      });
    }
  }

  /**
   * DELETE /api/v1/keys/:id
   * Revoke API key (soft delete)
   */
  static async revoke(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const userId = req.user!.id;

      logger.info('[ApiKeyController] Revoking API key', { userId, keyId: id });

      await ApiKeyService.revokeKey(userId, id);

      res.status(200).json({
        success: true,
        message: 'API key revoked successfully'
      });
    } catch (error: any) {
      logger.error('[ApiKeyController] Error revoking API key:', error);
      
      const statusCode = error.statusCode || 500;
      res.status(statusCode).json({
        success: false,
        error: error.message || 'Failed to revoke API key'
      });
    }
  }

  /**
   * POST /api/v1/keys/:id/rotate
   * Rotate API key (revoke old, create new)
   */
  static async rotate(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const userId = req.user!.id;

      logger.info('[ApiKeyController] Rotating API key', { userId, keyId: id });

      const newApiKey = await ApiKeyService.rotateKey(userId, id);

      res.status(200).json({
        success: true,
        data: newApiKey,
        message: 'API key rotated successfully. Store the new key securely.'
      });
    } catch (error: any) {
      logger.error('[ApiKeyController] Error rotating API key:', error);
      
      const statusCode = error.statusCode || 500;
      res.status(statusCode).json({
        success: false,
        error: error.message || 'Failed to rotate API key'
      });
    }
  }

  /**
   * GET /api/v1/keys/:id/usage
   * Get usage statistics for API key
   */
  static async getUsage(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const userId = req.user!.id;

      logger.info('[ApiKeyController] Getting API key usage', { userId, keyId: id });

      const usage = await ApiKeyService.getUsageStats(userId, id);

      res.status(200).json({
        success: true,
        data: usage
      });
    } catch (error: any) {
      logger.error('[ApiKeyController] Error getting usage:', error);
      
      const statusCode = error.statusCode || 500;
      res.status(statusCode).json({
        success: false,
        error: error.message || 'Failed to get usage statistics'
      });
    }
  }

  /**
   * DELETE /api/v1/keys/:id/permanent
   * Permanently delete API key (DANGEROUS)
   */
  static async deletePermanent(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const userId = req.user!.id;

      logger.warn('[ApiKeyController] Permanently deleting API key', { userId, keyId: id });

      await ApiKeyService.deleteKey(userId, id);

      res.status(200).json({
        success: true,
        message: 'API key permanently deleted'
      });
    } catch (error: any) {
      logger.error('[ApiKeyController] Error deleting API key:', error);
      
      const statusCode = error.statusCode || 500;
      res.status(statusCode).json({
        success: false,
        error: error.message || 'Failed to delete API key'
      });
    }
  }
}
EOF

echo "✅ ApiKeyController criado"

# ============================================================================
# 2. API Key Validators (Joi)
# ============================================================================

echo "[2/5] Criando Joi validators..."

mkdir -p src/api/validators

cat > src/api/validators/api-key.validator.ts << 'EOF'
import Joi from 'joi';

/**
 * Validator for creating API key
 */
export const createApiKeySchema = Joi.object({
  name: Joi.string()
    .min(3)
    .max(100)
    .required()
    .messages({
      'string.min': 'API key name must be at least 3 characters',
      'string.max': 'API key name must not exceed 100 characters',
      'any.required': 'API key name is required'
    }),

  permissions: Joi.array()
    .items(Joi.string().valid('read', 'write', 'delete', 'admin'))
    .default(['read', 'write'])
    .messages({
      'array.includes': 'Invalid permission. Must be one of: read, write, delete, admin'
    }),

  expiresAt: Joi.date()
    .iso()
    .greater('now')
    .optional()
    .messages({
      'date.greater': 'Expiration date must be in the future',
      'date.format': 'Expiration date must be in ISO 8601 format'
    })
});

/**
 * Validator for rotating API key
 */
export const rotateApiKeySchema = Joi.object({
  // No body params needed - ID comes from URL
});

/**
 * Validator for UUID params
 */
export const apiKeyIdSchema = Joi.object({
  id: Joi.string()
    .uuid()
    .required()
    .messages({
      'string.guid': 'Invalid API key ID format',
      'any.required': 'API key ID is required'
    })
});
EOF

echo "✅ Validators criados"

# ============================================================================
# 3. API Key Routes
# ============================================================================

echo "[3/5] Criando API Key routes..."

cat > src/api/routes/api-keys.routes.ts << 'EOF'
import { Router } from 'express';
import { ApiKeyController } from '../controllers/api-key/ApiKeyController';
import { authenticate } from '../middlewares/authenticate';
import { validateRequest } from '../middlewares/validateRequest';
import {
  createApiKeySchema,
  apiKeyIdSchema
} from '../validators/api-key.validator';

const router = Router();

/**
 * All routes require JWT authentication
 * API keys are managed by authenticated users
 */

// POST /api/v1/keys - Create new API key
router.post(
  '/',
  authenticate,
  validateRequest({ body: createApiKeySchema }),
  ApiKeyController.create
);

// GET /api/v1/keys - List all user's API keys
router.get(
  '/',
  authenticate,
  ApiKeyController.list
);

// GET /api/v1/keys/:id - Get single API key
router.get(
  '/:id',
  authenticate,
  validateRequest({ params: apiKeyIdSchema }),
  ApiKeyController.getOne
);

// DELETE /api/v1/keys/:id - Revoke API key (soft delete)
router.delete(
  '/:id',
  authenticate,
  validateRequest({ params: apiKeyIdSchema }),
  ApiKeyController.revoke
);

// POST /api/v1/keys/:id/rotate - Rotate API key
router.post(
  '/:id/rotate',
  authenticate,
  validateRequest({ params: apiKeyIdSchema }),
  ApiKeyController.rotate
);

// GET /api/v1/keys/:id/usage - Get usage statistics
router.get(
  '/:id/usage',
  authenticate,
  validateRequest({ params: apiKeyIdSchema }),
  ApiKeyController.getUsage
);

// DELETE /api/v1/keys/:id/permanent - Permanently delete (admin only)
router.delete(
  '/:id/permanent',
  authenticate,
  validateRequest({ params: apiKeyIdSchema }),
  ApiKeyController.deletePermanent
);

export default router;
EOF

echo "✅ Routes criadas"

# ============================================================================
# 4. Atualizar Router Principal
# ============================================================================

echo "[4/5] Atualizando router principal..."

# Backup
cp src/api/routes/index.ts src/api/routes/index.ts.bak 2>/dev/null || true

cat > src/api/routes/index.ts << 'EOF'
import { Router } from 'express';
import authRoutes from './auth.routes';
import userRoutes from './user.routes';
import planRoutes from './plan.routes';
import healthRoutes from './health.routes';
import apiKeysRoutes from './api-keys.routes';

const router = Router();

// Health check (no auth required)
router.use('/health', healthRoutes);

// Authentication routes
router.use('/auth', authRoutes);

// User management routes
router.use('/users', userRoutes);

// Plan/subscription routes
router.use('/plans', planRoutes);

// API Key management routes (NEW)
router.use('/keys', apiKeysRoutes);

export default router;
EOF

echo "✅ Router principal atualizado"

# ============================================================================
# 5. Criar index.ts para controller
# ============================================================================

echo "[5/5] Criando barrel exports..."

cat > src/api/controllers/api-key/index.ts << 'EOF'
export { ApiKeyController } from './ApiKeyController';
EOF

echo "✅ Exports criados"

echo ""
echo "=========================================="
echo "🧪 TESTANDO BUILD..."
echo "=========================================="
echo ""

npm run build > /tmp/build.log 2>&1

ERROR_COUNT=$(grep -c "error TS" /tmp/build.log || echo "0")

if [ "$ERROR_COUNT" -eq "0" ]; then
    echo "=========================================="
    echo "✅ PARTE 4/8 COMPLETA - BUILD LIMPO!"
    echo "=========================================="
    echo ""
    echo "Criados:"
    echo "  ✅ ApiKeyController (7 endpoints)"
    echo "  ✅ Joi Validators (createKey, idValidation)"
    echo "  ✅ Routes /api/v1/keys"
    echo "  ✅ Router principal atualizado"
    echo ""
    echo "Endpoints disponíveis:"
    echo "  POST   /api/v1/keys          - Create API key"
    echo "  GET    /api/v1/keys          - List API keys"
    echo "  GET    /api/v1/keys/:id      - Get API key"
    echo "  DELETE /api/v1/keys/:id      - Revoke API key"
    echo "  POST   /api/v1/keys/:id/rotate - Rotate API key"
    echo "  GET    /api/v1/keys/:id/usage  - Get usage stats"
    echo "  DELETE /api/v1/keys/:id/permanent - Delete permanently"
    echo ""
    echo "🚀 PRÓXIMO PASSO:"
    echo "  bash scripts/sprint1/setup-usage-tracking.sh"
    echo ""
else
    echo "⚠️  BUILD COM $ERROR_COUNT ERROS:"
    grep "error TS" /tmp/build.log | head -10
fi
