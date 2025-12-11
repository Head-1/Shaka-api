#!/bin/bash
# Script 1: Create missing type files

cd ~/shaka-api

echo "📝 Creating auth.types.ts..."
cat > src/core/types/auth.types.ts << 'EOF'
export interface LoginCredentials {
  email: string;
  password: string;
}

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
  expiresIn: string;
}

export interface JWTPayload {
  userId: string;
  type: 'access' | 'refresh';
}
EOF

echo "✅ Types created"
