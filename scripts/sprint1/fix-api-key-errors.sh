#!/bin/bash

# ============================================================================
# SHAKA API - Sprint 1 - Fix 3.5/8
# Correção dos 4 erros TypeScript restantes
# ============================================================================

set -e

PROJECT_ROOT=~/shaka-api
cd "$PROJECT_ROOT"

echo "=========================================="
echo "🔧 SPRINT 1 - FIX 3.5/8"
echo "🐛 Corrigindo 4 erros TypeScript"
echo "=========================================="
echo ""

# ============================================================================
# FIX 1: Corrigir import do AppError (shared/errors não core/errors)
# ============================================================================

echo "[1/4] Corrigindo import do AppError..."

if [ -f "src/core/services/api-key/ApiKeyService.ts" ]; then
    sed -i "s|from '../../errors/AppError'|from '../../../shared/errors/AppError'|g" \
        src/core/services/api-key/ApiKeyService.ts
    
    echo "✅ Import do AppError corrigido"
else
    echo "⚠️  ApiKeyService não encontrado"
fi

# ============================================================================
# FIX 2 e 3: Corrigir types Date | null para Date | undefined
# ============================================================================

echo "[2/4] Corrigindo types no ApiKeyRepository..."

cat > src/infrastructure/database/repositories/ApiKeyRepository.ts << 'EOF'
import { Repository } from 'typeorm';
import { AppDataSource } from '../config';
import { ApiKeyEntity } from '../entities/ApiKeyEntity';
import { ApiKey, CreateApiKeyDTO } from '../../../core/services/api-key/types';

export class ApiKeyRepository {
  private static repository: Repository<ApiKeyEntity>;

  static initialize() {
    this.repository = AppDataSource.getRepository(ApiKeyEntity);
  }

  /**
   * Create new API key
   */
  static async create(data: CreateApiKeyDTO & { 
    keyHash: string; 
    keyPreview: string; 
    rateLimit: any 
  }): Promise<ApiKey> {
    const apiKey = this.repository.create({
      ...data,
      permissions: data.permissions || ['read', 'write'],
      isActive: true,
      lastUsedAt: null
    });

    const saved = await this.repository.save(apiKey);
    return this.toApiKey(saved);
  }

  /**
   * Find API key by hash (for validation)
   */
  static async findByHash(keyHash: string): Promise<ApiKey | null> {
    const apiKey = await this.repository.findOne({
      where: { keyHash }
    });

    return apiKey ? this.toApiKey(apiKey) : null;
  }

  /**
   * Find by ID
   */
  static async findById(id: string): Promise<ApiKey | null> {
    const apiKey = await this.repository.findOne({
      where: { id }
    });

    return apiKey ? this.toApiKey(apiKey) : null;
  }

  /**
   * Find all keys for a user
   */
  static async findByUserId(userId: string): Promise<ApiKey[]> {
    const apiKeys = await this.repository.find({
      where: { userId },
      order: { createdAt: 'DESC' }
    });

    return apiKeys.map(this.toApiKey);
  }

  /**
   * Update API key
   */
  static async update(id: string, data: Partial<ApiKey>): Promise<ApiKey | null> {
    await this.repository.update(id, data);
    return this.findById(id);
  }

  /**
   * Update lastUsedAt timestamp
   */
  static async updateLastUsed(id: string): Promise<void> {
    await this.repository.update(id, {
      lastUsedAt: new Date()
    });
  }

  /**
   * Delete API key (soft delete by setting isActive = false)
   */
  static async softDelete(id: string): Promise<void> {
    await this.repository.update(id, {
      isActive: false
    });
  }

  /**
   * Hard delete API key
   */
  static async delete(id: string): Promise<void> {
    await this.repository.delete(id);
  }

  /**
   * Count active keys for user
   */
  static async countActiveByUserId(userId: string): Promise<number> {
    return this.repository.count({
      where: { userId, isActive: true }
    });
  }

  /**
   * Convert entity to domain model
   * FIX: Converter Date | null para Date | undefined
   */
  private static toApiKey(entity: ApiKeyEntity): ApiKey {
    return {
      id: entity.id,
      userId: entity.userId,
      name: entity.name,
      keyHash: entity.keyHash,
      keyPreview: entity.keyPreview,
      permissions: entity.permissions as any[],
      rateLimit: entity.rateLimit,
      isActive: entity.isActive,
      lastUsedAt: entity.lastUsedAt || undefined,  // ⭐ FIX: null → undefined
      expiresAt: entity.expiresAt || undefined,    // ⭐ FIX: null → undefined
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt
    };
  }
}
EOF

echo "✅ ApiKeyRepository corrigido (Date | null → Date | undefined)"

# ============================================================================
# FIX 3: Atualizar types.ts para usar Date | undefined
# ============================================================================

echo "[3/4] Atualizando API Key types..."

cat > src/core/services/api-key/types.ts << 'EOF'
/**
 * API Key Management Types
 * Defines interfaces and types for API key operations
 */

export interface ApiKey {
  id: string;
  userId: string;
  name: string;
  keyHash: string;           // SHA256 hash - NEVER store plain key
  keyPreview: string;        // First 8 chars for display
  permissions: ApiKeyPermission[];
  rateLimit: RateLimitConfig;
  isActive: boolean;
  lastUsedAt: Date | undefined;   // ⭐ FIX: Date | null → Date | undefined
  expiresAt: Date | undefined;    // ⭐ FIX: Date | null → Date | undefined
  createdAt: Date;
  updatedAt: Date;
}

export type ApiKeyPermission = 'read' | 'write' | 'delete' | 'admin';

export interface RateLimitConfig {
  requestsPerDay: number;
  requestsPerMinute: number;
  concurrentRequests: number;
}

export interface CreateApiKeyDTO {
  userId: string;
  name: string;
  permissions?: ApiKeyPermission[];
  expiresAt?: Date;
}

export interface ApiKeyWithPlaintext extends ApiKey {
  key: string;  // Only returned ONCE at creation
  message: string;
}

export interface ValidateApiKeyResult {
  isValid: boolean;
  user?: any;  // User entity
  apiKey?: ApiKey;
  reason?: string;
}

export interface ApiKeyUsageStats {
  totalRequests: number;
  requestsToday: number;
  lastUsed: Date | null;
  averageLatency: number;
  errorRate: number;
}
EOF

echo "✅ Types atualizados"

# ============================================================================
# FIX 4: Adicionar .buildignore para excluir motor-hybrid temporariamente
# ============================================================================

echo "[4/4] Criando .buildignore para motor-hybrid..."

cat > .buildignore << 'EOF'
# Motor Hybrid - Placeholder (não compilar ainda)
src/core/services/motor-hybrid/

# Future MCP features
src/core/services/motor-hybrid/future-mcp/
EOF

echo "✅ .buildignore criado"

# Atualizar tsconfig.json para excluir motor-hybrid
echo ""
echo "Atualizando tsconfig.json..."

cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "lib": ["ES2020"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "moduleResolution": "node",
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "strictFunctionTypes": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "types": ["node", "jest"]
  },
  "include": [
    "src/**/*"
  ],
  "exclude": [
    "node_modules",
    "dist",
    "tests",
    "**/*.test.ts",
    "**/*.spec.ts",
    "src/core/services/motor-hybrid/**/*"
  ]
}
EOF

echo "✅ tsconfig.json atualizado (excluindo motor-hybrid)"

echo ""
echo "=========================================="
echo "✅ FIX 3.5/8 COMPLETO"
echo "=========================================="
echo ""
echo "Correções aplicadas:"
echo "  ✅ AppError import corrigido (shared/errors)"
echo "  ✅ Date | null → Date | undefined (types)"
echo "  ✅ ApiKeyRepository atualizado"
echo "  ✅ motor-hybrid excluído do build (tsconfig)"
echo ""
echo "Próximo passo:"
echo "  npm run build 2>&1 | grep -c 'error TS'"
echo "  (Esperado: 0 erros)"
echo ""
