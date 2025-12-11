#!/bin/bash
# Script: setup-api-base.sh
# Descrição: Cria toda a estrutura base da API Node.js

echo "🚀 Criando estrutura base da API..."

# ==========================================
# 1. SERVER PRINCIPAL
# ==========================================
cat > src/server.ts << 'SERVERFILE'
import express, { Application } from 'express';
import dotenv from 'dotenv';
import helmet from 'helmet';
import cors from 'cors';
import compression from 'compression';
import { router } from './api/routes';
import { errorHandler } from './api/middlewares/errorHandler';
import { requestLogger } from './api/middlewares/requestLogger';
import { notFoundHandler } from './api/middlewares/notFoundHandler';
import { connectDatabase } from './infrastructure/database/connection';
import { connectRedis } from './infrastructure/cache/redis';
import logger from './shared/utils/logger';

dotenv.config();

class Server {
  private app: Application;
  private port: number;

  constructor() {
    this.app = express();
    this.port = parseInt(process.env.PORT || '3000', 10);
    this.initializeMiddlewares();
    this.initializeRoutes();
    this.initializeErrorHandling();
  }

  private initializeMiddlewares(): void {
    // Segurança
    this.app.use(helmet());
    this.app.use(cors({
      origin: process.env.CORS_ORIGIN || '*',
      credentials: true
    }));

    // Parsing
    this.app.use(express.json({ limit: '10mb' }));
    this.app.use(express.urlencoded({ extended: true, limit: '10mb' }));
    
    // Compressão
    this.app.use(compression());

    // Logging
    this.app.use(requestLogger);
  }

  private initializeRoutes(): void {
    // Health check
    this.app.get('/health', (req, res) => {
      res.status(200).json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        environment: process.env.NODE_ENV
      });
    });

    // API Routes
    this.app.use('/api/v1', router);

    // 404 Handler
    this.app.use(notFoundHandler);
  }

  private initializeErrorHandling(): void {
    this.app.use(errorHandler);
  }

  public async start(): Promise<void> {
    try {
      // Conectar ao banco de dados
      await connectDatabase();
      logger.info('✅ Database connected');

      // Conectar ao Redis
      await connectRedis();
      logger.info('✅ Redis connected');

      // Iniciar servidor
      this.app.listen(this.port, () => {
        logger.info(`🚀 Server running on port ${this.port}`);
        logger.info(`📝 Environment: ${process.env.NODE_ENV}`);
        logger.info(`🔗 API: http://localhost:${this.port}/api/v1`);
      });
    } catch (error) {
      logger.error('❌ Failed to start server:', error);
      process.exit(1);
    }
  }
}

// Inicializar servidor
const server = new Server();
server.start();

// Graceful shutdown
process.on('SIGTERM', () => {
  logger.info('SIGTERM received, shutting down gracefully');
  process.exit(0);
});

process.on('SIGINT', () => {
  logger.info('SIGINT received, shutting down gracefully');
  process.exit(0);
});
SERVERFILE

echo "✅ Server principal criado"

# ==========================================
# 2. ROUTES PRINCIPAIS
# ==========================================
cat > src/api/routes/index.ts << 'ROUTEFILE'
import { Router } from 'express';
import { authRoutes } from './auth.routes';
import { userRoutes } from './user.routes';
import { planRoutes } from './plan.routes';

const router = Router();

// Status da API
router.get('/', (req, res) => {
  res.json({
    name: 'Shaka API',
    version: '1.0.0',
    status: 'online',
    timestamp: new Date().toISOString()
  });
});

// Rotas
router.use('/auth', authRoutes);
router.use('/users', userRoutes);
router.use('/plans', planRoutes);

export { router };
ROUTEFILE

# Auth Routes
cat > src/api/routes/auth.routes.ts << 'AUTHROUTES'
import { Router } from 'express';
import { AuthController } from '../controllers/auth/AuthController';
import { validateRequest } from '../middlewares/validateRequest';
import { loginSchema, registerSchema } from '../validators/auth.validator';

const router = Router();
const authController = new AuthController();

router.post('/register', validateRequest(registerSchema), authController.register);
router.post('/login', validateRequest(loginSchema), authController.login);
router.post('/refresh', authController.refreshToken);
router.post('/logout', authController.logout);

export { router as authRoutes };
AUTHROUTES

# User Routes
cat > src/api/routes/user.routes.ts << 'USERROUTES'
import { Router } from 'express';
import { UserController } from '../controllers/users/UserController';
import { authenticate } from '../middlewares/authenticate';
import { rateLimiter } from '../middlewares/rateLimiter';

const router = Router();
const userController = new UserController();

// Todas as rotas requerem autenticação
router.use(authenticate);
router.use(rateLimiter);

router.get('/profile', userController.getProfile);
router.put('/profile', userController.updateProfile);
router.get('/usage', userController.getUsage);

export { router as userRoutes };
USERROUTES

# Plan Routes
cat > src/api/routes/plan.routes.ts << 'PLANROUTES'
import { Router } from 'express';
import { PlanController } from '../controllers/plans/PlanController';

const router = Router();
const planController = new PlanController();

router.get('/', planController.listPlans);
router.get('/:planId', planController.getPlan);

export { router as planRoutes };
PLANROUTES

echo "✅ Rotas criadas"

# ==========================================
# 3. MIDDLEWARES
# ==========================================

# Error Handler
cat > src/api/middlewares/errorHandler.ts << 'ERRORHANDLER'
import { Request, Response, NextFunction } from 'express';
import logger from '../../shared/utils/logger';
import { AppError } from '../../shared/errors/AppError';

export function errorHandler(
  error: Error,
  req: Request,
  res: Response,
  next: NextFunction
): void {
  if (error instanceof AppError) {
    logger.warn(`AppError: ${error.message}`, {
      statusCode: error.statusCode,
      path: req.path
    });

    res.status(error.statusCode).json({
      status: 'error',
      message: error.message,
      ...(process.env.NODE_ENV === 'development' && { stack: error.stack })
    });
    return;
  }

  logger.error('Unhandled error:', error);

  res.status(500).json({
    status: 'error',
    message: 'Internal server error',
    ...(process.env.NODE_ENV === 'development' && {
      error: error.message,
      stack: error.stack
    })
  });
}
ERRORHANDLER

# Request Logger
cat > src/api/middlewares/requestLogger.ts << 'REQLOGGER'
import { Request, Response, NextFunction } from 'express';
import logger from '../../shared/utils/logger';

export function requestLogger(
  req: Request,
  res: Response,
  next: NextFunction
): void {
  const start = Date.now();

  res.on('finish', () => {
    const duration = Date.now() - start;
    
    logger.info('HTTP Request', {
      method: req.method,
      path: req.path,
      statusCode: res.statusCode,
      duration: `${duration}ms`,
      ip: req.ip,
      userAgent: req.get('user-agent')
    });
  });

  next();
}
REQLOGGER

# Not Found Handler
cat > src/api/middlewares/notFoundHandler.ts << 'NOTFOUND'
import { Request, Response } from 'express';

export function notFoundHandler(req: Request, res: Response): void {
  res.status(404).json({
    status: 'error',
    message: 'Route not found',
    path: req.path
  });
}
NOTFOUND

# Authenticate Middleware
cat > src/api/middlewares/authenticate.ts << 'AUTHENTICATE'
import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { AppError } from '../../shared/errors/AppError';

interface JwtPayload {
  userId: string;
  email: string;
  plan: string;
}

declare global {
  namespace Express {
    interface Request {
      user?: JwtPayload;
    }
  }
}

export function authenticate(
  req: Request,
  res: Response,
  next: NextFunction
): void {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new AppError('No token provided', 401);
    }

    const token = authHeader.substring(7);
    const secret = process.env.JWT_SECRET || 'default_secret';

    const decoded = jwt.verify(token, secret) as JwtPayload;
    req.user = decoded;

    next();
  } catch (error) {
    if (error instanceof jwt.JsonWebTokenError) {
      next(new AppError('Invalid token', 401));
    } else {
      next(error);
    }
  }
}
AUTHENTICATE

# Rate Limiter
cat > src/api/middlewares/rateLimiter.ts << 'RATELIMITER'
import { Request, Response, NextFunction } from 'express';
import { RateLimiterService } from '../../core/services/rate-limiter/RateLimiterService';
import { AppError } from '../../shared/errors/AppError';

const rateLimiterService = new RateLimiterService();

export async function rateLimiter(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    if (!req.user) {
      throw new AppError('Unauthorized', 401);
    }

    const { userId, plan } = req.user;
    const allowed = await rateLimiterService.checkLimit(userId, plan);

    if (!allowed) {
      throw new AppError('Rate limit exceeded', 429);
    }

    next();
  } catch (error) {
    next(error);
  }
}
RATELIMITER

# Validate Request
cat > src/api/middlewares/validateRequest.ts << 'VALIDATE'
import { Request, Response, NextFunction } from 'express';
import Joi from 'joi';
import { AppError } from '../../shared/errors/AppError';

export function validateRequest(schema: Joi.ObjectSchema) {
  return (req: Request, res: Response, next: NextFunction): void => {
    const { error, value } = schema.validate(req.body, {
      abortEarly: false,
      stripUnknown: true
    });

    if (error) {
      const errors = error.details.map(detail => ({
        field: detail.path.join('.'),
        message: detail.message
      }));

      throw new AppError('Validation error', 400, errors);
    }

    req.body = value;
    next();
  };
}
VALIDATE

echo "✅ Middlewares criados"

# ==========================================
# 4. VALIDATORS
# ==========================================
cat > src/api/validators/auth.validator.ts << 'AUTHVALIDATOR'
import Joi from 'joi';

export const registerSchema = Joi.object({
  email: Joi.string().email().required(),
  password: Joi.string().min(8).required(),
  fullName: Joi.string().min(3).required(),
  plan: Joi.string().valid('starter', 'pro', 'business').default('starter')
});

export const loginSchema = Joi.object({
  email: Joi.string().email().required(),
  password: Joi.string().required()
});
AUTHVALIDATOR

echo "✅ Validators criados"

# ==========================================
# 5. CONTROLLERS
# ==========================================

# Auth Controller
cat > src/api/controllers/auth/AuthController.ts << 'AUTHCONTROLLER'
import { Request, Response, NextFunction } from 'express';
import { AuthService } from '../../../core/services/auth/AuthService';

const authService = new AuthService();

export class AuthController {
  async register(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await authService.register(req.body);
      
      res.status(201).json({
        status: 'success',
        data: result
      });
    } catch (error) {
      next(error);
    }
  }

  async login(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await authService.login(req.body);
      
      res.status(200).json({
        status: 'success',
        data: result
      });
    } catch (error) {
      next(error);
    }
  }

  async refreshToken(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { refreshToken } = req.body;
      const result = await authService.refreshToken(refreshToken);
      
      res.status(200).json({
        status: 'success',
        data: result
      });
    } catch (error) {
      next(error);
    }
  }

  async logout(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      // Implementar logout (invalidar token no Redis)
      res.status(200).json({
        status: 'success',
        message: 'Logged out successfully'
      });
    } catch (error) {
      next(error);
    }
  }
}
AUTHCONTROLLER

# User Controller
cat > src/api/controllers/users/UserController.ts << 'USERCONTROLLER'
import { Request, Response, NextFunction } from 'express';
import { UserService } from '../../../core/services/auth/UserService';

const userService = new UserService();

export class UserController {
  async getProfile(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user!.userId;
      const user = await userService.getUserById(userId);
      
      res.status(200).json({
        status: 'success',
        data: user
      });
    } catch (error) {
      next(error);
    }
  }

  async updateProfile(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user!.userId;
      const updatedUser = await userService.updateUser(userId, req.body);
      
      res.status(200).json({
        status: 'success',
        data: updatedUser
      });
    } catch (error) {
      next(error);
    }
  }

  async getUsage(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user!.userId;
      const usage = await userService.getUserUsage(userId);
      
      res.status(200).json({
        status: 'success',
        data: usage
      });
    } catch (error) {
      next(error);
    }
  }
}
USERCONTROLLER

# Plan Controller
cat > src/api/controllers/plans/PlanController.ts << 'PLANCONTROLLER'
import { Request, Response, NextFunction } from 'express';

export class PlanController {
  async listPlans(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const plans = [
        {
          id: 'starter',
          name: 'Starter',
          price: 0,
          features: ['100 requests/day', 'Basic support', 'Community access'],
          rateLimit: 100
        },
        {
          id: 'pro',
          name: 'Pro',
          price: 49,
          features: ['1000 requests/day', 'Priority support', 'Advanced features'],
          rateLimit: 1000
        },
        {
          id: 'business',
          name: 'Business',
          price: 199,
          features: ['10000 requests/day', 'Dedicated support', 'SLA 99.9%', 'Custom features'],
          rateLimit: 10000
        }
      ];

      res.status(200).json({
        status: 'success',
        data: plans
      });
    } catch (error) {
      next(error);
    }
  }

  async getPlan(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { planId } = req.params;
      
      // TODO: Buscar plano do banco
      res.status(200).json({
        status: 'success',
        data: { planId }
      });
    } catch (error) {
      next(error);
    }
  }
}
PLANCONTROLLER

echo "✅ Controllers criados"

# ==========================================
# 6. SHARED - Errors e Utils
# ==========================================

# App Error
cat > src/shared/errors/AppError.ts << 'APPERROR'
export class AppError extends Error {
  public readonly statusCode: number;
  public readonly details?: any;

  constructor(message: string, statusCode: number = 500, details?: any) {
    super(message);
    this.statusCode = statusCode;
    this.details = details;
    
    Error.captureStackTrace(this, this.constructor);
  }
}
APPERROR

# Logger
cat > src/shared/utils/logger.ts << 'LOGGER'
import winston from 'winston';

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize(),
        winston.format.simple()
      )
    })
  ]
});

export default logger;
LOGGER

echo "✅ Shared utilities criados"

echo ""
echo "================================================"
echo "✅ ESTRUTURA BASE DA API CRIADA!"
echo "================================================"
echo ""
echo "📁 Arquivos criados:"
echo "   - src/server.ts (servidor principal)"
echo "   - src/api/routes/* (rotas)"
echo "   - src/api/middlewares/* (middlewares)"
echo "   - src/api/controllers/* (controllers)"
echo "   - src/api/validators/* (validadores)"
echo "   - src/shared/errors/* (tratamento de erros)"
echo "   - src/shared/utils/* (utilitários)"
echo ""
echo "⚠️  Ainda falta criar:"
echo "   - Services (camada de negócio)"
echo "   - Database connections"
echo "   - Redis connections"
echo ""
