#!/bin/bash
# Fix type imports paths

cd ~/shaka-api

echo "📝 Fixing AuthService imports..."

cat > src/core/services/auth/AuthService.ts << 'EOF'
import { UserService } from '../user/UserService';
import { PasswordService } from './PasswordService';
import { TokenService } from './TokenService';
import { LoginCredentials, AuthTokens } from '../../types/auth.types';
import { CreateUserData } from '../../types/user.types';

export class AuthService {
  /**
   * Register new user
   */
  static async register(data: CreateUserData): Promise<AuthTokens> {
    const hashedPassword = await PasswordService.hashPassword(data.password);

    const user = await UserService.createUser({
      ...data,
      password: hashedPassword,
    });

    const tokens = TokenService.generateTokens(user.id);

    return tokens;
  }

  /**
   * Login user
   */
  static async login(credentials: LoginCredentials): Promise<AuthTokens> {
    const user = await UserService.getUserByEmail(credentials.email);

    if (!user) {
      throw new Error('Invalid credentials');
    }

    const isValid = await PasswordService.verifyPassword(
      credentials.password,
      user.password
    );

    if (!isValid) {
      throw new Error('Invalid credentials');
    }

    const tokens = TokenService.generateTokens(user.id);

    return tokens;
  }

  /**
   * Refresh access token
   */
  static async refreshToken(refreshToken: string): Promise<AuthTokens> {
    const payload = TokenService.verifyRefreshToken(refreshToken);

    if (payload.type !== 'refresh') {
      throw new Error('Invalid token type');
    }

    return TokenService.generateTokens(payload.userId);
  }

  /**
   * Logout user (invalidate tokens)
   */
  static async logout(userId: string): Promise<void> {
    await UserService.getUserById(userId);
  }
}
EOF

echo "📝 Fixing TokenService imports..."

cat > src/core/services/auth/TokenService.ts << 'EOF'
import jwt from 'jsonwebtoken';
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
    });
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
    });
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
EOF

echo "✅ Imports fixed"
