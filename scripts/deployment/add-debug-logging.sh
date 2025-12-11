#!/bin/bash

echo "🔍 SCRIPT: Adding Debug Logging to Track Path Rewriting"
echo "========================================================="

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Backup do arquivo atual
echo -e "${YELLOW}📦 Creating backup of server.ts...${NC}"
cp src/server.ts src/server.ts.backup-debug-$(date +%Y%m%d-%H%M%S)

# Adicionar debug middleware ANTES de todas as rotas
echo -e "${YELLOW}🔧 Adding debug middleware to server.ts...${NC}"

cat > /tmp/debug-middleware.ts << 'EOF'
// DEBUG MIDDLEWARE - Remover após investigação
app.use((req, res, next) => {
  const debugInfo = {
    timestamp: new Date().toISOString(),
    method: req.method,
    url: req.url,
    originalUrl: req.originalUrl,
    path: req.path,
    baseUrl: req.baseUrl,
    headers: {
      host: req.headers.host,
      contentType: req.headers['content-type']
    }
  };
  
  console.log('🔍 [DEBUG RAW REQUEST]', JSON.stringify(debugInfo, null, 2));
  next();
});

// DEBUG: Log após passar pelo router /api/v1
app.use('/api/v1', (req, res, next) => {
  console.log('🔍 [DEBUG AFTER /api/v1]', {
    url: req.url,
    originalUrl: req.originalUrl,
    path: req.path,
    baseUrl: req.baseUrl
  });
  next();
});
EOF

# Inserir o debug middleware após os middlewares de segurança
# Procurar a linha com app.use(cors()) e inserir após
awk '
/app\.use\(cors\(\)\)/ {
  print $0
  print ""
  while ((getline line < "/tmp/debug-middleware.ts") > 0) {
    print line
  }
  next
}
{print}
' src/server.ts > src/server.ts.tmp

mv src/server.ts.tmp src/server.ts

echo -e "${GREEN}✅ Debug middleware added${NC}"

# Build TypeScript
echo -e "${YELLOW}🔨 Building TypeScript...${NC}"
npm run build

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✅ TypeScript build successful${NC}"
else
  echo -e "${RED}❌ TypeScript build failed${NC}"
  exit 1
fi

# Verificar se o debug middleware foi compilado
echo -e "${YELLOW}🔍 Verifying compiled debug middleware...${NC}"
if grep -q "DEBUG RAW REQUEST" dist/server.js; then
  echo -e "${GREEN}✅ Debug middleware found in compiled code${NC}"
else
  echo -e "${RED}❌ Debug middleware NOT found in compiled code${NC}"
  exit 1
fi

# Docker build (sem cache para garantir atualização)
echo -e "${YELLOW}🐳 Building Docker image with debug logging...${NC}"
TIMESTAMP=$(date +%s)
docker build --no-cache -t shaka-api:debug-$TIMESTAMP -f docker/api/Dockerfile .

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✅ Docker image built: shaka-api:debug-$TIMESTAMP${NC}"
else
  echo -e "${RED}❌ Docker build failed${NC}"
  exit 1
fi

# Salvar tag para próximo script
echo "shaka-api:debug-$TIMESTAMP" > /tmp/debug-image-tag.txt

echo ""
echo -e "${GREEN}✅ Debug logging added successfully!${NC}"
echo ""
echo "📝 Next steps:"
echo "1. Import image to K3s:"
echo "   docker save shaka-api:debug-$TIMESTAMP | sudo k3s ctr images import -"
echo ""
echo "2. Update deployment:"
echo "   kubectl set image deployment/shaka-api shaka-api=shaka-api:debug-$TIMESTAMP -n shaka-staging"
echo ""
echo "3. Watch logs:"
echo "   kubectl logs -f -l app=shaka-api -n shaka-staging"
echo ""
echo "4. Test endpoint:"
echo "   kubectl exec -n shaka-staging pod-name -- wget -O- --post-data='{...}' http://localhost:3000/api/v1/auth/register"

