#!/bin/bash

echo "🔧 SCRIPT 4: Corrigindo Imports nos Arquivos"
echo "============================================"
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}📝 Corrigindo imports do config/env e config/logger...${NC}"
echo ""

# Encontrar todos os arquivos que importam config/env ou config/logger
FILES=$(grep -rl "from './config/\|from '../config/" src/ 2>/dev/null || echo "")

if [ -z "$FILES" ]; then
  echo -e "${YELLOW}⚠ Nenhum arquivo encontrado com imports relativos de config${NC}"
else
  echo "Arquivos encontrados com imports de config:"
  echo "$FILES" | while read -r file; do
    echo "  • $file"
  done
  echo ""
  
  # Corrigir cada arquivo
  echo "$FILES" | while read -r file; do
    echo -e "${YELLOW}Corrigindo: $file${NC}"
    
    # Substituir imports relativos por absolutos
    sed -i "s|from './config/env'|from '@config/env'|g" "$file"
    sed -i "s|from '../config/env'|from '@config/env'|g" "$file"
    sed -i "s|from '../../config/env'|from '@config/env'|g" "$file"
    sed -i "s|from './config/logger'|from '@config/logger'|g" "$file"
    sed -i "s|from '../config/logger'|from '@config/logger'|g" "$file"
    sed -i "s|from '../../config/logger'|from '@config/logger'|g" "$file"
    
    echo -e "${GREEN}✓ Corrigido${NC}"
  done
fi

echo ""
echo -e "${GREEN}✅ SCRIPT 4 CONCLUÍDO!${NC}"
echo ""
echo "📊 Imports corrigidos para usar paths absolutos"
echo ""
echo "🧪 Validação:"
echo "   npm run build 2>&1 | grep -c 'error TS'"
echo "   (Deve mostrar menos erros agora)"
echo ""
echo "🎯 Próximo passo:"
echo "   Execute: ./fix-services-static.sh"
echo ""
