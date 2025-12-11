#!/bin/bash

# ============================================================================
# Docker Start Script
# ============================================================================

set -e

MODE="${1:-dev}"

echo "🐳 Iniciando Shaka API em modo: $MODE"
echo ""

if [ "$MODE" = "prod" ]; then
    echo "🚀 Modo PRODUCTION"
    
    # Verificar se .env existe
    if [ ! -f ".env" ]; then
        echo "❌ Erro: Arquivo .env não encontrado"
        echo "   Copie .env.docker para .env e configure as variáveis"
        exit 1
    fi
    
    # Build e start production
    docker-compose -f docker-compose.prod.yml build --no-cache
    docker-compose -f docker-compose.prod.yml up -d
    
    echo ""
    echo "✅ Containers iniciados em modo PRODUCTION"
    
else
    echo "🔧 Modo DEVELOPMENT"
    
    # Usar .env.docker se .env não existir
    if [ ! -f ".env" ]; then
        echo "⚠️  .env não encontrado, usando .env.docker"
        cp .env.docker .env
    fi
    
    # Build e start development
    docker-compose build
    docker-compose up -d
    
    echo ""
    echo "✅ Containers iniciados em modo DEVELOPMENT"
fi

echo ""
echo "📊 Status dos containers:"
docker-compose ps

echo ""
echo "📝 Para ver logs em tempo real:"
echo "   docker-compose logs -f api"
echo ""
echo "🔗 Endpoints disponíveis:"
echo "   API:        http://localhost:3000"
echo "   Health:     http://localhost:3000/health"
echo "   PostgreSQL: localhost:5432"
echo "   Redis:      localhost:6379"
