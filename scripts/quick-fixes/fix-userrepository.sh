#!/bin/bash
# Fix UserRepository - Add all missing methods

cd ~/shaka-api

echo "📝 Fixing UserRepository..."

cat > src/infrastructure/database/repositories/UserRepository.ts << 'EOF'
import { Repository } from 'typeorm';
import { AppDataSource } from '../config';
import { UserEntity } from '../entities/UserEntity';
import { CreateUserData, UpdateUserData, UserResponse } from '../../../core/types/user.types';
import logger from '../../../config/logger';

export class UserRepository {
  private static repository: Repository<UserEntity>;

  /**
   * Initialize repository
   */
  static initialize(): void {
    this.repository = AppDataSource.getRepository(UserEntity);
  }

  /**
   * Create new user
   */
  static async create(data: CreateUserData & { passwordHash: string }): Promise<UserEntity> {
    const user = this.repository.create({
      name: data.name,
      email: data.email,
      passwordHash: data.passwordHash,
      plan: (data.plan as 'starter' | 'pro' | 'business') || 'starter',
      companyName: data.companyName,
      isActive: true,
    });

    const saved = await this.repository.save(user);
    logger.info(`User created in DB: ${saved.id}`);
    return saved;
  }

  /**
   * Find user by ID
   */
  static async findById(userId: string): Promise<UserEntity | null> {
    return await this.repository.findOne({
      where: { id: userId }
    });
  }

  /**
   * Find user by email
   */
  static async findByEmail(email: string): Promise<UserEntity | null> {
    return await this.repository.findOne({
      where: { email }
    });
  }

  /**
   * Update user
   */
  static async update(userId: string, data: UpdateUserData): Promise<UserEntity> {
    await this.repository.update(userId, data);
    
    const updated = await this.findById(userId);
    
    if (!updated) {
      throw new Error('User not found after update');
    }
    
    return updated;
  }

  /**
   * Find all users (paginated)
   */
  static async findAll(limit: number = 20, offset: number = 0): Promise<{
    users: UserEntity[];
    total: number;
  }> {
    const [users, total] = await this.repository.findAndCount({
      take: limit,
      skip: offset,
      order: {
        createdAt: 'DESC'
      }
    });

    return { users, total };
  }

  /**
   * Delete user (soft delete)
   */
  static async delete(userId: string): Promise<void> {
    await this.repository.update(userId, { isActive: false });
  }

  /**
   * Convert to UserResponse (remove sensitive data)
   */
  static toResponse(user: UserEntity): UserResponse {
    return {
      id: user.id,
      email: user.email,
      name: user.name,
      plan: user.plan,
      companyName: user.companyName,
      isActive: user.isActive,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    };
  }
}
EOF

echo "✅ UserRepository fixed"
