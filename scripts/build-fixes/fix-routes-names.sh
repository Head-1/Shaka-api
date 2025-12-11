#!/bin/bash

echo "🔧 SCRIPT 8: Corrigindo Nomes das Routes"
echo "========================================"
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 1. Corrigir auth.routes.ts
echo -e "${YELLOW}📝 Corrigindo auth.routes.ts...${NC}"
if [ -f "src/api/routes/auth.routes.ts" ]; then
  # Substituir authRoutes por authRouter E adicionar export default
  sed -i 's/const authRoutes/const authRouter/g' src/api/routes/auth.routes.ts
  sed -i 's/authRoutes\./authRouter./g' src/api/routes/auth.routes.ts
  sed -i 's/export { authRoutes };/export default authRouter;/g' src/api/routes/auth.routes.ts
  # Remover linha duplicada de export default se existir
  sed -i '/^export default authRouter;$/!b;N;s/\n.*export default authRouter;//' src/api/routes/auth.routes.ts
  echo -e "${GREEN}✓ auth.routes.ts corrigido${NC}"
else
  echo -e "⚠ auth.routes.ts não encontrado"
fi

echo ""

# 2. Corrigir user.routes.ts
echo -e "${YELLOW}📝 Corrigindo user.routes.ts...${NC}"
if [ -f "src/api/routes/user.routes.ts" ]; then
  sed -i 's/const userRoutes/const userRouter/g' src/api/routes/user.routes.ts
  sed -i 's/userRoutes\./userRouter./g' src/api/routes/user.routes.ts
  sed -i 's/export { userRoutes };/export default userRouter;/g' src/api/routes/user.routes.ts
  sed -i '/^export default userRouter;$/!b;N;s/\n.*export default userRouter;//' src/api/routes/user.routes.ts
  echo -e "${GREEN}✓ user.routes.ts corrigido${NC}"
else
  echo -e "⚠ user.routes.ts não encontrado"
fi

echo ""

# 3. Corrigir plan.routes.ts
echo -e "${YELLOW}📝 Corrigindo plan.routes.ts...${NC}"
if [ -f "src/api/routes/plan.routes.ts" ]; then
  sed -i 's/const planRoutes/const planRouter/g' src/api/routes/plan.routes.ts
  sed -i 's/planRoutes\./planRouter./g' src/api/routes/plan.routes.ts
  sed -i 's/export { planRoutes };/export default planRouter;/g' src/api/routes/plan.routes.ts
  sed -i '/^export default planRouter;$/!b;N;s/\n.*export default planRouter;//' src/api/routes/plan.routes.ts
  echo -e "${GREEN}✓ plan.routes.ts corrigido${NC}"
else
  echo -e "⚠ plan.routes.ts não encontrado"
fi

echo ""
echo -e "${GREEN}✅ SCRIPT 8 CONCLUÍDO!${NC}"
echo ""
echo "📊 Routes renomeadas para usar Router suffix"
echo ""
echo "🧪 Validação:"
echo "   npm run build 2>&1 | grep -c 'error TS'"
echo ""
