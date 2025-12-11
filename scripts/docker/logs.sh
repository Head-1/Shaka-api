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
