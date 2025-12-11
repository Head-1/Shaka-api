#!/bin/bash

# ============================================================================
# SHAKA API - Fix Final 7 Errors
# Corrige erros de PasswordService e UserEntity
# ============================================================================

set -e

PROJECT_ROOT=~/shaka-api
cd "$PROJECT_ROOT"

echo "=========================================="
echo "🔧 FIX FINAL - 7 ERROS RESTANTES"
echo "=========================================="
echo ""

# ============================================================================
# FIX 1: Corrigir PasswordService (métodos estáticos)
# ============================================================================

echo "[1/5] Corrigindo PasswordService..."

cat > src/core/services/auth/PasswordService.ts << 'EOF'
import bcrypt from 'bcrypt';
import { AppError } from '../../../shared/errors/AppError';
import { logger } from '../../../config/logger';

export class PasswordService {
  private static readonly SALT_ROUNDS = 12;

  /**
   * Hash password
   */
  static async hash(password: string): Promise<string> {
    try {
      return await bcrypt.hash(password, this.SALT_ROUNDS);
    } catch (error) {
      logger.error('[PasswordService] Error hashing password:', error);
      throw new AppError('Failed to hash password', 500);
    }
  }

  /**
   * Compare password with hash
   */
  static async compare(password: string, hash: string): Promise<boolean> {
    try {
      return await bcrypt.compare(password, hash);
    } catch (error) {
      logger.error('[PasswordService] Error comparing password:', error);
      throw new AppError('Failed to compare password', 500);
    }
  }

  /**
   * Validate password strength
   */
  static validateStrength(password: string): boolean {
    // Min 8 chars, at least one uppercase, one lowercase, one number, one special char
    const strongPasswordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&#])[A-Za-z\d@$!%*?&#]{8,}$/;
    return strongPasswordRegex.test(password);
  }
}
EOF

echo "✅ PasswordService corrigido (métodos estáticos)"

# ============================================================================
# FIX 2: Adicionar getUserByEmail no UserService
# ============================================================================

echo "[2/5] Adicionando getUserByEmail no UserService..."

cat > src/core/services/user/UserService.ts << 'EOF'
import { UserRepository } from '../../../infrastructure/database/repositories/UserRepository';
import { PasswordService } from '../auth/PasswordService';
import { AppError } from '../../../shared/errors/AppError';
import { logger } from '../../../config/logger';
import { CreateUserData, UpdateUserData, User, UserResponse } from '../../types/user.types';
import { UserEntity } from '../../../infrastructure/database/entities/UserEntity';

export class UserService {
  static async createUser(data: CreateUserData): Promise<User> {
    try {
      const existingUser = await UserRepository.findByEmail(data.email);
      
      if (existingUser) {
        throw new AppError('Email already in use', 409);
      }

      const passwordHash = await PasswordService.hash(data.password);

      const user = await UserRepository.create({
        ...data,
        passwordHash
      });

      logger.info('[UserService] User created successfully', { userId: user.id });

      return user;
    } catch (error: any) {
      logger.error('[UserService] Error creating user:', error);
      throw error;
    }
  }

  static async getUserById(id: string): Promise<User> {
    try {
      const user = await UserRepository.findById(id);

      if (!user) {
        throw new AppError('User not found', 404);
      }

      return user;
    } catch (error: any) {
      logger.error('[UserService] Error getting user:', error);
      throw error;
    }
  }

  static async getUserByEmail(email: string): Promise<UserEntity | null> {
    try {
      return await UserRepository.findByEmail(email);
    } catch (error: any) {
      logger.error('[UserService] Error getting user by email:', error);
      throw error;
    }
  }

  static async updateUser(id: string, data: UpdateUserData): Promise<User> {
    try {
      const user = await UserRepository.findById(id);

      if (!user) {
        throw new AppError('User not found', 404);
      }

      if (data.email && data.email !== user.email) {
        const existingUser = await UserRepository.findByEmail(data.email);
        if (existingUser) {
          throw new AppError('Email already in use', 409);
        }
      }

      const updatedUser = await UserRepository.update(id, data);

      if (!updatedUser) {
        throw new AppError('Failed to update user', 500);
      }

      logger.info('[UserService] User updated successfully', { userId: id });

      return updatedUser;
    } catch (error: any) {
      logger.error('[UserService] Error updating user:', error);
      throw error;
    }
  }

  static async deleteUser(id: string): Promise<void> {
    try {
      const user = await UserRepository.findById(id);

      if (!user) {
        throw new AppError('User not found', 404);
      }

      await UserRepository.delete(id);

      logger.info('[UserService] User deleted successfully', { userId: id });
    } catch (error: any) {
      logger.error('[UserService] Error deleting user:', error);
      throw error;
    }
  }

  static async changePassword(
    userId: string,
    currentPassword: string,
    newPassword: string
  ): Promise<void> {
    try {
      const user = await UserRepository.findById(userId);
      if (!user) {
        throw new AppError('User not found', 404);
      }

      const userEntity = await UserRepository.findByEmail(user.email);
      if (!userEntity) {
        throw new AppError('User entity not found', 404);
      }

      const isValid = await PasswordService.compare(currentPassword, userEntity.passwordHash);

      if (!isValid) {
        throw new AppError('Current password is incorrect', 401);
      }

      const newPasswordHash = await PasswordService.hash(newPassword);

      await UserRepository.updatePassword(userId, newPasswordHash);

      logger.info('[UserService] Password changed successfully', { userId });
    } catch (error: any) {
      logger.error('[UserService] Error changing password:', error);
      throw error;
    }
  }

  static async listUsers(limit: number = 100, offset: number = 0): Promise<User[]> {
    try {
      return await UserRepository.list(limit, offset);
    } catch (error: any) {
      logger.error('[UserService] Error listing users:', error);
      throw error;
    }
  }

  static toUserResponse(user: User): UserResponse {
    return UserRepository.toUserResponse(user);
  }
}
EOF

echo "✅ UserService.getUserByEmail() adicionado"

# ============================================================================
# FIX 3: Atualizar UserEntity (passwordHash em vez de password)
# ============================================================================

echo "[3/5] Atualizando UserEntity..."

cat > src/infrastructure/database/entities/UserEntity.ts << 'EOF'
import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, OneToMany } from 'typeorm';
import { ApiKeyEntity } from './ApiKeyEntity';

@Entity('users')
export class UserEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ unique: true })
  email!: string;

  @Column({ name: 'password_hash' })
  passwordHash!: string;

  @Column({
    type: 'varchar',
    length: 20,
    default: 'starter'
  })
  plan!: 'starter' | 'pro' | 'business' | 'enterprise';

  @CreateDateColumn({ name: 'created_at' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt!: Date;

  @OneToMany(() => ApiKeyEntity, apiKey => apiKey.user)
  apiKeys?: ApiKeyEntity[];
}
EOF

echo "✅ UserEntity.passwordHash corrigido"

# ============================================================================
# FIX 4: Atualizar UserRepository (corrigir create e adicionar updatePassword)
# ============================================================================

echo "[4/5] Atualizando UserRepository..."

cat > src/infrastructure/database/repositories/UserRepository.ts << 'EOF'
import { Repository } from 'typeorm';
import { AppDataSource } from '../config';
import { UserEntity } from '../entities/UserEntity';
import { CreateUserData, UpdateUserData, User, UserResponse } from '../../../core/types/user.types';

export class UserRepository {
  private static repository: Repository<UserEntity>;

  static initialize() {
    this.repository = AppDataSource.getRepository(UserEntity);
  }

  static async create(data: CreateUserData & { passwordHash: string }): Promise<User> {
    const user = this.repository.create({
      email: data.email,
      passwordHash: data.passwordHash,
      plan: data.plan || 'starter'
    });

    await this.repository.save(user);

    return this.toUser(user);
  }

  static async findById(id: string): Promise<User | null> {
    const user = await this.repository.findOne({ where: { id } });
    return user ? this.toUser(user) : null;
  }

  static async findByEmail(email: string): Promise<UserEntity | null> {
    return this.repository.findOne({ where: { email } });
  }

  static async update(id: string, data: UpdateUserData): Promise<User | null> {
    const updateData: any = {};

    if (data.email !== undefined) {
      updateData.email = data.email;
    }

    if (data.plan !== undefined) {
      updateData.plan = data.plan;
    }

    if (Object.keys(updateData).length > 0) {
      await this.repository.update(id, updateData);
    }

    return this.findById(id);
  }

  static async updatePassword(id: string, passwordHash: string): Promise<void> {
    await this.repository.update(id, { passwordHash });
  }

  static async delete(id: string): Promise<void> {
    await this.repository.delete(id);
  }

  static async list(limit: number = 100, offset: number = 0): Promise<User[]> {
    const users = await this.repository.find({
      take: limit,
      skip: offset,
      order: { createdAt: 'DESC' }
    });

    return users.map(this.toUser);
  }

  static async count(): Promise<number> {
    return this.repository.count();
  }

  private static toUser(entity: UserEntity): User {
    return {
      id: entity.id,
      email: entity.email,
      plan: entity.plan,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt
    };
  }

  static toUserResponse(user: User): UserResponse {
    return {
      id: user.id,
      email: user.email,
      plan: user.plan,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt
    };
  }
}
EOF

echo "✅ UserRepository.create() e updatePassword() corrigidos"

# ============================================================================
# FIX 5: Validar Build Final
# ============================================================================

echo ""
echo "[5/5] Validando build final..."
echo ""

npm run build > /tmp/build-final.log 2>&1

ERROR_COUNT=$(grep -c "error TS" /tmp/build-final.log || echo "0")

echo "=========================================="
if [ "$ERROR_COUNT" -eq "0" ]; then
    echo "✅✅✅ BUILD LIMPO! ZERO ERROS! ✅✅✅"
    echo "=========================================="
    echo ""
    echo "Correções aplicadas:"
    echo "  ✅ PasswordService.hash() - método estático"
    echo "  ✅ PasswordService.compare() - método estático"
    echo "  ✅ UserService.getUserByEmail() - adicionado"
    echo "  ✅ UserEntity.passwordHash - renomeado de password"
    echo "  ✅ UserRepository.create() - corrigido para passwordHash"
    echo "  ✅ UserRepository.updatePassword() - novo método"
    echo "  ✅ UserService.changePassword() - usa passwordHash"
    echo ""
    echo "📦 Arquivos .js gerados:"
    find dist -name "*.js" | wc -l
    echo ""
    echo "🚀 PRONTO PARA DEPLOY!"
    echo ""
    echo "PRÓXIMO PASSO:"
    echo "  bash scripts/sprint1/setup-build-deploy-test.sh"
    echo ""
else
    echo "⚠️  AINDA HÁ $ERROR_COUNT ERRO(S)"
    echo "=========================================="
    echo ""
    grep "error TS" /tmp/build-final.log | head -20
    echo ""
    echo "Ver log completo: cat /tmp/build-final.log"
    echo ""
fi
