import { RedisConfig } from './redis.config';
import { RateLimitInfo, RateLimitExceeded } from '../../core/types/rate-limiter.types';
import { PLAN_LIMITS } from '../../core/types/subscription.types';
import { logger } from '../../config/logger';

export class RedisRateLimiterService {
  private static readonly KEY_PREFIX = 'ratelimit';

  static async checkLimit(
    userId: string,
    plan: 'starter' | 'pro' | 'business'
  ): Promise<RateLimitInfo> {
    const client = RedisConfig.getClient();
    const limits = PLAN_LIMITS[plan];
    const key = `${this.KEY_PREFIX}:${userId}:daily`;
    
    try {
      const current = await client.get(key);
      const count = current ? parseInt(current) : 0;
      const ttl = await client.ttl(key);

      const resetAt = new Date();
      if (ttl > 0) {
        resetAt.setSeconds(resetAt.getSeconds() + ttl);
      } else {
        resetAt.setHours(24, 0, 0, 0);
      }

      const remaining = Math.max(0, limits.requestsPerDay - count);

      return {
        limit: limits.requestsPerDay,
        remaining,
        reset: resetAt,
        retryAfter: remaining === 0 ? ttl : undefined
      };
    } catch (error) {
      logger.error(`Rate limit check error for user ${userId}:`, error);
      throw error;
    }
  }

  static async incrementUsage(
    userId: string,
    plan: 'starter' | 'pro' | 'business'
  ): Promise<RateLimitExceeded> {
    const client = RedisConfig.getClient();
    const limits = PLAN_LIMITS[plan];
    const key = `${this.KEY_PREFIX}:${userId}:daily`;

    try {
      const info = await this.checkLimit(userId, plan);

      if (info.remaining === 0) {
        return {
          exceeded: true,
          limit: info.limit,
          current: info.limit,
          resetAt: info.reset
        };
      }

      const current = await client.incr(key);
      
      const ttl = await client.ttl(key);
      if (ttl === -1) {
        const now = new Date();
        const midnight = new Date(now);
        midnight.setHours(24, 0, 0, 0);
        const secondsUntilMidnight = Math.floor((midnight.getTime() - now.getTime()) / 1000);
        await client.expire(key, secondsUntilMidnight);
      }

      return {
        exceeded: false,
        limit: limits.requestsPerDay,
        current,
        resetAt: info.reset
      };
    } catch (error) {
      logger.error(`Rate limit increment error for user ${userId}:`, error);
      throw error;
    }
  }

  static async resetLimit(userId: string): Promise<void> {
    const client = RedisConfig.getClient();
    const key = `${this.KEY_PREFIX}:${userId}:daily`;
    
    try {
      await client.del(key);
      logger.info(`Rate limit reset for user: ${userId}`);
    } catch (error) {
      logger.error(`Rate limit reset error for user ${userId}:`, error);
      throw error;
    }
  }

  static async getCurrentUsage(userId: string): Promise<number> {
    const client = RedisConfig.getClient();
    const key = `${this.KEY_PREFIX}:${userId}:daily`;
    
    try {
      const current = await client.get(key);
      return current ? parseInt(current) : 0;
    } catch (error) {
      logger.error(`Get current usage error for user ${userId}:`, error);
      return 0;
    }
  }

  static async checkMinuteLimit(
    userId: string,
    plan: 'starter' | 'pro' | 'business'
  ): Promise<boolean> {
    const client = RedisConfig.getClient();
    const limits = PLAN_LIMITS[plan];
    const key = `${this.KEY_PREFIX}:${userId}:minute`;

    try {
      const current = await client.get(key);
      const count = current ? parseInt(current) : 0;

      if (count >= limits.requestsPerMinute) {
        return false;
      }

      await client.incr(key);
      const ttl = await client.ttl(key);
      if (ttl === -1) {
        await client.expire(key, 60);
      }

      return true;
    } catch (error) {
      logger.error(`Minute rate limit error for user ${userId}:`, error);
      return false;
    }
  }
}
