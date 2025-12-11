#!/bin/bash

echo "🚀 FASE 4 - PARTE 4: Redis Setup (Cache + Rate Limiting)"
echo "========================================================="

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}📦 Instalando dependências Redis...${NC}"

npm install --save \
  redis@^4.6.10 \
  ioredis@^5.3.2

npm install --save-dev \
  @types/redis@^4.0.11

echo -e "${GREEN}✅ Dependências instaladas!${NC}"

mkdir -p src/infrastructure/cache

# Redis Configuration
cat > src/infrastructure/cache/redis.config.ts << 'EOF'
import { createClient, RedisClientType } from 'redis';
import { logger } from '../../config/logger';

export class RedisConfig {
  private static client: RedisClientType | null = null;

  static async connect(): Promise<RedisClientType> {
    if (this.client?.isOpen) {
      return this.client;
    }

    this.client = createClient({
      socket: {
        host: process.env.REDIS_HOST || 'localhost',
        port: parseInt(process.env.REDIS_PORT || '6379')
      },
      password: process.env.REDIS_PASSWORD || undefined,
      database: parseInt(process.env.REDIS_DB || '0')
    });

    this.client.on('error', (err) => logger.error('Redis Client Error:', err));
    this.client.on('connect', () => logger.info('✅ Redis connected'));
    this.client.on('disconnect', () => logger.warn('⚠️  Redis disconnected'));

    await this.client.connect();
    return this.client;
  }

  static async disconnect(): Promise<void> {
    if (this.client?.isOpen) {
      await this.client.quit();
      logger.info('🔌 Redis disconnected');
    }
  }

  static getClient(): RedisClientType {
    if (!this.client?.isOpen) {
      throw new Error('Redis not connected. Call connect() first.');
    }
    return this.client;
  }

  static async healthCheck(): Promise<boolean> {
    try {
      await this.client?.ping();
      return true;
    } catch (error) {
      logger.error('❌ Redis health check failed:', error);
      return false;
    }
  }
}
EOF

# Cache Service
cat > src/infrastructure/cache/CacheService.ts << 'EOF'
import { RedisConfig } from './redis.config';
import { logger } from '../../config/logger';

export class CacheService {
  private static readonly DEFAULT_TTL = 3600; // 1 hora

  static async get<T>(key: string): Promise<T | null> {
    try {
      const client = RedisConfig.getClient();
      const value = await client.get(key);
      
      if (!value) return null;
      
      return JSON.parse(value) as T;
    } catch (error) {
      logger.error(`Cache GET error for key ${key}:`, error);
      return null;
    }
  }

  static async set(key: string, value: any, ttl: number = this.DEFAULT_TTL): Promise<boolean> {
    try {
      const client = RedisConfig.getClient();
      await client.setEx(key, ttl, JSON.stringify(value));
      return true;
    } catch (error) {
      logger.error(`Cache SET error for key ${key}:`, error);
      return false;
    }
  }

  static async delete(key: string): Promise<boolean> {
    try {
      const client = RedisConfig.getClient();
      const result = await client.del(key);
      return result > 0;
    } catch (error) {
      logger.error(`Cache DELETE error for key ${key}:`, error);
      return false;
    }
  }

  static async exists(key: string): Promise<boolean> {
    try {
      const client = RedisConfig.getClient();
      const result = await client.exists(key);
      return result === 1;
    } catch (error) {
      logger.error(`Cache EXISTS error for key ${key}:`, error);
      return false;
    }
  }

  static async increment(key: string, by: number = 1): Promise<number> {
    try {
      const client = RedisConfig.getClient();
      return await client.incrBy(key, by);
    } catch (error) {
      logger.error(`Cache INCREMENT error for key ${key}:`, error);
      throw error;
    }
  }

  static async expire(key: string, seconds: number): Promise<boolean> {
    try {
      const client = RedisConfig.getClient();
      return await client.expire(key, seconds);
    } catch (error) {
      logger.error(`Cache EXPIRE error for key ${key}:`, error);
      return false;
    }
  }

  static async getTTL(key: string): Promise<number> {
    try {
      const client = RedisConfig.getClient();
      return await client.ttl(key);
    } catch (error) {
      logger.error(`Cache TTL error for key ${key}:`, error);
      return -1;
    }
  }

  static async flush(): Promise<boolean> {
    try {
      const client = RedisConfig.getClient();
      await client.flushDb();
      logger.warn('⚠️  Redis cache flushed');
      return true;
    } catch (error) {
      logger.error('Cache FLUSH error:', error);
      return false;
    }
  }

  static async getMultiple<T>(keys: string[]): Promise<Record<string, T | null>> {
    try {
      const client = RedisConfig.getClient();
      const values = await client.mGet(keys);
      
      const result: Record<string, T | null> = {};
      keys.forEach((key, index) => {
        result[key] = values[index] ? JSON.parse(values[index]!) : null;
      });
      
      return result;
    } catch (error) {
      logger.error('Cache MGET error:', error);
      return {};
    }
  }

  static async setMultiple(data: Record<string, any>, ttl: number = this.DEFAULT_TTL): Promise<boolean> {
    try {
      const client = RedisConfig.getClient();
      const multi = client.multi();
      
      Object.entries(data).forEach(([key, value]) => {
        multi.setEx(key, ttl, JSON.stringify(value));
      });
      
      await multi.exec();
      return true;
    } catch (error) {
      logger.error('Cache MSET error:', error);
      return false;
    }
  }
}
EOF

# Redis Rate Limiter Service (integrado com Redis)
cat > src/infrastructure/cache/RedisRateLimiterService.ts << 'EOF'
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
EOF

# Atualizar .env.example com variáveis Redis
cat >> .env.example << 'EOF'

# Redis Configuration
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=redis_secret_password
REDIS_DB=0
EOF

echo -e "${GREEN}✅ PARTE 4 CONCLUÍDA!${NC}"
echo ""
echo "Arquivos criados:"
echo "  ✓ src/infrastructure/cache/redis.config.ts"
echo "  ✓ src/infrastructure/cache/CacheService.ts"
echo "  ✓ src/infrastructure/cache/RedisRateLimiterService.ts"
echo "  ✓ .env.example (atualizado com Redis vars)"
echo ""
echo "📋 Próximos passos:"
echo "  1. Configure Redis no .env"
echo "  2. Certifique-se que Redis está rodando"
echo "  3. Execute: ./setup-infrastructure-part5-integration.sh"
EOF

chmod +x setup-infrastructure-part4-redis.sh
