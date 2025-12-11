#!/bin/bash

echo "🔧 SCRIPT 7: Corrigindo Controllers e Services"
echo "=============================================="
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 1. Corrigir AuthController - mudar de instância para static
echo -e "${YELLOW}📝 Corrigindo AuthController...${NC}"
if [ -f "src/api/controllers/auth/AuthController.ts" ]; then
  cat > src/api/controllers/auth/AuthController.ts << 'EOF'
import { Request, Response } from 'express';
import { AuthService } from '@core/services/auth/AuthService';

export class AuthController {
  static async register(req: Request, res: Response): Promise<void> {
    try {
      const result = await AuthService.register(req.body);
      res.status(201).json(result);
    } catch (error) {
      res.status(400).json({ error: (error as Error).message });
    }
  }

  static async login(req: Request, res: Response): Promise<void> {
    try {
      const result = await AuthService.login(req.body);
      res.json(result);
    } catch (error) {
      res.status(401).json({ error: (error as Error).message });
    }
  }

  static async refreshToken(req: Request, res: Response): Promise<void> {
    try {
      const { refreshToken } = req.body;
      const result = await AuthService.refreshToken(refreshToken);
      res.json(result);
    } catch (error) {
      res.status(401).json({ error: (error as Error).message });
    }
  }
}
EOF
  echo -e "${GREEN}✓ AuthController corrigido (static methods)${NC}"
else
  echo -e "⚠ AuthController não encontrado"
fi

echo ""

# 2. Corrigir UserController - caminho do import
echo -e "${YELLOW}📝 Corrigindo UserController...${NC}"
if [ -f "src/api/controllers/users/UserController.ts" ]; then
  sed -i "s|from '../../../core/services/auth/UserService'|from '@core/services/user/UserService'|g" src/api/controllers/users/UserController.ts
  sed -i 's/userService\./UserService./g' src/api/controllers/users/UserController.ts
  echo -e "${GREEN}✓ UserController corrigido${NC}"
else
  echo -e "⚠ UserController não encontrado"
fi

echo ""

# 3. Corrigir RateLimiterMiddleware
echo -e "${YELLOW}📝 Corrigindo RateLimiterMiddleware...${NC}"
if [ -f "src/api/middlewares/rateLimiter.ts" ]; then
  sed -i 's/rateLimiterService\./RateLimiterService./g' src/api/middlewares/rateLimiter.ts
  echo -e "${GREEN}✓ RateLimiterMiddleware corrigido${NC}"
else
  echo -e "⚠ RateLimiterMiddleware não encontrado"
fi

echo ""
echo -e "${GREEN}✅ SCRIPT 7 CONCLUÍDO!${NC}"
echo ""
echo "📊 Controllers e Services corrigidos"
echo ""
echo "🧪 Validação:"
echo "   npm run build 2>&1 | grep -c 'error TS'"
echo ""
