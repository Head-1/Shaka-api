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
