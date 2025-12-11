#!/bin/bash

echo "🚀 FASE 4 - PARTE 5: Integration & Server Update"
echo "================================================="

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🔧 Atualizando Server.ts para usar Database e Redis...${NC}"

# Atualizar server.ts para inicializar Database e Redis
cat > src/server.ts << 'EOF'
import 'reflect-metadata';
import express, { Express } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { config } from './config/env';
import { logger } from './config/logger';
import { errorHandler } from './api/middlewares/errorHandler';
import { requestLogger } from './api/middlewares/requestLogger';
import authRoutes from './api/routes/auth.routes';
import userRoutes from './api/routes/user.routes';
import planRoutes from './api/routes/plan.routes';
import { DatabaseService } from './infrastructure/database/DatabaseService';
import { RedisConfig } from './infrastructure/cache/redis.config';

class Server {
  private app: Express;
  private port: number;

  constructor() {
    this.app = express();
    this.port = config.port;
  }

  private async initializeInfrastructure(): Promise<void> {
    try {
      logger.info('🔧 Initializing infrastructure...');
      
      // Conectar Database
      const dbService = DatabaseService.getInstance();
      await dbService.connect();
      logger.info('✅ Database connected');

      // Conectar Redis
      await RedisConfig.connect();
      logger.info('✅ Redis connected');

      logger.info('✅ Infrastructure initialized successfully');
    } catch (error) {
      logger.error('❌ Infrastructure initialization failed:', error);
      throw error;
    }
  }

  private setupMiddlewares(): void {
    this.app.use(helmet());
    this.app.use(cors());
    this.app.use(express.json());
    this.app.use(express.urlencoded({ extended: true }));
    this.app.use(requestLogger);
  }

  private setupRoutes(): void {
    this.app.get('/health', async (req, res) => {
      const dbService = DatabaseService.getInstance();
      const dbHealth = await dbService.healthCheck();
      const redisHealth = await RedisConfig.healthCheck();

      res.json({
        status: 'ok',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        environment: config.env,
        services: {
          database: dbHealth ? 'healthy' : 'unhealthy',
          redis: redisHealth ? 'healthy' : 'unhealthy'
        }
      });
    });

    this.app.use('/api/auth', authRoutes);
    this.app.use('/api/users', userRoutes);
    this.app.use('/api/plans', planRoutes);

    this.app.use(errorHandler);
  }

  private setupGracefulShutdown(): void {
    const shutdown = async (signal: string) => {
      logger.info(`\n${signal} received, shutting down gracefully...`);
      
      try {
        const dbService = DatabaseService.getInstance();
        await dbService.disconnect();
        await RedisConfig.disconnect();
        
        logger.info('✅ Graceful shutdown completed');
        process.exit(0);
      } catch (error) {
        logger.error('❌ Error during shutdown:', error);
        process.exit(1);
      }
    };

    process.on('SIGTERM', () => shutdown('SIGTERM'));
    process.on('SIGINT', () => shutdown('SIGINT'));
  }

  async start(): Promise<void> {
    try {
      await this.initializeInfrastructure();
      this.setupMiddlewares();
      this.setupRoutes();
      this.setupGracefulShutdown();

      this.app.listen(this.port, () => {
        logger.info(`🚀 Server running on port ${this.port}`);
        logger.info(`📝 Environment: ${config.env}`);
        logger.info(`🔗 Health check: http://localhost:${this.port}/health`);
      });
    } catch (error) {
      logger.error('❌ Failed to start server:', error);
      process.exit(1);
    }
  }
}

const server = new Server();
server.start();

export default server;
EOF

# Criar arquivo de índice para infrastructure
cat > src/infrastructure/index.ts << 'EOF'
export { DatabaseService } from './database/DatabaseService';
export { RedisConfig } from './cache/redis.config';
export { CacheService } from './cache/CacheService';
export { RedisRateLimiterService } from './cache/RedisRateLimiterService';
export { UserRepository, SubscriptionRepository, RepositoryFactory } from './database/repositories';
EOF

# Criar script de teste de conexões
cat > scripts/test-connections.sh << 'EOF'
#!/bin/bash

echo "🧪 Testing Database and Redis connections..."

# Testar PostgreSQL
echo "Testing PostgreSQL..."
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c "SELECT 1;" > /dev/null 2>&1

if [ $? -eq 0 ]; then
  echo "✅ PostgreSQL connection successful"
else
  echo "❌ PostgreSQL connection failed"
fi

# Testar Redis
echo "Testing Redis..."
redis-cli -h $REDIS_HOST -p $REDIS_PORT ping > /dev/null 2>&1

if [ $? -eq 0 ]; then
  echo "✅ Redis connection successful"
else
  echo "❌ Redis connection failed"
fi

echo ""
echo "Run 'npm run dev' to start the server"
EOF

chmod +x scripts/test-connections.sh

# Atualizar package.json com novos scripts
echo -e "${BLUE}📝 Atualizando package.json...${NC}"

# Adicionar scripts no package.json (se não existirem)
if ! grep -q "\"migration:run\"" package.json; then
  npm pkg set scripts.migration:run="npm run build && npx typeorm migration:run -d dist/infrastructure/database/config.js"
  npm pkg set scripts.migration:revert="npm run build && npx typeorm migration:revert -d dist/infrastructure/database/config.js"
  npm pkg set scripts.migration:generate="npx typeorm migration:generate -d src/infrastructure/database/config.ts"
  npm pkg set scripts.test:connections="./scripts/test-connections.sh"
fi

echo -e "${GREEN}✅ PARTE 5 CONCLUÍDA!${NC}"
echo ""
echo "Arquivos criados/atualizados:"
echo "  ✓ src/server.ts (atualizado com DB e Redis)"
echo "  ✓ src/infrastructure/index.ts"
echo "  ✓ scripts/test-connections.sh"
echo "  ✓ package.json (scripts adicionados)"
echo ""
echo -e "${YELLOW}📋 FASE 4 COMPLETA!${NC}"
echo ""
echo "Próximos passos:"
echo "  1. Configure .env com credenciais reais"
echo "  2. Inicie PostgreSQL e Redis"
echo "  3. Execute: npm run migration:run"
echo "  4. Execute: npm run dev"
echo "  5. Teste: curl http://localhost:3000/health"
EOF

chmod +x setup-infrastructure-part5-integration.sh
