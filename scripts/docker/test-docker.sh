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
