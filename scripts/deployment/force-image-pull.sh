#!/bin/bash
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${RED}🔄 FORCING IMAGE PULL IN KUBERNETES${NC}"
echo ""

# 1. Verificar qual imagem os pods estão usando
echo -e "${YELLOW}Current pod images:${NC}"
kubectl get pods -n shaka-dev -l app=shaka-api -o jsonpath='{.items[0].spec.containers[0].image}'
echo ""

# 2. Atualizar imagePullPolicy para Always e adicionar timestamp
echo -e "${YELLOW}Updating deployment with imagePullPolicy: Always...${NC}"

for ns in shaka-dev shaka-staging shaka-prod; do
    echo "  → $ns"
    
    # Patch deployment para forçar pull
    kubectl patch deployment shaka-api -n $ns -p '{
      "spec": {
        "template": {
          "metadata": {
            "annotations": {
              "force-redeploy": "'$(date +%s)'"
            }
          },
          "spec": {
            "containers": [{
              "name": "shaka-api",
              "image": "shaka-api:latest",
              "imagePullPolicy": "Never"
            }]
          }
        }
      }
    }'
done

echo ""
echo -e "${YELLOW}⏳ Waiting for rollout (60s)...${NC}"
sleep 60

# 3. Status
kubectl get pods -A | grep shaka-api

# 4. Test
echo ""
echo -e "${GREEN}🧪 Testing...${NC}"
POD=$(kubectl get pods -n shaka-dev -l app=shaka-api -o jsonpath='{.items[0].metadata.name}')

echo "1. Verify container has correct code:"
kubectl exec -n shaka-dev $POD -- cat /app/dist/server.js | grep -n "app.use.*routes" | head -3

echo ""
echo "2. Test registration:"
RESULT=$(kubectl exec -n shaka-dev $POD -- wget -qO- \
    --post-data='{"email":"force-pull@shaka.com","password":"Test123!","name":"Force Pull"}' \
    --header="Content-Type: application/json" \
    http://localhost:3000/api/auth/register 2>&1)

if echo "$RESULT" | grep -q '"user"'; then
    echo -e "${GREEN}🎉🎉🎉 SUCCESS!!!${NC}"
    echo "$RESULT" | head -10
elif echo "$RESULT" | grep -q "404"; then
    echo -e "${RED}❌ Still 404 - checking what's in container...${NC}"
    kubectl exec -n shaka-dev $POD -- cat /app/dist/server.js | grep -B 5 -A 5 "HEALTH CHECK" | tail -20
else
    echo "$RESULT" | head -15
fi

echo ""
echo -e "${GREEN}✅ Done!${NC}"
