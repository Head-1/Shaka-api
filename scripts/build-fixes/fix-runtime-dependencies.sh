#!/bin/bash

echo "🔧 SCRIPT 19: Instalando Dependências de Runtime"
echo "================================================"
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}📦 Instalando dependências de produção...${NC}"
echo ""

# Lista completa de dependências necessárias
npm install \
  bcrypt \
  jsonwebtoken \
  cors \
  winston \
  joi \
  express \
  dotenv \
  reflect-metadata

echo ""
echo -e "${GREEN}✓ Dependências de produção instaladas${NC}"
echo ""

# Verificar instalação
echo -e "${YELLOW}🔍 Verificando instalação...${NC}"
echo ""

PACKAGES=(
  "bcrypt"
  "jsonwebtoken"
  "cors"
  "winston"
  "joi"
  "express"
  "dotenv"
  "reflect-metadata"
)

ALL_OK=true

for pkg in "${PACKAGES[@]}"; do
  if [ -d "node_modules/$pkg" ]; then
    echo -e "${GREEN}✓ $pkg${NC}"
  else
    echo -e "${RED}✗ $pkg - FALTANDO${NC}"
    ALL_OK=false
  fi
done

echo ""

if [ "$ALL_OK" = true ]; then
  echo -e "${GREEN}✅ Todas as dependências instaladas corretamente!${NC}"
else
  echo -e "${RED}⚠ Algumas dependências falharam. Tente reinstalar manualmente.${NC}"
fi

echo ""
echo -e "${GREEN}✅ SCRIPT 19 CONCLUÍDO!${NC}"
echo ""
echo "📊 Dependências instaladas:"
echo "   • bcrypt - Hash de senhas"
echo "   • jsonwebtoken - JWT tokens"
echo "   • cors - CORS middleware"
echo "   • winston - Logging"
echo "   • joi - Validação"
echo "   • express - Web framework"
echo "   • dotenv - Env variables"
echo "   • reflect-metadata - TypeORM decorators"
echo ""
echo "🧪 Testar agora:"
echo "   npm run dev"
echo ""
echo "🎯 Resultado esperado: Server iniciando! 🚀"
echo ""
