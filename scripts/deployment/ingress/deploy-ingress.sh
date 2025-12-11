#!/bin/bash
# Shaka API - Deploy Ingress Configuration
# Fase 16: External Access via Traefik
# Criado: 01/Dez/2025

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "ðŸš€ Deploying Shaka API Ingress Configuration"
echo "=============================================="
echo ""

# 1. Verificar Traefik
echo "[1/7] Checking Traefik Ingress Controller..."
if kubectl get pods -n kube-system -l app.kubernetes.io/name=traefik | grep -q "Running"; then
    echo -e "${GREEN}âœ… Traefik is running${NC}"
    kubectl get pods -n kube-system -l app.kubernetes.io/name=traefik
else
    echo -e "${RED}âŒ Traefik not found or not running${NC}"
    exit 1
fi

# 2. Verificar Services existentes
echo ""
echo "[2/7] Checking existing Services..."
echo "Staging:"
kubectl get svc shaka-api -n shaka-staging 2>/dev/null || echo -e "${YELLOW}âš ï¸ Service not found${NC}"
echo "Dev:"
kubectl get svc shaka-api -n shaka-dev 2>/dev/null || echo -e "${YELLOW}âš ï¸ Service not found${NC}"

# 3. Backup de Ingress antigos (se existirem)
echo ""
echo "[3/7] Backing up existing Ingress (if any)..."
mkdir -p ~/shaka-api/backups/ingress
kubectl get ingress -n shaka-staging -o yaml > ~/shaka-api/backups/ingress/staging-$(date +%Y%m%d-%H%M%S).yaml 2>/dev/null || true
kubectl get ingress -n shaka-dev -o yaml > ~/shaka-api/backups/ingress/dev-$(date +%Y%m%d-%H%M%S).yaml 2>/dev/null || true
echo -e "${GREEN}âœ… Backups created${NC}"

# 4. Apply Middlewares primeiro
echo ""
echo "[4/7] Applying Middlewares (CORS + Rate Limit)..."
kubectl apply -f ~/shaka-api/infrastructure/kubernetes/ingress/03-middleware-cors.yaml
kubectl apply -f ~/shaka-api/infrastructure/kubernetes/ingress/04-middleware-ratelimit.yaml
echo -e "${GREEN}âœ… Middlewares applied${NC}"

# 5. Apply Ingress manifests
echo ""
echo "[5/7] Applying Ingress manifests..."
kubectl apply -f ~/shaka-api/infrastructure/kubernetes/ingress/01-ingress-staging.yaml
kubectl apply -f ~/shaka-api/infrastructure/kubernetes/ingress/02-ingress-dev.yaml
echo -e "${GREEN}âœ… Ingress manifests applied${NC}"

# 6. Configurar /etc/hosts
echo ""
echo "[6/7] Configuring /etc/hosts..."
if grep -q "staging.shaka.local" /etc/hosts && grep -q "dev.shaka.local" /etc/hosts; then
    echo -e "${GREEN}âœ… Hosts already configured${NC}"
else
    echo "Adding entries to /etc/hosts..."
    echo "127.0.0.1  staging.shaka.local" | sudo tee -a /etc/hosts
    echo "127.0.0.1  dev.shaka.local" | sudo tee -a /etc/hosts
    echo -e "${GREEN}âœ… Hosts configured${NC}"
fi

# 7. Aguardar e testar
echo ""
echo "[7/7] Testing endpoints..."
sleep 5

echo ""
echo "Testing STAGING..."
if curl -s -o /dev/null -w "%{http_code}" http://staging.shaka.local/health | grep -q "200"; then
    echo -e "${GREEN}âœ… Staging health check: OK${NC}"
else
    echo -e "${YELLOW}âš ï¸ Staging not responding (may take a few seconds)${NC}"
fi

echo ""
echo "Testing DEV..."
if curl -s -o /dev/null -w "%{http_code}" http://dev.shaka.local/health | grep -q "200"; then
    echo -e "${GREEN}âœ… Dev health check: OK${NC}"
else
    echo -e "${YELLOW}âš ï¸ Dev not responding (may take a few seconds)${NC}"
fi

# Status final
echo ""
echo "=============================================="
echo "âœ… Ingress deployment complete!"
echo "=============================================="
echo ""
echo "ðŸ"Š Status:"
kubectl get ingress -A

echo ""
echo "ðŸ"— Endpoints:"
echo "  - Staging: http://staging.shaka.local"
echo "  - Dev:     http://dev.shaka.local"

echo ""
echo "ðŸ§ª Test commands:"
echo "  curl http://staging.shaka.local/health"
echo "  curl http://staging.shaka.local/api/v1/auth/login"

echo ""
echo "ðŸ"š Documentation:"
echo "  ~/shaka-api/infrastructure/kubernetes/ingress/README.md"

echo ""
echo "ðŸ"§ Troubleshooting:"
echo "  bash ~/shaka-api/scripts/deployment/ingress/test-ingress.sh"
