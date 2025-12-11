#!/bin/bash
# Motor Hybrid - Build & Test
# Fase 16: Foundation

set -euo pipefail

echo "🔨 Building Motor Hybrid..."

cd ~/shaka-api

# 1. TypeScript build
echo "[1/3] Compiling TypeScript..."
npm run build

# 2. Verificar dist
echo "[2/3] Verifying compiled code..."
if [ -f dist/core/services/motor-hybrid/index.js ]; then
    echo "✅ Motor Hybrid compiled"
else
    echo "❌ Motor Hybrid NOT compiled"
    exit 1
fi

# 3. Verificar imports
echo "[3/3] Checking imports..."
grep -q "AuthMotor" dist/core/services/motor-hybrid/index.js && echo "✅ AuthMotor exported" || echo "⚠️  AuthMotor missing"

echo ""
echo "✅ Motor Hybrid build complete!"
