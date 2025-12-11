#!/bin/bash

# ============================================================================
# SCRIPT 42 - DOCKER SERVICES & MANAGEMENT
# ============================================================================
# Descrição: Criar scripts de gestão Docker e configurações auxiliares
# Autor: CTO Integrador
# Data: 27/11/2025
# Fase: 8 - Containerization
# ============================================================================

set -e

echo "============================================================================"
echo "🛠️  SCRIPT 42 - DOCKER SERVICES & MANAGEMENT"
echo "============================================================================"
echo "Objetivo: Criar scripts de gestão e configurações"
echo "Tempo estimado: 15 minutos"
echo ""

# ============================================================================
# PASSO 1: CRIAR DIRETÓRIO DE SCRIPTS DOCKER
# ============================================================================
echo "📁 [1/8] Criando estrutura de diretórios..."

mkdir -p scripts/docker
mkdir -p docker/postgres/scripts
mkdir -p docker/redis/config

echo "   ✅ Diretórios criados"
echo ""

# ============================================================================
# PASSO 2: SCRIPT DE START
# ============================================================================
echo "🚀 [2/8] Criando script de start..."

cat > scripts/docker/start.sh << 'EOF'
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
EOF

chmod +x scripts/docker/start.sh

echo "   ✅ scripts/docker/start.sh criado"
echo ""

# ============================================================================
# PASSO 3: SCRIPT DE STOP
# ============================================================================
echo "🛑 [3/8] Criando script de stop..."

cat > scripts/docker/stop.sh << 'EOF'
#!/bin/bash

# ============================================================================
# Docker Stop Script
# ============================================================================

set -e

MODE="${1:-dev}"

echo "🛑 Parando Shaka API (modo: $MODE)"
echo ""

if [ "$MODE" = "prod" ]; then
    docker-compose -f docker-compose.prod.yml down
else
    docker-compose down
fi

echo ""
echo "✅ Containers parados com sucesso"
echo ""
echo "💡 Para remover volumes (CUIDADO: apaga dados):"
echo "   bash scripts/docker/stop.sh $MODE --volumes"
EOF

chmod +x scripts/docker/stop.sh

echo "   ✅ scripts/docker/stop.sh criado"
echo ""

# ============================================================================
# PASSO 4: SCRIPT DE LOGS
# ============================================================================
echo "📋 [4/8] Criando script de logs..."

cat > scripts/docker/logs.sh << 'EOF'
#!/bin/bash

# ============================================================================
# Docker Logs Script
# ============================================================================

SERVICE="${1:-api}"
LINES="${2:-100}"

echo "📋 Logs do serviço: $SERVICE (últimas $LINES linhas)"
echo "=================================================="
echo ""

if [ "$SERVICE" = "all" ]; then
    docker-compose logs --tail=$LINES -f
else
    docker-compose logs --tail=$LINES -f $SERVICE
fi
EOF

chmod +x scripts/docker/logs.sh

echo "   ✅ scripts/docker/logs.sh criado"
echo ""

# ============================================================================
# PASSO 5: SCRIPT DE RESET
# ============================================================================
echo "🔄 [5/8] Criando script de reset..."

cat > scripts/docker/reset.sh << 'EOF'
#!/bin/bash

# ============================================================================
# Docker Reset Script
# ============================================================================
# CUIDADO: Este script remove TODOS os dados (volumes)
# ============================================================================

set -e

echo "⚠️  ATENÇÃO: Este script vai:"
echo "   1. Parar todos os containers"
echo "   2. Remover todos os containers"
echo "   3. Remover todos os volumes (DADOS SERÃO PERDIDOS)"
echo "   4. Remover imagens do projeto"
echo ""
read -p "Tem certeza? Digite 'RESET' para confirmar: " CONFIRM

if [ "$CONFIRM" != "RESET" ]; then
    echo "❌ Operação cancelada"
    exit 1
fi

echo ""
echo "🔄 Iniciando reset completo..."
echo ""

# Parar e remover containers
echo "1️⃣  Parando containers..."
docker-compose down -v

# Remover imagens do projeto
echo "2️⃣  Removendo imagens..."
docker images | grep shaka | awk '{print $3}' | xargs -r docker rmi -f

# Remover volumes órfãos
echo "3️⃣  Limpando volumes órfãos..."
docker volume prune -f

echo ""
echo "✅ Reset completo realizado"
echo ""
echo "🚀 Para reconstruir do zero:"
echo "   bash scripts/docker/start.sh"
EOF

chmod +x scripts/docker/reset.sh

echo "   ✅ scripts/docker/reset.sh criado"
echo ""

# ============================================================================
# PASSO 6: SCRIPT DE HEALTH CHECK
# ============================================================================
echo "🏥 [6/8] Criando script de health check..."

cat > scripts/docker/health.sh << 'EOF'
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
EOF

chmod +x scripts/docker/health.sh

echo "   ✅ scripts/docker/health.sh criado"
echo ""

# ============================================================================
# PASSO 7: SCRIPT DE MIGRATIONS
# ============================================================================
echo "🗃️  [7/8] Criando script de migrations..."

cat > scripts/docker/migrate.sh << 'EOF'
#!/bin/bash

# ============================================================================
# Docker Migrations Script
# ============================================================================

set -e

ACTION="${1:-run}"

echo "🗃️  Executando migrations: $ACTION"
echo ""

case $ACTION in
    run)
        echo "▶️  Rodando migrations..."
        docker-compose exec api npm run migration:run
        echo "✅ Migrations executadas com sucesso"
        ;;
    
    revert)
        echo "◀️  Revertendo última migration..."
        docker-compose exec api npm run migration:revert
        echo "✅ Migration revertida com sucesso"
        ;;
    
    generate)
        NAME="${2:-NewMigration}"
        echo "📝 Gerando nova migration: $NAME"
        docker-compose exec api npm run migration:generate -- $NAME
        echo "✅ Migration gerada com sucesso"
        ;;
    
    *)
        echo "❌ Ação inválida: $ACTION"
        echo ""
        echo "Uso:"
        echo "   bash scripts/docker/migrate.sh run      # Executar migrations"
        echo "   bash scripts/docker/migrate.sh revert   # Reverter última"
        echo "   bash scripts/docker/migrate.sh generate <name>  # Gerar nova"
        exit 1
        ;;
esac

echo ""
echo "🔍 Status das migrations:"
docker-compose exec api npm run migration:show || true
EOF

chmod +x scripts/docker/migrate.sh

echo "   ✅ scripts/docker/migrate.sh criado"
echo ""

# ============================================================================
# PASSO 8: SCRIPT PRINCIPAL (docker.sh)
# ============================================================================
echo "🎯 [8/8] Criando script principal docker.sh..."

cat > docker.sh << 'EOF'
#!/bin/bash

# ============================================================================
# SHAKA API - DOCKER MANAGEMENT
# ============================================================================
# Script principal de gestão Docker
# ============================================================================

set -e

COMMAND="${1:-help}"
shift || true

case $COMMAND in
    start)
        bash scripts/docker/start.sh "$@"
        ;;
    
    stop)
        bash scripts/docker/stop.sh "$@"
        ;;
    
    restart)
        bash scripts/docker/stop.sh "$@"
        sleep 2
        bash scripts/docker/start.sh "$@"
        ;;
    
    logs)
        bash scripts/docker/logs.sh "$@"
        ;;
    
    health)
        bash scripts/docker/health.sh
        ;;
    
    reset)
        bash scripts/docker/reset.sh
        ;;
    
    migrate)
        bash scripts/docker/migrate.sh "$@"
        ;;
    
    shell)
        SERVICE="${1:-api}"
        echo "🐚 Abrindo shell no container: $SERVICE"
        docker-compose exec $SERVICE sh
        ;;
    
    build)
        echo "🏗️  Rebuild containers..."
        docker-compose build --no-cache
        echo "✅ Build completo"
        ;;
    
    ps)
        docker-compose ps
        ;;
    
    help|*)
        echo "🐳 SHAKA API - Docker Management"
        echo "============================================================================"
        echo ""
        echo "Comandos disponíveis:"
        echo ""
        echo "  start [dev|prod]     Iniciar containers"
        echo "  stop [dev|prod]      Parar containers"
        echo "  restart [dev|prod]   Reiniciar containers"
        echo "  logs [service]       Ver logs (default: api)"
        echo "  health               Health check completo"
        echo "  reset                Reset completo (remove dados)"
        echo "  migrate [run|revert] Gerenciar migrations"
        echo "  shell [service]      Abrir shell no container"
        echo "  build                Rebuild containers"
        echo "  ps                   Status dos containers"
        echo "  help                 Mostrar esta ajuda"
        echo ""
        echo "Exemplos:"
        echo "  ./docker.sh start              # Iniciar em modo dev"
        echo "  ./docker.sh start prod         # Iniciar em modo prod"
        echo "  ./docker.sh logs api           # Ver logs da API"
        echo "  ./docker.sh health             # Verificar saúde"
        echo "  ./docker.sh migrate run        # Rodar migrations"
        echo "  ./docker.sh shell postgres     # Shell no PostgreSQL"
        echo ""
        echo "============================================================================"
        ;;
esac
EOF

chmod +x docker.sh

echo "   ✅ docker.sh criado"
echo ""

# ============================================================================
# CRIAR MAKEFILE (OPCIONAL)
# ============================================================================
echo "📝 [BONUS] Criando Makefile..."

cat > Makefile << 'EOF'
# ============================================================================
# SHAKA API - MAKEFILE
# ============================================================================

.PHONY: help start stop restart logs health reset migrate build ps shell

help:
	@./docker.sh help

start:
	@./docker.sh start

stop:
	@./docker.sh stop

restart:
	@./docker.sh restart

logs:
	@./docker.sh logs

health:
	@./docker.sh health

reset:
	@./docker.sh reset

migrate-run:
	@./docker.sh migrate run

migrate-revert:
	@./docker.sh migrate revert

build:
	@./docker.sh build

ps:
	@./docker.sh ps

shell:
	@./docker.sh shell

# Atalhos adicionais
dev:
	@./docker.sh start dev

prod:
	@./docker.sh start prod

test:
	@docker-compose exec api npm test

coverage:
	@docker-compose exec api npm run test:coverage
EOF

echo "   ✅ Makefile criado"
echo ""

# ============================================================================
# VALIDAÇÃO FINAL
# ============================================================================
echo "============================================================================"
echo "✅ SCRIPT 42 CONCLUÍDO COM SUCESSO!"
echo "============================================================================"
echo ""
echo "📦 Scripts criados:"
echo "   ✅ scripts/docker/start.sh       (Iniciar containers)"
echo "   ✅ scripts/docker/stop.sh        (Parar containers)"
echo "   ✅ scripts/docker/logs.sh        (Ver logs)"
echo "   ✅ scripts/docker/reset.sh       (Reset completo)"
echo "   ✅ scripts/docker/health.sh      (Health check)"
echo "   ✅ scripts/docker/migrate.sh     (Migrations)"
echo "   ✅ docker.sh                     (Script principal)"
echo "   ✅ Makefile                      (Make commands)"
echo ""
echo "🎯 Próximo passo:"
echo "   Execute: bash scripts/docker/test-docker.sh (Script 43)"
echo ""
echo "============================================================================" 
