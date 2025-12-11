
#!/bin/bash

echo "🚀 FASE 3 - PARTE 1: Types + PasswordService"
echo "=============================================="

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Criar diretórios
echo -e "${BLUE}📁 Criando estrutura...${NC}"
mkdir -p src/core/services/auth
mkdir -p src/core/services/user
mkdir -p src/core/services/subscription
mkdir -p src/core/services/rate-limiter
mkdir -p src/core/types

# Types para Auth
cat > src/core/types/auth.types.ts << 'EOF'
export interface LoginCredentials {
  email: string;
  password: string;
}

export interface RegisterData {
  name: string;
  email: string;
  password: string;
  companyName?: string;
}

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
}

export interface TokenPayload {
  userId: string;
  email: string;
  plan: 'starter' | 'pro' | 'business';
  iat?: number;
  exp?: number;
}

export interface RefreshTokenData {
  refreshToken: string;
}
EOF

# Types para User
cat > src/core/types/user.types.ts << 'EOF'
export interface User {
  id: string;
  name: string;
  email: string;
  passwordHash: string;
  plan: 'starter' | 'pro' | 'business';
  isActive: boolean;
  companyName?: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface CreateUserData {
  name: string;
  email: string;
  password: string;
  plan?: 'starter' | 'pro' | 'business';
  companyName?: string;
}

export interface UpdateUserData {
  name?: string;
  email?: string;
  companyName?: string;
  isActive?: boolean;
}

export type UserResponse = Omit<User, 'passwordHash'>;
EOF

# Types para Subscription
cat > src/core/types/subscription.types.ts << 'EOF'
export interface Subscription {
  id: string;
  userId: string;
  plan: 'starter' | 'pro' | 'business';
  status: 'active' | 'cancelled' | 'expired';
  startDate: Date;
  endDate: Date;
  autoRenew: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export interface PlanLimits {
  requestsPerDay: number;
  requestsPerMinute: number;
  maxConcurrentRequests: number;
  features: string[];
}

export interface ChangePlanData {
  newPlan: 'starter' | 'pro' | 'business';
  reason?: string;
}

export const PLAN_LIMITS: Record<string, PlanLimits> = {
  starter: {
    requestsPerDay: 100,
    requestsPerMinute: 10,
    maxConcurrentRequests: 2,
    features: ['basic_api', 'email_support']
  },
  pro: {
    requestsPerDay: 1000,
    requestsPerMinute: 50,
    maxConcurrentRequests: 10,
    features: ['basic_api', 'advanced_api', 'priority_support', 'webhooks']
  },
  business: {
    requestsPerDay: 10000,
    requestsPerMinute: 200,
    maxConcurrentRequests: 50,
    features: ['basic_api', 'advanced_api', 'premium_support', 'webhooks', 'custom_integrations', 'dedicated_support']
  }
};
EOF

# Types para Rate Limiter
cat > src/core/types/rate-limiter.types.ts << 'EOF'
export interface RateLimitInfo {
  limit: number;
  remaining: number;
  reset: Date;
  retryAfter?: number;
}

export interface RateLimitConfig {
  windowMs: number;
  maxRequests: number;
  keyPrefix: string;
}

export interface RateLimitExceeded {
  exceeded: boolean;
  limit: number;
  current: number;
  resetAt: Date;
}
EOF

# PasswordService
cat > src/core/services/auth/PasswordService.ts << 'EOF'
import bcrypt from 'bcrypt';
import { logger } from '../../../config/logger';

export class PasswordService {
  private static readonly SALT_ROUNDS = 12;
  private static readonly MIN_PASSWORD_LENGTH = 8;

  static validatePassword(password: string): { valid: boolean; errors: string[] } {
    const errors: string[] = [];

    if (password.length < this.MIN_PASSWORD_LENGTH) {
      errors.push(`Password must be at least ${this.MIN_PASSWORD_LENGTH} characters`);
    }
    if (!/[a-z]/.test(password)) {
      errors.push('Must contain lowercase letter');
    }
    if (!/[A-Z]/.test(password)) {
      errors.push('Must contain uppercase letter');
    }
    if (!/\d/.test(password)) {
      errors.push('Must contain number');
    }
    if (!/[@$!%*?&]/.test(password)) {
      errors.push('Must contain special character (@$!%*?&)');
    }

    return { valid: errors.length === 0, errors };
  }

  static async hashPassword(password: string): Promise<string> {
    const validation = this.validatePassword(password);
    if (!validation.valid) {
      throw new Error(`Invalid password: ${validation.errors.join(', ')}`);
    }
    return bcrypt.hash(password, this.SALT_ROUNDS);
  }

  static async comparePassword(password: string, hash: string): Promise<boolean> {
    return bcrypt.compare(password, hash);
  }

  static generateRandomPassword(length: number = 16): string {
    const chars = {
      lower: 'abcdefghijklmnopqrstuvwxyz',
      upper: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
      numbers: '0123456789',
      special: '@$!%*?&'
    };
    
    const all = Object.values(chars).join('');
    let password = '';
    
    // Garantir pelo menos um de cada
    password += chars.lower[Math.floor(Math.random() * chars.lower.length)];
    password += chars.upper[Math.floor(Math.random() * chars.upper.length)];
    password += chars.numbers[Math.floor(Math.random() * chars.numbers.length)];
    password += chars.special[Math.floor(Math.random() * chars.special.length)];
    
    // Preencher resto
    for (let i = password.length; i < length; i++) {
      password += all[Math.floor(Math.random() * all.length)];
    }
    
    // Embaralhar
    return password.split('').sort(() => Math.random() - 0.5).join('');
  }
}
EOF

echo -e "${GREEN}✅ PARTE 1 CONCLUÍDA!${NC}"
echo ""
echo "Arquivos criados:"
echo "  ✓ src/core/types/auth.types.ts"
echo "  ✓ src/core/types/user.types.ts"
echo "  ✓ src/core/types/subscription.types.ts"
echo "  ✓ src/core/types/rate-limiter.types.ts"
echo "  ✓ src/core/services/auth/PasswordService.ts"
echo ""
echo "Execute agora: ./setup-services-part2.sh"
EOF

chmod +x setup-services-part1.sh
./setup-services-part1.sh
