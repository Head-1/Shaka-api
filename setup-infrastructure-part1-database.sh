#!/bin/bash

echo "🚀 FASE 4 - PARTE 1: Database Setup (PostgreSQL + TypeORM)"
echo "=========================================================="

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}📦 Instalando dependências...${NC}"

# Instalar dependências do TypeORM e PostgreSQL
npm install --save \
  typeorm@^0.3.17 \
  pg@^8.11.3 \
  reflect-metadata@^0.1.13

npm install --save-dev \
  @types/pg@^8.10.0

echo -e "${GREEN}✅ Dependências instaladas!${NC}"

# Criar estrutura de diretórios
echo -e "${BLUE}📁 Criando estrutura de diretórios...${NC}"
mkdir -p src/infrastructure/database
mkdir -p src/infrastructure/database/entities
mkdir -p src/infrastructure/database/repositories
mkdir -p src/infrastructure/database/migrations

# Database Configuration
cat > src/infrastructure/database/config.ts << 'EOF'
import { DataSource } from 'typeorm';
import { UserEntity } from './entities/UserEntity';
import { SubscriptionEntity } from './entities/SubscriptionEntity';
import { logger } from '../../config/logger';

export const AppDataSource = new DataSource({
  type: 'postgres',
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '5432'),
  username: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres',
  database: process.env.DB_NAME || 'shaka_api',
  synchronize: process.env.NODE_ENV === 'development', // ATENÇÃO: false em produção!
  logging: process.env.NODE_ENV === 'development',
  entities: [UserEntity, SubscriptionEntity],
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
EOF

# User Entity
cat > src/infrastructure/database/entities/UserEntity.ts << 'EOF'
import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, OneToOne } from 'typeorm';
import { SubscriptionEntity } from './SubscriptionEntity';

@Entity('users')
export class UserEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ length: 100 })
  name!: string;

  @Column({ unique: true, length: 255 })
  email!: string;

  @Column({ name: 'password_hash', length: 255 })
  passwordHash!: string;

  @Column({ 
    type: 'enum', 
    enum: ['starter', 'pro', 'business'],
    default: 'starter'
  })
  plan!: 'starter' | 'pro' | 'business';

  @Column({ name: 'is_active', default: true })
  isActive!: boolean;

  @Column({ name: 'company_name', nullable: true, length: 255 })
  companyName?: string;

  @OneToOne(() => SubscriptionEntity, subscription => subscription.user)
  subscription?: SubscriptionEntity;

  @CreateDateColumn({ name: 'created_at' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt!: Date;
}
EOF

# Subscription Entity
cat > src/infrastructure/database/entities/SubscriptionEntity.ts << 'EOF'
import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, OneToOne, JoinColumn } from 'typeorm';
import { UserEntity } from './UserEntity';

@Entity('subscriptions')
export class SubscriptionEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'user_id', type: 'uuid' })
  userId!: string;

  @OneToOne(() => UserEntity, user => user.subscription)
  @JoinColumn({ name: 'user_id' })
  user!: UserEntity;

  @Column({ 
    type: 'enum', 
    enum: ['starter', 'pro', 'business'],
    default: 'starter'
  })
  plan!: 'starter' | 'pro' | 'business';

  @Column({ 
    type: 'enum', 
    enum: ['active', 'cancelled', 'expired'],
    default: 'active'
  })
  status!: 'active' | 'cancelled' | 'expired';

  @Column({ name: 'start_date', type: 'timestamp' })
  startDate!: Date;

  @Column({ name: 'end_date', type: 'timestamp' })
  endDate!: Date;

  @Column({ name: 'auto_renew', default: true })
  autoRenew!: boolean;

  @CreateDateColumn({ name: 'created_at' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt!: Date;
}
EOF

# Database Service (abstração)
cat > src/infrastructure/database/DatabaseService.ts << 'EOF'
import { AppDataSource } from './config';
import { logger } from '../../config/logger';

export class DatabaseService {
  private static instance: DatabaseService;

  private constructor() {}

  static getInstance(): DatabaseService {
    if (!DatabaseService.instance) {
      DatabaseService.instance = new DatabaseService();
    }
    return DatabaseService.instance;
  }

  async connect(): Promise<void> {
    try {
      if (!AppDataSource.isInitialized) {
        await AppDataSource.initialize();
        logger.info('✅ Database connected successfully');
      }
    } catch (error) {
      logger.error('❌ Database connection error:', error);
      throw error;
    }
  }

  async disconnect(): Promise<void> {
    if (AppDataSource.isInitialized) {
      await AppDataSource.destroy();
      logger.info('🔌 Database disconnected');
    }
  }

  async healthCheck(): Promise<boolean> {
    try {
      await AppDataSource.query('SELECT 1');
      return true;
    } catch (error) {
      logger.error('❌ Database health check failed:', error);
      return false;
    }
  }

  getDataSource() {
    if (!AppDataSource.isInitialized) {
      throw new Error('Database not initialized. Call connect() first.');
    }
    return AppDataSource;
  }
}
EOF

# Atualizar .env.example
cat >> .env.example << 'EOF'

# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=postgres_secret_password
DB_NAME=shaka_api
EOF

echo -e "${GREEN}✅ PARTE 1 CONCLUÍDA!${NC}"
echo ""
echo "Arquivos criados:"
echo "  ✓ src/infrastructure/database/config.ts"
echo "  ✓ src/infrastructure/database/entities/UserEntity.ts"
echo "  ✓ src/infrastructure/database/entities/SubscriptionEntity.ts"
echo "  ✓ src/infrastructure/database/DatabaseService.ts"
echo "  ✓ .env.example (atualizado com DB vars)"
echo ""
echo -e "${YELLOW}⚠️  IMPORTANTE:${NC}"
echo "  1. Configure o .env com credenciais reais do PostgreSQL"
echo "  2. Certifique-se que PostgreSQL está rodando"
echo "  3. Execute: ./setup-infrastructure-part2-repositories.sh"
EOF

chmod +x setup-infrastructure-part1-database.sh
