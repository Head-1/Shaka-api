#!/bin/bash

echo "🔧 SCRIPT 24: Corrigindo DatabaseService"
echo "========================================"
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}📝 Recriando DatabaseService com métodos corretos...${NC}"

cat > src/infrastructure/database/DatabaseService.ts << 'EOF'
import { DataSource } from 'typeorm';
import { AppDataSource } from './config';
import { logger } from '@config/logger';

export class DatabaseService {
  private static dataSource: DataSource | null = null;
  private static connected: boolean = false;

  static async connect(): Promise<void> {
    try {
      if (this.connected) {
        logger.info('Database already connected');
        return;
      }

      logger.info('Initializing database connection...');
      this.dataSource = await AppDataSource.initialize();
      this.connected = true;
      logger.info('✅ Database connected successfully');
    } catch (error) {
      logger.error('❌ Database connection error', { error });
      throw error;
    }
  }

  static async disconnect(): Promise<void> {
    try {
      if (this.dataSource && this.connected) {
        await this.dataSource.destroy();
        this.connected = false;
        logger.info('Database disconnected');
      }
    } catch (error) {
      logger.error('Error disconnecting database', { error });
      throw error;
    }
  }

  static isConnected(): boolean {
    return this.connected && this.dataSource?.isInitialized === true;
  }

  static getDataSource(): DataSource {
    if (!this.dataSource || !this.connected) {
      throw new Error('Database not connected. Call connect() first.');
    }
    return this.dataSource;
  }

  static async healthCheck(): Promise<boolean> {
    try {
      if (!this.isConnected()) {
        return false;
      }
      await this.dataSource!.query('SELECT 1');
      return true;
    } catch (error) {
      logger.error('Database health check failed', { error });
      return false;
    }
  }
}
EOF

echo -e "${GREEN}✓ DatabaseService.ts recriado${NC}"
echo ""

echo -e "${YELLOW}📝 Verificando CacheService...${NC}"

if ! grep -q "static async connect" src/infrastructure/cache/CacheService.ts; then
  echo -e "${YELLOW}⚠ CacheService também precisa de correção${NC}"
  
  cat > src/infrastructure/cache/CacheService.ts << 'EOF'
import Redis from 'ioredis';
import { config } from '@config/env';
import { logger } from '@config/logger';

export class CacheService {
  private static client: Redis | null = null;
  private static connected: boolean = false;

  static async connect(): Promise<void> {
    try {
      if (this.connected) {
        logger.info('Redis already connected');
        return;
      }

      logger.info('Connecting to Redis...');
      
      this.client = new Redis({
        host: config.redis.host,
        port: config.redis.port,
        password: config.redis.password || undefined,
        db: config.redis.db,
        retryStrategy: (times: number) => {
          const delay = Math.min(times * 50, 2000);
          return delay;
        },
      });

      this.client.on('connect', () => {
        this.connected = true;
        logger.info('✅ Redis connected successfully');
      });

      this.client.on('error', (error) => {
        logger.error('Redis error', { error });
      });

      // Wait for connection
      await new Promise((resolve, reject) => {
        this.client!.once('connect', resolve);
        this.client!.once('error', reject);
      });

    } catch (error) {
      logger.error('❌ Redis connection error', { error });
      throw error;
    }
  }

  static async disconnect(): Promise<void> {
    try {
      if (this.client && this.connected) {
        await this.client.quit();
        this.connected = false;
        logger.info('Redis disconnected');
      }
    } catch (error) {
      logger.error('Error disconnecting Redis', { error });
      throw error;
    }
  }

  static isConnected(): boolean {
    return this.connected && this.client?.status === 'ready';
  }

  static getClient(): Redis {
    if (!this.client || !this.connected) {
      throw new Error('Redis not connected. Call connect() first.');
    }
    return this.client;
  }

  static async get(key: string): Promise<string | null> {
    try {
      return await this.getClient().get(key);
    } catch (error) {
      logger.error('Cache get error', { key, error });
      return null;
    }
  }

  static async set(key: string, value: string, ttl?: number): Promise<void> {
    try {
      if (ttl) {
        await this.getClient().setex(key, ttl, value);
      } else {
        await this.getClient().set(key, value);
      }
    } catch (error) {
      logger.error('Cache set error', { key, error });
      throw error;
    }
  }

  static async delete(key: string): Promise<void> {
    try {
      await this.getClient().del(key);
    } catch (error) {
      logger.error('Cache delete error', { key, error });
      throw error;
    }
  }

  static async exists(key: string): Promise<boolean> {
    try {
      const result = await this.getClient().exists(key);
      return result === 1;
    } catch (error) {
      logger.error('Cache exists error', { key, error });
      return false;
    }
  }

  static async healthCheck(): Promise<boolean> {
    try {
      if (!this.isConnected()) {
        return false;
      }
      const result = await this.client!.ping();
      return result === 'PONG';
    } catch (error) {
      logger.error('Redis health check failed', { error });
      return false;
    }
  }
}
EOF

  echo -e "${GREEN}✓ CacheService.ts recriado${NC}"
else
  echo -e "${GREEN}✓ CacheService já tem método connect${NC}"
fi

echo ""
echo -e "${GREEN}✅ SCRIPT 24 CONCLUÍDO!${NC}"
echo ""
echo -e "📊 Serviços corrigidos:"
echo -e "   • DatabaseService.connect() criado"
echo -e "   • DatabaseService.disconnect() criado"
echo -e "   • DatabaseService.isConnected() criado"
echo -e "   • CacheService.connect() criado"
echo -e "   • CacheService.disconnect() criado"
echo -e "   • CacheService.isConnected() criado"
echo ""
echo -e "🧪 Testar agora:"
echo -e "   npm run dev"
echo ""
echo -e "🎯 Agora deve iniciar sem erros! 🚀"
echo ""
