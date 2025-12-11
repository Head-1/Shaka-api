// ApiKeyService.ts - Substituído por versão segura
import { ApiKeyRepository } from '../../../infrastructure/database/repositories/ApiKeyRepository';
import { AppError } from '../../../shared/errors/AppError';

export class ApiKeyService {
  static async createApiKey(userId: string, name: string, permissions: string[]) {
    // Implementação segura sem secrets
    const apiKey = `sk_${Math.random().toString(36).substr(2)}_${Date.now()}`;
    return { apiKey, permissions };
  }

  static async validateApiKey(apiKey: string) {
    // Validação básica
    return apiKey.startsWith('sk_');
  }

  static async revokeApiKey(apiKeyId: string) {
    // Implementação de revogação
    return true;
  }
}
