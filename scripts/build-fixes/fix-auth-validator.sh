#!/bin/bash

echo "🔧 SCRIPT 25: Corrigindo Auth Validator"
echo "======================================="
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}📝 Atualizando auth.validator.ts...${NC}"

cat > src/api/validators/auth.validator.ts << 'EOF'
import Joi from 'joi';

export const registerSchema = Joi.object({
  name: Joi.string().min(2).max(100).required()
    .messages({
      'string.min': 'Name must be at least 2 characters',
      'string.max': 'Name must not exceed 100 characters',
      'any.required': 'Name is required'
    }),
  email: Joi.string().email().required()
    .messages({
      'string.email': 'Please provide a valid email',
      'any.required': 'Email is required'
    }),
  password: Joi.string()
    .min(8)
    .pattern(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&#])[A-Za-z\d@$!%*?&#]/)
    .required()
    .messages({
      'string.min': 'Password must be at least 8 characters',
      'string.pattern.base': 'Password must contain at least one uppercase letter, one lowercase letter, one number and one special character',
      'any.required': 'Password is required'
    }),
  plan: Joi.string().valid('starter', 'pro', 'business').default('starter')
    .messages({
      'any.only': 'Plan must be one of: starter, pro, business'
    })
});

export const loginSchema = Joi.object({
  email: Joi.string().email().required()
    .messages({
      'string.email': 'Please provide a valid email',
      'any.required': 'Email is required'
    }),
  password: Joi.string().required()
    .messages({
      'any.required': 'Password is required'
    })
});

export const refreshTokenSchema = Joi.object({
  refreshToken: Joi.string().required()
    .messages({
      'any.required': 'Refresh token is required'
    })
});
EOF

echo -e "${GREEN}✓ auth.validator.ts atualizado (name ao invés de fullName)${NC}"
echo ""
echo -e "${GREEN}✅ SCRIPT 25 CONCLUÍDO!${NC}"
echo ""
echo -e "🔄 Reiniciar servidor:"
echo -e "   ./manage-server.sh restart"
echo ""
echo -e "🧪 Testar novamente:"
echo -e "   ./load-test-api.sh"
echo ""
