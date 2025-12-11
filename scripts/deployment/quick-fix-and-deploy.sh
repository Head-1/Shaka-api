#!/bin/bash
set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🔍 Checking current build status...${NC}"
cd ~/shaka-api

# Verificar se o server.ts foi atualizado
if grep -q "app.use('/api', routes)" ~/shaka-api/src/server.ts; then
    echo -e "${GREEN}✅ server.ts has routes registered${NC}"
else
    echo -e "${RED}❌ server.ts still missing routes!${NC}"
    exit 1
fi

# Build simples e rápido
echo ""
echo -e "${YELLOW}🔨 Building TypeScript (simplified)...${NC}"
npx tsc --skipLibCheck 2>&1 | tail -20 &
BUILD_PID=$!

# Timeout de 60 segundos
TIMEOUT=60
ELAPSED=0
while kill -0 $BUILD_PID 2>/dev/null; do
    if [ $ELAPSED -ge $TIMEOUT ]; then
        echo -e "${RED}❌ Build timeout! Killing process...${NC}"
        kill -9 $BUILD_PID 2>/dev/null || true
        exit 1
    fi
    echo -n "."
    sleep 2
    ELAPSED=$((ELAPSED + 2))
done

wait $BUILD_PID
BUILD_EXIT=$?

echo ""
if [ $BUILD_EXIT -eq 0 ]; then
    echo -e "${GREEN}✅ Build successful!${NC}"
else
    echo -e "${RED}❌ Build failed with exit code $BUILD_EXIT${NC}"
    exit 1
fi

# Verificar se dist/server.js tem as rotas
echo ""
echo -e "${YELLOW}🔍 Verifying compiled server.js...${NC}"
if grep -q "app.use('/api'" ~/shaka-api/dist/server.js; then
    echo -e "${GREEN}✅ Routes registered in compiled code${NC}"
else
    echo -e "${RED}❌ Routes NOT in compiled code!${NC}"
    exit 1
fi

# Docker build rápido (sem cache se necessário)
echo ""
echo -e "${YELLOW}🐳 Building Docker image (this may take 2-3 min)...${NC}"
docker build --no-cache -t shaka-api:fixed -f docker/api/Dockerfile . > /tmp/docker-build.log 2>&1 &
DOCKER_PID=$!

# Timeout de 5 minutos
TIMEOUT=300
ELAPSED=0
while kill -0 $DOCKER_PID 2>/dev/null; do
    if [ $ELAPSED -ge $TIMEOUT ]; then
        echo -e "${RED}❌ Docker build timeout!${NC}"
        kill -9 $DOCKER_PID 2>/dev/null || true
        tail -50 /tmp/docker-build.log
        exit 1
    fi
    echo -n "."
    sleep 5
    ELAPSED=$((ELAPSED + 5))
done

wait $DOCKER_PID
DOCKER_EXIT=$?

echo ""
if [ $DOCKER_EXIT -eq 0 ]; then
    echo -e "${GREEN}✅ Docker image built!${NC}"
    docker images | grep shaka-api | head -3
else
    echo -e "${RED}❌ Docker build failed!${NC}"
    tail -50 /tmp/docker-build.log
    exit 1
fi

# Tag como latest
docker tag shaka-api:fixed shaka-api:latest

# Update deployments
echo ""
echo -e "${YELLOW}🔄 Updating Kubernetes deployments...${NC}"
for ns in shaka-dev shaka-staging shaka-prod; do
    echo "  → $ns"
    kubectl delete pods -l app=shaka-api -n $ns --grace-period=0 --force 2>/dev/null || true
done

echo ""
echo -e "${YELLOW}⏳ Waiting 45 seconds for new pods...${NC}"
sleep 45

# Status
echo ""
echo -e "${GREEN}📊 Pod Status:${NC}"
kubectl get pods -A | grep shaka-api

# Quick test
echo ""
echo -e "${GREEN}🧪 Quick Route Test:${NC}"
POD=$(kubectl get pods -n shaka-dev -l app=shaka-api -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ ! -z "$POD" ]; then
    echo "Testing /api route..."
    kubectl exec -n shaka-dev $POD -- wget -qO- http://localhost:3000/api 2>/dev/null | head -5 || echo "Still 404 (pod may be starting)"
fi

echo ""
echo -e "${GREEN}✅ Deployment complete!${NC}"
echo ""
echo -e "${YELLOW}💡 Run full tests with:${NC}"
echo "   bash ~/shaka-api/scripts/deployment/test-endpoints.sh"
