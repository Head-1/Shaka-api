#!/bin/bash
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${RED}☢️  NUCLEAR OPTION - Complete Rebuild${NC}"
echo ""

cd ~/shaka-api

# 1. Limpar TUDO do Docker
echo -e "${YELLOW}🧹 Cleaning Docker cache...${NC}"
docker system prune -af --volumes 2>&1 | tail -5

# 2. Verificar source
echo ""
echo -e "${YELLOW}📝 Verifying source code...${NC}"
grep -n "app.use.*routes" src/server.ts

if ! grep -q "app.use('/api', routes)" src/server.ts; then
    echo -e "${RED}❌ Source doesn't have /api!${NC}"
    exit 1
fi

# 3. Fresh build local
echo ""
echo -e "${YELLOW}🔨 Fresh local build...${NC}"
rm -rf dist node_modules/.cache
npm run build

grep -n "app.use.*routes" dist/server.js
echo ""

if ! grep -q "app.use('/api'," dist/server.js; then
    echo -e "${RED}❌ Local dist doesn't have /api!${NC}"
    cat dist/server.js | grep -B 5 -A 5 "routes_1"
    exit 1
fi

echo -e "${GREEN}✅ Local build has correct /api${NC}"

# 4. Docker build from scratch
echo ""
echo -e "${YELLOW}🐳 Docker build from scratch (NO CACHE)...${NC}"
TIMESTAMP=$(date +%s)
docker build \
    --no-cache \
    --pull \
    --progress=plain \
    -t shaka-api:build-${TIMESTAMP} \
    -f docker/api/Dockerfile \
    . 2>&1 | tee /tmp/docker-build.log | grep -E "Step|RUN|Successfully"

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Docker build failed!${NC}"
    tail -50 /tmp/docker-build.log
    exit 1
fi

# 5. Verificar imagem ANTES de deployar
echo ""
echo -e "${YELLOW}🔍 Inspecting Docker image BEFORE deploy...${NC}"
CONTAINER_ID=$(docker create shaka-api:build-${TIMESTAMP})
docker cp ${CONTAINER_ID}:/app/dist/server.js /tmp/verify-server.js
docker rm ${CONTAINER_ID}

echo "Checking /tmp/verify-server.js:"
grep -n "app.use.*routes" /tmp/verify-server.js

if grep -q "app.use('/api'," /tmp/verify-server.js; then
    echo -e "${GREEN}✅✅✅ Docker image has CORRECT /api route!${NC}"
elif grep -q "app.use('/api/v1'," /tmp/verify-server.js; then
    echo -e "${RED}❌❌❌ Docker image STILL has /api/v1!${NC}"
    echo "This should NOT happen with --no-cache!"
    echo "Showing context:"
    grep -B 10 -A 10 "app.use.*routes" /tmp/verify-server.js
    exit 1
else
    echo -e "${RED}❌ No routes found at all!${NC}"
    exit 1
fi

# 6. Tag and deploy
docker tag shaka-api:build-${TIMESTAMP} shaka-api:latest

echo ""
echo -e "${YELLOW}🚀 Deploying verified image...${NC}"
for ns in shaka-dev shaka-staging shaka-prod; do
    kubectl delete pod -l app=shaka-api -n $ns --force --grace-period=0
done

sleep 45

kubectl get pods -A | grep shaka-api

# 7. Final test
echo ""
echo -e "${GREEN}🧪 Final test...${NC}"
POD=$(kubectl get pods -n shaka-dev -l app=shaka-api -o jsonpath='{.items[0].metadata.name}')

echo "Testing registration:"
kubectl exec -n shaka-dev $POD -- wget -qO- \
    --post-data='{"email":"nuclear@shaka.com","password":"Test123!","name":"Nuclear"}' \
    --header="Content-Type: application/json" \
    http://localhost:3000/api/auth/register 2>&1

echo ""
echo -e "${GREEN}✅ Nuclear rebuild complete!${NC}"
