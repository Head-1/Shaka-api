#!/bin/bash

echo "🔧 SCRIPT 29: Create Controllers with Directories"
echo "=================================================="
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# ====================
# 1. Criar diretórios necessários
# ====================
echo -e "${YELLOW}📁 Criando diretórios...${NC}"

mkdir -p src/api/controllers/user
mkdir -p src/api/controllers/plan

echo -e "${GREEN}✓ Diretórios criados${NC}"
echo ""

# ====================
# 2. Criar UserController
# ====================
echo -e "${YELLOW}📝 Criando src/api/controllers/user/UserController.ts...${NC}"

cat > src/api/controllers/user/UserController.ts << 'EOF'
import { Request, Response } from 'express';
import { UserService } from '../../../core/services/user/UserService';
import logger from '../../../config/logger';

export class UserController {
  static async getProfile(req: Request, res: Response): Promise<void> {
    try {
      const userId = (req as any).user?.id;
      
      if (!userId) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }

      const user = await UserService.getById(userId);
      
      if (!user) {
        res.status(404).json({ error: 'User not found' });
        return;
      }

      res.status(200).json({ user });
    } catch (error) {
      logger.error('Error getting profile:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  static async getById(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      
      const user = await UserService.getById(id);
      
      if (!user) {
        res.status(404).json({ error: 'User not found' });
        return;
      }

      res.status(200).json({ user });
    } catch (error) {
      logger.error('Error getting user by id:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  static async updateProfile(req: Request, res: Response): Promise<void> {
    try {
      const userId = (req as any).user?.id;
      
      if (!userId) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }

      const updateData = req.body;
      
      const updatedUser = await UserService.update(userId, updateData);
      
      res.status(200).json({ user: updatedUser });
    } catch (error) {
      logger.error('Error updating profile:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  static async changePassword(req: Request, res: Response): Promise<void> {
    try {
      const userId = (req as any).user?.id;
      
      if (!userId) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }

      const { currentPassword, newPassword } = req.body;
      
      await UserService.changePassword(userId, currentPassword, newPassword);
      
      res.status(200).json({ message: 'Password changed successfully' });
    } catch (error) {
      logger.error('Error changing password:', error);
      
      if (error instanceof Error && error.message === 'Invalid current password') {
        res.status(400).json({ error: 'Invalid current password' });
        return;
      }
      
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  static async list(req: Request, res: Response): Promise<void> {
    try {
      const page = parseInt(req.query.page as string) || 1;
      const limit = parseInt(req.query.limit as string) || 10;
      
      const result = await UserService.list(page, limit);
      
      res.status(200).json(result);
    } catch (error) {
      logger.error('Error listing users:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  }
}
EOF

echo -e "${GREEN}✓ UserController criado${NC}"
echo ""

# ====================
# 3. Criar PlanController
# ====================
echo -e "${YELLOW}📝 Criando src/api/controllers/plan/PlanController.ts...${NC}"

cat > src/api/controllers/plan/PlanController.ts << 'EOF'
import { Request, Response } from 'express';
import { SubscriptionService } from '../../../core/services/subscription/SubscriptionService';
import { PLAN_LIMITS } from '../../../core/types/subscription.types';
import logger from '../../../config/logger';

export class PlanController {
  static async list(req: Request, res: Response): Promise<void> {
    try {
      const plans = Object.entries(PLAN_LIMITS).map(([id, limits]) => ({
        id,
        name: id.charAt(0).toUpperCase() + id.slice(1),
        limits
      }));

      res.status(200).json({ plans });
    } catch (error) {
      logger.error('Error listing plans:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  static async changePlan(req: Request, res: Response): Promise<void> {
    try {
      const userId = (req as any).user?.id;
      
      if (!userId) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }

      const { plan } = req.body;
      
      const updatedSubscription = await SubscriptionService.changePlan(userId, plan);
      
      res.status(200).json({ subscription: updatedSubscription });
    } catch (error) {
      logger.error('Error changing plan:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  static async cancelSubscription(req: Request, res: Response): Promise<void> {
    try {
      const userId = (req as any).user?.id;
      
      if (!userId) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }

      await SubscriptionService.cancel(userId);
      
      res.status(200).json({ message: 'Subscription cancelled successfully' });
    } catch (error) {
      logger.error('Error cancelling subscription:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  }
}
EOF

echo -e "${GREEN}✓ PlanController criado${NC}"
echo ""

# ====================
# 4. Corrigir auth.types.ts - adicionar JWTPayload e TokenType
# ====================
echo -e "${YELLOW}📝 Atualizando src/core/types/auth.types.ts...${NC}"

cat > src/core/types/auth.types.ts << 'EOF'
export interface LoginCredentials {
  email: string;
  password: string;
}

export interface RegisterData {
  name: string;
  email: string;
  password: string;
  plan: 'starter' | 'pro' | 'business';
}

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
}

export type TokenType = 'access' | 'refresh';

export interface JWTPayload {
  userId: string;
  email: string;
  type: TokenType;
  iat?: number;
  exp?: number;
}

export interface AuthUser {
  id: string;
  email: string;
  name: string;
  plan: string;
}
EOF

echo -e "${GREEN}✓ auth.types.ts atualizado com JWTPayload e TokenType${NC}"
echo ""

# ====================
# 5. Corrigir AuthService - passar email para generateTokens
# ====================
echo -e "${YELLOW}📝 Atualizando src/core/services/auth/AuthService.ts...${NC}"

cat > src/core/services/auth/AuthService.ts << 'EOF'
import { RegisterData, LoginCredentials, AuthTokens, AuthUser } from '../../types/auth.types';
import { PasswordService } from './PasswordService';
import { TokenService } from './TokenService';
import logger from '../../../config/logger';

// Mock database - substituir por implementação real
const users = new Map<string, any>();

export class AuthService {
  static async register(data: RegisterData): Promise<{ user: AuthUser; tokens: AuthTokens }> {
    try {
      logger.info(`Registering user: ${data.email}`);

      // Verificar se usuário já existe
      if (users.has(data.email)) {
        throw new Error('User already exists');
      }

      // Validar senha
      const isPasswordValid = PasswordService.validatePasswordStrength(data.password);
      if (!isPasswordValid) {
        throw new Error('Password does not meet security requirements');
      }

      // Hash da senha
      const hashedPassword = await PasswordService.hashPassword(data.password);

      // Criar usuário
      const userId = `user_${Date.now()}`;
      const user = {
        id: userId,
        name: data.name,
        email: data.email,
        password: hashedPassword,
        plan: data.plan,
        isActive: true,
        createdAt: new Date(),
      };

      users.set(data.email, user);

      // Gerar tokens - PASSAR EMAIL
      const tokens = TokenService.generateTokens(userId, data.email);

      return {
        user: { id: user.id, email: user.email, name: user.name, plan: user.plan },
        tokens,
      };
    } catch (error) {
      logger.error('Error registering user:', error);
      throw error;
    }
  }

  static async login(credentials: LoginCredentials): Promise<{ user: AuthUser; tokens: AuthTokens }> {
    try {
      const user = users.get(credentials.email);

      if (!user) {
        throw new Error('Invalid credentials');
      }

      // Verificar senha
      const isPasswordValid = await PasswordService.comparePasswords(credentials.password, user.password);
      if (!isPasswordValid) {
        throw new Error('Invalid credentials');
      }

      // Gerar tokens - PASSAR EMAIL
      const tokens = TokenService.generateTokens(user.id, user.email);

      return {
        user: { id: user.id, email: user.email, name: user.name, plan: user.plan },
        tokens,
      };
    } catch (error) {
      logger.error('Error logging in:', error);
      throw error;
    }
  }

  static async refreshToken(refreshToken: string): Promise<AuthTokens> {
    try {
      const payload = TokenService.verifyRefreshToken(refreshToken);
      
      // Gerar novos tokens - PASSAR EMAIL
      return TokenService.generateTokens(payload.userId, payload.email);
    } catch (error) {
      logger.error('Error refreshing token:', error);
      throw error;
    }
  }

  static async validateToken(token: string): Promise<AuthUser | null> {
    try {
      const payload = TokenService.verifyAccessToken(token);
      
      const user = Array.from(users.values()).find(u => u.id === payload.userId);
      
      if (!user) {
        return null;
      }

      return { id: user.id, email: user.email, name: user.name, plan: user.plan };
    } catch (error) {
      return null;
    }
  }
}
EOF

echo -e "${GREEN}✓ AuthService.ts atualizado${NC}"
echo ""

# ====================
# 6. Corrigir env import
# ====================
echo -e "${YELLOW}📝 Verificando src/config/env.ts...${NC}"

# Verificar se env.ts exporta default
if grep -q "export default" src/config/env.ts; then
  echo -e "${GREEN}✓ env.ts já exporta default${NC}"
else
  echo -e "${YELLOW}⚠ Adicionando export default ao env.ts${NC}"
  
  # Fazer backup
  cp src/config/env.ts src/config/env.ts.backup
  
  # Adicionar export default no final se não existir
  echo "" >> src/config/env.ts
  echo "export default env;" >> src/config/env.ts
  
  echo -e "${GREEN}✓ export default adicionado${NC}"
fi

echo ""

# ====================
# Validação
# ====================
echo -e "${YELLOW}🧪 Validando arquivos criados...${NC}"

FILES_TO_CHECK=(
  "src/api/controllers/user/UserController.ts"
  "src/api/controllers/plan/PlanController.ts"
  "src/core/types/auth.types.ts"
  "src/core/services/auth/AuthService.ts"
)

ALL_OK=true
for file in "${FILES_TO_CHECK[@]}"; do
  if [ -f "$file" ]; then
    echo -e "${GREEN}✓ $file${NC}"
  else
    echo -e "${RED}✗ $file NOT FOUND${NC}"
    ALL_OK=false
  fi
done

if [ "$ALL_OK" = true ]; then
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}✅ CONTROLLERS E TYPES CORRIGIDOS!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "${BLUE}📊 Resumo:${NC}"
    echo "  ✓ Diretórios user/ e plan/ criados"
    echo "  ✓ UserController criado"
    echo "  ✓ PlanController criado"
    echo "  ✓ auth.types.ts com JWTPayload e TokenType"
    echo "  ✓ AuthService.ts corrigido (email em generateTokens)"
    echo "  ✓ env.ts com export default"
    echo ""
    echo -e "${YELLOW}📝 Próximos passos:${NC}"
    echo "  1. Build: npm run build"
    echo "  2. Testes: npm run test:integration"
    echo ""
else
    echo -e "${RED}Alguns arquivos não foram criados${NC}"
    exit 1
fi
