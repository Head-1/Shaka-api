#!/bin/bash

# ============================================================================
# Docker Health Check Script
# ============================================================================

set -e

echo "🏥 Health Check - Shaka API"
echo "============================================================================"
echo ""

# Verificar se containers estão rodando
echo "📦 Status dos Containers:"
echo "----------------------------------------"
docker-compose ps
echo ""

# Health da API
echo "🔍 API Health Check:"
echo "----------------------------------------"
if curl -f -s http://localhost:3000/health > /dev/null 2>&1; then
    RESPONSE=$(curl -s http://localhost:3000/health)
    echo "✅ API está saudável"
    echo "$RESPONSE" | jq . 2>/dev/null || echo "$RESPONSE"
else
    echo "❌ API não está respondendo"
fi
echo ""

# Health do PostgreSQL
echo "🐘 PostgreSQL Health Check:"
echo "----------------------------------------"
if docker-compose exec -T postgres pg_isready -U shaka -d shaka_api > /dev/null 2>&1; then
    echo "✅ PostgreSQL está saudável"
    docker-compose exec -T postgres psql -U shaka -d shaka_api -c "SELECT version();" | head -n 3
else
    echo "❌ PostgreSQL não está respondendo"
fi
echo ""

# Health do Redis
echo "🔴 Redis Health Check:"
echo "----------------------------------------"
if docker-compose exec -T redis redis-cli ping > /dev/null 2>&1; then
    echo "✅ Redis está saudável"
    docker-compose exec -T redis redis-cli INFO server | grep "redis_version"
else
    echo "❌ Redis não está respondendo"
fi
echo ""

echo "============================================================================"
