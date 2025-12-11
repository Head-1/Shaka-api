#!/bin/bash

echo "🔧 SCRIPT 2: Criando Arquivos de Configuração"
echo "=============================================="
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Criar diretório config se não existir
mkdir -p src/config

echo -e "${YELLOW}📝 Criando src/config/env.ts...${NC}"

cat > src/config/env.ts << 'EOF'
import { config as dotenvConfig } from 'dotenv';

dotenvConfig();

interface Config {
  env: string;
  port: number;
  jwtSecret: string;
  jwtRefreshSecret: string;
  jwtExpiresIn: string;
  jwtRefreshExpiresIn: string;
  db: {
    host: string;
    port: number;
    user: string;
    password: string;
    name: string;
  };
  redis: {
    host: string;
    port: number;
    password?: string;
    db: number;
  };
}

export const config: Config = {
  env: process.env.NODE_ENV || 'development',
  port: parseInt(process.env.PORT || '3000', 10),
  jwtSecret: process.env.JWT_SECRET || 'your-super-secret-jwt-key-change-in-production',
  jwtRefreshSecret: process.env.JWT_REFRESH_SECRET || 'your-super-secret-refresh-key-change-in-production',
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '15m',
  jwtRefreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d',
  db: {
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '5432', 10),
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD || 'postgres',
    name: process.env.DB_NAME || 'shaka_api',
  },
  redis: {
    host: process.env.REDIS_HOST || 'localhost',
    port: parseInt(process.env.REDIS_PORT || '6379', 10),
    password: process.env.REDIS_PASSWORD || undefined,
    db: parseInt(process.env.REDIS_DB || '0', 10),
  },
};
EOF

echo -e "${GREEN}âœ" src/config/env.ts criado${NC}"
echo ""

echo -e "${YELLOW}📝 Criando src/config/logger.ts...${NC}"

cat > src/config/logger.ts << 'EOF'
import winston from 'winston';

const logLevel = process.env.LOG_LEVEL || 'info';

const logFormat = winston.format.combine(
  winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
  winston.format.errors({ stack: true }),
  winston.format.splat(),
  winston.format.json()
);

const consoleFormat = winston.format.combine(
  winston.format.colorize(),
  winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
  winston.format.printf(({ timestamp, level, message, ...meta }) => {
    let msg = `${timestamp} [${level}]: ${message}`;
    if (Object.keys(meta).length > 0) {
      msg += ` ${JSON.stringify(meta)}`;
    }
    return msg;
  })
);

export const logger = winston.createLogger({
  level: logLevel,
  format: logFormat,
  defaultMeta: { service: 'shaka-api' },
  transports: [
    new winston.transports.Console({
      format: consoleFormat,
    }),
    new winston.transports.File({
      filename: 'logs/error.log',
      level: 'error',
      maxsize: 5242880, // 5MB
      maxFiles: 5,
    }),
    new winston.transports.File({
      filename: 'logs/combined.log',
      maxsize: 5242880, // 5MB
      maxFiles: 5,
    }),
  ],
});

// Se não estiver em produção, logar também no console de forma mais legível
if (process.env.NODE_ENV !== 'production') {
  logger.add(
    new winston.transports.Console({
      format: consoleFormat,
    })
  );
}

export default logger;
EOF

echo -e "${GREEN}âœ" src/config/logger.ts criado${NC}"
echo ""

# Criar diretório de logs
echo -e "${YELLOW}📁 Criando diretório logs/...${NC}"
mkdir -p logs
touch logs/.gitkeep

cat > logs/.gitignore << 'EOF'
# Ignorar todos os logs
*.log

# Mas manter o diretório
!.gitkeep
EOF

echo -e "${GREEN}âœ" Diretório logs/ criado${NC}"
echo ""

# Verificar arquivos criados
echo "🔍 Verificando arquivos criados..."
echo ""

if [ -f "src/config/env.ts" ]; then
  echo -e "${GREEN}âœ" src/config/env.ts${NC}"
  wc -l src/config/env.ts | awk '{print "   └─ " $1 " linhas"}'
else
  echo "❌ src/config/env.ts - FALHOU"
fi

if [ -f "src/config/logger.ts" ]; then
  echo -e "${GREEN}âœ" src/config/logger.ts${NC}"
  wc -l src/config/logger.ts | awk '{print "   └─ " $1 " linhas"}'
else
  echo "❌ src/config/logger.ts - FALHOU"
fi

if [ -d "logs" ]; then
  echo -e "${GREEN}âœ" logs/${NC}"
else
  echo "❌ logs/ - FALHOU"
fi

echo ""
echo -e "${GREEN}✅ SCRIPT 2 CONCLUÍDO!${NC}"
echo ""
echo "📊 Impacto esperado: ~30 erros resolvidos"
echo ""
echo "🧪 Validação:"
echo "   npm run build 2>&1 | grep -c 'error TS'"
echo "   (Deve mostrar ~29 erros agora)"
echo ""
echo "🎯 Próximo passo:"
echo "   Execute: ./fix-services-static.sh"
echo ""
