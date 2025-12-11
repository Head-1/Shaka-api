#!/bin/bash
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${RED}🔥 FORCE REBUILD (NO CACHE)${NC}"
echo ""

cd ~/shaka-api

# Verificar source
echo "Checking source..."
if grep -q "app.use('/api', routes)" src/server.ts; then
    echo -e "${GREEN}✅ Source has /api${NC}"
else
    echo -e "${RED}❌ Source still has /api/v1${NC}"
    exit 1
fi

# Verificar dist local
if grep -q "app.use('/api'," dist/server.js; then
    echo -e "${GREEN}✅ Local dist has /api${NC}"
else
    echo -e "${RED}❌ Local dist still has /api/v1${NC}"
    exit 1
fi

# Force rebuild Docker (NO CACHE)
echo ""
echo -e "${YELLOW}🐳 Docker rebuild (NO CACHE - may take 3-5 min)...${NC}"
docker build --no-cache --progress=plain -t shaka-api:nocache -f docker/api/Dockerfile . 2>&1 | grep -E "Step|RUN npm run build|Successfully" | tail -20

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Docker build failed${NC}"
    exit 1
fi

docker tag shaka-api:nocache shaka-api:latest

# Verificar imagem
echo ""
echo -e "${YELLOW}🔍 Verifying image...${NC}"
TEMP_CONTAINER=$(docker create shaka-api:nocache)
docker cp $TEMP_CONTAINER:/app/dist/server.js /tmp/server-from-image.js
docker rm $TEMP_CONTAINER

if grep -q "app.use('/api'," /tmp/server-from-image.js; then
    echo -e "${GREEN}✅ Docker image has /api${NC}"
else
    echo -e "${RED}❌ Docker image still has /api/v1!${NC}"
    grep "app.use('/api" /tmp/server-from-image.js
    exit 1
fi

# Deploy
echo ""
echo -e "${YELLOW}🚀 Deploying...${NC}"
for ns in shaka-dev shaka-staging shaka-prod; do
    kubectl set image deployment/shaka-api shaka-api=shaka-api:nocache -n $ns
    kubectl rollout restart deployment/shaka-api -n $ns
done

echo ""
echo -e "${YELLOW}⏳ Waiting 60 seconds...${NC}"
sleep 60

# Status
kubectl get pods -A | grep shaka-api

# Test
echo ""
echo -e "${GREEN}🧪 Testing /api endpoint...${NC}"
POD=$(kubectl get pods -n shaka-dev -l app=shaka-api -o jsonpath='{.items[0].metadata.name}')

echo "1. Checking compiled code in container..."
kubectl exec -n shaka-dev $POD -- grep "app.use('/api" /app/dist/server.js | head -3

echo ""
echo "2. Testing GET /api..."
kubectl exec -n shaka-dev $POD -- wget -qO- http://localhost:3000/api 2>&1 | head -5

echo ""
echo "3. Testing POST /api/auth/register..."
RESULT=$(kubectl exec -n shaka-dev $POD -- wget -qO- \
    --post-data='{"email":"nocache@shaka.com","password":"Test123!","name":"No Cache"}' \
    --header="Content-Type: application/json" \
    http://localhost:3000/api/auth/register 2>&1)

if echo "$RESULT" | grep -q '"user"'; then
    echo -e "${GREEN}✅✅✅ SUCCESS! Registration working!${NC}"
    echo "$RESULT" | head -10
elif echo "$RESULT" | grep -q "404"; then
    echo -e "${RED}❌ Still 404${NC}"
    echo "Checking what's in the container..."
    kubectl exec -n shaka-dev $POD -- cat /app/dist/server.js | grep -B 2 -A 2 "app.use" | head -40
else
    echo -e "${YELLOW}⚠️  Different response:${NC}"
    echo "$RESULT" | head -15
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ REBUILD COMPLETE${NC}"
echo -e "${GREEN}========================================${NC}"
