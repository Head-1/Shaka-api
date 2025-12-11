#!/bin/bash

echo "🔧 SCRIPT 22: Registrando Rotas no Server"
echo "========================================="
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}📝 Atualizando server.ts para registrar rotas...${NC}"

# Verificar conteúdo atual do server.ts
if grep -q "app.use('/api/v1'" src/server.ts; then
  echo -e "${GREEN}✓ Rotas já registradas${NC}"
else
  echo -e "${YELLOW}⚠ Rotas não registradas, adicionando...${NC}"
  
  # Criar novo server.ts com rotas registradas
  cat > src/server.ts << 'EOF'
import 'reflect-metadata';
import express, { Request, Response } from 'express';
import cors from 'cors';
import { config } from '@config/env';
import { logger } from '@config/logger';
import { DatabaseService } from '@infrastructure/database/DatabaseService';
import { CacheService } from '@infrastructure/cache/CacheService';
import routes from './api/routes';

const app = express();

// Middlewares
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Request logging
app.use((req: Request, res: Response, next) => {
  logger.info(`${req.method} ${req.path}`);
  next();
});

// Health check endpoint
app.get('/health', async (req: Request, res: Response) => {
  try {
    const dbHealthy = DatabaseService.isConnected();
    const redisHealthy = CacheService.isConnected();

    res.json({
      status: 'ok',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      environment: config.env,
      services: {
        database: dbHealthy ? 'healthy' : 'unhealthy',
        redis: redisHealthy ? 'healthy' : 'unhealthy'
      }
    });
  } catch (error) {
    logger.error('Health check failed', { error });
    res.status(503).json({
      status: 'error',
      message: 'Service unhealthy'
    });
  }
});

// API Routes
app.use('/api/v1', routes);

// 404 handler
app.use((req: Request, res: Response) => {
  res.status(404).json({
    error: 'Not Found',
    message: `Cannot ${req.method} ${req.path}`
  });
});

// Error handler
app.use((err: Error, req: Request, res: Response, next: any) => {
  logger.error('Unhandled error', { error: err.message, stack: err.stack });
  res.status(500).json({
    error: 'Internal Server Error',
    message: config.env === 'development' ? err.message : 'Something went wrong'
  });
});

// Initialize and start server
async function startServer() {
  try {
    // Initialize infrastructure
    logger.info('🔧 Initializing infrastructure...');
    
    await DatabaseService.connect();
    logger.info('✅ Database connected');
    
    await CacheService.connect();
    logger.info('✅ Redis connected');
    
    logger.info('✅ Infrastructure initialized successfully');

    // Start server
    app.listen(config.port, () => {
      logger.info(`🚀 Server running on port ${config.port}`);
      logger.info(`📝 Environment: ${config.env}`);
      logger.info(`🔗 Health check: http://localhost:${config.port}/health`);
      logger.info(`🔗 API Base: http://localhost:${config.port}/api/v1`);
      logger.info(`🔗 Auth endpoints:`);
      logger.info(`   POST http://localhost:${config.port}/api/v1/auth/register`);
      logger.info(`   POST http://localhost:${config.port}/api/v1/auth/login`);
      logger.info(`   POST http://localhost:${config.port}/api/v1/auth/refresh`);
    });
  } catch (error) {
    logger.error('❌ Failed to start server', { error });
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

startServer();
EOF

  echo -e "${GREEN}✓ server.ts atualizado com registro de rotas${NC}"
fi

echo ""
echo -e "${GREEN}✅ SCRIPT 22 CONCLUÍDO!${NC}"
echo ""
echo -e "📊 Mudanças aplicadas:"
echo -e "   • Rotas registradas em /api/v1"
echo -e "   • Logging de requisições adicionado"
echo -e "   • 404 handler adicionado"
echo -e "   • Error handler global adicionado"
echo ""
echo -e "🧪 Reiniciar servidor:"
echo -e "   Ctrl+C no terminal do servidor"
echo -e "   npm run dev"
echo ""
echo -e "🎯 Testar depois:"
echo -e "   ./load-test-api.sh"
echo ""
