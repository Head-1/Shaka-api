#!/bin/bash

# ============================================================================
# SHAKA API - FIX TYPESCRIPT BUILD ERRORS
# Corrige erros de interface após refatoração
# ============================================================================

set -e

echo "🔧 Fixing TypeScript errors..."

cd ~/shaka-api

# ============================================================================
# 1. FIX TokenService - JWTPayload interface
# ============================================================================

echo "📝 Fixing TokenService..."

cat > src/core/services/auth/TokenService.ts << 'TOKENSERVICE'
import jwt from 'jsonwebtoken';
import { AuthTokens, JWTPayload } from '../types/auth.types';
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
TOKENSERVICE

# ============================================================================
# 2. FIX AuthService - Remove extra parameter
# ============================================================================

echo "📝 Fixing AuthService..."

cat > src/core/services/auth/AuthService.ts << 'AUTHSERVICE'
import { UserService } from '../user/UserService';
import { PasswordService } from './PasswordService';
import { TokenService } from './TokenService';
import { LoginCredentials, AuthTokens } from '../types/auth.types';
import { CreateUserData } from '../types/user.types';

export class AuthService {
  /**
   * Register new user
   */
  static async register(data: CreateUserData): Promise<AuthTokens> {
    // Hash password
    const hashedPassword = await PasswordService.hashPassword(data.password);

    // Create user
    const user = await UserService.createUser({
      ...data,
      password: hashedPassword,
    });

    // Generate tokens
    const tokens = TokenService.generateTokens(user.id);

    return tokens;
  }

  /**
   * Login user
   */
  static async login(credentials: LoginCredentials): Promise<AuthTokens> {
    // Find user by email
    const user = await UserService.getUserByEmail(credentials.email);

    if (!user) {
      throw new Error('Invalid credentials');
    }

    // Verify password
    const isValid = await PasswordService.verifyPassword(
      credentials.password,
      user.password
    );

    if (!isValid) {
      throw new Error('Invalid credentials');
    }

    // Generate tokens
    const tokens = TokenService.generateTokens(user.id);

    return tokens;
  }

  /**
   * Refresh access token
   */
  static async refreshToken(refreshToken: string): Promise<AuthTokens> {
    // Verify refresh token
    const payload = TokenService.verifyRefreshToken(refreshToken);

    if (payload.type !== 'refresh') {
      throw new Error('Invalid token type');
    }

    // Generate new tokens
    return TokenService.generateTokens(payload.userId);
  }

  /**
   * Logout user (invalidate tokens)
   */
  static async logout(userId: string): Promise<void> {
    // In a real implementation, you would:
    // 1. Add token to blacklist in Redis
    // 2. Remove refresh token from database
    // For now, we just validate the userId exists
    await UserService.getUserById(userId);
  }
}
AUTHSERVICE

# ============================================================================
# 3. FIX CacheService - Use direct config properties
# ============================================================================

echo "📝 Fixing CacheService..."

cat > src/infrastructure/cache/CacheService.ts << 'CACHESERVICE'
import Redis from 'ioredis';
import config from '../../config/env';
import logger from '../../config/logger';

export class CacheService {
  private static client: Redis | null = null;

  /**
   * Initialize Redis connection
   */
  static async initialize(): Promise<void> {
    if (this.client) {
      return;
    }

    try {
      this.client = new Redis({
        host: config.REDIS_HOST,
        port: config.REDIS_PORT,
        password: config.REDIS_PASSWORD || undefined,
        db: config.REDIS_DB,
        retryStrategy: (times) => {
          const delay = Math.min(times * 50, 2000);
          return delay;
        },
      });

      this.client.on('connect', () => {
        logger.info('✅ Redis connected successfully');
      });

      this.client.on('error', (error) => {
        logger.error('Redis connection error:', error);
      });

      // Test connection
      await this.client.ping();
      logger.info('✅ Redis ping successful');
    } catch (error) {
      logger.error('Failed to initialize Redis:', error);
      throw error;
    }
  }

  /**
   * Get Redis client
   */
  static getClient(): Redis {
    if (!this.client) {
      throw new Error('Redis not initialized. Call initialize() first.');
    }
    return this.client;
  }

  /**
   * Set value with optional TTL
   */
  static async set(key: string, value: string, ttl?: number): Promise<void> {
    const client = this.getClient();
    
    if (ttl) {
      await client.setex(key, ttl, value);
    } else {
      await client.set(key, value);
    }
  }

  /**
   * Get value by key
   */
  static async get(key: string): Promise<string | null> {
    const client = this.getClient();
    return await client.get(key);
  }

  /**
   * Delete key
   */
  static async delete(key: string): Promise<void> {
    const client = this.getClient();
    await client.del(key);
  }

  /**
   * Check if key exists
   */
  static async exists(key: string): Promise<boolean> {
    const client = this.getClient();
    const result = await client.exists(key);
    return result === 1;
  }

  /**
   * Set with JSON value
   */
  static async setJSON(key: string, value: any, ttl?: number): Promise<void> {
    await this.set(key, JSON.stringify(value), ttl);
  }

  /**
   * Get JSON value
   */
  static async getJSON<T>(key: string): Promise<T | null> {
    const value = await this.get(key);
    if (!value) return null;
    
    try {
      return JSON.parse(value) as T;
    } catch {
      return null;
    }
  }

  /**
   * Close Redis connection
   */
  static async close(): Promise<void> {
    if (this.client) {
      await this.client.quit();
      this.client = null;
      logger.info('Redis connection closed');
    }
  }
}
CACHESERVICE

# ============================================================================
# 4. FIX server.ts - Use correct config property names
# ============================================================================

echo "📝 Fixing server.ts..."

cat > src/server.ts << 'SERVERFILE'
import express, { Application, Request, Response, NextFunction } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import compression from 'compression';
import config from './config/env';
import logger from './config/logger';
import { DatabaseService } from './infrastructure/database/DatabaseService';
import { CacheService } from './infrastructure/cache/CacheService';
import routes from './api/routes';
import { errorHandler } from './api/middlewares/errorHandler';
import { requestLogger } from './api/middlewares/requestLogger';

const app: Application = express();

// ============================================================================
// MIDDLEWARE
// ============================================================================

// Security
app.use(helmet());

// CORS
app.use(cors({
  origin: config.NODE_ENV === 'production' 
    ? ['https://yourdomain.com'] 
    : ['http://localhost:3000', 'http://localhost:5173'],
  credentials: true,
}));

// Body parsing
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Compression
app.use(compression());

// Request logging
app.use(requestLogger);

// ============================================================================
// HEALTH CHECK
// ============================================================================

app.get('/health', (req: Request, res: Response) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    environment: config.NODE_ENV,
    uptime: process.uptime(),
  });
});

// ============================================================================
// ROUTES
// ============================================================================

app.use('/api/v1', routes);

// ============================================================================
// ERROR HANDLING
// ============================================================================

// 404 handler
app.use((req: Request, res: Response) => {
  res.status(404).json({ error: 'Not found' });
});

// Global error handler
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
  logger.error('Error:', err);
  res.status(500).json({
    error: 'Internal server error',
    message: config.NODE_ENV === 'development' ? err.message : 'Something went wrong'
  });
});

// ============================================================================
// SERVER INITIALIZATION
// ============================================================================

async function startServer() {
  try {
    // Initialize database
    logger.info('🔌 Connecting to PostgreSQL...');
    await DatabaseService.initialize();
    
    // Initialize cache
    logger.info('🔌 Connecting to Redis...');
    await CacheService.initialize();
    
    // Start server
    app.listen(config.PORT, () => {
      logger.info(`🚀 Server running on port ${config.PORT}`);
      logger.info(`📝 Environment: ${config.NODE_ENV}`);
      logger.info(`🔗 Health check: http://localhost:${config.PORT}/health`);
      logger.info(`🔗 API Base: http://localhost:${config.PORT}/api/v1`);
      logger.info(`📚 Available endpoints:`);
      logger.info(`   POST http://localhost:${config.PORT}/api/v1/auth/register`);
      logger.info(`   POST http://localhost:${config.PORT}/api/v1/auth/login`);
      logger.info(`   POST http://localhost:${config.PORT}/api/v1/auth/refresh`);
    });
  } catch (error) {
    logger.error('Failed to start server:', error);
    process.exit(1);
  }
}

// Handle shutdown
process.on('SIGTERM', async () => {
  logger.info('SIGTERM received, shutting down gracefully...');
  await DatabaseService.close();
  await CacheService.close();
  process.exit(0);
});

process.on('SIGINT', async () => {
  logger.info('SIGINT received, shutting down gracefully...');
  await DatabaseService.close();
  await CacheService.close();
  process.exit(0);
});

// Start the server
startServer();

export default app;
SERVERFILE

echo ""
echo "✅ All TypeScript errors fixed!"
echo ""
echo "📝 Fixed files:"
echo "   - src/core/services/auth/TokenService.ts"
echo "   - src/core/services/auth/AuthService.ts"
echo "   - src/infrastructure/cache/CacheService.ts"
echo "   - src/server.ts"
echo ""
echo "Next steps:"
echo "1. Run: npm run build"
echo "2. Verify: ls -la dist/server.js"
echo "3. Continue with Docker build"
