#!/bin/bash

echo "🚀 FASE 4 - PARTE 2: Repositories (User + Subscription)"
echo "======================================================="

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}📝 Criando Repositories...${NC}"

# Base Repository (abstração comum)
cat > src/infrastructure/database/repositories/BaseRepository.ts << 'EOF'
import { Repository, FindOptionsWhere, FindManyOptions } from 'typeorm';
import { AppDataSource } from '../config';
import { logger } from '../../../config/logger';

export abstract class BaseRepository<T> {
  protected repository: Repository<T>;

  constructor(entity: new () => T) {
    this.repository = AppDataSource.getRepository(entity);
  }

  async findById(id: string): Promise<T | null> {
    return this.repository.findOne({ where: { id } as FindOptionsWhere<T> });
  }

  async findAll(options?: FindManyOptions<T>): Promise<T[]> {
    return this.repository.find(options);
  }

  async create(data: Partial<T>): Promise<T> {
    const entity = this.repository.create(data as any);
    return this.repository.save(entity);
  }

  async update(id: string, data: Partial<T>): Promise<T | null> {
    await this.repository.update(id, data as any);
    return this.findById(id);
  }

  async delete(id: string): Promise<boolean> {
    const result = await this.repository.delete(id);
    return (result.affected ?? 0) > 0;
  }

  async count(where?: FindOptionsWhere<T>): Promise<number> {
    return this.repository.count({ where });
  }
}
EOF

# User Repository
cat > src/infrastructure/database/repositories/UserRepository.ts << 'EOF'
import { FindOptionsWhere } from 'typeorm';
import { BaseRepository } from './BaseRepository';
import { UserEntity } from '../entities/UserEntity';
import { CreateUserData, UpdateUserData, UserResponse } from '../../../core/types/user.types';
import { logger } from '../../../config/logger';

export class UserRepository extends BaseRepository<UserEntity> {
  constructor() {
    super(UserEntity);
  }

  async findByEmail(email: string): Promise<UserEntity | null> {
    return this.repository.findOne({ 
      where: { email } as FindOptionsWhere<UserEntity>
    });
  }

  async findActiveUsers(): Promise<UserEntity[]> {
    return this.repository.find({
      where: { isActive: true } as FindOptionsWhere<UserEntity>
    });
  }

  async createUser(data: CreateUserData & { passwordHash: string }): Promise<UserEntity> {
    const user = this.repository.create({
      name: data.name,
      email: data.email,
      passwordHash: data.passwordHash,
      plan: data.plan || 'starter',
      companyName: data.companyName,
      isActive: true
    });

    const saved = await this.repository.save(user);
    logger.info(`User created in DB: ${saved.id}`);
    return saved;
  }

  async updateUser(id: string, data: UpdateUserData): Promise<UserEntity | null> {
    const user = await this.findById(id);
    if (!user) return null;

    Object.assign(user, data);
    return this.repository.save(user);
  }

  async deactivateUser(id: string): Promise<boolean> {
    const result = await this.repository.update(id, { isActive: false });
    return (result.affected ?? 0) > 0;
  }

  async findPaginated(page: number = 1, limit: number = 10): Promise<{
    users: UserEntity[];
    total: number;
    page: number;
    totalPages: number;
  }> {
    const [users, total] = await this.repository.findAndCount({
      skip: (page - 1) * limit,
      take: limit,
      order: { createdAt: 'DESC' }
    });

    return {
      users,
      total,
      page,
      totalPages: Math.ceil(total / limit)
    };
  }

  toUserResponse(user: UserEntity): UserResponse {
    const { passwordHash, ...userResponse } = user;
    return userResponse as UserResponse;
  }
}
EOF

# Subscription Repository
cat > src/infrastructure/database/repositories/SubscriptionRepository.ts << 'EOF'
import { FindOptionsWhere, LessThan } from 'typeorm';
import { BaseRepository } from './BaseRepository';
import { SubscriptionEntity } from '../entities/SubscriptionEntity';
import { logger } from '../../../config/logger';

export class SubscriptionRepository extends BaseRepository<SubscriptionEntity> {
  constructor() {
    super(SubscriptionEntity);
  }

  async findByUserId(userId: string): Promise<SubscriptionEntity | null> {
    return this.repository.findOne({
      where: { userId } as FindOptionsWhere<SubscriptionEntity>,
      relations: ['user']
    });
  }

  async findActiveByUserId(userId: string): Promise<SubscriptionEntity | null> {
    return this.repository.findOne({
      where: { 
        userId,
        status: 'active'
      } as FindOptionsWhere<SubscriptionEntity>
    });
  }

  async createSubscription(
    userId: string,
    plan: 'starter' | 'pro' | 'business'
  ): Promise<SubscriptionEntity> {
    const subscription = this.repository.create({
      userId,
      plan,
      status: 'active',
      startDate: new Date(),
      endDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // +30 dias
      autoRenew: true
    });

    const saved = await this.repository.save(subscription);
    logger.info(`Subscription created in DB: ${saved.id}`);
    return saved;
  }

  async changePlan(
    userId: string,
    newPlan: 'starter' | 'pro' | 'business'
  ): Promise<SubscriptionEntity | null> {
    const subscription = await this.findActiveByUserId(userId);
    if (!subscription) return null;

    subscription.plan = newPlan;
    return this.repository.save(subscription);
  }

  async cancelSubscription(userId: string): Promise<boolean> {
    const subscription = await this.findActiveByUserId(userId);
    if (!subscription) return false;

    subscription.status = 'cancelled';
    subscription.autoRenew = false;
    await this.repository.save(subscription);
    return true;
  }

  async findExpiredSubscriptions(): Promise<SubscriptionEntity[]> {
    return this.repository.find({
      where: {
        status: 'active',
        endDate: LessThan(new Date())
      } as FindOptionsWhere<SubscriptionEntity>
    });
  }

  async markAsExpired(id: string): Promise<void> {
    await this.repository.update(id, { status: 'expired' });
  }
}
EOF

# Repository Factory (facilita acesso)
cat > src/infrastructure/database/repositories/index.ts << 'EOF'
import { UserRepository } from './UserRepository';
import { SubscriptionRepository } from './SubscriptionRepository';

export class RepositoryFactory {
  private static userRepository: UserRepository;
  private static subscriptionRepository: SubscriptionRepository;

  static getUserRepository(): UserRepository {
    if (!this.userRepository) {
      this.userRepository = new UserRepository();
    }
    return this.userRepository;
  }

  static getSubscriptionRepository(): SubscriptionRepository {
    if (!this.subscriptionRepository) {
      this.subscriptionRepository = new SubscriptionRepository();
    }
    return this.subscriptionRepository;
  }
}

export { UserRepository, SubscriptionRepository };
EOF

echo -e "${GREEN}✅ PARTE 2 CONCLUÍDA!${NC}"
echo ""
echo "Arquivos criados:"
echo "  ✓ src/infrastructure/database/repositories/BaseRepository.ts"
echo "  ✓ src/infrastructure/database/repositories/UserRepository.ts"
echo "  ✓ src/infrastructure/database/repositories/SubscriptionRepository.ts"
echo "  ✓ src/infrastructure/database/repositories/index.ts"
echo ""
echo "Execute agora: ./setup-infrastructure-part3-migrations.sh"
EOF

chmod +x setup-infrastructure-part2-repositories.sh
