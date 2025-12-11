#!/bin/bash

# ============================================================================
# SHAKA API - Sprint 1 - Parte 5/8
# Setup: Usage Tracking Service (métricas detalhadas)
# ============================================================================

set -e

PROJECT_ROOT=~/shaka-api
cd "$PROJECT_ROOT"

echo "=========================================="
echo "🚀 SPRINT 1 - DIA 1 - PARTE 5/8"
echo "📊 Usage Tracking Service"
echo "=========================================="
echo ""

# ============================================================================
# 1. Usage Tracking Types
# ============================================================================

echo "[1/6] Criando Usage Tracking types..."

mkdir -p src/core/services/usage-tracking

cat > src/core/services/usage-tracking/types.ts << 'EOF'
/**
 * Usage Tracking Types
 * Define interfaces para rastreamento de uso da API
 */

export interface UsageRecord {
  id: string;
  apiKeyId: string;
  userId: string;
  endpoint: string;
  method: string;
  statusCode: number;
  responseTime: number; // milliseconds
  timestamp: Date;
  ipAddress?: string;
  userAgent?: string;
  errorMessage?: string;
}

export interface UsageStats {
  totalRequests: number;
  requestsToday: number;
  requestsThisWeek: number;
  requestsThisMonth: number;
  lastUsed: Date | null;
  averageLatency: number;
  errorRate: number;
  mostUsedEndpoints: EndpointStats[];
  statusCodeDistribution: { [key: number]: number };
}

export interface EndpointStats {
  endpoint: string;
  method: string;
  count: number;
  averageLatency: number;
  errorCount: number;
}

export interface DailyUsage {
  date: string; // YYYY-MM-DD
  requests: number;
  errors: number;
  averageLatency: number;
}

export interface TrackUsageDTO {
  apiKeyId: string;
  userId: string;
  endpoint: string;
  method: string;
  statusCode: number;
  responseTime: number;
  ipAddress?: string;
  userAgent?: string;
  errorMessage?: string;
}
EOF

echo "✅ Types criados"

# ============================================================================
# 2. Usage Tracking Entity (TypeORM)
# ============================================================================

echo "[2/6] Criando UsageRecordEntity..."

cat > src/infrastructure/database/entities/UsageRecordEntity.ts << 'EOF'
import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  Index
} from 'typeorm';

@Entity('usage_records')
@Index(['apiKeyId', 'timestamp'])
@Index(['userId', 'timestamp'])
@Index(['timestamp'])
export class UsageRecordEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'uuid' })
  apiKeyId!: string;

  @Column({ type: 'uuid' })
  userId!: string;

  @Column({ type: 'varchar', length: 200 })
  endpoint!: string;

  @Column({ type: 'varchar', length: 10 })
  method!: string;

  @Column({ type: 'int' })
  statusCode!: number;

  @Column({ type: 'int' })
  responseTime!: number; // milliseconds

  @Column({ type: 'varchar', length: 45, nullable: true })
  ipAddress?: string;

  @Column({ type: 'text', nullable: true })
  userAgent?: string;

  @Column({ type: 'text', nullable: true })
  errorMessage?: string;

  @CreateDateColumn()
  timestamp!: Date;
}
EOF

echo "✅ Entity criado"

# ============================================================================
# 3. Usage Tracking Repository
# ============================================================================

echo "[3/6] Criando UsageRecordRepository..."

mkdir -p src/infrastructure/database/repositories

cat > src/infrastructure/database/repositories/UsageRecordRepository.ts << 'EOF'
import { Repository, Between, MoreThan } from 'typeorm';
import { AppDataSource } from '../config';
import { UsageRecordEntity } from '../entities/UsageRecordEntity';
import { UsageRecord, DailyUsage, EndpointStats } from '../../../core/services/usage-tracking/types';

export class UsageRecordRepository {
  private static repository: Repository<UsageRecordEntity>;

  static initialize() {
    this.repository = AppDataSource.getRepository(UsageRecordEntity);
  }

  /**
   * Create usage record
   */
  static async create(data: Partial<UsageRecord>): Promise<UsageRecord> {
    const record = this.repository.create(data);
    const saved = await this.repository.save(record);
    return this.toUsageRecord(saved);
  }

  /**
   * Get total requests count for API key
   */
  static async getTotalRequests(apiKeyId: string): Promise<number> {
    return this.repository.count({ where: { apiKeyId } });
  }

  /**
   * Get requests count for date range
   */
  static async getRequestsInRange(
    apiKeyId: string,
    startDate: Date,
    endDate: Date
  ): Promise<number> {
    return this.repository.count({
      where: {
        apiKeyId,
        timestamp: Between(startDate, endDate)
      }
    });
  }

  /**
   * Get average response time
   */
  static async getAverageLatency(apiKeyId: string): Promise<number> {
    const result = await this.repository
      .createQueryBuilder('usage')
      .select('AVG(usage.responseTime)', 'avg')
      .where('usage.apiKeyId = :apiKeyId', { apiKeyId })
      .getRawOne();

    return result?.avg ? parseFloat(result.avg) : 0;
  }

  /**
   * Get error rate (percentage)
   */
  static async getErrorRate(apiKeyId: string): Promise<number> {
    const total = await this.getTotalRequests(apiKeyId);
    
    if (total === 0) return 0;

    const errors = await this.repository.count({
      where: {
        apiKeyId,
        statusCode: MoreThan(399)
      }
    });

    return (errors / total) * 100;
  }

  /**
   * Get most used endpoints
   */
  static async getMostUsedEndpoints(
    apiKeyId: string,
    limit: number = 10
  ): Promise<EndpointStats[]> {
    const results = await this.repository
      .createQueryBuilder('usage')
      .select('usage.endpoint', 'endpoint')
      .addSelect('usage.method', 'method')
      .addSelect('COUNT(*)', 'count')
      .addSelect('AVG(usage.responseTime)', 'averageLatency')
      .addSelect(
        'SUM(CASE WHEN usage.statusCode >= 400 THEN 1 ELSE 0 END)',
        'errorCount'
      )
      .where('usage.apiKeyId = :apiKeyId', { apiKeyId })
      .groupBy('usage.endpoint')
      .addGroupBy('usage.method')
      .orderBy('count', 'DESC')
      .limit(limit)
      .getRawMany();

    return results.map((r) => ({
      endpoint: r.endpoint,
      method: r.method,
      count: parseInt(r.count),
      averageLatency: parseFloat(r.averageLatency || 0),
      errorCount: parseInt(r.errorCount || 0)
    }));
  }

  /**
   * Get status code distribution
   */
  static async getStatusCodeDistribution(
    apiKeyId: string
  ): Promise<{ [key: number]: number }> {
    const results = await this.repository
      .createQueryBuilder('usage')
      .select('usage.statusCode', 'statusCode')
      .addSelect('COUNT(*)', 'count')
      .where('usage.apiKeyId = :apiKeyId', { apiKeyId })
      .groupBy('usage.statusCode')
      .getRawMany();

    const distribution: { [key: number]: number } = {};
    results.forEach((r) => {
      distribution[r.statusCode] = parseInt(r.count);
    });

    return distribution;
  }

  /**
   * Get daily usage for last N days
   */
  static async getDailyUsage(
    apiKeyId: string,
    days: number = 30
  ): Promise<DailyUsage[]> {
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);

    const results = await this.repository
      .createQueryBuilder('usage')
      .select("DATE(usage.timestamp)", 'date')
      .addSelect('COUNT(*)', 'requests')
      .addSelect(
        'SUM(CASE WHEN usage.statusCode >= 400 THEN 1 ELSE 0 END)',
        'errors'
      )
      .addSelect('AVG(usage.responseTime)', 'averageLatency')
      .where('usage.apiKeyId = :apiKeyId', { apiKeyId })
      .andWhere('usage.timestamp >= :startDate', { startDate })
      .groupBy('date')
      .orderBy('date', 'ASC')
      .getRawMany();

    return results.map((r) => ({
      date: r.date,
      requests: parseInt(r.requests),
      errors: parseInt(r.errors || 0),
      averageLatency: parseFloat(r.averageLatency || 0)
    }));
  }

  /**
   * Get last used timestamp
   */
  static async getLastUsed(apiKeyId: string): Promise<Date | null> {
    const record = await this.repository.findOne({
      where: { apiKeyId },
      order: { timestamp: 'DESC' }
    });

    return record?.timestamp || null;
  }

  /**
   * Delete old records (cleanup)
   */
  static async deleteOlderThan(days: number): Promise<number> {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - days);

    const result = await this.repository
      .createQueryBuilder()
      .delete()
      .where('timestamp < :cutoffDate', { cutoffDate })
      .execute();

    return result.affected || 0;
  }

  /**
   * Convert entity to domain model
   */
  private static toUsageRecord(entity: UsageRecordEntity): UsageRecord {
    return {
      id: entity.id,
      apiKeyId: entity.apiKeyId,
      userId: entity.userId,
      endpoint: entity.endpoint,
      method: entity.method,
      statusCode: entity.statusCode,
      responseTime: entity.responseTime,
      timestamp: entity.timestamp,
      ipAddress: entity.ipAddress,
      userAgent: entity.userAgent,
      errorMessage: entity.errorMessage
    };
  }
}
EOF

echo "✅ Repository criado"

# ============================================================================
# 4. Usage Tracking Service
# ============================================================================

echo "[4/6] Criando UsageTrackingService..."

cat > src/core/services/usage-tracking/UsageTrackingService.ts << 'EOF'
import { UsageRecordRepository } from '../../../infrastructure/database/repositories/UsageRecordRepository';
import { ApiKeyRepository } from '../../../infrastructure/database/repositories/ApiKeyRepository';
import { logger } from '../../../config/logger';
import {
  TrackUsageDTO,
  UsageStats,
  UsageRecord,
  DailyUsage
} from './types';

export class UsageTrackingService {
  /**
   * Track API usage (called from middleware)
   */
  static async trackUsage(data: TrackUsageDTO): Promise<void> {
    try {
      await UsageRecordRepository.create(data);
      
      // Update API key lastUsedAt (fire and forget)
      ApiKeyRepository.updateLastUsed(data.apiKeyId).catch((err) => {
        logger.error('[UsageTrackingService] Error updating lastUsedAt:', err);
      });
    } catch (error: any) {
      logger.error('[UsageTrackingService] Error tracking usage:', {
        error: error.message,
        data
      });
      // Don't throw - tracking failures shouldn't block requests
    }
  }

  /**
   * Get comprehensive usage statistics
   */
  static async getStats(apiKeyId: string): Promise<UsageStats> {
    try {
      const now = new Date();
      const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
      const thisWeek = new Date(now);
      thisWeek.setDate(thisWeek.getDate() - 7);
      const thisMonth = new Date(now);
      thisMonth.setDate(thisMonth.getDate() - 30);

      const [
        totalRequests,
        requestsToday,
        requestsThisWeek,
        requestsThisMonth,
        lastUsed,
        averageLatency,
        errorRate,
        mostUsedEndpoints,
        statusCodeDistribution
      ] = await Promise.all([
        UsageRecordRepository.getTotalRequests(apiKeyId),
        UsageRecordRepository.getRequestsInRange(apiKeyId, today, now),
        UsageRecordRepository.getRequestsInRange(apiKeyId, thisWeek, now),
        UsageRecordRepository.getRequestsInRange(apiKeyId, thisMonth, now),
        UsageRecordRepository.getLastUsed(apiKeyId),
        UsageRecordRepository.getAverageLatency(apiKeyId),
        UsageRecordRepository.getErrorRate(apiKeyId),
        UsageRecordRepository.getMostUsedEndpoints(apiKeyId, 10),
        UsageRecordRepository.getStatusCodeDistribution(apiKeyId)
      ]);

      return {
        totalRequests,
        requestsToday,
        requestsThisWeek,
        requestsThisMonth,
        lastUsed,
        averageLatency: Math.round(averageLatency),
        errorRate: Math.round(errorRate * 100) / 100,
        mostUsedEndpoints,
        statusCodeDistribution
      };
    } catch (error: any) {
      logger.error('[UsageTrackingService] Error getting stats:', {
        error: error.message,
        apiKeyId
      });
      throw error;
    }
  }

  /**
   * Get daily usage chart data
   */
  static async getDailyUsage(
    apiKeyId: string,
    days: number = 30
  ): Promise<DailyUsage[]> {
    try {
      return await UsageRecordRepository.getDailyUsage(apiKeyId, days);
    } catch (error: any) {
      logger.error('[UsageTrackingService] Error getting daily usage:', {
        error: error.message,
        apiKeyId
      });
      throw error;
    }
  }

  /**
   * Cleanup old records (run as cron job)
   */
  static async cleanupOldRecords(retentionDays: number = 90): Promise<number> {
    try {
      logger.info('[UsageTrackingService] Cleaning up old records', {
        retentionDays
      });

      const deleted = await UsageRecordRepository.deleteOlderThan(retentionDays);

      logger.info('[UsageTrackingService] Cleanup completed', {
        deletedRecords: deleted
      });

      return deleted;
    } catch (error: any) {
      logger.error('[UsageTrackingService] Error cleaning up records:', {
        error: error.message
      });
      throw error;
    }
  }
}
EOF

echo "✅ Service criado"

# ============================================================================
# 5. Atualizar ApiKeyService para usar UsageTrackingService
# ============================================================================

echo "[5/6] Atualizando ApiKeyService.getUsageStats()..."

# Substituir placeholder no ApiKeyService
sed -i '/\/\/ Placeholder - will implement with UsageTrackingService/,/}/c\
    const apiKey = await this.getKey(userId, keyId);\
    const stats = await UsageTrackingService.getStats(apiKey.id);\
    return {\
      totalRequests: stats.totalRequests,\
      requestsToday: stats.requestsToday,\
      lastUsed: stats.lastUsed,\
      averageLatency: stats.averageLatency,\
      errorRate: stats.errorRate\
    };' src/core/services/api-key/ApiKeyService.ts

# Adicionar import
sed -i "1i import { UsageTrackingService } from '../usage-tracking/UsageTrackingService';" \
    src/core/services/api-key/ApiKeyService.ts

echo "✅ ApiKeyService atualizado"

# ============================================================================
# 6. Atualizar DatabaseService para inicializar UsageRecordRepository
# ============================================================================

echo "[6/6] Atualizando DatabaseService..."

# Adicionar import
if ! grep -q "UsageRecordRepository" src/infrastructure/database/DatabaseService.ts; then
    sed -i '/import { ApiKeyRepository }/a import { UsageRecordRepository } from '"'"'./repositories/UsageRecordRepository'"'"';' \
        src/infrastructure/database/DatabaseService.ts
    
    # Adicionar inicialização
    sed -i '/ApiKeyRepository.initialize();/a \      UsageRecordRepository.initialize();  // ⭐ NOVO' \
        src/infrastructure/database/DatabaseService.ts
fi

echo "✅ DatabaseService atualizado"

# Criar index exports
cat > src/core/services/usage-tracking/index.ts << 'EOF'
export * from './types';
export { UsageTrackingService } from './UsageTrackingService';
EOF

echo ""
echo "=========================================="
echo "🧪 TESTANDO BUILD..."
echo "=========================================="
echo ""

npm run build > /tmp/build.log 2>&1

ERROR_COUNT=$(grep -c "error TS" /tmp/build.log || echo "0")

if [ "$ERROR_COUNT" -eq "0" ]; then
    echo "=========================================="
    echo "✅ PARTE 5/8 COMPLETA - BUILD LIMPO!"
    echo "=========================================="
    echo ""
    echo "Criados:"
    echo "  ✅ UsageTrackingService (track, getStats, getDailyUsage)"
    echo "  ✅ UsageRecordEntity (TypeORM)"
    echo "  ✅ UsageRecordRepository (analytics queries)"
    echo "  ✅ Types completos"
    echo "  ✅ ApiKeyService integrado"
    echo ""
    echo "Features:"
    echo "  📊 Total requests tracking"
    echo "  📈 Daily/weekly/monthly stats"
    echo "  ⚡ Average latency"
    echo "  🚨 Error rate calculation"
    echo "  🎯 Endpoint usage distribution"
    echo "  📊 Status code distribution"
    echo "  🧹 Automatic cleanup (90 days retention)"
    echo ""
    echo "🚀 PRÓXIMO PASSO:"
    echo "  bash scripts/sprint1/setup-migration-and-test.sh"
    echo ""
else
    echo "⚠️  BUILD COM $ERROR_COUNT ERROS:"
    grep "error TS" /tmp/build.log | head -10
fi
