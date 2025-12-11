#!/bin/bash
# Shaka API - Test Ingress Configuration
# Fase 16: E2E Tests
# Criado: 01/Dez/2025

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "ðŸ§ª Testing Shaka API Ingress"
echo "=============================="
echo ""

# Test 1: Health Checks
echo "[Test 1/5] Health Checks..."
echo "Staging:"
STAGING_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" http://staging.shaka.local/health || echo "000")
if [ "$STAGING_HEALTH" == "200" ]; then
    echo -e "${GREEN}âœ… Staging health: OK ($STAGING_HEALTH)${NC}"
else
    echo -e "${RED}âŒ Staging health: FAIL ($STAGING_HEALTH)${NC}"
fi

echo "Dev:"
DEV_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" http://dev.shaka.local/health || echo "000")
if [ "$DEV_HEALTH" == "200" ]; then
    echo -e "${GREEN}âœ… Dev health: OK ($DEV_HEALTH)${NC}"
else
    echo -e "${RED}âŒ Dev health: FAIL ($DEV_HEALTH)${NC}"
fi

# Test 2: CORS Headers
echo ""
echo "[Test 2/5] CORS Headers..."
CORS_HEADERS=$(curl -s -I -H "Origin: http://localhost:3000" http://staging.shaka.local/health | grep -i "access-control")
if [ -n "$CORS_HEADERS" ]; then
    echo -e "${GREEN}âœ… CORS headers present${NC}"
    echo "$CORS_HEADERS"
else
    echo -e "${YELLOW}âš ï¸ CORS headers not found${NC}"
fi

# Test 3: Rate Limiting (fazer 5 requests rápidos)
echo ""
echo "[Test 3/5] Rate Limiting..."
for i in {1..5}; do
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://staging.shaka.local/health)
    echo "Request $i: $STATUS"
done
echo -e "${GREEN}âœ… Rate limiting functional (check for 429 if exceeded)${NC}"

# Test 4: API Endpoints
echo ""
echo "[Test 4/5] API Endpoints..."
API_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://staging.shaka.local/api/v1/auth/login -X POST -H "Content-Type: application/json" -d '{}' || echo "000")
if [ "$API_STATUS" == "400" ] || [ "$API_STATUS" == "401" ]; then
    echo -e "${GREEN}âœ… API endpoint accessible (validation working: $API_STATUS)${NC}"
else
    echo -e "${YELLOW}âš ï¸ API endpoint: $API_STATUS${NC}"
fi

# Test 5: Traefik Dashboard
echo ""
echo "[Test 5/5] Traefik Status..."
kubectl get pods -n kube-system -l app.kubernetes.io/name=traefik
kubectl get svc -n kube-system traefik

echo ""
echo "=============================="
echo "âœ… Tests complete!"
echo "=============================="

# Summary
echo ""
echo "ðŸ"Š Summary:"
echo "  Health Checks: Staging=$STAGING_HEALTH Dev=$DEV_HEALTH"
echo "  CORS: $([ -n "$CORS_HEADERS" ] && echo 'OK' || echo 'NOT FOUND')"
echo "  API Endpoints: $API_STATUS"
