#!/bin/bash
# Fix DatabaseService - Add missing methods

cd ~/shaka-api

echo "📝 Fixing DatabaseService..."

cat > src/infrastructure/database/DatabaseService.ts << 'EOF'
import { AppDataSource } from './config';
import logger from '../../config/logger';

export class DatabaseService {
  private static isInitialized = false;

  /**
   * Initialize database connection
   */
  static async initialize(): Promise<void> {
    if (this.isInitialized) {
      logger.info('Database already initialized');
      return;
    }

    try {
      await AppDataSource.initialize();
      this.isInitialized = true;
      logger.info('✅ Database connected successfully');
    } catch (error) {
      logger.error('❌ Database connection failed:', error);
      throw error;
    }
  }

  /**
   * Close database connection
   */
  static async close(): Promise<void> {
    if (!this.isInitialized) {
      logger.info('Database not initialized, nothing to close');
      return;
    }

    try {
      await AppDataSource.destroy();
      this.isInitialized = false;
      logger.info('Database connection closed');
    } catch (error) {
      logger.error('Error closing database:', error);
      throw error;
    }
  }

  /**
   * Get connection status
   */
  static isConnected(): boolean {
    return this.isInitialized && AppDataSource.isInitialized;
  }

  /**
   * Get data source instance
   */
  static getDataSource() {
    if (!this.isInitialized) {
      throw new Error('Database not initialized. Call initialize() first.');
    }
    return AppDataSource;
  }
}
EOF

echo "✅ DatabaseService fixed"
