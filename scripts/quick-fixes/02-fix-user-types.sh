#!/bin/bash
# Script 2: Create user.types.ts

cd ~/shaka-api

echo "📝 Creating user.types.ts..."
cat > src/core/types/user.types.ts << 'EOF'
export interface CreateUserData {
  email: string;
  password: string;
  name?: string;
}

export interface UpdateUserData {
  name?: string;
  email?: string;
}

export interface User {
  id: string;
  email: string;
  password: string;
  name?: string;
  createdAt: Date;
}
EOF

echo "✅ User types created"
