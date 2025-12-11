#!/bin/bash

echo "🚀 FASE 3 - PARTE 2: TokenService + AuthService"
echo "================================================"

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# TokenService
cat > src/core/services/auth/TokenService.ts << 'EOF'
import jwt from 'jsonwebtoken';
import { TokenPayload, AuthTokens } from '../../types/auth.types';
import { logger } from '../../../config/logger';

export class TokenService {
  private static readonly ACCESS_TOKEN_EXPIRY = '15m';
  private static readonly REFRESH_TOKEN_EXPIRY = '7d';
  private static readonly JWT_SECRET = process.env.JWT_SECRET || 'dev-secret-change-in-prod';
  private static readonly JWT_REFRESH_SECRET = process.env.JWT_REFRESH_SECRET || 'dev-refresh-secret';

  static generateTokens(payload: Omit<TokenPayload, 'iat' | 'exp'>): AuthTokens {
    const accessToken = jwt.sign(payload, this.JWT_SECRET, {
      expiresIn: this.ACCESS_TOKEN_EXPIRY
    });

    const refreshToken = jwt.sign(
      { userId: payload.userId },
      this.JWT_REFRESH_SECRET,
      { expiresIn: this.REFRESH_TOKEN_EXPIRY }
    );

    const decoded = jwt.decode(accessToken) as jwt.JwtPayload;
    const expiresIn = decoded.exp ? decoded.exp - Math.floor(Date.now() / 1000) : 900;

    logger.info(`Tokens generated for user: ${payload.userId}`);

    return { accessToken, refreshToken, expiresIn };
  }

  static verifyAccessToken(token: string): TokenPayload {
    try {
      return jwt.verify(token, this.JWT_SECRET) as TokenPayload;
    } catch (error) {
      if (error instanceof jwt.TokenExpiredError) {
        throw new Error('Access token expired');
      }
      throw new Error('Invalid access token');
    }
  }

  static verifyRefreshToken(token: string): { userId: string } {
    try {
      return jwt.verify(token, this.JWT_REFRESH_SECRET) as { userId: string };
    } catch (error) {
      if (error instanceof jwt.TokenExpiredError) {
        throw new Error('Refresh token expired');
      }
      throw new Error('Invalid refresh token');
    }
  }

  static decodeToken(token: string): TokenPayload | null {
    return jwt.decode(token) as TokenPayload;
  }

  static isTokenExpired(token: string): boolean {
    const decoded = jwt.decode(token) as jwt.JwtPayload;
    if (!decoded || !decoded.exp) return true;
    return decoded.exp < Math.floor(Date.now() / 1000);
  }
}
EOF

# AuthService
cat > src/core/services/auth/AuthService.ts << 'EOF'
import { v4 as uuidv4 } from 'uuid';
import { LoginCredentials, RegisterData, AuthTokens, RefreshTokenData } from '../../types/auth.types';
import { User, UserResponse } from '../../types/user.types';
import { PasswordService } from './PasswordService';
import { TokenService } from './TokenService';
import { logger } from '../../../config/logger';

export class AuthService {
  // Mock database (será substituído por PostgreSQL)
  private static users: Map<string, User> = new Map();

  static async register(data: RegisterData): Promise<{ user: UserResponse; tokens: AuthTokens }> {
    logger.info(`Registering user: ${data.email}`);

    const existingUser = Array.from(this.users.values()).find(u => u.email === data.email);
    if (existingUser) {
      throw new Error('Email already registered');
    }

    const passwordHash = await PasswordService.hashPassword(data.password);

    const user: User = {
      id: uuidv4(),
      name: data.name,
      email: data.email,
      passwordHash,
      plan: 'starter',
      isActive: true,
      companyName: data.companyName,
      createdAt: new Date(),
      updatedAt: new Date()
    };

    this.users.set(user.id, user);

    const tokens = TokenService.generateTokens({
      userId: user.id,
      email: user.email,
      plan: user.plan
    });

    const { passwordHash: _, ...userResponse } = user;
    return { user: userResponse, tokens };
  }

  static async login(credentials: LoginCredentials): Promise<{ user: UserResponse; tokens: AuthTokens }> {
    const user = Array.from(this.users.values()).find(u => u.email === credentials.email);
    
    if (!user) throw new Error('Invalid credentials');
    if (!user.isActive) throw new Error('Account inactive');

    const isValid = await PasswordService.comparePassword(credentials.password, user.passwordHash);
    if (!isValid) throw new Error('Invalid credentials');

    const tokens = TokenService.generateTokens({
      userId: user.id,
      email: user.email,
      plan: user.plan
    });

    const { passwordHash: _, ...userResponse } = user;
    return { user: userResponse, tokens };
  }

  static async refreshTokens(data: RefreshTokenData): Promise<AuthTokens> {
    const { userId } = TokenService.verifyRefreshToken(data.refreshToken);
    const user = this.users.get(userId);
    
    if (!user || !user.isActive) throw new Error('Invalid refresh token');

    return TokenService.generateTokens({
      userId: user.id,
      email: user.email,
      plan: user.plan
    });
  }

  static async validateAccessToken(token: string): Promise<UserResponse> {
    const payload = TokenService.verifyAccessToken(token);
    const user = this.users.get(payload.userId);
    
    if (!user || !user.isActive) throw new Error('Invalid token');

    const { passwordHash: _, ...userResponse } = user;
    return userResponse;
  }
}
EOF

echo -e "${GREEN}✅ PARTE 2 CONCLUÍDA!${NC}"
echo ""
echo "Arquivos criados:"
echo "  ✓ src/core/services/auth/TokenService.ts"
echo "  ✓ src/core/services/auth/AuthService.ts"
echo ""
echo "Execute agora: ./setup-services-part3.sh"
EOF

chmod +x setup-services-part2.sh
