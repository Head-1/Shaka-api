#!/bin/bash
# Shaka API - Rollback Ingress Configuration
# Fase 16: Rollback to previous state
# Criado: 01/Dez/2025

set -euo pipefail

echo "ðŸ"„ Rolling back Ingress configuration..."

# Encontrar backup mais recente
LATEST_STAGING=$(ls -t ~/shaka-api/backups/ingress/staging-*.yaml 2>/dev/null | head -1)
LATEST_DEV=$(ls -t ~/shaka-api/backups/ingress/dev-*.yaml 2>/dev/null | head -1)

if [ -n "$LATEST_STAGING" ]; then
    echo "Restoring staging from: $LATEST_STAGING"
    kubectl apply -f "$LATEST_STAGING"
else
    echo "Deleting staging ingress..."
    kubectl delete ingress shaka-api -n shaka-staging || true
fi

if [ -n "$LATEST_DEV" ]; then
    echo "Restoring dev from: $LATEST_DEV"
    kubectl apply -f "$LATEST_DEV"
else
    echo "Deleting dev ingress..."
    kubectl delete ingress shaka-api -n shaka-dev || true
fi

echo "âœ… Rollback complete!"
