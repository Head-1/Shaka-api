#!/bin/bash
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🚀 Deploying fixed image...${NC}"

# Tag the image
docker tag shaka-api:nocache shaka-api:latest

# Force delete pods (they will recreate with new image)
for ns in shaka-dev shaka-staging shaka-prod; do
    echo "  → Restarting $ns"
    kubectl delete pod -l app=shaka-api -n $ns --force --grace-period=0
done

echo ""
echo -e "${YELLOW}⏳ Waiting 60 seconds for pods to start...${NC}"
sleep 60

# Status
echo ""
echo -e "${GREEN}📊 Pod Status:${NC}"
kubectl get pods -A | grep shaka-api

# Test
echo ""
echo -e "${GREEN}🧪 Testing API...${NC}"
POD=$(kubectl get pods -n shaka-dev -l app=shaka-api -o jsonpath='{.items[0].metadata.name}')

echo "1. Verify /api in container:"
kubectl exec -n shaka-dev $POD -- grep "app.use('/api'" /app/dist/server.js | head -2

echo ""
echo "2. Test GET /health:"
kubectl exec -n shaka-dev $POD -- wget -qO- http://localhost:3000/health 2>/dev/null | head -3

echo ""
echo "3. Test GET /api:"
API_TEST=$(kubectl exec -n shaka-dev $POD -- wget -qO- http://localhost:3000/api 2>&1)
if echo "$API_TEST" | grep -q "404"; then
    echo -e "${RED}❌ /api returns 404${NC}"
else
    echo -e "${GREEN}✅ /api responds!${NC}"
    echo "$API_TEST" | head -5
fi

echo ""
echo "4. Test POST /api/auth/register:"
REGISTER=$(kubectl exec -n shaka-dev $POD -- wget -qO- \
    --post-data='{"email":"deploy-fixed@shaka.com","password":"Test123!","name":"Deploy Fixed"}' \
    --header="Content-Type: application/json" \
    http://localhost:3000/api/auth/register 2>&1)

if echo "$REGISTER" | grep -q '"user"'; then
    echo -e "${GREEN}🎉🎉🎉 SUCCESS! Registration working!${NC}"
    echo "$REGISTER" | jq '.' 2>/dev/null || echo "$REGISTER" | head -10
elif echo "$REGISTER" | grep -q "404"; then
    echo -e "${RED}❌ Still 404${NC}"
    echo "Response: $REGISTER" | head -10
else
    echo -e "${YELLOW}⚠️  Got response (not 404):${NC}"
    echo "$REGISTER" | head -15
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ Deployment complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Run full E2E tests:"
echo "  bash ~/shaka-api/scripts/deployment/test-endpoints.sh"
