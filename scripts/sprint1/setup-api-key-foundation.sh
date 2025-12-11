#!/bin/bash

# ============================================================================
# SHAKA API - Sprint 1 - Parte 1/8
# Setup: Types, Entity, Repository para API Keys
# ============================================================================

set -e

PROJECT_ROOT=~/shaka-api
cd "$PROJECT_ROOT"

echo "=========================================="
echo "🚀 SPRINT 1 - DIA 1 - PARTE 1/8"
echo "📦 Criando Types, Entity e Repository"
echo "=========================================="
echo ""

# ============================================================================
# 1. API Key Types
# ============================================================================

echo "[1/4] Criando API Key Types..."

mkdir -p src/core/services/api-key

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
  lastUsedAt: Date | null;
  expiresAt: Date | null;
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

echo "✅ Types criados"

# ============================================================================
# 2. API Key Entity (TypeORM)
# ============================================================================

echo "[2/4] Criando API Key Entity..."

mkdir -p src/infrastructure/database/entities

cat > src/infrastructure/database/entities/ApiKeyEntity.ts << 'EOF'
import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
  Index
} from 'typeorm';
import { UserEntity } from './UserEntity';

@Entity('api_keys')
@Index(['keyHash'], { unique: true })
@Index(['userId'])
export class ApiKeyEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'uuid' })
  userId!: string;

  @Column({ type: 'varchar', length: 100 })
  name!: string;

  @Column({ type: 'varchar', length: 64 })
  keyHash!: string;  // SHA256 = 64 chars hex

  @Column({ type: 'varchar', length: 16 })
  keyPreview!: string;  // First 12 chars for display (e.g., "sk_live_abcd...")

  @Column({ type: 'simple-array', default: 'read,write' })
  permissions!: string[];

  @Column({ type: 'jsonb' })
  rateLimit!: {
    requestsPerDay: number;
    requestsPerMinute: number;
    concurrentRequests: number;
  };

  @Column({ type: 'boolean', default: true })
  isActive!: boolean;

  @Column({ type: 'timestamp', nullable: true })
  lastUsedAt!: Date | null;

  @Column({ type: 'timestamp', nullable: true })
  expiresAt!: Date | null;

  @CreateDateColumn()
  createdAt!: Date;

  @UpdateDateColumn()
  updatedAt!: Date;

  // Relations
  @ManyToOne(() => UserEntity, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'userId' })
  user!: UserEntity;
}
EOF

echo "✅ Entity criada"

# ============================================================================
# 3. API Key Repository
# ============================================================================

echo "[3/4] Criando API Key Repository..."

mkdir -p src/infrastructure/database/repositories

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
      lastUsedAt: entity.lastUsedAt,
      expiresAt: entity.expiresAt,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt
    };
  }
}
EOF

echo "✅ Repository criado"

# ============================================================================
# 4. Migration para API Keys table
# ============================================================================

echo "[4/4] Criando Migration..."

TIMESTAMP=$(date +%s)
MIGRATION_NAME="CreateApiKeysTable"

mkdir -p src/infrastructure/database/migrations

cat > "src/infrastructure/database/migrations/${TIMESTAMP}-${MIGRATION_NAME}.ts" << 'EOF'
import { MigrationInterface, QueryRunner, Table, TableForeignKey, TableIndex } from 'typeorm';

export class CreateApiKeysTable1234567890123 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    // Create api_keys table
    await queryRunner.createTable(
      new Table({
        name: 'api_keys',
        columns: [
          {
            name: 'id',
            type: 'uuid',
            isPrimary: true,
            default: 'uuid_generate_v4()'
          },
          {
            name: 'userId',
            type: 'uuid',
            isNullable: false
          },
          {
            name: 'name',
            type: 'varchar',
            length: '100',
            isNullable: false
          },
          {
            name: 'keyHash',
            type: 'varchar',
            length: '64',
            isNullable: false,
            isUnique: true
          },
          {
            name: 'keyPreview',
            type: 'varchar',
            length: '16',
            isNullable: false
          },
          {
            name: 'permissions',
            type: 'text',
            isNullable: false,
            default: "'read,write'"
          },
          {
            name: 'rateLimit',
            type: 'jsonb',
            isNullable: false
          },
          {
            name: 'isActive',
            type: 'boolean',
            default: true
          },
          {
            name: 'lastUsedAt',
            type: 'timestamp',
            isNullable: true
          },
          {
            name: 'expiresAt',
            type: 'timestamp',
            isNullable: true
          },
          {
            name: 'createdAt',
            type: 'timestamp',
            default: 'CURRENT_TIMESTAMP'
          },
          {
            name: 'updatedAt',
            type: 'timestamp',
            default: 'CURRENT_TIMESTAMP'
          }
        ]
      }),
      true
    );

    // Create foreign key to users table
    await queryRunner.createForeignKey(
      'api_keys',
      new TableForeignKey({
        columnNames: ['userId'],
        referencedColumnNames: ['id'],
        referencedTableName: 'users',
        onDelete: 'CASCADE'
      })
    );

    // Create indexes
    await queryRunner.createIndex(
      'api_keys',
      new TableIndex({
        name: 'IDX_api_keys_userId',
        columnNames: ['userId']
      })
    );

    await queryRunner.createIndex(
      'api_keys',
      new TableIndex({
        name: 'IDX_api_keys_keyHash',
        columnNames: ['keyHash'],
        isUnique: true
      })
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.dropTable('api_keys');
  }
}
EOF

echo "✅ Migration criada"

# ============================================================================
# 5. Atualizar index exports
# ============================================================================

echo ""
echo "Criando index exports..."

cat > src/core/services/api-key/index.ts << 'EOF'
export * from './types';
export { ApiKeyService } from './ApiKeyService';
EOF

echo ""
echo "=========================================="
echo "✅ PARTE 1/8 COMPLETA"
echo "=========================================="
echo ""
echo "Criados:"
echo "  ✅ Types (api-key/types.ts)"
echo "  ✅ Entity (ApiKeyEntity.ts)"
echo "  ✅ Repository (ApiKeyRepository.ts)"
echo "  ✅ Migration (CreateApiKeysTable)"
echo ""
echo "Próximo passo:"
echo "  bash scripts/sprint1/setup-api-key-service.sh"
echo ""

