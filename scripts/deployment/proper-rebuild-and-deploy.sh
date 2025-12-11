#!/bin/bash
set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  PROPER REBUILD & DEPLOY${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

cd ~/shaka-api

# 1. Verificar source
echo -e "${YELLOW}[1/6] Verifying source code...${NC}"
if grep -q "app.use('/api', routes)" src/server.ts; then
    echo -e "${GREEN}✅ server.ts has correct routes${NC}"
else
    echo -e "${RED}❌ server.ts missing routes! Fixing...${NC}"
    # Se faltar, não continuar - pedir para corrigir manualmente
    exit 1
fi

# 2. Limpar build anterior
echo ""
echo -e "${YELLOW}[2/6] Cleaning previous build...${NC}"
rm -rf dist
echo -e "${GREEN}✅ Clean complete${NC}"

# 3. Build fresh (com timeout manual)
echo ""
echo -e "${YELLOW}[3/6] Building TypeScript (max 2 minutes)...${NC}"
timeout 120 npm run build || {
    echo -e "${RED}❌ Build timeout or failed${NC}"
    echo "Trying with npx tsc directly..."
    timeout 120 npx tsc --skipLibCheck || {
        echo -e "${RED}❌ Direct tsc also failed${NC}"
        exit 1
    }
}

# Verificar dist
if [ -f "dist/server.js" ] && grep -q "app.use('/api'" dist/server.js; then
    echo -e "${GREEN}✅ Build successful with routes!${NC}"
else
    echo -e "${RED}❌ Build incomplete or routes missing${NC}"
    exit 1
fi

# 4. Docker build
echo ""
echo -e "${YELLOW}[4/6] Building Docker image (max 5 minutes)...${NC}"
timeout 300 docker build -t shaka-api:v2 -f docker/api/Dockerfile . || {
    echo -e "${RED}❌ Docker build timeout${NC}"
    exit 1
}

docker tag shaka-api:v2 shaka-api:latest
echo -e "${GREEN}✅ Docker image ready${NC}"

# 5. Deploy to Kubernetes
echo ""
echo -e "${YELLOW}[5/6] Deploying to Kubernetes...${NC}"
for ns in shaka-dev shaka-staging shaka-prod; do
    echo "  → Updating $ns..."
    # Forçar re-pull da imagem
    kubectl set image deployment/shaka-api shaka-api=shaka-api:v2 -n $ns
    kubectl rollout restart deployment/shaka-api -n $ns
done

echo ""
echo -e "${YELLOW}⏳ Waiting 60 seconds for rollout...${NC}"
sleep 60

# 6. Verify
echo ""
echo -e "${YELLOW}[6/6] Verifying deployment...${NC}"
kubectl get pods -A | grep shaka-api

echo ""
echo -e "${GREEN}🧪 Testing Dev environment...${NC}"
POD=$(kubectl get pods -n shaka-dev -l app=shaka-api -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -z "$POD" ]; then
    echo -e "${RED}❌ No pod found!${NC}"
    exit 1
fi

# Test /api
echo "Testing GET /api..."
API_RESULT=$(kubectl exec -n shaka-dev $POD -- wget -qO- http://localhost:3000/api 2>&1)
if echo "$API_RESULT" | grep -q "404"; then
    echo -e "${RED}❌ Still 404${NC}"
    echo "Checking container..."
    kubectl exec -n shaka-dev $POD -- cat /app/dist/server.js | grep -A 2 "app.use('/api'" || echo "Routes not in container!"
else
    echo -e "${GREEN}✅ /api responding!${NC}"
fi

# Test register
echo ""
echo "Testing POST /api/auth/register..."
REG_RESULT=$(kubectl exec -n shaka-dev $POD -- wget -qO- \
    --post-data='{"email":"test-final@shaka.com","password":"Test123!","name":"Final Test"}' \
    --header="Content-Type: application/json" \
    http://localhost:3000/api/auth/register 2>&1)

if echo "$REG_RESULT" | grep -q '"user"'; then
    echo -e "${GREEN}✅ Registration working!${NC}"
    echo "$REG_RESULT" | head -5
elif echo "$REG_RESULT" | grep -q "404"; then
    echo -e "${RED}❌ Still 404 on register${NC}"
else
    echo -e "${YELLOW}⚠️  Got response:${NC}"
    echo "$REG_RESULT" | head -10
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✅ Deployment process complete${NC}"
echo -e "${BLUE}========================================${NC}"
