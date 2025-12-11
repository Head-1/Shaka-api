#!/bin/bash

# ============================================================================
# SHAKA API - Sprint 1 - Fix Sintaxe
# Corrigir vírgulas extras em authenticate.ts e health.routes.ts
# ============================================================================

set -e

PROJECT_ROOT=~/shaka-api
cd "$PROJECT_ROOT"

echo "=========================================="
echo "🔧 FIX SINTAXE - 2 ERROS RESTANTES"
echo "=========================================="
echo ""

# ============================================================================
# FIX 1: authenticate.ts - Remover vírgula extra
# ============================================================================

echo "[1/2] Corrigindo authenticate.ts..."

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
        error: 'Unauthorized',
        message: 'Authentication token is required'
      });
      return;
    }

    const token = authHeader.substring(7);
    const payload = TokenService.verifyAccessToken(token);

    const user = await UserRepository.findById(payload.userId);

    if (!user) {
      res.status(401).json({
        error: 'Unauthorized',
        message: 'User not found'
      });
      return;
    }

    req.user = user;
    next();
  } catch (error: any) {
    logger.error('[authenticate] Authentication error:', error);
    res.status(401).json({
      error: 'Unauthorized',
      message: 'Invalid or expired token'
    });
  }
};
EOF

echo "✅ authenticate.ts corrigido"

# ============================================================================
# FIX 2: health.routes.ts - Remover vírgula extra
# ============================================================================

echo "[2/2] Corrigindo health.routes.ts..."

cat > src/api/routes/health.routes.ts << 'EOF'
import { Router } from 'express';
import { DatabaseService } from '../../infrastructure/database/DatabaseService';

const router = Router();

router.get('/', async (req, res) => {
  try {
    const dbHealthy = await DatabaseService.healthCheck();

    const health = {
      status: dbHealthy ? 'healthy' : 'unhealthy',
      timestamp: new Date().toISOString(),
      service: 'shaka-api',
      version: '1.0.0',
      database: dbHealthy ? 'connected' : 'disconnected'
    };

    const statusCode = dbHealthy ? 200 : 503;
    res.status(statusCode).json(health);
  } catch (error) {
    res.status(503).json({
      status: 'unhealthy',
      timestamp: new Date().toISOString(),
      service: 'shaka-api',
      version: '1.0.0',
      database: 'error',
      error: error instanceof Error ? error.message : 'Unknown error'
    });
  }
});

export default router;
EOF

echo "✅ health.routes.ts corrigido"

echo ""
echo "=========================================="
echo "🧪 TESTANDO BUILD..."
echo "=========================================="
echo ""

# Build e verificar
npm run build > /tmp/build.log 2>&1

ERROR_COUNT=$(grep -c "error TS" /tmp/build.log || echo "0")

if [ "$ERROR_COUNT" -eq "0" ]; then
    echo "=========================================="
    echo "🎉 BUILD LIMPO! ZERO ERROS!"
    echo "=========================================="
    echo ""
    echo "📊 STATUS COMPLETO:"
    echo "  ✅ Types + Entity + Repository"
    echo "  ✅ ApiKeyService (Business Logic)"
    echo "  ✅ Middleware apiKeyAuth"
    echo "  ✅ RateLimiterService"
    echo "  ✅ TypeScript Build: 0 erros"
    echo ""
    echo "🚀 PRÓXIMO PASSO:"
    echo "  bash scripts/sprint1/setup-api-key-controller.sh"
    echo ""
else
    echo "⚠️  AINDA HÁ $ERROR_COUNT ERROS:"
    grep "error TS" /tmp/build.log
fi
