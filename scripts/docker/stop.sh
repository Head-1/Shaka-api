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
