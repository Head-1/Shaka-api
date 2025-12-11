import * as jwt from 'jsonwebtoken';
import { AuthTokens, JWTPayload } from '../../types/auth.types';
import config from '../../../config/env';

export class TokenService {
  private static JWT_SECRET = config.JWT_SECRET;
  private static JWT_REFRESH_SECRET = config.JWT_REFRESH_SECRET || config.JWT_SECRET;
  private static JWT_EXPIRES_IN = config.JWT_EXPIRES_IN;

  /**
   * Generate access and refresh tokens
   */
  static generateTokens(userId: string): AuthTokens {
    const accessToken = this.generateAccessToken(userId);
    const refreshToken = this.generateRefreshToken(userId);

    return {
      accessToken,
      refreshToken,
      expiresIn: this.JWT_EXPIRES_IN,
    };
  }

  /**
   * Generate access token
   */
  private static generateAccessToken(userId: string): string {
    const payload: JWTPayload = {
      userId,
      type: 'access',
    };

    return jwt.sign(payload, this.JWT_SECRET, {
      expiresIn: this.JWT_EXPIRES_IN,
    } as jwt.SignOptions);
  }

  /**
   * Generate refresh token
   */
  private static generateRefreshToken(userId: string): string {
    const payload: JWTPayload = {
      userId,
      type: 'refresh',
    };

    return jwt.sign(payload, this.JWT_REFRESH_SECRET, {
      expiresIn: '7d',
    } as jwt.SignOptions);
  }

  /**
   * Verify access token
   */
  static verifyAccessToken(token: string): JWTPayload {
    try {
      return jwt.verify(token, this.JWT_SECRET) as JWTPayload;
    } catch (error) {
      throw new Error('Invalid access token');
    }
  }

  /**
   * Verify refresh token
   */
  static verifyRefreshToken(token: string): JWTPayload {
    try {
      return jwt.verify(token, this.JWT_REFRESH_SECRET) as JWTPayload;
    } catch (error) {
      throw new Error('Invalid refresh token');
    }
  }

  /**
   * Decode token without verification (for debugging)
   */
  static decodeToken(token: string): JWTPayload | null {
    try {
      return jwt.decode(token) as JWTPayload;
    } catch {
      return null;
    }
  }
}
