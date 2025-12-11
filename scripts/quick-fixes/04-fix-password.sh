#!/bin/bash
# Script 4: Add PasswordService verifyPassword method

cd ~/shaka-api

echo "📝 Creating PasswordService..."
cat > src/core/services/auth/PasswordService.ts << 'EOF'
import bcrypt from 'bcrypt';

export class PasswordService {
  static async hashPassword(password: string): Promise<string> {
    return bcrypt.hash(password, 10);
  }

  static async verifyPassword(
    password: string, 
    hash: string
  ): Promise<boolean> {
    return bcrypt.compare(password, hash);
  }
}
EOF

echo "✅ PasswordService created"
