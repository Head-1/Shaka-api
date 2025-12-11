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
