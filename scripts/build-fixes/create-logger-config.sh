#!/bin/bash

echo "📝 Criando src/config/logger.ts..."

mkdir -p src/config
mkdir -p logs

cat > src/config/logger.ts << 'LOGEOF'
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
  winston.format.printf((info) => {
    const { timestamp, level, message } = info;
    return `${timestamp} [${level}]: ${message}`;
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
      maxsize: 5242880,
      maxFiles: 5,
    }),
    new winston.transports.File({
      filename: 'logs/combined.log',
      maxsize: 5242880,
      maxFiles: 5,
    }),
  ],
});

if (process.env.NODE_ENV !== 'production') {
  logger.add(
    new winston.transports.Console({
      format: consoleFormat,
    })
  );
}

export default logger;
LOGEOF

echo "✅ src/config/logger.ts criado!"
ls -lh src/config/logger.ts

# Criar .gitkeep no logs
touch logs/.gitkeep

echo ""
echo "✅ Arquivos de config criados com sucesso!"
echo ""
echo "🧪 Testar agora:"
echo "   npm run build 2>&1 | grep -c 'error TS'"
