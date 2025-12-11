#!/bin/bash

# ============================================================================
# SHAKA API - Sprint 1 - Fix Completo com Validação
# Corrige todos os 13 erros TypeScript e valida build
# ============================================================================

set -e

PROJECT_ROOT=~/shaka-api
cd "$PROJECT_ROOT"

echo "=========================================="
echo "🔧 FIX SPRINT 1 - 13 ERROS + VALIDAÇÃO"
echo "=========================================="
echo ""

# ============================================================================
# FIX 1: User Type Issues (userId → id)
# ============================================================================

echo "[1/7] Corrigindo UserController (userId → id)..."

cat > src/api/controllers/user/UserController.ts << 'EOF'
import { Request, Response } from 'express';
import { UserService } from '../../../core/services/user/UserService';
import { logger } from '../../../config/logger';

export class UserController {
  /**
   * Get current user profile
   */
  static async getProfile(req: Request, res: Response): Promise<void> {
    try {
      const userId = req.user!.id;  // ✅ CORRIGIDO: userId → id

      const user = await UserService.getUserById(userId);

      res.json({
        success: true,
        data: user
      });
    } catch (error: any) {
      logger.error('[UserController] Error getting profile:', error);
      
      res.status(error.statusCode || 500).json({
        success: false,
        error: error.message
      });
    }
  }

  /**
   * Update user profile
   */
  static async updateProfile(req: Request, res: Response): Promise<void> {
    try {
      const userId = req.user!.id;  // ✅ CORRIGIDO: userId → id
      const updateData = req.body;

      const user = await UserService.updateUser(userId, updateData);

      res.json({
        success: true,
        data: user,
        message: 'Profile updated successfully'
      });
    } catch (error: any) {
      logger.error('[UserController] Error updating profile:', error);
      
      res.status(error.statusCode || 500).json({
        success: false,
        error: error.message
      });
    }
  }

  /**
   * Change password
   */
  static async changePassword(req: Request, res: Response): Promise<void> {
    try {
      const userId = req.user!.id;  // ✅ CORRIGIDO: userId → id
      const { currentPassword, newPassword } = req.body;

      await UserService.changePassword(userId, currentPassword, newPassword);

      res.json({
        success: true,
        message: 'Password changed successfully'
      });
    } catch (error: any) {
      logger.error('[UserController] Error changing password:', error);
      
      res.status(error.statusCode || 500).json({
        success: false,
        error: error.message
      });
    }
  }

  /**
   * Delete user account
   */
  static async deleteAccount(req: Request, res: Response): Promise<void> {
    try {
      const userId = req.user!.id;

      await UserService.deleteUser(userId);

      res.json({
        success: true,
        message: 'Account deleted successfully'
      });
    } catch (error: any) {
      logger.error('[UserController] Error deleting account:', error);
      
      res.status(error.statusCode || 500).json({
        success: false,
        error: error.message
      });
    }
  }
}
EOF

echo "✅ UserController corrigido"

# ============================================================================
# FIX 2: Authenticate Middleware (User type)
# ============================================================================

echo "[2/7] Corrigindo authenticate.ts (User type)..."

cat > src/api/middlewares/authenticate.ts << 'EOF'
import { Request, Response, NextFunction } from 'express';
import { TokenService } from '../../core/services/auth/TokenService';
import { UserRepository } from '../../infrastructure/database/repositories/UserRepository';
import { logger } from '../../config/logger';

export const authenticate = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      res.status(401).json({
        error: 'Authentication required',
        message: 'Please provide a valid authentication token'
      });
      return;
    }

    const token = authHeader.substring(7);
    const payload = TokenService.verifyAccessToken(token);

    if (!payload) {
      res.status(401).json({
        error: 'Invalid token',
        message: 'The provided token is invalid or expired'
      });
      return;
    }

    // ✅ CORRIGIDO: Buscar usuário completo do banco
    const userEntity = await UserRepository.findById(payload.userId);

    if (!userEntity) {
      res.status(401).json({
        error: 'User not found',
        message: 'The user associated with this token no longer exists'
      });
      return;
    }

    // ✅ CORRIGIDO: Converter UserEntity para User (sem password)
    req.user = {
      id: userEntity.id,
      email: userEntity.email,
      plan: userEntity.plan,
      createdAt: userEntity.createdAt,
      updatedAt: userEntity.updatedAt
    };

    next();
  } catch (error: any) {
    logger.error('[authenticate] Error:', error);
    
    res.status(401).json({
      error: 'Authentication failed',
      message: 'An error occurred during authentication'
    });
  }
};
EOF

echo "✅ authenticate.ts corrigido"

# ============================================================================
# FIX 3: RateLimiter Middleware
# ============================================================================

echo "[3/7] Corrigindo rateLimiter.ts..."

cat > src/api/middlewares/rateLimiter.ts << 'EOF'
import { Request, Response, NextFunction } from 'express';
import { RateLimiterService } from '../../core/services/rate-limiter/RateLimiterService';
import { PLAN_LIMITS } from '../../core/types/subscription.types';
import { logger } from '../../config/logger';

export const rateLimiter = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    if (!req.user) {
      next();
      return;
    }

    const userId = req.user.id;  // ✅ CORRIGIDO: userId → id
    const userPlan = req.user.plan || 'starter';
    const limits = PLAN_LIMITS[userPlan];  // ✅ CORRIGIDO: Usar objeto limits

    const result = await RateLimiterService.checkLimit(userId, limits);

    if (!result.allowed) {
      logger.warn('[rateLimiter] Rate limit exceeded', {
        userId,
        plan: userPlan
      });

      res.status(429).json({
        error: 'Rate limit exceeded',
        message: `You have exceeded your rate limit of ${result.limit} requests per day`,
        limit: result.limit,
        remaining: result.remaining,
        resetAt: result.resetAt
      });
      return;
    }

    await RateLimiterService.incrementUsage(userId, limits);

    res.setHeader('X-RateLimit-Limit', result.limit.toString());
    res.setHeader('X-RateLimit-Remaining', result.remaining.toString());
    res.setHeader('X-RateLimit-Reset', result.resetAt.toISOString());

    next();
  } catch (error: any) {
    logger.error('[rateLimiter] Error:', error);
    next();
  }
};
EOF

echo "✅ rateLimiter.ts corrigido"

# ============================================================================
# FIX 4: ValidateRequest Middleware (corrigir assinatura)
# ============================================================================

echo "[4/7] Corrigindo validateRequest.ts..."

cat > src/api/middlewares/validateRequest.ts << 'EOF'
import { Request, Response, NextFunction } from 'express';
import { ObjectSchema } from 'joi';
import { logger } from '../../config/logger';

/**
 * Middleware para validação de request usando Joi
 * @param schema - Joi schema
 * @param source - 'body' | 'query' | 'params' (default: 'body')
 */
export const validateRequest = (
  schema: ObjectSchema,
  source: 'body' | 'query' | 'params' = 'body'
) => {
  return (req: Request, res: Response, next: NextFunction): void => {
    const dataToValidate = req[source];

    const { error, value } = schema.validate(dataToValidate, {
      abortEarly: false,
      stripUnknown: true
    });

    if (error) {
      logger.warn('[validateRequest] Validation error:', {
        source,
        errors: error.details.map(d => ({
          field: d.path.join('.'),
          message: d.message
        }))
      });

      res.status(400).json({
        error: 'Validation error',
        message: 'The request contains invalid data',
        details: error.details.map(d => ({
          field: d.path.join('.'),
          message: d.message
        }))
      });
      return;
    }

    // Replace request data with validated data
    req[source] = value;

    next();
  };
};
EOF

echo "✅ validateRequest.ts corrigido"

# ============================================================================
# FIX 5: API Keys Routes (corrigir uso de validateRequest)
# ============================================================================

echo "[5/7] Corrigindo api-keys.routes.ts..."

cat > src/api/routes/api-keys.routes.ts << 'EOF'
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
  authenticate,
  trackUsage,
  ApiKeyController.list
);

// GET /api/v1/keys/:id
router.get(
  '/:id',
  authenticate,
  validateRequest(apiKeyIdSchema, 'params'),  // ✅ CORRIGIDO
  trackUsage,
  ApiKeyController.getOne
);

// GET /api/v1/keys/:id/usage
router.get(
  '/:id/usage',
  authenticate,
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
EOF

echo "✅ api-keys.routes.ts corrigido"

# ============================================================================
# FIX 6: Health Routes (adicionar healthCheck ao DatabaseService)
# ============================================================================

echo "[6/7] Adicionando healthCheck() ao DatabaseService..."

# Verificar se healthCheck já existe
if ! grep -q "static async healthCheck" src/infrastructure/database/DatabaseService.ts; then
    # Adicionar método healthCheck antes do getDataSource
    sed -i '/static getDataSource/i\
  static async healthCheck(): Promise<boolean> {\
    try {\
      if (!this.isInitialized) {\
        return false;\
      }\
\
      await AppDataSource.query('"'"'SELECT 1'"'"');\
      return true;\
    } catch (error) {\
      logger.error('"'"'[DatabaseService] Health check failed:'"'"', error);\
      return false;\
    }\
  }\
\
' src/infrastructure/database/DatabaseService.ts

    echo "✅ healthCheck() adicionado ao DatabaseService"
else
    echo "✅ healthCheck() já existe no DatabaseService"
fi

# ============================================================================
# FIX 7: User Type Definition (garantir que está correto)
# ============================================================================

echo "[7/7] Verificando User type definition..."

cat > src/core/types/user.types.ts << 'EOF'
export interface User {
  id: string;
  email: string;
  plan: 'starter' | 'pro' | 'business' | 'enterprise';
  createdAt: Date;
  updatedAt: Date;
}

export interface CreateUserData {
  email: string;
  password: string;
  plan?: 'starter' | 'pro' | 'business' | 'enterprise';
}

export interface UpdateUserData {
  email?: string;
  plan?: 'starter' | 'pro' | 'business' | 'enterprise';
}

export interface UserResponse {
  id: string;
  email: string;
  plan: string;
  createdAt: Date;
  updatedAt: Date;
}
EOF

echo "✅ User types verificados"

# ============================================================================
# VALIDAÇÃO FINAL COM BUILD
# ============================================================================

echo ""
echo "=========================================="
echo "🧪 VALIDAÇÃO FINAL - TESTANDO BUILD"
echo "=========================================="
echo ""

npm run build > /tmp/build.log 2>&1

ERROR_COUNT=$(grep -c "error TS" /tmp/build.log || echo "0")
WARNING_COUNT=$(grep -c "warning" /tmp/build.log || echo "0")

echo "Resultado do Build:"
echo "  Erros TypeScript: $ERROR_COUNT"
echo "  Warnings: $WARNING_COUNT"
echo ""

if [ "$ERROR_COUNT" -eq "0" ]; then
    echo "=========================================="
    echo "✅ BUILD LIMPO! TODOS OS ERROS CORRIGIDOS!"
    echo "=========================================="
    echo ""
    echo "Correções aplicadas:"
    echo "  ✅ UserController (userId → id)"
    echo "  ✅ authenticate.ts (User type sem password)"
    echo "  ✅ rateLimiter.ts (RateLimitConfig correto)"
    echo "  ✅ validateRequest.ts (assinatura corrigida)"
    echo "  ✅ api-keys.routes.ts (validateRequest correto)"
    echo "  ✅ DatabaseService (healthCheck adicionado)"
    echo "  ✅ User types (interface correta)"
    echo ""
    echo "🚀 PRÓXIMOS PASSOS:"
    echo ""
    echo "1. Aplicar migrations:"
    echo "   bash scripts/database/apply-migrations.sh shaka-staging"
    echo ""
    echo "2. Build e deploy Docker:"
    echo "   bash scripts/sprint1/build-and-deploy.sh"
    echo ""
    echo "3. Testar API Keys endpoints:"
    echo "   bash scripts/sprint1/test-api-keys.sh"
    echo ""
    
    # Mostrar estrutura criada
    echo "📦 ESTRUTURA CRIADA (Sprint 1 - Partes 1-6):"
    echo ""
    echo "Backend Core:"
    echo "  ✅ ApiKeyService (geração, validação, CRUD)"
    echo "  ✅ UsageTrackingService (métricas completas)"
    echo "  ✅ RateLimiterService (por API key)"
    echo ""
    echo "Database:"
    echo "  ✅ ApiKeyEntity + Repository"
    echo "  ✅ UsageRecordEntity + Repository"
    echo "  ✅ Migrations prontas"
    echo ""
    echo "API Layer:"
    echo "  ✅ ApiKeyController (7 endpoints)"
    echo "  ✅ Middlewares: apiKeyAuth, trackUsage"
    echo "  ✅ Routes: /api/v1/keys/*"
    echo "  ✅ Validators: Joi schemas"
    echo ""
else
    echo "=========================================="
    echo "⚠️  AINDA HÁ $ERROR_COUNT ERROS"
    echo "=========================================="
    echo ""
    echo "Primeiros 20 erros:"
    grep "error TS" /tmp/build.log | head -20
    echo ""
    echo "Log completo: /tmp/build.log"
    echo ""
    echo "Execute para ver todos os erros:"
    echo "  cat /tmp/build.log | grep 'error TS'"
    echo ""
fi
