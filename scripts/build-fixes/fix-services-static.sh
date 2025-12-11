#!/bin/bash

echo "🔧 SCRIPT 5: Corrigindo Chamadas de Services (Static Methods)"
echo "============================================================="
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}📝 Corrigindo AuthController...${NC}"
if [ -f "src/api/controllers/AuthController.ts" ]; then
  sed -i 's/authService\./AuthService./g' src/api/controllers/AuthController.ts
  sed -i 's/const authService/\/\/ const authService/g' src/api/controllers/AuthController.ts
  echo -e "${GREEN}✓ AuthController corrigido${NC}"
else
  echo -e "⚠ AuthController não encontrado"
fi

echo ""
echo -e "${YELLOW}📝 Corrigindo UserController...${NC}"
if [ -f "src/api/controllers/UserController.ts" ]; then
  sed -i 's/userService\./UserService./g' src/api/controllers/UserController.ts
  sed -i 's/const userService/\/\/ const userService/g' src/api/controllers/UserController.ts
  echo -e "${GREEN}✓ UserController corrigido${NC}"
else
  echo -e "⚠ UserController não encontrado"
fi

echo ""
echo -e "${YELLOW}📝 Corrigindo RateLimiterMiddleware...${NC}"
if [ -f "src/api/middlewares/RateLimiterMiddleware.ts" ]; then
  sed -i 's/rateLimiterService\./RateLimiterService./g' src/api/middlewares/RateLimiterMiddleware.ts
  sed -i 's/const rateLimiterService/\/\/ const rateLimiterService/g' src/api/middlewares/RateLimiterMiddleware.ts
  echo -e "${GREEN}✓ RateLimiterMiddleware corrigido${NC}"
else
  echo -e "⚠ RateLimiterMiddleware não encontrado"
fi

echo ""
echo -e "${GREEN}✅ SCRIPT 5 CONCLUÍDO!${NC}"
echo ""
echo "📊 Services corrigidos para usar métodos estáticos"
echo ""
echo "🧪 Validação:"
echo "   npm run build 2>&1 | grep -c 'error TS'"
echo ""
echo "🎯 Próximo passo:"
echo "   Execute: ./fix-routes-exports.sh"
echo ""
