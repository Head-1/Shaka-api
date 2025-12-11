#!/bin/bash

# ============================================================================
# SHAKA API - Sprint 1 - Parte 3/8
# Setup: API Key Authentication Middleware
# ============================================================================

set -e

PROJECT_ROOT=~/shaka-api
cd "$PROJECT_ROOT"

echo "=========================================="
echo "🚀 SPRINT 1 - DIA 1 - PARTE 3/8"
echo "🔐 Criando Middleware de Autenticação"
echo "=========================================="
echo ""

# ============================================================================
# 1. API Key Authentication Middleware
# ============================================================================

echo "[1/5] Criando apiKeyAuth middleware..."

cat > src/api/middlewares/apiKeyAuth.ts << 'EOF'
import { Request, Response, NextFunction } from 'express';
import { ApiKeyService } from '../../core/services/api-key/ApiKeyService';
import { RateLimiterService } from '../../core/services/rate-limiter/RateLimiterService';
import { logger } from '../../config/logger';

/**
 * Middleware para autenticação via API Key
 * Valida X-API-Key header e anexa user + apiKey ao request
 */
export const apiKeyAuth = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const apiKey = req.headers['x-api-key'] as string;

    // 1. Check if API key is provided
    if (!apiKey) {
      res.status(401).json({
        error: 'Authentication required',
        message: 'API key is required. Include X-API-Key header in your request.',
        docs: 'https://docs.shaka.com/authentication'
      });
      return;
    }

    // 2. Validate API key
    const validation = await ApiKeyService.validateKey(apiKey);

    if (!validation.isValid) {
      logger.warn('[apiKeyAuth] Invalid API key attempt', {
        reason: validation.reason,
        ip: req.ip,
        userAgent: req.get('user-agent')
      });

      res.status(403).json({
        error: 'Invalid API key',
        message: validation.reason || 'The provided API key is invalid or has been revoked.',
        docs: 'https://docs.shaka.com/authentication'
      });
      return;
    }

    // 3. Check rate limiting
    const rateLimitResult = await RateLimiterService.checkLimit(
      validation.apiKey!.id,
      validation.apiKey!.rateLimit
    );

    if (!rateLimitResult.allowed) {
      logger.warn('[apiKeyAuth] Rate limit exceeded', {
        apiKeyId: validation.apiKey!.id,
        userId: validation.user!.id,
        limit: rateLimitResult.limit
      });

      res.status(429).json({
        error: 'Rate limit exceeded',
        message: `You have exceeded your rate limit of ${rateLimitResult.limit} requests.`,
        limit: rateLimitResult.limit,
        remaining: 0,
        resetAt: rateLimitResult.resetAt,
        upgrade: 'https://shaka.com/pricing'
      });
      return;
    }

    // 4. Increment usage counter
    await RateLimiterService.incrementUsage(
      validation.apiKey!.id,
      validation.apiKey!.rateLimit
    );

    // 5. Set rate limit headers
    res.setHeader('X-RateLimit-Limit', rateLimitResult.limit.toString());
    res.setHeader('X-RateLimit-Remaining', rateLimitResult.remaining.toString());
    res.setHeader('X-RateLimit-Reset', rateLimitResult.resetAt.toISOString());

    // 6. Attach user and apiKey to request
    req.user = validation.user!;
    req.apiKey = validation.apiKey!;

    logger.info('[apiKeyAuth] API key authenticated', {
      userId: validation.user!.id,
      apiKeyId: validation.apiKey!.id,
      path: req.originalUrl
    });

    next();
  } catch (error: any) {
    logger.error('[apiKeyAuth] Error in middleware:', {
      error: error.message,
      stack: error.stack
    });

    res.status(500).json({
      error: 'Internal server error',
      message: 'An error occurred while authenticating your request.'
    });
  }
};

/**
 * Optional middleware - permite tanto JWT quanto API Key
 */
export const optionalApiKeyAuth = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  const apiKey = req.headers['x-api-key'] as string;

  if (!apiKey) {
    // Sem API key, continua sem autenticação
    next();
    return;
  }

  // Tem API key, valida
  await apiKeyAuth(req, res, next);
};
EOF

echo "✅ apiKeyAuth middleware criado"

# ============================================================================
# 2. Atualizar Express Request Type para incluir apiKey
# ============================================================================

echo "[2/5] Verificando/criando tipos Express Request..."

if [ ! -f "src/types/express.d.ts" ]; then
    mkdir -p src/types
    
    cat > src/types/express.d.ts << 'EOF'
import { User } from '../core/types/user.types';
import { ApiKey } from '../core/services/api-key/types';

declare global {
  namespace Express {
    interface Request {
      user?: User;
      apiKey?: ApiKey;
    }
  }
}

export {};
EOF

    echo "✅ Tipos Express criados (src/types/express.d.ts)"
else
    echo "✅ Express types já existem"
fi

# ============================================================================
# 3. Atualizar RateLimiterService para suportar API Keys
# ============================================================================

echo "[3/5] Atualizando RateLimiterService..."

# Backup se existir
if [ -f "src/core/services/rate-limiter/RateLimiterService.ts" ]; then
    cp src/core/services/rate-limiter/RateLimiterService.ts \
       src/core/services/rate-limiter/RateLimiterService.ts.bak 2>/dev/null || true
fi

cat > src/core/services/rate-limiter/RateLimiterService.ts << 'EOF'
import { logger } from '../../../config/logger';

export interface RateLimitConfig {
  requestsPerDay: number;
  requestsPerMinute: number;
  concurrentRequests: number;
}

export interface RateLimitResult {
  allowed: boolean;
  remaining: number;
  limit: number;
  resetAt: Date;
}

/**
 * Rate Limiter Service
 * Implementa rate limiting usando contadores em memória
 * TODO: Migrar para Redis em produção para clustering
 */
export class RateLimiterService {
  private static usageCounters: Map<string, { count: number; resetAt: Date }> = new Map();

  /**
   * Check if request is allowed based on rate limits
   */
  static async checkLimit(
    identifier: string,
    limits: RateLimitConfig
  ): Promise<RateLimitResult> {
    const now = new Date();
    const usage = this.usageCounters.get(identifier);

    // No usage yet, allow
    if (!usage) {
      return {
        allowed: true,
        remaining: limits.requestsPerDay - 1,
        limit: limits.requestsPerDay,
        resetAt: this.getResetTime()
      };
    }

    // Check if reset time passed
    if (now >= usage.resetAt) {
      // Reset counter
      this.usageCounters.delete(identifier);
      return {
        allowed: true,
        remaining: limits.requestsPerDay - 1,
        limit: limits.requestsPerDay,
        resetAt: this.getResetTime()
      };
    }

    // Check if limit exceeded
    if (usage.count >= limits.requestsPerDay) {
      logger.warn('[RateLimiterService] Rate limit exceeded', {
        identifier,
        count: usage.count,
        limit: limits.requestsPerDay
      });

      return {
        allowed: false,
        remaining: 0,
        limit: limits.requestsPerDay,
        resetAt: usage.resetAt
      };
    }

    // Within limits
    return {
      allowed: true,
      remaining: limits.requestsPerDay - usage.count - 1,
      limit: limits.requestsPerDay,
      resetAt: usage.resetAt
    };
  }

  /**
   * Increment usage counter
   */
  static async incrementUsage(
    identifier: string,
    limits: RateLimitConfig
  ): Promise<void> {
    const usage = this.usageCounters.get(identifier);

    if (!usage) {
      this.usageCounters.set(identifier, {
        count: 1,
        resetAt: this.getResetTime()
      });
    } else {
      usage.count++;
    }
  }

  /**
   * Get reset time (midnight UTC)
   */
  private static getResetTime(): Date {
    const tomorrow = new Date();
    tomorrow.setUTCHours(24, 0, 0, 0);
    return tomorrow;
  }

  /**
   * Reset counter for identifier (for testing)
   */
  static resetCounter(identifier: string): void {
    this.usageCounters.delete(identifier);
  }

  /**
   * Get current usage
   */
  static getUsage(identifier: string): number {
    return this.usageCounters.get(identifier)?.count || 0;
  }

  /**
   * Clear all counters (for testing)
   */
  static clearAll(): void {
    this.usageCounters.clear();
  }
}
EOF

echo "✅ RateLimiterService atualizado (com interfaces inline)"

# ============================================================================
# 4. Criar/atualizar rate-limiter index
# ============================================================================

echo "[4/5] Criando rate-limiter index..."

cat > src/core/services/rate-limiter/index.ts << 'EOF'
export { RateLimiterService, RateLimitConfig, RateLimitResult } from './RateLimiterService';
EOF

echo "✅ Index criado"

# ============================================================================
# 5. Rodar migration do ApiKey (se ainda não rodou)
# ============================================================================

echo "[5/5] Verificando migration..."

# Verificar se migration já foi executada
if kubectl exec -n shaka-staging deployment/postgres-staging -- \
   psql -U shakauser -d shakadb -c "\d api_keys" 2>/dev/null | grep -q "id"; then
    echo "✅ Tabela api_keys já existe"
else
    echo "⚠️  Tabela api_keys não existe - será criada no próximo deploy"
fi

echo ""
echo "=========================================="
echo "✅ PARTE 3/8 COMPLETA"
echo "=========================================="
echo ""
echo "Criados/Atualizados:"
echo "  ✅ apiKeyAuth middleware (autenticação completa)"
echo "  ✅ optionalApiKeyAuth middleware"
echo "  ✅ Express types (Request.apiKey)"
echo "  ✅ RateLimiterService (suporte a API keys)"
echo "  ✅ Rate limiter exports"
echo ""
echo "Próximo passo:"
echo "  bash scripts/sprint1/setup-api-key-controller.sh"
echo ""
echo "Testar build:"
echo "  npm run build 2>&1 | grep -c 'error TS'"
echo ""
