import { Request, Response, NextFunction } from 'express';
import { ApiKeyService } from '../../core/services/api-key/ApiKeyService';
import { RateLimiterService } from '../../core/services/rate-limiter';
import { logger } from '../../config/logger';

// Helper: Convert simple number to RateLimitConfig
function toRateLimitConfig(rateLimit: number) {
  return {
    requestsPerDay: rateLimit,
    requestsPerMinute: Math.ceil(rateLimit / 1440),
    concurrentRequests: 10
  };
}

export async function apiKeyAuth(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    // 1. Extract API key from header
    const apiKey = req.headers['x-api-key'] as string;
    
    if (!apiKey) {
      res.status(401).json({
        error: 'API key is required',
        message: 'Please provide a valid API key in X-API-Key header'
      });
      return;
    }

    // 2. Validate API key
    const validation = await ApiKeyService.validateKey(apiKey);
    
    if (!validation.isValid || !validation.apiKey || !validation.user) {
      res.status(401).json({
        error: 'Invalid API key',
        message: validation.reason || 'The provided API key is not valid'
      });
      return;
    }

    // 3. Check rate limiting
    const rateLimitResult = await RateLimiterService.checkLimit(
      validation.apiKey.id,
      toRateLimitConfig(validation.apiKey.rateLimit)
    );

    if (!rateLimitResult.allowed) {
      logger.warn('[apiKeyAuth] Rate limit exceeded', {
        apiKeyId: validation.apiKey.id,
        userId: validation.user.id,
        rateLimit: validation.apiKey.rateLimit
      });

      res.status(429).json({
        error: 'Rate limit exceeded',
        message: 'Too many requests. Please try again later.',
        resetAt: rateLimitResult.resetAt
      });
      return;
    }

    // 4. Increment usage counter
    await RateLimiterService.incrementUsage(
      validation.apiKey.id,
      toRateLimitConfig(validation.apiKey.rateLimit)
    );

    // 5. Set rate limit headers
    res.setHeader('X-RateLimit-Limit', rateLimitResult.limit.toString());
    res.setHeader('X-RateLimit-Remaining', rateLimitResult.remaining.toString());
    res.setHeader('X-RateLimit-Reset', rateLimitResult.resetAt.toISOString());

    // 6. Attach user and API key to request
    req.user = validation.user;
    req.apiKey = validation.apiKey;

    logger.info('[apiKeyAuth] API key validated successfully', {
      apiKeyId: validation.apiKey.id,
      userId: validation.user.id
    });

    next();
  } catch (error) {
    logger.error('[apiKeyAuth] Error validating API key', { error });
    res.status(500).json({
      error: 'Internal server error',
      message: 'An error occurred while validating the API key'
    });
  }
}
