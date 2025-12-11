#!/bin/bash

echo "🔧 SCRIPT 10: Corrigindo Nomes dos Métodos Auth"
echo "==============================================="
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 1. Corrigir AuthController - refreshToken → refreshTokens
echo -e "${YELLOW}📝 Corrigindo AuthController (refreshToken → refreshTokens)...${NC}"
if [ -f "src/api/controllers/auth/AuthController.ts" ]; then
  sed -i 's/AuthService.refreshToken/AuthService.refreshTokens/g' src/api/controllers/auth/AuthController.ts
  echo -e "${GREEN}✓ AuthController corrigido${NC}"
fi

echo ""

# 2. Remover getUserUsage do UserController (método não existe)
echo -e "${YELLOW}📝 Corrigindo UserController (removendo getUserUsage)...${NC}"
if [ -f "src/api/controllers/users/UserController.ts" ]; then
  # Comentar a linha do getUserUsage
  sed -i 's/const usage = await UserService.getUserUsage/\/\/ const usage = await UserService.getUserUsage/g' src/api/controllers/users/UserController.ts
  sed -i 's/res.json({ user, usage });/res.json({ user });/g' src/api/controllers/users/UserController.ts
  echo -e "${GREEN}✓ UserController corrigido${NC}"
fi

echo ""

# 3. Corrigir RateLimiter - adicionar type assertion para plan
echo -e "${YELLOW}📝 Corrigindo RateLimiter (type assertion)...${NC}"
if [ -f "src/api/middlewares/rateLimiter.ts" ]; then
  sed -i "s/checkLimit(userId, plan)/checkLimit(userId, plan as 'starter' | 'pro' | 'business')/g" src/api/middlewares/rateLimiter.ts
  echo -e "${GREEN}✓ RateLimiter corrigido${NC}"
fi

echo ""
echo -e "${GREEN}✅ SCRIPT 10 CONCLUÍDO!${NC}"
echo ""
echo "📊 Métodos Auth corrigidos"
echo ""
echo "🧪 Validação:"
echo "   npm run build 2>&1 | grep -c 'error TS'"
echo ""
