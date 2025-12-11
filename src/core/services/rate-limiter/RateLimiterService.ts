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
