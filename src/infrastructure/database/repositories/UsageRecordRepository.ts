import { Repository, Between, MoreThan } from 'typeorm';
import { AppDataSource } from '../config';
import { UsageRecordEntity } from '../entities/UsageRecordEntity';
import { UsageRecord, DailyUsage, EndpointStats } from '../../../core/services/usage-tracking/types';

export class UsageRecordRepository {
  private static _repository: Repository<UsageRecordEntity> | null = null;

  static get repository(): Repository<UsageRecordEntity> {
    if (!this._repository) {
      if (!AppDataSource.isInitialized) {
        throw new Error('AppDataSource is not initialized. Call DatabaseService.initialize() first.');
      }
      this._repository = AppDataSource.getRepository(UsageRecordEntity);
    }
    return this._repository;
  }

  static initialize() {
    if (!AppDataSource.isInitialized) {
      throw new Error('AppDataSource must be initialized before UsageRecordRepository');
    }
    this._repository = AppDataSource.getRepository(UsageRecordEntity);
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
