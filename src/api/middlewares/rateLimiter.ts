import { Request, Response, NextFunction } from 'express';
import { RateLimiterService } from '../../core/services/rate-limiter/RateLimiterService';
import { PLAN_LIMITS } from '../../core/types/subscription.types';
import { logger } from '../../config/logger';

export const rateLimiter = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    if (!req.user) {
      next();
      return;
    }

    const userId = req.user.id;  // ✅ CORRIGIDO: userId → id
    const userPlan = req.user.plan || 'starter';
    const limits = PLAN_LIMITS[userPlan];  // ✅ CORRIGIDO: Usar objeto limits

    const result = await RateLimiterService.checkLimit(userId, limits);

    if (!result.allowed) {
      logger.warn('[rateLimiter] Rate limit exceeded', {
        userId,
        plan: userPlan
      });

      res.status(429).json({
        error: 'Rate limit exceeded',
        message: `You have exceeded your rate limit of ${result.limit} requests per day`,
        limit: result.limit,
        remaining: result.remaining,
        resetAt: result.resetAt
      });
      return;
    }

    await RateLimiterService.incrementUsage(userId, limits);

    res.setHeader('X-RateLimit-Limit', result.limit.toString());
    res.setHeader('X-RateLimit-Remaining', result.remaining.toString());
    res.setHeader('X-RateLimit-Reset', result.resetAt.toISOString());

    next();
  } catch (error: any) {
    logger.error('[rateLimiter] Error:', error);
    next();
  }
};
