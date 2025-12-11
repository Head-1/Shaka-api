/**
 * Motor Hybrid - Type Definitions
 * Status: Fase 1 - Foundation
 */

export interface AuthMotorResult {
  valid: boolean;
  userId?: string;
  payload?: any;
  error?: string;
}

export interface HealthCheckResult {
  status: 'healthy' | 'degraded' | 'unhealthy';
  timestamp: string;
  details: {
    motor: string;
    version: string;
    athosReady: boolean;
    mcpReady: boolean;
  };
}

export interface RefreshTokenResult {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
}
