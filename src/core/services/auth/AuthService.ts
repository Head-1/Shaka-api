import { UserRepository } from '../../../infrastructure/database/repositories/UserRepository';
import { UserService } from '../user/UserService';
import { PasswordService } from './PasswordService';
import { TokenService } from './TokenService';
import { AppError } from '../../../shared/errors/AppError';
import { logger } from '../../../config/logger';

export class AuthService {
  static async register(email: string, password: string, name: string, plan: string = 'starter') {
    try {
      // Create user via UserService (handles password hashing)
      const user = await UserService.createUser({
        email,
        password,
        name,
        plan: plan as 'starter' | 'pro' | 'business' | 'enterprise'
      });

      // Generate tokens
      const tokens = await TokenService.generateTokens(user.id);

      logger.info('[AuthService] User registered successfully', { userId: user.id });

      return { user, tokens };
    } catch (error: any) {
      logger.error('[AuthService] Error during registration:', error);
      throw error;
    }
  }

  static async login(email: string, password: string) {
    try {
      // Find user by email (returns UserEntity with passwordHash)
      const userEntity = await UserService.getUserByEmail(email);

      if (!userEntity) {
        throw new AppError('Invalid credentials', 401);
      }

      // Verify password using PasswordService.compare
      const isValid = await PasswordService.compare(password, userEntity.passwordHash);

      if (!isValid) {
        throw new AppError('Invalid credentials', 401);
      }

      // Get user data (without password)
      const user = await UserService.getUserById(userEntity.id);

      // Generate tokens
      const tokens = await TokenService.generateTokens(user.id);

      logger.info('[AuthService] User logged in successfully', { userId: user.id });

      return { user, tokens };
    } catch (error: any) {
      logger.error('[AuthService] Error during login:', error);
      throw error;
    }
  }

  static async refreshToken(refreshToken: string) {
    try {
      const payload = await TokenService.verifyRefreshToken(refreshToken);

      const user = await UserService.getUserById(payload.userId);

      const tokens = await TokenService.generateTokens(user.id);

      logger.info('[AuthService] Token refreshed successfully', { userId: user.id });

      return { user, tokens };
    } catch (error: any) {
      logger.error('[AuthService] Error refreshing token:', error);
      throw error;
    }
  }

  static async logout(userId: string) {
    try {
      // In a production app, you might want to:
      // - Invalidate refresh tokens
      // - Add access token to blacklist
      // - Clear session data
      
      logger.info('[AuthService] User logged out', { userId });

      return { message: 'Logged out successfully' };
    } catch (error: any) {
      logger.error('[AuthService] Error during logout:', error);
      throw error;
    }
  }
}
