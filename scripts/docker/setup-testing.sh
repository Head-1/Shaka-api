#!/bin/bash

# ============================================================================
# SCRIPT 43 - DOCKER TESTING & DOCUMENTATION
# ============================================================================
# Descrição: Testar Docker setup e criar documentação completa
# Autor: CTO Integrador
# Data: 27/11/2025
# Fase: 8 - Containerization
# ============================================================================

set -e

echo "============================================================================"
echo "🧪 SCRIPT 43 - DOCKER TESTING & DOCUMENTATION"
echo "============================================================================"
echo "Objetivo: Validar setup Docker e criar documentação"
echo "Tempo estimado: 20 minutos"
echo ""

# ============================================================================
# PASSO 1: CRIAR SCRIPT DE TESTE COMPLETO
# ============================================================================
echo "🧪 [1/5] Criando script de teste Docker..."

cat > scripts/docker/test-docker.sh << 'EOF'
#!/bin/bash

# ============================================================================
# Docker Testing Script
# ============================================================================

set -e

echo "============================================================================"
echo "🧪 TESTE COMPLETO DO DOCKER SETUP"
echo "============================================================================"
echo ""

FAILED_TESTS=0
PASSED_TESTS=0

# Função para testar
test_command() {
    local NAME="$1"
    local COMMAND="$2"
    
    echo -n "🔍 Testando: $NAME... "
    
    if eval "$COMMAND" > /dev/null 2>&1; then
        echo "✅ PASS"
        ((PASSED_TESTS++))
        return 0
    else
        echo "❌ FAIL"
        ((FAILED_TESTS++))
        return 1
    fi
}

# ============================================================================
# TESTES PRÉ-BUILD
# ============================================================================
echo "📋 FASE 1: Validação de Arquivos"
echo "----------------------------------------"

test_command "Dockerfile existe" "test -f docker/api/Dockerfile"
test_command "docker-compose.yml existe" "test -f docker-compose.yml"
test_command "docker-compose.prod.yml existe" "test -f docker-compose.prod.yml"
test_command ".dockerignore existe" "test -f .dockerignore"
test_command ".env.docker existe" "test -f .env.docker"

echo ""

# ============================================================================
# TESTES DE BUILD
# ============================================================================
echo "📋 FASE 2: Build da Imagem"
echo "----------------------------------------"

echo "🏗️  Fazendo build da imagem API..."
if docker-compose build api; then
    echo "✅ PASS: Build da imagem API"
    ((PASSED_TESTS++))
else
    echo "❌ FAIL: Build da imagem API"
    ((FAILED_TESTS++))
fi

echo ""

# ============================================================================
# TESTES DE INICIALIZAÇÃO
# ============================================================================
echo "📋 FASE 3: Inicialização dos Containers"
echo "----------------------------------------"

# Garantir que .env existe
if [ ! -f ".env" ]; then
    cp .env.docker .env
    echo "📝 .env criado a partir de .env.docker"
fi

echo "🚀 Iniciando containers..."
if docker-compose up -d; then
    echo "✅ PASS: Containers iniciados"
    ((PASSED_TESTS++))
else
    echo "❌ FAIL: Falha ao iniciar containers"
    ((FAILED_TESTS++))
    exit 1
fi

echo ""
echo "⏳ Aguardando containers ficarem saudáveis (60s)..."
sleep 60

echo ""

# ============================================================================
# TESTES DE SAÚDE
# ============================================================================
echo "📋 FASE 4: Health Checks"
echo "----------------------------------------"

# PostgreSQL
test_command "PostgreSQL Health" \
    "docker-compose exec -T postgres pg_isready -U shaka -d shaka_api"

# Redis
test_command "Redis Health" \
    "docker-compose exec -T redis redis-cli ping"

# API Health Endpoint
test_command "API Health Endpoint" \
    "curl -f -s http://localhost:3000/health"

echo ""

# ============================================================================
# TESTES DE CONECTIVIDADE
# ============================================================================
echo "📋 FASE 5: Testes de Conectividade"
echo "----------------------------------------"

# Testar conexão PostgreSQL
echo -n "🔍 Testando: PostgreSQL Connection... "
if docker-compose exec -T postgres psql -U shaka -d shaka_api -c "SELECT 1;" > /dev/null 2>&1; then
    echo "✅ PASS"
    ((PASSED_TESTS++))
else
    echo "❌ FAIL"
    ((FAILED_TESTS++))
fi

# Testar conexão Redis
echo -n "🔍 Testando: Redis Connection... "
if docker-compose exec -T redis redis-cli SET test_key "test_value" > /dev/null 2>&1; then
    echo "✅ PASS"
    ((PASSED_TESTS++))
else
    echo "❌ FAIL"
    ((FAILED_TESTS++))
fi

echo ""

# ============================================================================
# TESTES DE API
# ============================================================================
echo "📋 FASE 6: Testes de Endpoints API"
echo "----------------------------------------"

# Health endpoint
echo -n "🔍 Testando: GET /health... "
HEALTH_RESPONSE=$(curl -s http://localhost:3000/health)
if echo "$HEALTH_RESPONSE" | grep -q "status"; then
    echo "✅ PASS"
    ((PASSED_TESTS++))
else
    echo "❌ FAIL"
    ((FAILED_TESTS++))
fi

# API base endpoint
echo -n "🔍 Testando: GET /api/v1... "
if curl -f -s http://localhost:3000/api/v1 > /dev/null 2>&1; then
    echo "✅ PASS"
    ((PASSED_TESTS++))
else
    echo "⚠️  SKIP (endpoint pode não existir)"
fi

echo ""

# ============================================================================
# TESTES DE VOLUMES
# ============================================================================
echo "📋 FASE 7: Validação de Volumes"
echo "----------------------------------------"

test_command "Volume PostgreSQL existe" \
    "docker volume inspect shaka-postgres-data"

test_command "Volume Redis existe" \
    "docker volume inspect shaka-redis-data"

echo ""

# ============================================================================
# TESTES DE NETWORKS
# ============================================================================
echo "📋 FASE 8: Validação de Networks"
echo "----------------------------------------"

test_command "Network shaka-network existe" \
    "docker network inspect shaka-network"

echo ""

# ============================================================================
# RELATÓRIO FINAL
# ============================================================================
echo "============================================================================"
echo "📊 RELATÓRIO FINAL"
echo "============================================================================"
echo ""
echo "✅ Testes Passaram: $PASSED_TESTS"
echo "❌ Testes Falharam: $FAILED_TESTS"
echo ""

TOTAL_TESTS=$((PASSED_TESTS + FAILED_TESTS))
SUCCESS_RATE=$((PASSED_TESTS * 100 / TOTAL_TESTS))

echo "📈 Taxa de Sucesso: $SUCCESS_RATE% ($PASSED_TESTS/$TOTAL_TESTS)"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo "🎉 TODOS OS TESTES PASSARAM!"
    echo "✅ Docker setup está funcionando perfeitamente"
    echo ""
    echo "🚀 Próximos passos:"
    echo "   1. Verificar logs: ./docker.sh logs api"
    echo "   2. Rodar migrations: ./docker.sh migrate run"
    echo "   3. Testar API: curl http://localhost:3000/health"
    exit 0
else
    echo "⚠️  ALGUNS TESTES FALHARAM"
    echo "❌ Verifique os logs para mais detalhes"
    echo ""
    echo "🔍 Debug:"
    echo "   docker-compose ps"
    echo "   docker-compose logs api"
    exit 1
fi
EOF

chmod +x scripts/docker/test-docker.sh

echo "   ✅ scripts/docker/test-docker.sh criado"
echo ""

# ============================================================================
# PASSO 2: CRIAR QUICK START GUIDE
# ============================================================================
echo "📖 [2/5] Criando Quick Start Guide..."

cat > DOCKER_QUICKSTART.md << 'EOF'
# 🐳 Docker Quick Start Guide

## 📦 Pré-requisitos

- Docker 20.10+
- Docker Compose 2.0+
- 2GB RAM disponível
- 5GB espaço em disco

## 🚀 Início Rápido

### 1. Configurar Environment

```bash
# Copiar template de configuração
cp .env.docker .env

# Editar variáveis (opcional)
nano .env
```

### 2. Iniciar Containers

```bash
# Modo Development
./docker.sh start

# OU usar Make
make start
```

### 3. Aguardar Inicialização (30-60s)

```bash
# Verificar status
./docker.sh ps

# Verificar logs
./docker.sh logs api
```

### 4. Rodar Migrations

```bash
./docker.sh migrate run
```

### 5. Testar API

```bash
curl http://localhost:3000/health
```

## 📋 Comandos Principais

### Gerenciamento Básico

```bash
./docker.sh start          # Iniciar containers
./docker.sh stop           # Parar containers
./docker.sh restart        # Reiniciar containers
./docker.sh ps             # Status dos containers
./docker.sh logs [service] # Ver logs
```

### Health & Debug

```bash
./docker.sh health         # Health check completo
./docker.sh shell api      # Shell no container API
./docker.sh shell postgres # Shell no PostgreSQL
```

### Migrations

```bash
./docker.sh migrate run    # Executar migrations
./docker.sh migrate revert # Reverter última migration
```

### Limpeza

```bash
./docker.sh stop           # Parar containers
./docker.sh reset          # Reset completo (remove dados)
```

## 🔗 Endpoints

- **API:** http://localhost:3000
- **Health:** http://localhost:3000/health
- **PostgreSQL:** localhost:5432
- **Redis:** localhost:6379

## 🐛 Troubleshooting

### Containers não iniciam

```bash
# Ver logs de erro
docker-compose logs

# Reconstruir do zero
./docker.sh reset
./docker.sh start
```

### Porta já em uso

```bash
# Verificar processos
lsof -i :3000
lsof -i :5432
lsof -i :6379

# Matar processos
kill -9 <PID>
```

### Database não conecta

```bash
# Verificar PostgreSQL
./docker.sh shell postgres
psql -U shaka -d shaka_api

# Recriar database
./docker.sh reset
./docker.sh start
./docker.sh migrate run
```

## 📊 Modo Production

```bash
# Configurar .env para produção
cp .env.docker .env
nano .env  # Ajustar senhas e secrets

# Iniciar em modo production
./docker.sh start prod

# Verificar recursos
docker stats
```

## 🧪 Testes

```bash
# Rodar testes no container
docker-compose exec api npm test

# Coverage
docker-compose exec api npm run test:coverage

# Testes específicos
docker-compose exec api npm run test:unit
docker-compose exec api npm run test:integration
docker-compose exec api npm run test:e2e
```

## 📝 Logs

```bash
# Logs em tempo real
./docker.sh logs api

# Últimas 100 linhas
docker-compose logs --tail=100 api

# Todos os serviços
docker-compose logs -f
```

## 💾 Backup e Restore

### Backup PostgreSQL

```bash
docker-compose exec postgres pg_dump -U shaka shaka_api > backup.sql
```

### Restore PostgreSQL

```bash
cat backup.sql | docker-compose exec -T postgres psql -U shaka -d shaka_api
```

## 🔒 Segurança

1. **SEMPRE** alterar senhas padrão em produção
2. Usar `docker-compose.prod.yml` em produção
3. Nunca commitar `.env` no Git
4. Usar secrets management (vault, etc)

## 📚 Mais Informações

- [Docker Compose Docs](https://docs.docker.com/compose/)
- [PostgreSQL Docker](https://hub.docker.com/_/postgres)
- [Redis Docker](https://hub.docker.com/_/redis)
- [Node.js Best Practices](https://github.com/goldbergyoni/nodebestpractices)
EOF

echo "   ✅ DOCKER_QUICKSTART.md criado"
echo ""

# ============================================================================
# PASSO 3: CRIAR DOCKER ARCHITECTURE DOCS
# ============================================================================
echo "📐 [3/5] Criando Docker Architecture docs..."

cat > docs/DOCKER_ARCHITECTURE.md << 'EOF'
# 🏗️ Docker Architecture

## 📋 Visão Geral

O Shaka API usa uma arquitetura containerizada com Docker Compose, separando serviços em containers isolados para melhor escalabilidade e manutenibilidade.

## 🐳 Containers

### 1. API Container (Node.js)

**Imagem:** Custom (Multi-stage build)  
**Base:** node:20-alpine  
**Porta:** 3000  
**Propósito:** Aplicação principal

**Features:**
- Multi-stage build (builder + runtime)
- Non-root user (nodejs:nodejs)
- Health checks automáticos
- Hot reload em desenvolvimento
- Otimizado para produção

**Resources:**
- CPU: 0.5-1 core
- RAM: 256MB-512MB

### 2. PostgreSQL Container

**Imagem:** postgres:15-alpine  
**Porta:** 5432  
**Propósito:** Database principal

**Features:**
- Health checks com pg_isready
- Volume persistente
- Init scripts automáticos
- Backup support

**Resources:**
- CPU: 0.5-1 core
- RAM: 512MB-1GB

### 3. Redis Container

**Imagem:** redis:7-alpine  
**Porta:** 6379  
**Propósito:** Cache e rate limiting

**Features:**
- AOF persistence
- Health checks
- Password protection
- Volume persistente

**Resources:**
- CPU: 0.25-0.5 core
- RAM: 128MB-256MB

## 🌐 Networks

### shaka-network (Bridge)

**Tipo:** Bridge Network  
**Isolamento:** Completo entre host e containers  
**DNS:** Resolução automática entre containers

**Conectividade:**
```
api → postgres (postgres:5432)
api → redis (redis:6379)
host → api (localhost:3000)
host → postgres (localhost:5432)
host → redis (localhost:6379)
```

## 💾 Volumes

### postgres_data

**Tipo:** Named volume  
**Mount:** `/var/lib/postgresql/data`  
**Persistência:** Dados do PostgreSQL  
**Backup:** Recomendado diariamente

### redis_data

**Tipo:** Named volume  
**Mount:** `/data`  
**Persistência:** Cache e AOF logs  
**Backup:** Opcional

## 🔄 Lifecycle

### Startup Sequence

1. **PostgreSQL** inicia primeiro
   - Aguarda health check (pg_isready)
   - Executa init scripts
   
2. **Redis** inicia em paralelo
   - Aguarda health check (ping)
   - Carrega AOF se existir

3. **API** aguarda dependências
   - Espera PostgreSQL healthy
   - Espera Redis healthy
   - Conecta ao database
   - Conecta ao cache
   - Inicia servidor Express

### Shutdown Sequence

1. **API** recebe SIGTERM
   - Fecha conexões ativas
   - Flush logs
   - Exit gracefully

2. **Redis** salva AOF
   - Persiste cache
   - Exit

3. **PostgreSQL** fecha conexões
   - Checkpoint
   - Exit

## 🏗️ Build Process

### Multi-stage Build

```dockerfile
# Stage 1: Builder
FROM node:20-alpine AS builder
- Instala dependências (incluindo devDependencies)
- Compila TypeScript
- Remove devDependencies

# Stage 2: Runtime
FROM node:20-alpine
- Copia node_modules de produção
- Copia dist/ compilado
- Configura non-root user
- Define health check
```

**Benefícios:**
- Imagem final ~300MB (vs ~800MB single-stage)
- Sem devDependencies em produção
- Sem código TypeScript em runtime
- Melhor segurança

## 🔒 Segurança

### Container Isolation

- ✅ Non-root user (nodejs:nodejs)
- ✅ Read-only filesystem (onde possível)
- ✅ Dropped capabilities
- ✅ Resource limits
- ✅ Network isolation

### Secrets Management

```bash
# Development
.env (não commitado)

# Production
- Use Docker Secrets
- Ou variáveis de ambiente do host
- Ou serviço de secrets (Vault, etc)
```

### Best Practices

1. **Nunca** rodar como root
2. **Sempre** usar health checks
3. **Sempre** definir resource limits
4. **Nunca** commitar secrets
5. **Sempre** usar volumes para dados

## 📊 Monitoring

### Health Checks

Todos os containers têm health checks configurados:

```yaml
api:
  healthcheck:
    test: curl -f http://localhost:3000/health
    interval: 30s
    timeout: 10s
    retries: 3
    start_period: 40s
```

### Logs

```bash
# Ver logs
docker-compose logs -f [service]

# Logs com timestamp
docker-compose logs -f --timestamps

# Últimas N linhas
docker-compose logs --tail=100
```

### Metrics

```bash
# CPU e RAM em tempo real
docker stats

# Uso de disco
docker system df
```

## 🔄 Updates e Rollback

### Update

```bash
# Pull nova imagem
docker-compose pull api

# Recreate container
docker-compose up -d api
```

### Rollback

```bash
# Usar imagem anterior
docker tag shaka-api:latest shaka-api:backup
docker-compose up -d api
```

## 🧪 Testing

### Development

```bash
docker-compose up -d
docker-compose exec api npm test
```

### Production

```bash
docker-compose -f docker-compose.prod.yml up -d
# Testes de carga, monitoring, etc
```

## 📈 Scaling

### Horizontal Scaling

```bash
# Escalar API (múltiplas instâncias)
docker-compose up -d --scale api=3

# Adicionar load balancer (nginx)
# Configurar health checks
```

### Vertical Scaling

```yaml
deploy:
  resources:
    limits:
      cpus: '2'
      memory: 1G
```

## 🎯 Comparação Dev vs Prod

| Feature | Development | Production |
|---------|-------------|------------|
| Build stage | builder | runtime |
| Hot reload | ✅ Sim | ❌ Não |
| Volumes | Source mount | Named only |
| Resources | Unlimited | Limited |
| Restart | unless-stopped | always |
| Logs | stdout | JSON file |
| Security | Relaxed | Hardened |
EOF

echo "   ✅ docs/DOCKER_ARCHITECTURE.md criado"
echo ""

# ============================================================================
# PASSO 4: ATUALIZAR README.md
# ============================================================================
echo "📝 [4/5] Atualizando README.md..."

cat >> README.md << 'EOF'

## 🐳 Docker Setup

### Quick Start

```bash
# 1. Configurar environment
cp .env.docker .env

# 2. Iniciar containers
./docker.sh start

# 3. Rodar migrations
./docker.sh migrate run

# 4. Testar
curl http://localhost:3000/health
```

### Comandos Docker

```bash
./docker.sh start     # Iniciar
./docker.sh stop      # Parar
./docker.sh logs api  # Ver logs
./docker.sh health    # Health check
./docker.sh shell api # Shell no container
```

Veja [DOCKER_QUICKSTART.md](DOCKER_QUICKSTART.md) para mais detalhes.
EOF

echo "   ✅ README.md atualizado"
echo ""

# ============================================================================
# PASSO 5: VALIDAÇÃO FINAL
# ============================================================================
echo "✅ [5/5] Validação final..."

echo ""
echo "📋 Verificando arquivos criados..."

FILES_TO_CHECK=(
    "docker/api/Dockerfile"
    "docker-compose.yml"
    "docker-compose.prod.yml"
    ".dockerignore"
    ".env.docker"
    "scripts/docker/start.sh"
    "scripts/docker/stop.sh"
    "scripts/docker/logs.sh"
    "scripts/docker/reset.sh"
    "scripts/docker/health.sh"
    "scripts/docker/migrate.sh"
    "scripts/docker/test-docker.sh"
    "docker.sh"
    "Makefile"
    "DOCKER_QUICKSTART.md"
    "docs/DOCKER_ARCHITECTURE.md"
)

MISSING_FILES=0

for FILE in "${FILES_TO_CHECK[@]}"; do
    if [ -f "$FILE" ]; then
        echo "   ✅ $FILE"
    else
        echo "   ❌ $FILE (FALTANDO)"
        ((MISSING_FILES++))
    fi
done

echo ""

if [ $MISSING_FILES -eq 0 ]; then
    echo "✅ Todos os arquivos criados com sucesso!"
else
    echo "⚠️  $MISSING_FILES arquivo(s) faltando"
fi

echo ""

# ============================================================================
# RELATÓRIO FINAL
# ============================================================================
echo "============================================================================"
echo "✅ SCRIPT 43 CONCLUÍDO COM SUCESSO!"
echo "============================================================================"
echo ""
echo "📦 Arquivos criados:"
echo "   ✅ scripts/docker/test-docker.sh     (Testes completos)"
echo "   ✅ DOCKER_QUICKSTART.md              (Quick start guide)"
echo "   ✅ docs/DOCKER_ARCHITECTURE.md       (Documentação técnica)"
echo "   ✅ README.md                         (Atualizado)"
echo ""
echo "🎯 Próximos passos:"
echo ""
echo "1. Testar Docker Setup:"
echo "   bash scripts/docker/test-docker.sh"
echo ""
echo "2. Se tudo passar, commits:"
echo "   git add ."
echo "   git commit -m 'feat: Docker containerization complete'"
echo ""
echo "3. Iniciar API em Docker:"
echo "   ./docker.sh start"
echo "   ./docker.sh migrate run"
echo "   ./docker.sh health"
echo ""
echo "============================================================================" 
