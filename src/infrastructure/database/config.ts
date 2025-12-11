import { DataSource } from 'typeorm';
import { UserEntity } from './entities/UserEntity';
import { SubscriptionEntity } from './entities/SubscriptionEntity';
import { ApiKeyEntity } from './entities/ApiKeyEntity';
import { UsageRecordEntity } from './entities/UsageRecordEntity';
import { logger } from '../../config/logger';

const isProduction = process.env.NODE_ENV === 'production';

export const AppDataSource = new DataSource({
  type: 'postgres',
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '5432'),
  username: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres',
  database: process.env.DB_NAME || 'shaka_dev',
  synchronize: false, // Never use true in production
  logging: !isProduction,
  entities: [UserEntity, SubscriptionEntity, ApiKeyEntity, UsageRecordEntity],
  migrations: ['src/infrastructure/database/migrations/*.ts'],
  subscribers: [],
});

export const initializeDatabase = async () => {
  try {
    await AppDataSource.initialize();
    logger.info('✅ Database connection established');
    return AppDataSource;
  } catch (error) {
    logger.error('❌ Database connection failed:', error);
    throw error;
  }
};

export const closeDatabase = async () => {
  if (AppDataSource.isInitialized) {
    await AppDataSource.destroy();
    logger.info('🔌 Database connection closed');
  }
};
