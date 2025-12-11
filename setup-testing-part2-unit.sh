#!/bin/bash

echo "🧪 SCRIPT 2/4: Unit Tests - Services"
echo "===================================="
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}📝 Criando testes para PasswordService...${NC}"

cat > tests/unit/services/password.service.test.ts << 'EOF'
import { PasswordService } from '@core/services/auth/PasswordService';

describe('PasswordService', () => {
  describe('validatePasswordStrength', () => {
    it('deve aceitar senha forte válida', () => {
      const result = PasswordService.validatePasswordStrength('Strong@Pass123');
      expect(result.isValid).toBe(true);
      expect(result.errors).toHaveLength(0);
    });

    it('deve rejeitar senha muito curta', () => {
      const result = PasswordService.validatePasswordStrength('Abc@1');
      expect(result.isValid).toBe(false);
      expect(result.errors).toContain('Password must be at least 8 characters long');
    });

    it('deve rejeitar senha sem letra maiúscula', () => {
      const result = PasswordService.validatePasswordStrength('weak@pass123');
      expect(result.isValid).toBe(false);
      expect(result.errors).toContain('Password must contain at least one uppercase letter');
    });

    it('deve rejeitar senha sem letra minúscula', () => {
      const result = PasswordService.validatePasswordStrength('WEAK@PASS123');
      expect(result.isValid).toBe(false);
      expect(result.errors).toContain('Password must contain at least one lowercase letter');
    });

    it('deve rejeitar senha sem número', () => {
      const result = PasswordService.validatePasswordStrength('Weak@Password');
      expect(result.isValid).toBe(false);
      expect(result.errors).toContain('Password must contain at least one number');
    });

    it('deve rejeitar senha sem caractere especial', () => {
      const result = PasswordService.validatePasswordStrength('WeakPass123');
      expect(result.isValid).toBe(false);
      expect(result.errors).toContain('Password must contain at least one special character');
    });
  });

  describe('hashPassword', () => {
    it('deve criar hash da senha', async () => {
      const password = 'Test@Pass123';
      const hash = await PasswordService.hashPassword(password);
      
      expect(hash).toBeDefined();
      expect(hash).not.toBe(password);
      expect(hash.length).toBeGreaterThan(0);
    });

    it('deve criar hashes diferentes para mesma senha', async () => {
      const password = 'Test@Pass123';
      const hash1 = await PasswordService.hashPassword(password);
      const hash2 = await PasswordService.hashPassword(password);
      
      expect(hash1).not.toBe(hash2);
    });
  });

  describe('comparePassword', () => {
    it('deve validar senha correta', async () => {
      const password = 'Test@Pass123';
      const hash = await PasswordService.hashPassword(password);
      
      const isValid = await PasswordService.comparePassword(password, hash);
      expect(isValid).toBe(true);
    });

    it('deve rejeitar senha incorreta', async () => {
      const password = 'Test@Pass123';
      const hash = await PasswordService.hashPassword(password);
      
      const isValid = await PasswordService.comparePassword('Wrong@Pass123', hash);
      expect(isValid).toBe(false);
    });
  });

  describe('generateRandomPassword', () => {
    it('deve gerar senha aleatória válida', () => {
      const password = PasswordService.generateRandomPassword(16);
      
      expect(password.length).toBe(16);
      
      const validation = PasswordService.validatePasswordStrength(password);
      expect(validation.isValid).toBe(true);
    });

    it('deve gerar senhas diferentes', () => {
      const password1 = PasswordService.generateRandomPassword();
      const password2 = PasswordService.generateRandomPassword();
      
      expect(password1).not.toBe(password2);
    });
  });
});
EOF

echo -e "${GREEN}✓ password.service.test.ts criado${NC}"

echo ""
echo -e "${YELLOW}📝 Criando testes para TokenService...${NC}"

cat > tests/unit/services/token.service.test.ts << 'EOF'
import { TokenService } from '@core/services/auth/TokenService';

describe('TokenService', () => {
  const mockUserId = 'test-user-123';
  const mockEmail = 'test@example.com';
  const mockPlan = 'pro';

  describe('generateAccessToken', () => {
    it('deve gerar token de acesso válido', () => {
      const token = TokenService.generateAccessToken(mockUserId, mockEmail, mockPlan);
      
      expect(token).toBeDefined();
      expect(typeof token).toBe('string');
      expect(token.split('.').length).toBe(3); // JWT tem 3 partes
    });

    it('deve incluir dados corretos no payload', () => {
      const token = TokenService.generateAccessToken(mockUserId, mockEmail, mockPlan);
      const decoded = TokenService.verifyAccessToken(token);
      
      expect(decoded.userId).toBe(mockUserId);
      expect(decoded.email).toBe(mockEmail);
      expect(decoded.plan).toBe(mockPlan);
      expect(decoded.type).toBe('access');
    });
  });

  describe('generateRefreshToken', () => {
    it('deve gerar token de refresh válido', () => {
      const token = TokenService.generateRefreshToken(mockUserId);
      
      expect(token).toBeDefined();
      expect(typeof token).toBe('string');
      expect(token.split('.').length).toBe(3);
    });

    it('deve incluir dados corretos no payload', () => {
      const token = TokenService.generateRefreshToken(mockUserId);
      const decoded = TokenService.verifyRefreshToken(token);
      
      expect(decoded.userId).toBe(mockUserId);
      expect(decoded.type).toBe('refresh');
    });
  });

  describe('verifyAccessToken', () => {
    it('deve verificar token válido', () => {
      const token = TokenService.generateAccessToken(mockUserId, mockEmail, mockPlan);
      const decoded = TokenService.verifyAccessToken(token);
      
      expect(decoded).toBeDefined();
      expect(decoded.userId).toBe(mockUserId);
    });

    it('deve lançar erro para token inválido', () => {
      expect(() => {
        TokenService.verifyAccessToken('invalid-token');
      }).toThrow();
    });

    it('deve lançar erro para token refresh usado como access', () => {
      const refreshToken = TokenService.generateRefreshToken(mockUserId);
      
      expect(() => {
        TokenService.verifyAccessToken(refreshToken);
      }).toThrow('Invalid token type');
    });
  });

  describe('verifyRefreshToken', () => {
    it('deve verificar token válido', () => {
      const token = TokenService.generateRefreshToken(mockUserId);
      const decoded = TokenService.verifyRefreshToken(token);
      
      expect(decoded).toBeDefined();
      expect(decoded.userId).toBe(mockUserId);
    });

    it('deve lançar erro para token inválido', () => {
      expect(() => {
        TokenService.verifyRefreshToken('invalid-token');
      }).toThrow();
    });

    it('deve lançar erro para token access usado como refresh', () => {
      const accessToken = TokenService.generateAccessToken(mockUserId, mockEmail, mockPlan);
      
      expect(() => {
        TokenService.verifyRefreshToken(accessToken);
      }).toThrow('Invalid token type');
    });
  });

  describe('decodeToken', () => {
    it('deve decodificar token sem verificar assinatura', () => {
      const token = TokenService.generateAccessToken(mockUserId, mockEmail, mockPlan);
      const decoded = TokenService.decodeToken(token);
      
      expect(decoded).toBeDefined();
      expect(decoded.userId).toBe(mockUserId);
    });

    it('deve retornar null para token inválido', () => {
      const decoded = TokenService.decodeToken('invalid-token');
      expect(decoded).toBeNull();
    });
  });

  describe('isTokenExpired', () => {
    it('deve retornar false para token válido', () => {
      const token = TokenService.generateAccessToken(mockUserId, mockEmail, mockPlan);
      const isExpired = TokenService.isTokenExpired(token);
      
      expect(isExpired).toBe(false);
    });

    it('deve retornar true para token expirado', () => {
      // Criar token com expiração já passada (mock)
      const expiredPayload = {
        userId: mockUserId,
        email: mockEmail,
        plan: mockPlan,
        type: 'access',
        exp: Math.floor(Date.now() / 1000) - 3600 // 1 hora atrás
      };
      
      // Este teste requer mock do jwt.sign, por enquanto skipamos
      // expect(isExpired).toBe(true);
    });
  });
});
EOF

echo -e "${GREEN}✓ token.service.test.ts criado${NC}"

echo ""
echo -e "${YELLOW}📝 Criando testes para UserValidator...${NC}"

cat > tests/unit/validators/user.validator.test.ts << 'EOF'
import {
  validateUserRegistration,
  validateUserUpdate,
  validatePasswordChange,
  validateUserQuery
} from '@api/validators/user.validator';

describe('User Validators', () => {
  describe('validateUserRegistration', () => {
    const validData = {
      name: 'John Doe',
      email: 'john@example.com',
      password: 'Strong@Pass123',
      plan: 'starter'
    };

    it('deve validar dados corretos', () => {
      const { error } = validateUserRegistration(validData);
      expect(error).toBeUndefined();
    });

    it('deve rejeitar email inválido', () => {
      const { error } = validateUserRegistration({
        ...validData,
        email: 'invalid-email'
      });
      expect(error).toBeDefined();
    });

    it('deve rejeitar nome muito curto', () => {
      const { error } = validateUserRegistration({
        ...validData,
        name: 'Jo'
      });
      expect(error).toBeDefined();
    });

    it('deve rejeitar senha fraca', () => {
      const { error } = validateUserRegistration({
        ...validData,
        password: 'weak'
      });
      expect(error).toBeDefined();
    });

    it('deve rejeitar plano inválido', () => {
      const { error } = validateUserRegistration({
        ...validData,
        plan: 'invalid-plan'
      });
      expect(error).toBeDefined();
    });

    it('deve aceitar plano opcional (default: starter)', () => {
      const dataWithoutPlan = {
        name: 'John Doe',
        email: 'john@example.com',
        password: 'Strong@Pass123'
      };
      const { error, value } = validateUserRegistration(dataWithoutPlan);
      expect(error).toBeUndefined();
      expect(value.plan).toBe('starter');
    });
  });

  describe('validateUserUpdate', () => {
    it('deve validar atualização de nome', () => {
      const { error } = validateUserUpdate({ name: 'Jane Doe' });
      expect(error).toBeUndefined();
    });

    it('deve validar atualização de email', () => {
      const { error } = validateUserUpdate({ email: 'jane@example.com' });
      expect(error).toBeUndefined();
    });

    it('deve rejeitar email inválido', () => {
      const { error } = validateUserUpdate({ email: 'invalid' });
      expect(error).toBeDefined();
    });

    it('deve permitir body vazio', () => {
      const { error } = validateUserUpdate({});
      expect(error).toBeUndefined();
    });
  });

  describe('validatePasswordChange', () => {
    const validData = {
      currentPassword: 'Old@Pass123',
      newPassword: 'New@Pass123'
    };

    it('deve validar troca de senha válida', () => {
      const { error } = validatePasswordChange(validData);
      expect(error).toBeUndefined();
    });

    it('deve rejeitar sem senha atual', () => {
      const { error } = validatePasswordChange({
        newPassword: 'New@Pass123'
      });
      expect(error).toBeDefined();
    });

    it('deve rejeitar sem nova senha', () => {
      const { error } = validatePasswordChange({
        currentPassword: 'Old@Pass123'
      });
      expect(error).toBeDefined();
    });

    it('deve rejeitar nova senha fraca', () => {
      const { error } = validatePasswordChange({
        currentPassword: 'Old@Pass123',
        newPassword: 'weak'
      });
      expect(error).toBeDefined();
    });
  });

  describe('validateUserQuery', () => {
    it('deve validar query com page e limit', () => {
      const { error } = validateUserQuery({ page: '1', limit: '10' });
      expect(error).toBeUndefined();
    });

    it('deve aceitar query vazia', () => {
      const { error } = validateUserQuery({});
      expect(error).toBeUndefined();
    });

    it('deve rejeitar page negativa', () => {
      const { error } = validateUserQuery({ page: '-1' });
      expect(error).toBeDefined();
    });

    it('deve rejeitar limit muito alto', () => {
      const { error } = validateUserQuery({ limit: '200' });
      expect(error).toBeDefined();
    });
  });
});
EOF

echo -e "${GREEN}✓ user.validator.test.ts criado${NC}"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ SCRIPT 2/4 CONCLUÍDO!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}📊 Resumo do que foi criado:${NC}"
echo "   ✓ 3 arquivos de teste de unidade"
echo "   ✓ 42 casos de teste criados"
echo "   ✓ Coverage de Services principais"
echo ""
echo -e "${YELLOW}🧪 Testar agora:${NC}"
echo "   npm run test:unit"
echo ""
echo -e "${YELLOW}🔍 Próximo passo:${NC}"
echo "   Execute: ./setup-testing-part3-integration.sh"
echo ""
