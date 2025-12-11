#!/bin/bash

echo "🧪 SCRIPT 1/4: Setup Jest + Estrutura de Testes"
echo "================================================"
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}📦 Instalando dependências de teste...${NC}"
npm install --save-dev \
  jest@29.7.0 \
  @types/jest@29.5.11 \
  ts-jest@29.1.1 \
  supertest@6.3.3 \
  @types/supertest@6.0.2

echo ""
echo -e "${YELLOW}📝 Criando jest.config.js...${NC}"

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
  setupFilesAfterEnv: ['<rootDir>/tests/setup.ts'],
  testTimeout: 10000
};
EOF

echo -e "${GREEN}✓ jest.config.js criado${NC}"

echo ""
echo -e "${YELLOW}📝 Atualizando package.json com scripts de teste...${NC}"

# Backup do package.json
cp package.json package.json.backup

# Adicionar scripts de teste
node << 'NODESCRIPT'
const fs = require('fs');
const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));

pkg.scripts = pkg.scripts || {};
pkg.scripts['test'] = 'jest';
pkg.scripts['test:watch'] = 'jest --watch';
pkg.scripts['test:coverage'] = 'jest --coverage';
pkg.scripts['test:unit'] = 'jest tests/unit';
pkg.scripts['test:integration'] = 'jest tests/integration';
pkg.scripts['test:e2e'] = 'jest tests/e2e';

fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2));
NODESCRIPT

echo -e "${GREEN}✓ package.json atualizado${NC}"

echo ""
echo -e "${YELLOW}📁 Criando estrutura de diretórios de testes...${NC}"

mkdir -p tests/{unit/{services,validators},integration/{api,database},e2e,__mocks__}

echo -e "${GREEN}✓ Estrutura criada:${NC}"
tree tests/ -L 2 2>/dev/null || find tests/ -type d

echo ""
echo -e "${YELLOW}📝 Criando arquivo de setup dos testes...${NC}"

cat > tests/setup.ts << 'EOF'
// Setup global para testes
import { config } from '@config/env';

// Mock de environment variables para testes
process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'test-jwt-secret-key';
process.env.JWT_REFRESH_SECRET = 'test-jwt-refresh-secret-key';

// Aumentar timeout global se necessário
jest.setTimeout(10000);

// Limpar mocks após cada teste
afterEach(() => {
  jest.clearAllMocks();
});
EOF

echo -e "${GREEN}✓ tests/setup.ts criado${NC}"

echo ""
echo -e "${YELLOW}📝 Criando mocks básicos...${NC}"

# Mock do DatabaseService
cat > tests/__mocks__/database.mock.ts << 'EOF'
export const mockDatabaseService = {
  initialize: jest.fn().mockResolvedValue(undefined),
  getDataSource: jest.fn().mockReturnValue({
    isInitialized: true,
    manager: {
      save: jest.fn(),
      find: jest.fn(),
      findOne: jest.fn(),
      update: jest.fn(),
      delete: jest.fn()
    }
  }),
  disconnect: jest.fn().mockResolvedValue(undefined)
};
EOF

# Mock do CacheService
cat > tests/__mocks__/cache.mock.ts << 'EOF'
export const mockCacheService = {
  initialize: jest.fn().mockResolvedValue(undefined),
  get: jest.fn(),
  set: jest.fn().mockResolvedValue('OK'),
  delete: jest.fn().mockResolvedValue(1),
  exists: jest.fn().mockResolvedValue(false),
  disconnect: jest.fn().mockResolvedValue(undefined)
};
EOF

echo -e "${GREEN}✓ Mocks criados${NC}"

echo ""
echo -e "${YELLOW}📝 Criando arquivo .env.test...${NC}"

cat > .env.test << 'EOF'
NODE_ENV=test
PORT=3001

# JWT
JWT_SECRET=test-jwt-secret-key-for-testing-only
JWT_REFRESH_SECRET=test-jwt-refresh-secret-key-for-testing-only
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=7d

# Database (usar banco de teste separado)
DB_HOST=localhost
DB_PORT=5432
DB_USER=shaka_user
DB_PASSWORD=shaka_password_2025
DB_NAME=shaka_api_test

# Redis (usar DB diferente para testes)
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=redis_secret_password
REDIS_DB=1

# Rate Limiting (valores baixos para testes)
RATE_LIMIT_WINDOW_MS=60000
RATE_LIMIT_MAX_REQUESTS=10
EOF

echo -e "${GREEN}✓ .env.test criado${NC}"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ SCRIPT 1/4 CONCLUÍDO!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}📊 Resumo do que foi criado:${NC}"
echo "   ✓ Jest e dependências instaladas"
echo "   ✓ jest.config.js configurado"
echo "   ✓ Scripts de teste no package.json"
echo "   ✓ Estrutura de pastas tests/"
echo "   ✓ Arquivo de setup"
echo "   ✓ Mocks básicos"
echo "   ✓ .env.test"
echo ""
echo -e "${YELLOW}🧪 Próximo passo:${NC}"
echo "   Execute: ./setup-testing-part2-unit.sh"
echo ""
echo -e "${YELLOW}🔍 Validação rápida:${NC}"
echo "   npm test -- --version"
echo ""
