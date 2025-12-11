/**
 * Motor Hybrid - Authentication Module
 * 
 * Responsabilidades:
 * - Centralizar lógica de autenticação
 * - Interface para ATHOS (futuro)
 * - Preparado para MCP (quando necessário)
 * 
 * Status: Fase 1 - Foundation
 */

import { AuthService } from '../../auth/AuthService';
import { TokenService } from '../../auth/TokenService';
import { AuthMotorResult, HealthCheckResult, RefreshTokenResult } from '../types';

export class AuthMotor {
  /**
   * Valida token JWT
   * ATHOS-ready: Pode ser chamado externamente
   */
  static async validateToken(token: string): Promise<AuthMotorResult> {
    try {
      const payload = TokenService.verifyAccessToken(token);
      return {
        valid: true,
        userId: payload.userId,
        payload
      };
    } catch (error: any) {
      return {
        valid: false,
        error: error.message
      };
    }
  }

  /**
   * Refresh de sessão
   */
  static async refreshSession(refreshToken: string): Promise<RefreshTokenResult> {
    return await AuthService.refresh({ refreshToken });
  }

  /**
   * Health check do motor
   * ATHOS pode monitorar este endpoint
   */
  static async healthCheck(): Promise<HealthCheckResult> {
    return {
      status: 'healthy',
      timestamp: new Date().toISOString(),
      details: {
        motor: 'auth',
        version: '1.0.0',
        athosReady: true,
        mcpReady: false
      }
    };
  }
}
