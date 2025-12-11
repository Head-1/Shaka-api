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
