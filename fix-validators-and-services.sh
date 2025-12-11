#!/bin/bash

echo "🔧 Corrigindo Validators e Services para Match com Testes"
echo "========================================================="
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}1️⃣ Criando user.validator.ts completo...${NC}"

cat > src/api/validators/user.validator.ts << 'EOF'
import Joi from 'joi';

// Schemas Joi
export const registerUserSchema = Joi.object({
  name: Joi.string().min(3).max(100).required(),
  email: Joi.string().email().required(),
  password: Joi.string()
    .min(8)
    .pattern(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&#])[A-Za-z\d@$!%*?&#]/)
    .required()
    .messages({
      'string.pattern.base': 'Password must contain at least one uppercase letter, one lowercase letter, one number and one special character'
    }),
  plan: Joi.string().valid('starter', 'pro', 'business').default('starter')
});

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

export const userQuerySchema = Joi.object({
  page: Joi.string().pattern(/^\d+$/).default('1'),
  limit: Joi.string().pattern(/^\d+$/).max(100).default('10')
});

// Funções de validação (wrapper para os testes)
export function validateUserRegistration(data: any) {
  return registerUserSchema.validate(data);
}

export function validateUserUpdate(data: any) {
  return updateUserSchema.validate(data);
}

export function validatePasswordChange(data: any) {
  return changePasswordSchema.validate(data);
}

export function validateUserQuery(data: any) {
  return userQuerySchema.validate(data);
}
EOF

echo -e "${GREEN}✓ user.validator.ts atualizado${NC}"
echo ""

echo -e "${YELLOW}2️⃣ Adicionando métodos faltantes no PasswordService...${NC}"

cat > src/core/services/auth/PasswordService.ts << 'EOF'
import bcrypt from 'bcrypt';
import { logger } from '../../../config/logger';

export class PasswordService {
  private static readonly SALT_ROUNDS = 12;
  private static readonly MIN_PASSWORD_LENGTH = 8;

  // Método original (mantido para compatibilidade)
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
    if (!/[@$!%*?&#]/.test(password)) {
      errors.push('Must contain special character');
    }

    return {
      valid: errors.length === 0,
      errors
    };
  }

  // Novo método para os testes
  static validatePasswordStrength(password: string): { isValid: boolean; errors: string[] } {
    const errors: string[] = [];

    if (password.length < this.MIN_PASSWORD_LENGTH) {
      errors.push('Password must be at least 8 characters long');
    }
    if (!/[a-z]/.test(password)) {
      errors.push('Password must contain at least one lowercase letter');
    }
    if (!/[A-Z]/.test(password)) {
      errors.push('Password must contain at least one uppercase letter');
    }
    if (!/\d/.test(password)) {
      errors.push('Password must contain at least one number');
    }
    if (!/[@$!%*?&#]/.test(password)) {
      errors.push('Password must contain at least one special character');
    }

    return {
      isValid: errors.length === 0,
      errors
    };
  }

  static async hashPassword(password: string): Promise<string> {
    try {
      return await bcrypt.hash(password, this.SALT_ROUNDS);
    } catch (error) {
      logger.error('Error hashing password', error);
      throw new Error('Failed to hash password');
    }
  }

  static async comparePassword(plainPassword: string, hashedPassword: string): Promise<boolean> {
    try {
      return await bcrypt.compare(plainPassword, hashedPassword);
    } catch (error) {
      logger.error('Error comparing passwords', error);
      throw new Error('Failed to compare passwords');
    }
  }

  static generateRandomPassword(length: number = 16): string {
    const lowercase = 'abcdefghijklmnopqrstuvwxyz';
    const uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const numbers = '0123456789';
    const special = '@$!%*?&#';
    const allChars = lowercase + uppercase + numbers + special;

    let password = '';
    
    // Garantir pelo menos 1 de cada tipo
    password += lowercase[Math.floor(Math.random() * lowercase.length)];
    password += uppercase[Math.floor(Math.random() * uppercase.length)];
    password += numbers[Math.floor(Math.random() * numbers.length)];
    password += special[Math.floor(Math.random() * special.length)];

    // Preencher o resto
    for (let i = password.length; i < length; i++) {
      password += allChars[Math.floor(Math.random() * allChars.length)];
    }

    // Embaralhar
    return password.split('').sort(() => Math.random() - 0.5).join('');
  }
}
EOF

echo -e "${GREEN}✓ PasswordService.ts atualizado${NC}"
echo ""

echo -e "${YELLOW}3️⃣ Adicionando métodos faltantes no TokenService...${NC}"

cat > src/core/services/auth/TokenService.ts << 'EOF'
import jwt from 'jsonwebtoken';
import { TokenPayload, AuthTokens } from '../../types/auth.types';
import { logger } from '../../../config/logger';

export class TokenService {
  private static readonly ACCESS_TOKEN_EXPIRY = '15m';
  private static readonly REFRESH_TOKEN_EXPIRY = '7d';
  private static readonly JWT_SECRET = process.env.JWT_SECRET || 'dev-secret-change-in-prod';
  private static readonly JWT_REFRESH_SECRET = process.env.JWT_REFRESH_SECRET || 'dev-refresh-secret';

  // Método original (mantido)
  static generateTokens(payload: Omit<TokenPayload, 'iat' | 'exp'>): AuthTokens {
    const accessToken = jwt.sign(payload, this.JWT_SECRET, {
      expiresIn: this.ACCESS_TOKEN_EXPIRY
    });

    const refreshToken = jwt.sign(
      { userId: payload.userId },
      this.JWT_REFRESH_SECRET,
      { expiresIn: this.REFRESH_TOKEN_EXPIRY }
    );

    return { accessToken, refreshToken };
  }

  // Novos métodos para os testes
  static generateAccessToken(userId: string, email: string, plan: string): string {
    return jwt.sign(
      { userId, email, plan, type: 'access' },
      this.JWT_SECRET,
      { expiresIn: this.ACCESS_TOKEN_EXPIRY }
    );
  }

  static generateRefreshToken(userId: string): string {
    return jwt.sign(
      { userId, type: 'refresh' },
      this.JWT_REFRESH_SECRET,
      { expiresIn: this.REFRESH_TOKEN_EXPIRY }
    );
  }

  static verifyAccessToken(token: string): any {
    try {
      const decoded = jwt.verify(token, this.JWT_SECRET) as any;
      
      if (decoded.type && decoded.type !== 'access') {
        throw new Error('Invalid token type');
      }
      
      return decoded;
    } catch (error) {
      logger.error('Error verifying access token', error);
      throw error;
    }
  }

  static verifyRefreshToken(token: string): any {
    try {
      const decoded = jwt.verify(token, this.JWT_REFRESH_SECRET) as any;
      
      if (decoded.type && decoded.type !== 'refresh') {
        throw new Error('Invalid token type');
      }
      
      return decoded;
    } catch (error) {
      logger.error('Error verifying refresh token', error);
      throw error;
    }
  }

  static decodeToken(token: string): any {
    try {
      return jwt.decode(token);
    } catch (error) {
      logger.error('Error decoding token', error);
      return null;
    }
  }

  static isTokenExpired(token: string): boolean {
    try {
      const decoded = this.decodeToken(token);
      if (!decoded || !decoded.exp) {
        return true;
      }
      
      return decoded.exp * 1000 < Date.now();
    } catch (error) {
      return true;
    }
  }

  static verifyToken(token: string): TokenPayload {
    try {
      return jwt.verify(token, this.JWT_SECRET) as TokenPayload;
    } catch (error) {
      logger.error('Token verification failed', error);
      throw new Error('Invalid or expired token');
    }
  }
}
EOF

echo -e "${GREEN}✓ TokenService.ts atualizado${NC}"
echo ""

echo -e "${YELLOW}4️⃣ Testando novamente...${NC}"
echo ""

npm run test:unit

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ CORREÇÃO APLICADA!${NC}"
echo -e "${GREEN}========================================${NC}"
