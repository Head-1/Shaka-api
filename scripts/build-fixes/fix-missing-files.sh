#!/bin/bash

echo "🔧 SCRIPT 14: Criando Arquivos Faltantes"
echo "========================================"
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 1. Criar validator middleware se não existir
echo -e "${YELLOW}📝 Criando validator.ts...${NC}"
cat > src/api/middlewares/validator.ts << 'EOF'
import { Request, Response, NextFunction } from 'express';
import Joi from 'joi';

export const validateRequest = (schema: Joi.ObjectSchema) => {
  return (req: Request, res: Response, next: NextFunction): void => {
    const { error } = schema.validate(req.body, { abortEarly: false });
    
    if (error) {
      const errors = error.details.map(detail => ({
        field: detail.path.join('.'),
        message: detail.message
      }));
      
      res.status(400).json({ errors });
      return;
    }
    
    next();
  };
};
EOF
echo -e "${GREEN}✓ validator.ts criado${NC}"

echo ""

# 2. Criar auth middleware se não existir
echo -e "${YELLOW}📝 Criando auth.ts...${NC}"
cat > src/api/middlewares/auth.ts << 'EOF'
import { Request, Response, NextFunction } from 'express';
import { TokenService } from '@core/services/auth/TokenService';

export interface AuthRequest extends Request {
  userId?: string;
  userEmail?: string;
}

export const authenticate = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      res.status(401).json({ error: 'No token provided' });
      return;
    }
    
    const token = authHeader.substring(7);
    const payload = TokenService.verifyAccessToken(token);
    
    req.userId = payload.userId;
    req.userEmail = payload.email;
    
    next();
  } catch (error) {
    res.status(401).json({ error: 'Invalid or expired token' });
  }
};
EOF
echo -e "${GREEN}✓ auth.ts criado${NC}"

echo ""

# 3. Criar user validator se não existir
echo -e "${YELLOW}📝 Criando user.validator.ts...${NC}"
mkdir -p src/api/validators
cat > src/api/validators/user.validator.ts << 'EOF'
import Joi from 'joi';

export const updateUserSchema = Joi.object({
  name: Joi.string().min(2).max(100),
  email: Joi.string().email(),
  plan: Joi.string().valid('starter', 'pro', 'business')
});

export const changePasswordSchema = Joi.object({
  currentPassword: Joi.string().required(),
  newPassword: Joi.string()
    .min(8)
    .pattern(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&#])[A-Za-z\d@$!%*?&#]/)
    .required()
    .messages({
      'string.pattern.base': 'Password must contain at least one uppercase letter, one lowercase letter, one number and one special character'
    })
});
EOF
echo -e "${GREEN}✓ user.validator.ts criado${NC}"

echo ""
echo -e "${GREEN}✅ SCRIPT 14 CONCLUÍDO!${NC}"
echo ""
echo "📊 Arquivos criados:"
echo "   • validator.ts (middleware)"
echo "   • auth.ts (middleware)"
echo "   • user.validator.ts (validator)"
echo ""
echo "🧪 Validação:"
echo "   npm run build 2>&1 | grep -c 'error TS'"
echo ""
