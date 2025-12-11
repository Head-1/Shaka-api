#!/bin/bash
# Fix PasswordService - Add missing methods

cd ~/shaka-api

echo "📝 Fixing PasswordService..."

cat > src/core/services/auth/PasswordService.ts << 'EOF'
import bcrypt from 'bcryptjs';

export class PasswordService {
  private static readonly SALT_ROUNDS = 10;

  /**
   * Hash password
   */
  static async hashPassword(password: string): Promise<string> {
    return await bcrypt.hash(password, this.SALT_ROUNDS);
  }

  /**
   * Verify password
   */
  static async verifyPassword(
    plainPassword: string,
    hashedPassword: string
  ): Promise<boolean> {
    return await bcrypt.compare(plainPassword, hashedPassword);
  }

  /**
   * Compare password (alias for verifyPassword)
   */
  static async comparePassword(
    plainPassword: string,
    hashedPassword: string
  ): Promise<boolean> {
    return await this.verifyPassword(plainPassword, hashedPassword);
  }

  /**
   * Validate password strength
   */
  static validatePasswordStrength(password: string): boolean {
    // At least 8 characters
    if (password.length < 8) {
      return false;
    }

    // At least one uppercase letter
    if (!/[A-Z]/.test(password)) {
      return false;
    }

    // At least one lowercase letter
    if (!/[a-z]/.test(password)) {
      return false;
    }

    // At least one number
    if (!/[0-9]/.test(password)) {
      return false;
    }

    return true;
  }
}
EOF

echo "✅ PasswordService fixed"
