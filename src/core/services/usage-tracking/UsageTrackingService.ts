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
        totalRequests: totalRequests || 0,
        requestsToday: requestsToday || 0,
        requestsThisWeek: requestsThisWeek || 0,
        requestsThisMonth: requestsThisMonth || 0,
        lastUsed: lastUsed || null,
        averageLatency: averageLatency ? Math.round(averageLatency) : 0,
        errorRate: errorRate ? Math.round(errorRate * 100) / 100 : 0,
        mostUsedEndpoints: mostUsedEndpoints || [],
        statusCodeDistribution: statusCodeDistribution || []
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
