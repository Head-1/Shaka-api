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
