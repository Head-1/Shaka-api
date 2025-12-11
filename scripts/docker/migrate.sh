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
