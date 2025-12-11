import { createClient, RedisClientType } from 'redis';
import config from '../../config/env';
import logger from '../../config/logger';

export class CacheService {
  private static client: RedisClientType | null = null;

  static async initialize(): Promise<void> {
    try {
      if (this.client?.isOpen) {
        logger.info('Redis already connected');
        return;
      }

      this.client = createClient({
        socket: {
          host: config.REDIS_HOST,
          port: config.REDIS_PORT,
        },
        database: config.REDIS_DB,
        password: config.REDIS_PASSWORD || undefined,
      });

      this.client.on('error', (err) => {
        logger.error('Redis Client Error:', err);
      });

      await this.client.connect();
      logger.info('✅ Redis connected successfully');
    } catch (error) {
      logger.error('❌ Redis connection failed:', error);
      throw error;
    }
  }

  static async disconnect(): Promise<void> {
    try {
      if (this.client?.isOpen) {
        await this.client.quit();
        this.client = null;
        logger.info('✅ Redis disconnected');
      }
    } catch (error) {
      logger.error('❌ Redis disconnect failed:', error);
      throw error;
    }
  }

  static getClient(): RedisClientType {
    if (!this.client?.isOpen) {
      throw new Error('Redis not connected. Call initialize() first.');
    }
    return this.client;
  }

  static async get(key: string): Promise<string | null> {
    const client = this.getClient();
    return await client.get(key);
  }

  static async set(
    key: string,
    value: string,
    expirationSeconds?: number
  ): Promise<void> {
    const client = this.getClient();
    if (expirationSeconds) {
      await client.setEx(key, expirationSeconds, value);
    } else {
      await client.set(key, value);
    }
  }

  static async delete(key: string): Promise<void> {
    const client = this.getClient();
    await client.del(key);
  }

  static async exists(key: string): Promise<boolean> {
    const client = this.getClient();
    const result = await client.exists(key);
    return result === 1;
  }

  static isConnected(): boolean {
    return this.client?.isOpen ?? false;
  }
}
