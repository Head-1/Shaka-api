#!/bin/bash

echo "🔧 Correção Definitiva - Jest Types"
echo "===================================="
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}1️⃣ Removendo tests/setup.ts problemático...${NC}"
rm -f tests/setup.ts

echo -e "${GREEN}✓ Removido${NC}"
echo ""

echo -e "${YELLOW}2️⃣ Atualizando jest.config.js (removendo setupFilesAfterEnv)...${NC}"

cat > jest.config.js << 'EOF'
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  roots: ['<rootDir>/tests'],
  testMatch: ['**/*.test.ts'],
  moduleNameMapper: {
    '^@config/(.*)$': '<rootDir>/src/config/$1',
    '^@core/(.*)$': '<rootDir>/src/core/$1',
    '^@infrastructure/(.*)$': '<rootDir>/src/infrastructure/$1',
    '^@domain/(.*)$': '<rootDir>/src/domain/$1',
    '^@api/(.*)$': '<rootDir>/src/api/$1'
  },
  collectCoverageFrom: [
    'src/**/*.ts',
    '!src/**/*.d.ts',
    '!src/server.ts',
    '!src/**/*.types.ts'
  ],
  coverageDirectory: 'coverage',
  coverageReporters: ['text', 'lcov', 'html'],
  coverageThreshold: {
    global: {
      branches: 70,
      functions: 70,
      lines: 70,
      statements: 70
    }
  },
  testTimeout: 10000,
  globals: {
    'ts-jest': {
      isolatedModules: true
    }
  }
};
EOF

echo -e "${GREEN}✓ jest.config.js atualizado${NC}"
echo ""

echo -e "${YELLOW}3️⃣ Criando tests/jest.setup.js (JavaScript puro)...${NC}"

cat > tests/jest.setup.js << 'EOF'
// Setup em JavaScript (sem tipos)
process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'test-jwt-secret-key';
process.env.JWT_REFRESH_SECRET = 'test-jwt-refresh-secret-key';
EOF

echo -e "${GREEN}✓ jest.setup.js criado${NC}"
echo ""

echo -e "${YELLOW}4️⃣ Atualizando jest.config.js para usar o novo setup...${NC}"

cat > jest.config.js << 'EOF'
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  roots: ['<rootDir>/tests'],
  testMatch: ['**/*.test.ts'],
  moduleNameMapper: {
    '^@config/(.*)$': '<rootDir>/src/config/$1',
    '^@core/(.*)$': '<rootDir>/src/core/$1',
    '^@infrastructure/(.*)$': '<rootDir>/src/infrastructure/$1',
    '^@domain/(.*)$': '<rootDir>/src/domain/$1',
    '^@api/(.*)$': '<rootDir>/src/api/$1'
  },
  collectCoverageFrom: [
    'src/**/*.ts',
    '!src/**/*.d.ts',
    '!src/server.ts',
    '!src/**/*.types.ts'
  ],
  coverageDirectory: 'coverage',
  coverageReporters: ['text', 'lcov', 'html'],
  coverageThreshold: {
    global: {
      branches: 70,
      functions: 70,
      lines: 70,
      statements: 70
    }
  },
  setupFilesAfterEnv: ['<rootDir>/tests/jest.setup.js'],
  testTimeout: 10000,
  globals: {
    'ts-jest': {
      isolatedModules: true
    }
  }
};
EOF

echo -e "${GREEN}✓ Configuração atualizada${NC}"
echo ""

echo -e "${YELLOW}5️⃣ Testando novamente...${NC}"
echo ""

npm run test:unit

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ CORREÇÃO APLICADA!${NC}"
echo -e "${GREEN}========================================${NC}"
