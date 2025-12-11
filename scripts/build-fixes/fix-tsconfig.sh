#!/bin/bash

echo "🔧 SCRIPT 3: Corrigindo tsconfig.json"
echo "====================================="
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Backup do tsconfig.json original
if [ -f "tsconfig.json" ]; then
  echo -e "${YELLOW}📦 Fazendo backup do tsconfig.json...${NC}"
  cp tsconfig.json tsconfig.json.backup
  echo -e "${GREEN}✓ Backup criado: tsconfig.json.backup${NC}"
  echo ""
fi

echo -e "${YELLOW}📝 Criando novo tsconfig.json com paths corretos...${NC}"

cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "lib": ["ES2020"],
    "moduleResolution": "node",
    "esModuleInterop": true,
    "allowSyntheticDefaultImports": true,
    "strict": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "outDir": "./dist",
    "rootDir": "./src",
    "baseUrl": "./src",
    "paths": {
      "@/*": ["./*"],
      "@config/*": ["./config/*"],
      "@core/*": ["./core/*"],
      "@infrastructure/*": ["./infrastructure/*"],
      "@domain/*": ["./domain/*"]
    },
    "experimentalDecorators": true,
    "emitDecoratorMetadata": true,
    "strictPropertyInitialization": false,
    "types": ["node"]
  },
  "include": [
    "src/**/*"
  ],
  "exclude": [
    "node_modules",
    "dist",
    "**/*.test.ts",
    "**/*.spec.ts"
  ]
}
EOF

echo -e "${GREEN}✓ tsconfig.json criado${NC}"
echo ""

# Verificar se foi criado
if [ -f "tsconfig.json" ]; then
  echo -e "${GREEN}✓ tsconfig.json existe${NC}"
  wc -l tsconfig.json | awk '{print "   └─ " $1 " linhas"}'
else
  echo -e "${RED}✗ tsconfig.json NÃO foi criado${NC}"
fi

echo ""
echo -e "${GREEN}✅ SCRIPT 3 CONCLUÍDO!${NC}"
echo ""
echo "📊 Mudanças aplicadas:"
echo "   • baseUrl: './src'"
echo "   • paths mapeados para @config, @core, @infrastructure, @domain"
echo "   • experimentalDecorators: true (para TypeORM)"
echo "   • emitDecoratorMetadata: true (para TypeORM)"
echo ""
echo "🧪 Validação:"
echo "   npm run build 2>&1 | grep -c 'error TS'"
echo "   (Deve mostrar ~25-30 erros agora)"
echo ""
echo "🎯 Próximo passo:"
echo "   Execute: ./fix-imports.sh"
echo ""
