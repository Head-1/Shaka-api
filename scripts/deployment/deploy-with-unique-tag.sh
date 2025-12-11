#!/bin/bash
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${RED}🎯 DEPLOYING WITH UNIQUE TAG${NC}"
echo ""

# 1. Encontrar a imagem correta
CORRECT_IMAGE=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep "shaka-api:build-" | head -1)
echo "Found correct image: $CORRECT_IMAGE"

# Verificar se tem /api
TEMP_ID=$(docker create $CORRECT_IMAGE)
docker cp $TEMP_ID:/app/dist/server.js /tmp/check.js
docker rm $TEMP_ID

if grep -q "app.use('/api'," /tmp/check.js; then
    echo -e "${GREEN}✅ Image has /api (correct)${NC}"
elif grep -q "app.use('/api/v1'," /tmp/check.js; then
    echo -e "${RED}❌ Image has /api/v1 (wrong!)${NC}"
    exit 1
fi

# 2. Tag com timestamp novo
NEW_TAG="v$(date +%s)"
docker tag $CORRECT_IMAGE shaka-api:$NEW_TAG
docker tag $CORRECT_IMAGE shaka-api:latest

echo "Tagged as: shaka-api:$NEW_TAG"

# 3. Delete OLD pods primeiro
echo ""
echo -e "${YELLOW}🗑️  Deleting old pods...${NC}"
for ns in shaka-dev shaka-staging shaka-prod; do
    kubectl delete pod -l app=shaka-api -n $ns --all --force --grace-period=0 2>/dev/null || true
done

sleep 10

# 4. Update deployments com nova tag
echo ""
echo -e "${YELLOW}🚀 Updating deployments to $NEW_TAG...${NC}"
for ns in shaka-dev shaka-staging shaka-prod; do
    kubectl set image deployment/shaka-api shaka-api=shaka-api:$NEW_TAG -n $ns
    kubectl rollout restart deployment/shaka-api -n $ns
done

echo ""
echo -e "${YELLOW}⏳ Waiting 60s for rollout...${NC}"
sleep 60

# 5. Status
echo ""
kubectl get pods -A | grep shaka-api

# 6. Test
echo ""
echo -e "${GREEN}🧪 FINAL TEST${NC}"
POD=$(kubectl get pods -n shaka-dev -l app=shaka-api -o jsonpath='{.items[0].metadata.name}')

if [ -z "$POD" ]; then
    echo -e "${RED}No pod found!${NC}"
    exit 1
fi

echo ""
echo "Image in pod:"
kubectl describe pod -n shaka-dev $POD | grep "Image:" | head -2

echo ""
echo "Code in container:"
kubectl exec -n shaka-dev $POD -- grep "app.use.*routes" /app/dist/server.js

echo ""
echo "Testing registration:"
RESULT=$(kubectl exec -n shaka-dev $POD -- wget -qO- \
    --post-data='{"email":"unique-tag@shaka.com","password":"Test123!","name":"Unique Tag"}' \
    --header="Content-Type: application/json" \
    http://localhost:3000/api/auth/register 2>&1)

if echo "$RESULT" | grep -q '"user"'; then
    echo -e "${GREEN}"
    echo "╔════════════════════════════════════╗"
    echo "║   🎉 SUCCESS! IT WORKS! 🎉        ║"
    echo "╚════════════════════════════════════╝"
    echo -e "${NC}"
    echo "$RESULT" | jq '.' 2>/dev/null || echo "$RESULT" | head -10
    echo ""
    echo -e "${GREEN}✅ Run full E2E tests:${NC}"
    echo "   bash ~/shaka-api/scripts/deployment/test-endpoints.sh"
elif echo "$RESULT" | grep -q "404"; then
    echo -e "${RED}❌ STILL 404! Something is very wrong...${NC}"
    echo "Showing full server.js routes section:"
    kubectl exec -n shaka-dev $POD -- cat /app/dist/server.js | grep -B 10 -A 10 "HEALTH CHECK"
else
    echo -e "${YELLOW}⚠️  Different response:${NC}"
    echo "$RESULT"
fi

echo ""
echo -e "${GREEN}✅ Deploy complete!${NC}"
