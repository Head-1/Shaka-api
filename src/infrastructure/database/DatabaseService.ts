import { DataSource } from 'typeorm';
import { AppDataSource } from './config';
import logger from '../../config/logger';

export class DatabaseService {
  private static isInitialized = false;
  private static dataSource: DataSource = AppDataSource;

  static async initialize(): Promise<void> {
    try {
      if (this.dataSource.isInitialized) {
        logger.info('Database already initialized');
        return;
      }

      await this.dataSource.initialize();
      logger.info('✅ Database connected successfully');
    } catch (error) {
      logger.error('❌ Database connection failed:', error);
      throw error;
    }
  }

  static async disconnect(): Promise<void> {
    try {
      if (this.dataSource.isInitialized) {
        await this.dataSource.destroy();
        logger.info('✅ Database disconnected');
      }
    } catch (error) {
      logger.error('❌ Database disconnect failed:', error);
      throw error;
    }
  }

  static async healthCheck(): Promise<boolean> {
    try {
      if (!this.isInitialized) {
        return false;
      }

      await AppDataSource.query('SELECT 1');
      return true;
    } catch (error) {
      logger.error('[DatabaseService] Health check failed:', error);
      return false;
    }
  }


  static getDataSource(): DataSource {
    if (!this.dataSource.isInitialized) {
      throw new Error('Database not initialized. Call initialize() first.');
    }
    return this.dataSource;
  }

  static isConnected(): boolean {
    return this.dataSource.isInitialized;
  }
}
