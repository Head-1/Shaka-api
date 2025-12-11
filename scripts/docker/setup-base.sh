#!/bin/bash

# ============================================================================
# SCRIPT 41 - DOCKER CLEAN SETUP
# ============================================================================
# Descrição: Reconstruir estrutura Docker do zero (production-ready)
# Autor: CTO Integrador
# Data: 27/11/2025
# Fase: 8 - Containerization
# ============================================================================

set -e

echo "============================================================================"
echo "🐳 SCRIPT 41 - DOCKER CLEAN SETUP"
echo "============================================================================"
echo "Objetivo: Reconstruir estrutura Docker otimizada"
echo "Tempo estimado: 15 minutos"
echo ""

# ============================================================================
# PASSO 1: BACKUP E LIMPEZA
# ============================================================================
echo "📦 [1/7] Fazendo backup da estrutura antiga..."

# Criar diretório de backup
mkdir -p backup/docker-old-$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="backup/docker-old-$(date +%Y%m%d-%H%M%S)"

# Backup dos arquivos existentes
if [ -f "docker-compose.yml" ]; then
    cp docker-compose.yml "$BACKUP_DIR/"
    echo "   ✅ Backup: docker-compose.yml"
fi

if [ -d "docker" ]; then
    cp -r docker "$BACKUP_DIR/"
    echo "   ✅ Backup: docker/"
fi

echo "   📁 Backup salvo em: $BACKUP_DIR"
echo ""

# ============================================================================
# PASSO 2: CRIAR .dockerignore
# ============================================================================
echo "📝 [2/7] Criando .dockerignore otimizado..."

cat > .dockerignore << 'EOF'
# Dependências
node_modules
npm-debug.log
yarn-error.log

# Ambiente
.env
.env.*
!.env.example

# Build
dist
build
*.log

# Testes
coverage
tests
*.test.ts
*.spec.ts

# Git
.git
.gitignore
.gitattributes

# Docker
docker-compose*.yml
Dockerfile
.dockerignore

# IDE
.vscode
.idea
*.swp
*.swo

# Documentação
docs
README.md
*.md

# CI/CD
.github
.gitlab-ci.yml

# Outros
backup
scripts
k8s
monitoring
EOF

echo "   ✅ .dockerignore criado"
echo ""

# ============================================================================
# PASSO 3: CRIAR DOCKERFILE MULTI-STAGE OTIMIZADO
# ============================================================================
echo "🏗️  [3/7] Criando Dockerfile multi-stage..."

mkdir -p docker/api

cat > docker/api/Dockerfile << 'EOF'
# ============================================================================
# Stage 1: Builder (Dependências + Build)
# ============================================================================
FROM node:20-alpine AS builder

WORKDIR /app

# Instalar dependências de sistema para build
RUN apk add --no-cache \
    python3 \
    make \
    g++ \
    curl

# Copiar package files
COPY package*.json ./
COPY tsconfig.json ./

# Instalar TODAS as dependências (incluindo devDependencies para build)
RUN npm ci && npm cache clean --force

# Copiar código fonte
COPY src ./src

# Build TypeScript
RUN npm run build

# Remover devDependencies após build
RUN npm prune --production

# ============================================================================
# Stage 2: Runtime (Produção)
# ============================================================================
FROM node:20-alpine

WORKDIR /app

# Instalar apenas curl para healthcheck
RUN apk add --no-cache curl

# Criar usuário não-root para segurança
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Copiar node_modules de produção
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules

# Copiar build compilado
COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist

# Copiar package.json (necessário para runtime)
COPY --from=builder --chown=nodejs:nodejs /app/package*.json ./

# Variáveis de ambiente padrão
ENV NODE_ENV=production
ENV PORT=3000

# Expor porta
EXPOSE 3000

# Usar usuário não-root
USER nodejs

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

# Comando de inicialização
CMD ["node", "dist/server.js"]
EOF

echo "   ✅ Dockerfile criado: docker/api/Dockerfile"
echo ""

# ============================================================================
# PASSO 4: CRIAR WAIT-FOR SCRIPT
# ============================================================================
echo "⏰ [4/7] Criando wait-for.sh script..."

cat > docker/api/wait-for.sh << 'EOF'
#!/bin/sh
# wait-for.sh - Aguardar serviços estarem prontos

set -e

host="$1"
shift
cmd="$@"

until nc -z "$host" 5432; do
  >&2 echo "PostgreSQL não está pronto - aguardando..."
  sleep 1
done

>&2 echo "PostgreSQL está pronto - executando comando"
exec $cmd
EOF

chmod +x docker/api/wait-for.sh

echo "   ✅ wait-for.sh criado"
echo ""

# ============================================================================
# PASSO 5: CRIAR docker-compose.yml SIMPLIFICADO
# ============================================================================
echo "🐋 [5/7] Criando docker-compose.yml otimizado..."

cat > docker-compose.yml << 'EOF'
version: '3.8'

# ============================================================================
# SHAKA API - DOCKER COMPOSE
# ============================================================================
# Descrição: Ambiente de desenvolvimento completo
# Serviços: API + PostgreSQL + Redis
# ============================================================================

services:
  # ==========================================================================
  # API (Node.js + TypeScript)
  # ==========================================================================
  api:
    build:
      context: .
      dockerfile: docker/api/Dockerfile
      target: builder  # Usar stage builder para dev
    container_name: shaka-api
    restart: unless-stopped
    ports:
      - "${APP_PORT:-3000}:3000"
    environment:
      # Application
      - NODE_ENV=${NODE_ENV:-development}
      - APP_NAME=${APP_NAME:-shaka-api}
      - APP_PORT=3000
      - API_VERSION=${API_VERSION:-v1}
      
      # Database
      - DB_HOST=postgres
      - DB_PORT=5432
      - DB_NAME=${DB_NAME:-shaka_api}
      - DB_USER=${DB_USER:-shaka}
      - DB_PASSWORD=${DB_PASSWORD:-shaka123}
      
      # Redis
      - REDIS_HOST=redis
      - REDIS_PORT=6379
      - REDIS_PASSWORD=${REDIS_PASSWORD:-}
      - REDIS_DB=${REDIS_DB:-0}
      
      # JWT
      - JWT_SECRET=${JWT_SECRET:-dev_secret_change_in_production}
      - JWT_EXPIRES_IN=${JWT_EXPIRES_IN:-24h}
      
      # Rate Limiting
      - RATE_LIMIT_STARTER=${RATE_LIMIT_STARTER:-100}
      - RATE_LIMIT_PRO=${RATE_LIMIT_PRO:-1000}
      - RATE_LIMIT_BUSINESS=${RATE_LIMIT_BUSINESS:-10000}
    
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    
    volumes:
      # Hot reload em desenvolvimento
      - ./src:/app/src:ro
      - ./dist:/app/dist
      - /app/node_modules  # Named volume para node_modules
    
    networks:
      - shaka-network
    
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    
    command: npm run dev

  # ==========================================================================
  # PostgreSQL 15 (Database)
  # ==========================================================================
  postgres:
    image: postgres:15-alpine
    container_name: shaka-postgres
    restart: unless-stopped
    ports:
      - "${DB_PORT:-5432}:5432"
    environment:
      - POSTGRES_DB=${DB_NAME:-shaka_api}
      - POSTGRES_USER=${DB_USER:-shaka}
      - POSTGRES_PASSWORD=${DB_PASSWORD:-shaka123}
      - PGDATA=/var/lib/postgresql/data/pgdata
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - shaka-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER:-shaka} -d ${DB_NAME:-shaka_api}"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 10s

  # ==========================================================================
  # Redis 7 (Cache)
  # ==========================================================================
  redis:
    image: redis:7-alpine
    container_name: shaka-redis
    restart: unless-stopped
    ports:
      - "${REDIS_PORT:-6379}:6379"
    command: >
      sh -c "redis-server 
      --appendonly yes 
      --requirepass '${REDIS_PASSWORD:-}'"
    volumes:
      - redis_data:/data
    networks:
      - shaka-network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 5
      start_period: 5s

# ============================================================================
# Networks
# ============================================================================
networks:
  shaka-network:
    driver: bridge
    name: shaka-network

# ============================================================================
# Volumes Persistentes
# ============================================================================
volumes:
  postgres_data:
    name: shaka-postgres-data
  redis_data:
    name: shaka-redis-data
EOF

echo "   ✅ docker-compose.yml criado"
echo ""

# ============================================================================
# PASSO 6: CRIAR docker-compose.prod.yml
# ============================================================================
echo "🚀 [6/7] Criando docker-compose.prod.yml..."

cat > docker-compose.prod.yml << 'EOF'
version: '3.8'

# ============================================================================
# SHAKA API - PRODUCTION COMPOSE
# ============================================================================
# Descrição: Ambiente de produção otimizado
# Diferenças: Sem hot reload, security hardened, resource limits
# ============================================================================

services:
  api:
    build:
      context: .
      dockerfile: docker/api/Dockerfile
      target: runtime  # Stage de produção
    container_name: shaka-api-prod
    restart: always
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - APP_NAME=shaka-api
      - APP_PORT=3000
      - API_VERSION=v1
      - DB_HOST=postgres
      - DB_PORT=5432
      - DB_NAME=${DB_NAME}
      - DB_USER=${DB_USER}
      - DB_PASSWORD=${DB_PASSWORD}
      - REDIS_HOST=redis
      - REDIS_PORT=6379
      - REDIS_PASSWORD=${REDIS_PASSWORD}
      - REDIS_DB=0
      - JWT_SECRET=${JWT_SECRET}
      - JWT_EXPIRES_IN=24h
      - RATE_LIMIT_STARTER=100
      - RATE_LIMIT_PRO=1000
      - RATE_LIMIT_BUSINESS=10000
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    networks:
      - shaka-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 512M
        reservations:
          cpus: '0.5'
          memory: 256M
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  postgres:
    image: postgres:15-alpine
    container_name: shaka-postgres-prod
    restart: always
    ports:
      - "5432:5432"
    environment:
      - POSTGRES_DB=${DB_NAME}
      - POSTGRES_USER=${DB_USER}
      - POSTGRES_PASSWORD=${DB_PASSWORD}
      - PGDATA=/var/lib/postgresql/data/pgdata
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - shaka-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER} -d ${DB_NAME}"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 10s
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 512M

  redis:
    image: redis:7-alpine
    container_name: shaka-redis-prod
    restart: always
    ports:
      - "6379:6379"
    command: >
      sh -c "redis-server 
      --appendonly yes 
      --requirepass '${REDIS_PASSWORD}'"
    volumes:
      - redis_data:/data
    networks:
      - shaka-network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 5
      start_period: 5s
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 256M
        reservations:
          cpus: '0.25'
          memory: 128M

networks:
  shaka-network:
    driver: bridge
    name: shaka-network-prod

volumes:
  postgres_data:
    name: shaka-postgres-data-prod
  redis_data:
    name: shaka-redis-data-prod
EOF

echo "   ✅ docker-compose.prod.yml criado"
echo ""

# ============================================================================
# PASSO 7: CRIAR .env.docker
# ============================================================================
echo "🔐 [7/7] Criando .env.docker..."

cat > .env.docker << 'EOF'
# ============================================================================
# SHAKA API - DOCKER ENVIRONMENT
# ============================================================================
# Arquivo de configuração para uso com Docker Compose
# Copie para .env e ajuste os valores conforme necessário
# ============================================================================

# Application
NODE_ENV=development
APP_NAME=shaka-api
APP_PORT=3000
API_VERSION=v1

# Database (PostgreSQL)
DB_HOST=postgres
DB_PORT=5432
DB_NAME=shaka_api
DB_USER=shaka
DB_PASSWORD=shaka123_change_in_production

# Redis
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=
REDIS_DB=0

# JWT
JWT_SECRET=your_super_secret_jwt_key_change_in_production
JWT_EXPIRES_IN=24h

# Rate Limiting (requisições por hora por plano)
RATE_LIMIT_STARTER=100
RATE_LIMIT_PRO=1000
RATE_LIMIT_BUSINESS=10000
EOF

echo "   ✅ .env.docker criado"
echo ""

# ============================================================================
# VALIDAÇÃO FINAL
# ============================================================================
echo "============================================================================"
echo "✅ SCRIPT 41 CONCLUÍDO COM SUCESSO!"
echo "============================================================================"
echo ""
echo "📦 Arquivos criados:"
echo "   ✅ .dockerignore"
echo "   ✅ docker/api/Dockerfile (multi-stage)"
echo "   ✅ docker/api/wait-for.sh"
echo "   ✅ docker-compose.yml (development)"
echo "   ✅ docker-compose.prod.yml (production)"
echo "   ✅ .env.docker (environment template)"
echo ""
echo "📁 Backup salvo em: $BACKUP_DIR"
echo ""
echo "🎯 Próximo passo:"
echo "   Execute: bash scripts/docker/setup-services.sh (Script 42)"
echo ""
echo "============================================================================"
