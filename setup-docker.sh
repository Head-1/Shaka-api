#!/bin/bash
# Script: setup-docker.sh
# Descrição: Cria todos os arquivos Docker necessários para o Shaka API

echo "🐳 Criando configurações Docker..."

# ==========================================
# 1. DOCKERFILE PRINCIPAL (Node.js API)
# ==========================================
cat > docker/api/Dockerfile << 'DOCKERFILE'
FROM node:20-alpine AS builder

WORKDIR /app

# Instalar dependências do sistema
RUN apk add --no-cache python3 make g++

# Copiar arquivos de dependências
COPY package*.json ./
COPY tsconfig.json ./

# Instalar dependências
RUN npm ci --only=production && \
    npm cache clean --force

# Copiar código fonte
COPY src ./src

# Build da aplicação
RUN npm run build

# ==========================================
# Stage 2: Runtime
# ==========================================
FROM node:20-alpine

WORKDIR /app

# Criar usuário não-root
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Copiar dependências e build
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist
COPY --from=builder --chown=nodejs:nodejs /app/package*.json ./

# Variáveis de ambiente
ENV NODE_ENV=production
ENV PORT=3000

# Expor porta
EXPOSE 3000

# Trocar para usuário não-root
USER nodejs

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Iniciar aplicação
CMD ["node", "dist/server.js"]
DOCKERFILE

echo "✅ Dockerfile da API criado"

# ==========================================
# 2. DOCKERFILE DO NGINX (Load Balancer)
# ==========================================
cat > docker/nginx/Dockerfile << 'DOCKERFILE'
FROM nginx:alpine

# Remover configuração padrão
RUN rm /etc/nginx/conf.d/default.conf

# Copiar configuração customizada
COPY nginx.conf /etc/nginx/nginx.conf
COPY conf.d/ /etc/nginx/conf.d/

# Criar diretório para cache
RUN mkdir -p /var/cache/nginx/client_temp && \
    chown -R nginx:nginx /var/cache/nginx

EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]
DOCKERFILE

echo "✅ Dockerfile do Nginx criado"

# ==========================================
# 3. NGINX CONFIGURATION
# ==========================================
mkdir -p docker/nginx/conf.d

cat > docker/nginx/nginx.conf << 'NGINXCONF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 2048;
    use epoll;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    # Gzip
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript 
               application/json application/javascript application/xml+rss;

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;

    include /etc/nginx/conf.d/*.conf;
}
NGINXCONF

cat > docker/nginx/conf.d/api.conf << 'APICONF'
upstream api_backend {
    least_conn;
    server api:3000 max_fails=3 fail_timeout=30s;
    keepalive 32;
}

server {
    listen 80;
    server_name _;

    client_max_body_size 10M;

    # Rate limiting
    limit_req zone=api_limit burst=20 nodelay;

    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }

    location /api/ {
        proxy_pass http://api_backend/;
        
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        proxy_cache_bypass $http_upgrade;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    location / {
        return 404 '{"error":"Not Found"}';
        add_header Content-Type application/json;
    }
}
APICONF

echo "✅ Configuração do Nginx criada"

# ==========================================
# 4. DOCKER COMPOSE (Desenvolvimento)
# ==========================================
cat > docker-compose.yml << 'COMPOSE'
version: '3.8'

services:
  # ==========================================
  # API Principal (Node.js)
  # ==========================================
  api:
    build:
      context: .
      dockerfile: docker/api/Dockerfile
    container_name: shaka-api
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=development
      - PORT=3000
      - DB_HOST=postgres
      - DB_PORT=5432
      - DB_NAME=${DB_NAME:-shaka_api}
      - DB_USER=${DB_USER:-shaka}
      - DB_PASSWORD=${DB_PASSWORD:-shaka123}
      - REDIS_HOST=redis
      - REDIS_PORT=6379
      - RABBITMQ_HOST=rabbitmq
      - RABBITMQ_PORT=5672
      - JWT_SECRET=${JWT_SECRET:-dev_secret_change_me}
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
      rabbitmq:
        condition: service_healthy
    volumes:
      - ./src:/app/src
      - ./node_modules:/app/node_modules
    networks:
      - shaka-network
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  # ==========================================
  # PostgreSQL Database
  # ==========================================
  postgres:
    image: postgres:16-alpine
    container_name: shaka-postgres
    restart: unless-stopped
    ports:
      - "5432:5432"
    environment:
      - POSTGRES_DB=${DB_NAME:-shaka_api}
      - POSTGRES_USER=${DB_USER:-shaka}
      - POSTGRES_PASSWORD=${DB_PASSWORD:-shaka123}
      - PGDATA=/var/lib/postgresql/data/pgdata
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./scripts/init-db.sql:/docker-entrypoint-initdb.d/init.sql
    networks:
      - shaka-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER:-shaka} -d ${DB_NAME:-shaka_api}"]
      interval: 10s
      timeout: 5s
      retries: 5

  # ==========================================
  # Redis Cache
  # ==========================================
  redis:
    image: redis:7-alpine
    container_name: shaka-redis
    restart: unless-stopped
    ports:
      - "6379:6379"
    command: redis-server --appendonly yes --requirepass ${REDIS_PASSWORD:-}
    volumes:
      - redis_data:/data
    networks:
      - shaka-network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 5

  # ==========================================
  # RabbitMQ Message Queue
  # ==========================================
  rabbitmq:
    image: rabbitmq:3-management-alpine
    container_name: shaka-rabbitmq
    restart: unless-stopped
    ports:
      - "5672:5672"
      - "15672:15672"
    environment:
      - RABBITMQ_DEFAULT_USER=${RABBITMQ_USER:-shaka}
      - RABBITMQ_DEFAULT_PASS=${RABBITMQ_PASSWORD:-shaka123}
    volumes:
      - rabbitmq_data:/var/lib/rabbitmq
    networks:
      - shaka-network
    healthcheck:
      test: ["CMD", "rabbitmq-diagnostics", "ping"]
      interval: 30s
      timeout: 10s
      retries: 5

  # ==========================================
  # Nginx Load Balancer
  # ==========================================
  nginx:
    build:
      context: docker/nginx
      dockerfile: Dockerfile
    container_name: shaka-nginx
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    depends_on:
      - api
    volumes:
      - ./docker/nginx/conf.d:/etc/nginx/conf.d:ro
    networks:
      - shaka-network
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost/health"]
      interval: 30s
      timeout: 5s
      retries: 3

  # ==========================================
  # Prometheus (Monitoring)
  # ==========================================
  prometheus:
    image: prom/prometheus:latest
    container_name: shaka-prometheus
    restart: unless-stopped
    ports:
      - "9090:9090"
    volumes:
      - ./monitoring/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/usr/share/prometheus/console_libraries'
      - '--web.console.templates=/usr/share/prometheus/consoles'
    networks:
      - shaka-network

  # ==========================================
  # Grafana (Visualization)
  # ==========================================
  grafana:
    image: grafana/grafana:latest
    container_name: shaka-grafana
    restart: unless-stopped
    ports:
      - "3001:3000"
    environment:
      - GF_SECURITY_ADMIN_USER=${GRAFANA_USER:-admin}
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_PASSWORD:-admin123}
      - GF_INSTALL_PLUGINS=grafana-clock-panel
    volumes:
      - grafana_data:/var/lib/grafana
      - ./monitoring/grafana/provisioning:/etc/grafana/provisioning:ro
    depends_on:
      - prometheus
    networks:
      - shaka-network

# ==========================================
# Networks
# ==========================================
networks:
  shaka-network:
    driver: bridge

# ==========================================
# Volumes
# ==========================================
volumes:
  postgres_data:
    driver: local
  redis_data:
    driver: local
  rabbitmq_data:
    driver: local
  prometheus_data:
    driver: local
  grafana_data:
    driver: local
COMPOSE

echo "✅ docker-compose.yml criado"

# ==========================================
# 5. .dockerignore
# ==========================================
cat > .dockerignore << 'DOCKERIGNORE'
node_modules
npm-debug.log
.git
.gitignore
README.md
.env
.env.*
dist
coverage
.vscode
.idea
*.log
tmp
temp
tests
docs
k8s
monitoring
scripts
.github
.gitlab-ci
DOCKERIGNORE

echo "✅ .dockerignore criado"

# ==========================================
# 6. package.json
# ==========================================
cat > package.json << 'PACKAGE'
{
  "name": "shaka-api",
  "version": "1.0.0",
  "description": "API robusta multi-tenant com motorização híbrida",
  "main": "dist/server.js",
  "scripts": {
    "dev": "ts-node-dev --respawn --transpile-only src/server.ts",
    "build": "tsc",
    "start": "node dist/server.js",
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage",
    "lint": "eslint src --ext .ts",
    "format": "prettier --write \"src/**/*.ts\""
  },
  "keywords": ["api", "microservices", "kubernetes"],
  "author": "Shaka Team",
  "license": "MIT",
  "dependencies": {
    "express": "^4.18.2",
    "dotenv": "^16.3.1",
    "pg": "^8.11.3",
    "redis": "^4.6.10",
    "amqplib": "^0.10.3",
    "jsonwebtoken": "^9.0.2",
    "bcryptjs": "^2.4.3",
    "joi": "^17.11.0",
    "winston": "^3.11.0",
    "express-rate-limit": "^7.1.5",
    "helmet": "^7.1.0",
    "cors": "^2.8.5",
    "compression": "^1.7.4"
  },
  "devDependencies": {
    "@types/express": "^4.17.21",
    "@types/node": "^20.10.5",
    "typescript": "^5.3.3",
    "ts-node-dev": "^2.0.0",
    "jest": "^29.7.0",
    "@types/jest": "^29.5.11",
    "eslint": "^8.56.0",
    "prettier": "^3.1.1"
  }
}
PACKAGE

echo "✅ package.json criado"

# ==========================================
# 7. tsconfig.json
# ==========================================
cat > tsconfig.json << 'TSCONFIG'
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "commonjs",
    "lib": ["ES2022"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "moduleResolution": "node",
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "removeComments": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "tests"]
}
TSCONFIG

echo "✅ tsconfig.json criado"

# ==========================================
# 8. Script de inicialização do DB
# ==========================================
mkdir -p scripts
cat > scripts/init-db.sql << 'SQL'
-- Shaka API - Inicialização do Banco de Dados

-- Extensões
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Schema principal
CREATE SCHEMA IF NOT EXISTS shaka;

-- Tabela de usuários
CREATE TABLE IF NOT EXISTS shaka.users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    plan VARCHAR(50) NOT NULL DEFAULT 'starter',
    status VARCHAR(50) NOT NULL DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabela de API Keys
CREATE TABLE IF NOT EXISTS shaka.api_keys (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES shaka.users(id) ON DELETE CASCADE,
    key_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    last_used_at TIMESTAMP,
    expires_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(key_hash)
);

-- Tabela de uso da API (rate limiting)
CREATE TABLE IF NOT EXISTS shaka.api_usage (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES shaka.users(id) ON DELETE CASCADE,
    endpoint VARCHAR(255) NOT NULL,
    method VARCHAR(10) NOT NULL,
    status_code INTEGER NOT NULL,
    response_time_ms INTEGER NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices para performance
CREATE INDEX idx_users_email ON shaka.users(email);
CREATE INDEX idx_users_plan ON shaka.users(plan);
CREATE INDEX idx_api_keys_user ON shaka.api_keys(user_id);
CREATE INDEX idx_api_usage_user_timestamp ON shaka.api_usage(user_id, timestamp);
CREATE INDEX idx_api_usage_timestamp ON shaka.api_usage(timestamp);

-- Inserir usuário de teste
INSERT INTO shaka.users (email, password_hash, full_name, plan)
VALUES ('admin@shaka.api', crypt('admin123', gen_salt('bf')), 'Admin User', 'business')
ON CONFLICT (email) DO NOTHING;

COMMENT ON SCHEMA shaka IS 'Schema principal da Shaka API';
SQL

echo "✅ Script de inicialização do DB criado"

echo ""
echo "================================================"
echo "✅ CONFIGURAÇÃO DOCKER COMPLETA!"
echo "================================================"
echo ""
echo "📁 Arquivos criados:"
echo "   - docker/api/Dockerfile"
echo "   - docker/nginx/Dockerfile"
echo "   - docker/nginx/nginx.conf"
echo "   - docker/nginx/conf.d/api.conf"
echo "   - docker-compose.yml"
echo "   - .dockerignore"
echo "   - package.json"
echo "   - tsconfig.json"
echo "   - scripts/init-db.sql"
echo ""
echo "🚀 Próximos passos:"
echo "   1. Copie .env.example para .env"
echo "   2. Execute: npm install"
echo "   3. Execute: make dev"
echo ""
