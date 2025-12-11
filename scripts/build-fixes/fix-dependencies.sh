#!/bin/bash

echo "🔧 SCRIPT 1: Instalando Dependências de Tipos TypeScript"
echo "=========================================================="
echo ""

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}📦 Instalando @types packages...${NC}"
echo ""

# Instalar todas as dependências de tipos de uma vez
npm install --save-dev \
  @types/jsonwebtoken \
  @types/cors \
  @types/bcrypt \
  @types/node

echo ""
echo -e "${GREEN}âœ… Dependências de tipos instaladas!${NC}"
echo ""

# Verificar instalação
echo "🔍 Verificando instalação..."
echo ""

if [ -d "node_modules/@types/jsonwebtoken" ]; then
  echo -e "${GREEN}âœ" @types/jsonwebtoken${NC}"
else
  echo -e "❌ @types/jsonwebtoken - FALHOU"
fi

if [ -d "node_modules/@types/cors" ]; then
  echo -e "${GREEN}âœ" @types/cors${NC}"
else
  echo -e "❌ @types/cors - FALHOU"
fi

if [ -d "node_modules/@types/bcrypt" ]; then
  echo -e "${GREEN}âœ" @types/bcrypt${NC}"
else
  echo -e "❌ @types/bcrypt - FALHOU"
fi

if [ -d "node_modules/@types/node" ]; then
  echo -e "${GREEN}âœ" @types/node${NC}"
else
  echo -e "❌ @types/node - FALHOU"
fi

echo ""
echo -e "${GREEN}✅ SCRIPT 1 CONCLUÍDO!${NC}"
echo ""
echo "📊 Impacto esperado: ~15 erros de tipo resolvidos"
echo ""
echo "🎯 Próximo passo:"
echo "   Execute: ./fix-config-files.sh"
echo ""
