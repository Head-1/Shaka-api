#!/bin/bash

echo "🔧 SCRIPT 18: Configurando TS-Node para Resolver Paths"
echo "======================================================"
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 1. Instalar tsconfig-paths
echo -e "${YELLOW}📦 Instalando tsconfig-paths...${NC}"
npm install --save-dev tsconfig-paths
echo -e "${GREEN}✓ tsconfig-paths instalado${NC}"
echo ""

# 2. Atualizar package.json com -r tsconfig-paths/register
echo -e "${YELLOW}📝 Atualizando script dev no package.json...${NC}"

# Fazer backup do package.json
cp package.json package.json.backup

# Usar node para atualizar o JSON corretamente
node << 'NODESCRIPT'
const fs = require('fs');
const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));

// Atualizar o script dev
pkg.scripts.dev = "ts-node-dev --respawn --transpile-only -r tsconfig-paths/register src/server.ts";

// Adicionar script start se não existir
if (!pkg.scripts.start) {
  pkg.scripts.start = "node -r tsconfig-paths/register dist/server.js";
}

fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2) + '\n');
console.log('✓ package.json atualizado');
NODESCRIPT

echo -e "${GREEN}✓ Scripts atualizados${NC}"
echo ""

# 3. Atualizar tsconfig.json para incluir ts-node
echo -e "${YELLOW}📝 Atualizando tsconfig.json...${NC}"

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
  "ts-node": {
    "require": ["tsconfig-paths/register"]
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

echo -e "${GREEN}✓ tsconfig.json atualizado com ts-node config${NC}"
echo ""

# 4. Verificar instalação
echo -e "${YELLOW}🔍 Verificando instalação...${NC}"
if [ -d "node_modules/tsconfig-paths" ]; then
  echo -e "${GREEN}✓ tsconfig-paths instalado corretamente${NC}"
else
  echo -e "❌ tsconfig-paths NÃO instalado"
fi
echo ""

echo -e "${GREEN}✅ SCRIPT 18 CONCLUÍDO!${NC}"
echo ""
echo "📊 Configurações aplicadas:"
echo "   • tsconfig-paths instalado"
echo "   • package.json dev script atualizado"
echo "   • tsconfig.json com ts-node config"
echo ""
echo "🧪 Testar agora:"
echo "   npm run dev"
echo ""
echo "🎯 Resultado esperado: Server rodando sem erros! ✅"
echo ""
