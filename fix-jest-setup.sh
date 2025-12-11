#!/bin/bash

echo "🔧 Corrigindo tests/setup.ts..."
echo ""

cat > tests/setup.ts << 'EOF'
import '@jest/globals';

// Setup global para testes
process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'test-jwt-secret-key';
process.env.JWT_REFRESH_SECRET = 'test-jwt-refresh-secret-key';

// Timeout global
jest.setTimeout(10000);

// Limpar mocks após cada teste
afterEach(() => {
  jest.clearAllMocks();
});
EOF

echo "✅ tests/setup.ts corrigido!"
echo ""
echo "🧪 Testando novamente..."
npm run test:unit
