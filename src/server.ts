import express, { Application, Request, Response, NextFunction } from 'express';
import helmet from 'helmet';
import cors from 'cors';
import compression from 'compression';
import config from './config/env';
import logger from './config/logger';
import { DatabaseService } from './infrastructure/database/DatabaseService';
import { CacheService } from './infrastructure/cache/CacheService';
import { errorHandler } from './api/middlewares/errorHandler';
import { requestLogger } from './api/middlewares/requestLogger';
import routes from './api/routes';

const app: Application = express();
const PORT = config.PORT || 3000;

// ============================================================================
// MIDDLEWARE SETUP
// ============================================================================

// Security headers
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
// API ROUTES
// ============================================================================
app.use('/api/v1', routes);

// ============================================================================
// ERROR HANDLING
// ============================================================================
app.use(errorHandler);

// 404 Handler
app.use((req: Request, res: Response) => {
  res.status(404).json({
    error: 'Not Found',
    message: `Cannot ${req.method} ${req.path}`,
    timestamp: new Date().toISOString(),
  });
});

// ============================================================================
// SERVER STARTUP
// ============================================================================
async function startServer() {
  try {
    // Connect to database
    logger.info('Connecting to database...');
    await DatabaseService.initialize();
    logger.info('✅ Database connected successfully');

    // Connect to Redis
    logger.info('Connecting to Redis...');
    await CacheService.initialize();
    logger.info('✅ Redis connected successfully');

    // Start server
    app.listen(PORT, () => {
      logger.info(`🚀 Server running on port ${PORT}`);
      logger.info(`📊 Environment: ${config.NODE_ENV}`);
      logger.info(`🔗 Health check: http://localhost:${PORT}/health`);
      logger.info(`🎯 API base: http://localhost:${PORT}/api`);
    });
  } catch (error) {
    logger.error('Failed to start server:', error);
    process.exit(1);
  }
}

// Graceful shutdown
process.on('SIGTERM', async () => {
  logger.info('SIGTERM received, shutting down gracefully...');
  await DatabaseService.disconnect();
  await CacheService.disconnect();
  process.exit(0);
});

process.on('SIGINT', async () => {
  logger.info('SIGINT received, shutting down gracefully...');
  await DatabaseService.disconnect();
  await CacheService.disconnect();
  process.exit(0);
});

// Start the server
startServer();

export default app;
