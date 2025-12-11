#!/bin/bash
# Fix UserService - Remove duplicates and fix methods

cd ~/shaka-api

echo "📝 Fixing UserService..."

cat > src/core/services/user/UserService.ts << 'EOF'
import { UserRepository } from '../../../infrastructure/database/repositories/UserRepository';
import { CreateUserData, UpdateUserData } from '../../types/user.types';
import { PasswordService } from '../auth/PasswordService';

export class UserService {
  /**
   * Create new user
   */
  static async createUser(data: CreateUserData): Promise<any> {
    const passwordHash = await PasswordService.hashPassword(data.password);
    
    const userData = {
      ...data,
      passwordHash
    };
    
    return await UserRepository.create(userData);
  }

  /**
   * Get user by ID
   */
  static async getUserById(userId: string): Promise<any> {
    const user = await UserRepository.findById(userId);
    
    if (!user) {
      throw new Error('User not found');
    }

    return user;
  }

  /**
   * Get user by email
   */
  static async getUserByEmail(email: string): Promise<any> {
    return await UserRepository.findByEmail(email);
  }

  /**
   * Update user
   */
  static async updateUser(userId: string, data: UpdateUserData): Promise<any> {
    const user = await this.getUserById(userId);
    
    return await UserRepository.update(userId, data);
  }

  /**
   * Change password
   */
  static async changePassword(
    userId: string,
    currentPassword: string,
    newPassword: string
  ): Promise<void> {
    const user = await this.getUserById(userId);

    const isPasswordValid = await PasswordService.verifyPassword(
      currentPassword, 
      user.password
    );

    if (!isPasswordValid) {
      throw new Error('Current password is incorrect');
    }

    const newPasswordHash = await PasswordService.hashPassword(newPassword);

    await UserRepository.update(userId, { 
      password: newPasswordHash 
    });
  }

  /**
   * Deactivate user
   */
  static async deactivateUser(userId: string): Promise<void> {
    await this.getUserById(userId);
    await UserRepository.update(userId, { isActive: false });
  }

  /**
   * List all users (admin)
   */
  static async listUsers(
    page: number = 1,
    limit: number = 20
  ): Promise<any> {
    const offset = (page - 1) * limit;
    return await UserRepository.findAll(limit, offset);
  }
}
EOF

echo "✅ UserService fixed"
