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
