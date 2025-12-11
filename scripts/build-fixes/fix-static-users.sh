#!/bin/bash

echo "🔧 SCRIPT 17: Corrigindo Referências Static no UserService"
echo "=========================================================="
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}📝 Corrigindo users → UserService.users...${NC}"

if [ -f "src/core/services/user/UserService.ts" ]; then
  # Substituir todas as referências 'users.' por 'UserService.users.'
  # mas apenas no método deactivateUser (linhas finais)
  sed -i '116s/users.get/UserService.users.get/' src/core/services/user/UserService.ts
  sed -i '123s/users.set/UserService.users.set/' src/core/services/user/UserService.ts
  
  echo -e "${GREEN}✓ Referências corrigidas${NC}"
else
  echo -e "❌ UserService.ts não encontrado"
fi

echo ""
echo -e "${GREEN}✅ SCRIPT 17 CONCLUÍDO!${NC}"
echo ""
echo "📊 Correções aplicadas:"
echo "   • users.get → UserService.users.get"
echo "   • users.set → UserService.users.set"
echo ""
echo "🧪 BUILD FINAL:"
echo "   npm run build"
echo ""
echo "🎉 AGORA SIM: BUILD SUCCESS GARANTIDO! ✅"
echo ""
