#!/bin/bash
# Script 5: Fix config JWT_EXPIRES_IN & install compression types

cd ~/shaka-api

echo "📝 Fixing config..."
cat >> src/config/env.ts << 'EOF'

// Add missing JWT_EXPIRES_IN
export default {
  ...config,
  JWT_EXPIRES_IN: process.env.JWT_EXPIRES_IN || '15m'
};
EOF

echo "📦 Installing compression types..."
npm install --save-dev @types/compression

echo "✅ Config & deps fixed"
