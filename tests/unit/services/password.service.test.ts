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
