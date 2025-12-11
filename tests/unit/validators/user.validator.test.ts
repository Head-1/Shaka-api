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
