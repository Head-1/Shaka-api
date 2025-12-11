#!/bin/bash

# ============================================================================
# SHAKA API - Fix User Type Issues
# Corrige 16 erros de inconsistência User/UserEntity
# ============================================================================

set -e

PROJECT_ROOT=~/shaka-api
cd "$PROJECT_ROOT"

echo "=========================================="
echo "🔧 FIX USER TYPE ISSUES - 16 ERROS"
echo "=========================================="
echo ""

# ============================================================================
# FIX 1: Atualizar User Types (adicionar campos faltantes)
# ============================================================================

echo "[1/5] Atualizando User types..."

cat > src/core/types/user.types.ts << 'EOF'
export interface User {
  id: string;
  email: string;
  plan: 'starter' | 'pro' | 'business' | 'enterprise';
  createdAt: Date;
  updatedAt: Date;
}

export interface CreateUserData {
  email: string;
  password: string;
  plan?: 'starter' | 'pro' | 'business' | 'enterprise';
}

export interface UpdateUserData {
  email?: string;
  plan?: 'starter' | 'pro' | 'business' | 'enterprise';
}

export interface UserResponse {
  id: string;
  email: string;
  plan: string;
  createdAt: Date;
  updatedAt: Date;
}
EOF

echo "✅ User types atualizados (versão minimalista)"

# ============================================================================
# FIX 2: Atualizar UserRepository (remover campos extras)
# ============================================================================

echo "[2/5] Atualizando UserRepository..."

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
      password: data.passwordHash,
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

echo "✅ UserRepository simplificado"

# ============================================================================
# FIX 3: Atualizar UserService (remover campos extras)
# ============================================================================

echo "[3/5] Atualizando UserService..."

cat > src/core/services/user/UserService.ts << 'EOF'
import { UserRepository } from '../../../infrastructure/database/repositories/UserRepository';
import { PasswordService } from '../auth/PasswordService';
import { AppError } from '../../../shared/errors/AppError';
import { logger } from '../../../config/logger';
import { CreateUserData, UpdateUserData, User, UserResponse } from '../../types/user.types';

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
      const userEntity = await UserRepository.findByEmail(
        (await UserRepository.findById(userId))!.email
      );

      if (!userEntity) {
        throw new AppError('User not found', 404);
      }

      const isValid = await PasswordService.compare(currentPassword, userEntity.password);

      if (!isValid) {
        throw new AppError('Current password is incorrect', 401);
      }

      const newPasswordHash = await PasswordService.hash(newPassword);

      await UserRepository.update(userId, { email: userEntity.email });
      
      // Update password directly in repository
      await UserRepository['repository'].update(userId, {
        password: newPasswordHash
      });

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

echo "✅ UserService atualizado"

# ============================================================================
# FIX 4: Adicionar métodos faltantes no UserController
# ============================================================================

echo "[4/5] Adicionando métodos faltantes no UserController..."

cat > src/api/controllers/user/UserController.ts << 'EOF'
import { Request, Response } from 'express';
import { UserService } from '../../../core/services/user/UserService';
import { logger } from '../../../config/logger';

export class UserController {
  /**
   * Get current user profile
   */
  static async getProfile(req: Request, res: Response): Promise<void> {
    try {
      const userId = req.user!.id;

      const user = await UserService.getUserById(userId);

      res.json({
        success: true,
        data: UserService.toUserResponse(user)
      });
    } catch (error: any) {
      logger.error('[UserController] Error getting profile:', error);
      
      res.status(error.statusCode || 500).json({
        success: false,
        error: error.message
      });
    }
  }

  /**
   * Get user by ID (admin only)
   */
  static async getUserById(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;

      const user = await UserService.getUserById(id);

      res.json({
        success: true,
        data: UserService.toUserResponse(user)
      });
    } catch (error: any) {
      logger.error('[UserController] Error getting user:', error);
      
      res.status(error.statusCode || 500).json({
        success: false,
        error: error.message
      });
    }
  }

  /**
   * List users (admin only)
   */
  static async listUsers(req: Request, res: Response): Promise<void> {
    try {
      const limit = parseInt(req.query.limit as string) || 100;
      const offset = parseInt(req.query.offset as string) || 0;

      const users = await UserService.listUsers(limit, offset);

      res.json({
        success: true,
        data: users.map(UserService.toUserResponse),
        pagination: {
          limit,
          offset,
          total: users.length
        }
      });
    } catch (error: any) {
      logger.error('[UserController] Error listing users:', error);
      
      res.status(error.statusCode || 500).json({
        success: false,
        error: error.message
      });
    }
  }

  /**
   * Update user profile
   */
  static async updateProfile(req: Request, res: Response): Promise<void> {
    try {
      const userId = req.user!.id;
      const updateData = req.body;

      const user = await UserService.updateUser(userId, updateData);

      res.json({
        success: true,
        data: UserService.toUserResponse(user),
        message: 'Profile updated successfully'
      });
    } catch (error: any) {
      logger.error('[UserController] Error updating profile:', error);
      
      res.status(error.statusCode || 500).json({
        success: false,
        error: error.message
      });
    }
  }

  /**
   * Change password
   */
  static async changePassword(req: Request, res: Response): Promise<void> {
    try {
      const userId = req.user!.id;
      const { currentPassword, newPassword } = req.body;

      await UserService.changePassword(userId, currentPassword, newPassword);

      res.json({
        success: true,
        message: 'Password changed successfully'
      });
    } catch (error: any) {
      logger.error('[UserController] Error changing password:', error);
      
      res.status(error.statusCode || 500).json({
        success: false,
        error: error.message
      });
    }
  }

  /**
   * Delete user account
   */
  static async deleteAccount(req: Request, res: Response): Promise<void> {
    try {
      const userId = req.user!.id;

      await UserService.deleteUser(userId);

      res.json({
        success: true,
        message: 'Account deleted successfully'
      });
    } catch (error: any) {
      logger.error('[UserController] Error deleting account:', error);
      
      res.status(error.statusCode || 500).json({
        success: false,
        error: error.message
      });
    }
  }
}
EOF

echo "✅ UserController completo"

# ============================================================================
# FIX 5: Corrigir DatabaseService.isInitialized
# ============================================================================

echo "[5/5] Corrigindo DatabaseService..."

# Verificar se isInitialized existe
if ! grep -q "private static isInitialized = false" src/infrastructure/database/DatabaseService.ts; then
    # Adicionar propriedade isInitialized
    sed -i '/export class DatabaseService {/a\
  private static isInitialized = false;' src/infrastructure/database/DatabaseService.ts
    
    echo "✅ isInitialized adicionado ao DatabaseService"
else
    echo "✅ isInitialized já existe no DatabaseService"
fi

echo ""
echo "=========================================="
echo "🧪 VALIDAÇÃO FINAL"
echo "=========================================="
echo ""

# Build e contar erros
npm run build > /tmp/build-fix.log 2>&1

ERROR_COUNT=$(grep -c "error TS" /tmp/build-fix.log || echo "0")

if [ "$ERROR_COUNT" -eq "0" ]; then
    echo "=========================================="
    echo "✅ BUILD LIMPO! ZERO ERROS!"
    echo "=========================================="
    echo ""
    echo "Correções aplicadas:"
    echo "  ✅ User types simplificados (email + plan apenas)"
    echo "  ✅ UserRepository limpo (sem campos extras)"
    echo "  ✅ UserService.deleteUser() adicionado"
    echo "  ✅ UserController.getUserById() adicionado"
    echo "  ✅ UserController.listUsers() adicionado"
    echo "  ✅ DatabaseService.isInitialized corrigido"
    echo ""
    echo "🚀 PRÓXIMO PASSO:"
    echo "  bash scripts/sprint1/setup-build-deploy-test.sh"
    echo ""
else
    echo "=========================================="
    echo "⚠️  AINDA HÁ $ERROR_COUNT ERROS"
    echo "=========================================="
    echo ""
    grep "error TS" /tmp/build-fix.log | head -20
    echo ""
    echo "Ver log completo: cat /tmp/build-fix.log"
fi
