#!/bin/bash

echo "🔧 SCRIPT 13: Corrigindo Imports Restantes"
echo "=========================================="
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 1. Corrigir UserController - remover linha com 'usage'
echo -e "${YELLOW}📝 Corrigindo UserController (remover usage da response)...${NC}"
if [ -f "src/api/controllers/users/UserController.ts" ]; then
  sed -i '/data: usage/d' src/api/controllers/users/UserController.ts
  sed -i 's/res.json({$/res.json({/g' src/api/controllers/users/UserController.ts
  echo -e "${GREEN}✓ UserController corrigido${NC}"
fi

echo ""

# 2. Corrigir routes/index.ts - mudar para default imports
echo -e "${YELLOW}📝 Corrigindo routes/index.ts...${NC}"
cat > src/api/routes/index.ts << 'EOF'
import { Router } from 'express';
import authRoutes from './auth.routes';
import userRoutes from './user.routes';
import planRoutes from './plan.routes';

const router = Router();

router.use('/auth', authRoutes);
router.use('/users', userRoutes);
router.use('/plans', planRoutes);

export default router;
EOF
echo -e "${GREEN}✓ routes/index.ts corrigido${NC}"

echo ""

# 3. Listar arquivos que faltam (middleware e validators)
echo -e "${YELLOW}📝 Verificando arquivos faltantes...${NC}"
echo ""

MISSING_FILES=()

if [ ! -f "src/api/middlewares/validator.ts" ]; then
  echo "❌ Faltando: src/api/middlewares/validator.ts"
  MISSING_FILES+=("validator")
fi

if [ ! -f "src/api/middlewares/auth.ts" ]; then
  echo "❌ Faltando: src/api/middlewares/auth.ts"
  MISSING_FILES+=("auth")
fi

if [ ! -f "src/api/validators/user.validator.ts" ]; then
  echo "❌ Faltando: src/api/validators/user.validator.ts"
  MISSING_FILES+=("user.validator")
fi

echo ""
echo -e "${GREEN}✅ SCRIPT 13 CONCLUÍDO!${NC}"
echo ""
echo "📊 Arquivos corrigidos"
echo ""

if [ ${#MISSING_FILES[@]} -gt 0 ]; then
  echo -e "${YELLOW}⚠ Arquivos faltando detectados!${NC}"
  echo "   Execute: ./fix-missing-files.sh (próximo script)"
else
  echo -e "${GREEN}✓ Todos os arquivos necessários existem${NC}"
fi

echo ""
