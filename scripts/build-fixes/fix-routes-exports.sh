#!/bin/bash

echo "🔧 SCRIPT 6: Corrigindo Exports das Routes"
echo "=========================================="
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Função para adicionar default export se não existir
add_default_export() {
  local file=$1
  local router_name=$2
  
  if ! grep -q "export default" "$file"; then
    echo "" >> "$file"
    echo "export default ${router_name};" >> "$file"
    echo -e "${GREEN}✓ Default export adicionado em $(basename $file)${NC}"
  else
    echo -e "⚠ Default export já existe em $(basename $file)"
  fi
}

echo -e "${YELLOW}📝 Verificando routes...${NC}"
echo ""

if [ -f "src/api/routes/auth.routes.ts" ]; then
  add_default_export "src/api/routes/auth.routes.ts" "authRouter"
fi

if [ -f "src/api/routes/user.routes.ts" ]; then
  add_default_export "src/api/routes/user.routes.ts" "userRouter"
fi

if [ -f "src/api/routes/plan.routes.ts" ]; then
  add_default_export "src/api/routes/plan.routes.ts" "planRouter"
fi

echo ""
echo -e "${GREEN}✅ SCRIPT 6 CONCLUÍDO!${NC}"
echo ""
echo "📊 Exports corrigidos nas routes"
echo ""
echo "🧪 Validação final:"
echo "   npm run build 2>&1 | grep -c 'error TS'"
echo "   (Deve mostrar ZERO ou muito poucos erros)"
echo ""
echo "🎯 Se ainda houver erros, execute:"
echo "   npm run build"
echo "   (Para ver detalhes dos erros restantes)"
echo ""
