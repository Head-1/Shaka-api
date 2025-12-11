#!/bin/bash

# ============================================================================
# SHAKA API - Sprint 1 - Parte 6/8
# Setup: Migrations + Tracking Middleware
# ============================================================================

set -e

PROJECT_ROOT=~/shaka-api
cd "$PROJECT_ROOT"

echo "=========================================="
echo "🚀 SPRINT 1 - DIA 1 - PARTE 6/8"
echo "📦 Migrations + Tracking Middleware"
echo "=========================================="
echo ""

# ============================================================================
# 1. Migration para UsageRecords table
# ============================================================================

echo "[1/4] Criando Migration para usage_records..."

TIMESTAMP=$(date +%s)
MIGRATION_NAME="CreateUsageRecordsTable"

mkdir -p src/infrastructure/database/migrations

cat > "src/infrastructure/database/migrations/${TIMESTAMP}-${MIGRATION_NAME}.ts" << 'EOF'
import { MigrationInterface, QueryRunner, Table, TableIndex } from 'typeorm';

export class CreateUsageRecordsTable1234567890124 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    // Create usage_records table
    await queryRunner.createTable(
      new Table({
        name: 'usage_records',
        columns: [
          {
            name: 'id',
            type: 'uuid',
            isPrimary: true,
            default: 'uuid_generate_v4()'
          },
          {
            name: 'apiKeyId',
            type: 'uuid',
            isNullable: false
          },
          {
            name: 'userId',
            type: 'uuid',
            isNullable: false
          },
          {
            name: 'endpoint',
            type: 'varchar',
            length: '200',
            isNullable: false
          },
          {
            name: 'method',
            type: 'varchar',
            length: '10',
            isNullable: false
          },
          {
            name: 'statusCode',
            type: 'int',
            isNullable: false
          },
          {
            name: 'responseTime',
            type: 'int',
            isNullable: false
          },
          {
            name: 'ipAddress',
            type: 'varchar',
            length: '45',
            isNullable: true
          },
          {
            name: 'userAgent',
            type: 'text',
            isNullable: true
          },
          {
            name: 'errorMessage',
            type: 'text',
            isNullable: true
          },
          {
            name: 'timestamp',
            type: 'timestamp',
            default: 'CURRENT_TIMESTAMP'
          }
        ]
      }),
      true
    );

    // Create composite index for apiKeyId + timestamp (most common query)
    await queryRunner.createIndex(
      'usage_records',
      new TableIndex({
        name: 'IDX_usage_records_apiKeyId_timestamp',
        columnNames: ['apiKeyId', 'timestamp']
      })
    );

    // Create composite index for userId + timestamp
    await queryRunner.createIndex(
      'usage_records',
      new TableIndex({
        name: 'IDX_usage_records_userId_timestamp',
        columnNames: ['userId', 'timestamp']
      })
    );

    // Create index for timestamp only (for cleanup queries)
    await queryRunner.createIndex(
      'usage_records',
      new TableIndex({
        name: 'IDX_usage_records_timestamp',
        columnNames: ['timestamp']
      })
    );

    // Create index for endpoint analysis
    await queryRunner.createIndex(
      'usage_records',
      new TableIndex({
        name: 'IDX_usage_records_endpoint',
        columnNames: ['endpoint', 'method']
      })
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.dropTable('usage_records');
  }
}
EOF

echo "✅ Migration criada"

# ============================================================================
# 2. Middleware para tracking automático
# ============================================================================

echo "[2/4] Criando trackUsage middleware..."

cat > src/api/middlewares/trackUsage.ts << 'EOF'
import { Request, Response, NextFunction } from 'express';
import { UsageTrackingService } from '../../core/services/usage-tracking/UsageTrackingService';
import { logger } from '../../config/logger';

/**
 * Middleware para rastrear uso da API automaticamente
 * Deve ser usado DEPOIS do apiKeyAuth middleware
 */
export const trackUsage = (
  req: Request,
  res: Response,
  next: NextFunction
): void => {
  // Capturar timestamp de início
  const startTime = Date.now();

  // Interceptar res.send() para capturar statusCode e responseTime
  const originalSend = res.send;
  
  res.send = function (data: any): Response {
    // Calcular tempo de resposta
    const responseTime = Date.now() - startTime;
    
    // Verificar se tem API key (tracking só funciona com API key auth)
    if (req.apiKey && req.user) {
      // Track usage (fire and forget - não bloqueia response)
      UsageTrackingService.trackUsage({
        apiKeyId: req.apiKey.id,
        userId: req.user.id,
        endpoint: req.originalUrl || req.url,
        method: req.method,
        statusCode: res.statusCode,
        responseTime,
        ipAddress: req.ip || req.socket.remoteAddress,
        userAgent: req.get('user-agent'),
        errorMessage: res.statusCode >= 400 ? (data?.error || data?.message) : undefined
      }).catch((error) => {
        logger.error('[trackUsage] Error tracking usage:', {
          error: error.message,
          apiKeyId: req.apiKey?.id
        });
      });
    }
    
    // Chamar método original
    return originalSend.call(this, data);
  };

  next();
};

/**
 * Middleware simplificado para rotas públicas
 * Apenas loga requests sem salvar no banco
 */
export const logRequest = (
  req: Request,
  _res: Response,
  next: NextFunction
): void => {
  logger.info('[Request]', {
    method: req.method,
    url: req.originalUrl,
    ip: req.ip,
    userAgent: req.get('user-agent')
  });

  next();
};
EOF

echo "✅ Middleware criado"

# ============================================================================
# 3. Atualizar API Key routes para incluir tracking
# ============================================================================

echo "[3/4] Atualizando api-keys.routes.ts com tracking..."

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

// Todas as rotas de API keys requerem autenticação JWT
// e incluem tracking automático

/**
 * @route POST /api/v1/keys
 * @desc Create new API key
 * @access Private (JWT)
 */
router.post(
  '/',
  authenticate,
  validateRequest(createApiKeySchema),
  trackUsage,
  ApiKeyController.create
);

/**
 * @route GET /api/v1/keys
 * @desc List all API keys for authenticated user
 * @access Private (JWT)
 */
router.get(
  '/',
  authenticate,
  trackUsage,
  ApiKeyController.list
);

/**
 * @route GET /api/v1/keys/:id
 * @desc Get single API key details
 * @access Private (JWT)
 */
router.get(
  '/:id',
  authenticate,
  validateRequest(apiKeyIdSchema, 'params'),
  trackUsage,
  ApiKeyController.getOne
);

/**
 * @route GET /api/v1/keys/:id/usage
 * @desc Get usage statistics for API key
 * @access Private (JWT)
 */
router.get(
  '/:id/usage',
  authenticate,
  validateRequest(apiKeyIdSchema, 'params'),
  trackUsage,
  ApiKeyController.getUsage
);

/**
 * @route POST /api/v1/keys/:id/rotate
 * @desc Rotate API key (revoke old, create new)
 * @access Private (JWT)
 */
router.post(
  '/:id/rotate',
  authenticate,
  validateRequest(apiKeyIdSchema, 'params'),
  trackUsage,
  ApiKeyController.rotate
);

/**
 * @route DELETE /api/v1/keys/:id
 * @desc Revoke API key (soft delete)
 * @access Private (JWT)
 */
router.delete(
  '/:id',
  authenticate,
  validateRequest(apiKeyIdSchema, 'params'),
  trackUsage,
  ApiKeyController.revoke
);

/**
 * @route DELETE /api/v1/keys/:id/permanent
 * @desc Permanently delete API key
 * @access Private (JWT)
 */
router.delete(
  '/:id/permanent',
  authenticate,
  validateRequest(apiKeyIdSchema, 'params'),
  trackUsage,
  ApiKeyController.deletePermanent
);

export default router;
EOF

echo "✅ Routes atualizadas com tracking"

# ============================================================================
# 4. Criar script de apply migrations
# ============================================================================

echo "[4/4] Criando script para aplicar migrations..."

mkdir -p scripts/database

cat > scripts/database/apply-migrations.sh << 'EOF'
#!/bin/bash

# ============================================================================
# Apply Database Migrations
# ============================================================================

set -e

NAMESPACE="${1:-shaka-staging}"
POD="${2:-postgres-staging-0}"

echo "=========================================="
echo "🗄️  APPLYING MIGRATIONS"
echo "=========================================="
echo ""
echo "Namespace: $NAMESPACE"
echo "Pod: $POD"
echo ""

# 1. API Keys table
echo "[1/2] Creating api_keys table..."

kubectl exec -n "$NAMESPACE" "$POD" -- psql -U shakauser -d shakadb << 'EOSQL'
-- Create api_keys table if not exists
CREATE TABLE IF NOT EXISTS api_keys (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  "userId" UUID NOT NULL,
  name VARCHAR(100) NOT NULL,
  "keyHash" VARCHAR(64) NOT NULL UNIQUE,
  "keyPreview" VARCHAR(16) NOT NULL,
  permissions TEXT NOT NULL DEFAULT 'read,write',
  "rateLimit" JSONB NOT NULL,
  "isActive" BOOLEAN DEFAULT true,
  "lastUsedAt" TIMESTAMP NULL,
  "expiresAt" TIMESTAMP NULL,
  "createdAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX IF NOT EXISTS "IDX_api_keys_userId" ON api_keys("userId");
CREATE UNIQUE INDEX IF NOT EXISTS "IDX_api_keys_keyHash" ON api_keys("keyHash");

-- Add foreign key
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'FK_api_keys_userId'
  ) THEN
    ALTER TABLE api_keys
    ADD CONSTRAINT "FK_api_keys_userId"
    FOREIGN KEY ("userId") REFERENCES users(id) ON DELETE CASCADE;
  END IF;
END $$;

SELECT 'api_keys table ready' AS status;
EOSQL

echo "✅ api_keys table created"

# 2. Usage Records table
echo "[2/2] Creating usage_records table..."

kubectl exec -n "$NAMESPACE" "$POD" -- psql -U shakauser -d shakadb << 'EOSQL'
-- Create usage_records table if not exists
CREATE TABLE IF NOT EXISTS usage_records (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  "apiKeyId" UUID NOT NULL,
  "userId" UUID NOT NULL,
  endpoint VARCHAR(200) NOT NULL,
  method VARCHAR(10) NOT NULL,
  "statusCode" INT NOT NULL,
  "responseTime" INT NOT NULL,
  "ipAddress" VARCHAR(45) NULL,
  "userAgent" TEXT NULL,
  "errorMessage" TEXT NULL,
  timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS "IDX_usage_records_apiKeyId_timestamp" 
  ON usage_records("apiKeyId", timestamp);

CREATE INDEX IF NOT EXISTS "IDX_usage_records_userId_timestamp" 
  ON usage_records("userId", timestamp);

CREATE INDEX IF NOT EXISTS "IDX_usage_records_timestamp" 
  ON usage_records(timestamp);

CREATE INDEX IF NOT EXISTS "IDX_usage_records_endpoint" 
  ON usage_records(endpoint, method);

SELECT 'usage_records table ready' AS status;
EOSQL

echo "✅ usage_records table created"

echo ""
echo "=========================================="
echo "✅ MIGRATIONS APPLIED SUCCESSFULLY"
echo "=========================================="
echo ""
echo "Verify tables:"
echo "  kubectl exec -n $NAMESPACE $POD -- psql -U shakauser -d shakadb -c '\\dt'"
echo ""
EOF

chmod +x scripts/database/apply-migrations.sh

echo "✅ Migration script criado"

echo ""
echo "=========================================="
echo "🧪 TESTANDO BUILD..."
echo "=========================================="
echo ""

npm run build > /tmp/build.log 2>&1

ERROR_COUNT=$(grep -c "error TS" /tmp/build.log || echo "0")

if [ "$ERROR_COUNT" -eq "0" ]; then
    echo "=========================================="
    echo "✅ PARTE 6/8 COMPLETA - BUILD LIMPO!"
    echo "=========================================="
    echo ""
    echo "Criados:"
    echo "  ✅ Migration: CreateUsageRecordsTable"
    echo "  ✅ Middleware: trackUsage (automático)"
    echo "  ✅ Middleware: logRequest (público)"
    echo "  ✅ Routes atualizadas com tracking"
    echo "  ✅ Script: apply-migrations.sh"
    echo ""
    echo "🚀 PRÓXIMOS PASSOS:"
    echo ""
    echo "1. Aplicar migrations no banco:"
    echo "   bash scripts/database/apply-migrations.sh shaka-staging"
    echo ""
    echo "2. Build Docker image atualizada:"
    echo "   bash scripts/sprint1/build-and-deploy.sh"
    echo ""
    echo "3. Testar endpoints API Keys:"
    echo "   bash scripts/sprint1/test-api-keys.sh"
    echo ""
else
    echo "⚠️  BUILD COM $ERROR_COUNT ERROS:"
    grep "error TS" /tmp/build.log | head -10
fi
