#!/bin/bash
# Fix all types

cd ~/shaka-api

echo "📝 Creating types directory..."
mkdir -p src/core/types

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

echo "📝 Creating user.types.ts..."
cat > src/core/types/user.types.ts << 'EOF'
export interface CreateUserData {
  email: string;
  password: string;
  name?: string;
  plan?: string;
  companyName?: string;
}

export interface UpdateUserData {
  name?: string;
  email?: string;
  password?: string;
  isActive?: boolean;
  plan?: string;
  companyName?: string;
}

export interface User {
  id: string;
  email: string;
  password: string;
  name?: string;
  plan: string;
  companyName?: string;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export interface UserResponse {
  id: string;
  email: string;
  name?: string;
  plan: string;
  companyName?: string;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}
EOF

echo "✅ Types created successfully"
