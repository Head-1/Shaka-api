/**
 * API Key Management Types
 * Defines interfaces and types for API key operations
 */
export interface ApiKey {
  id: string;
  userId: string;
  name: string;
  keyHash: string;
  keyPreview: string;
  permissions: ApiKeyPermission[];
  rateLimit: number;
  isActive: boolean;
  lastUsedAt: Date | undefined;
  expiresAt: Date | undefined;
  createdAt: Date;
  updatedAt: Date;
}

export type ApiKeyPermission = 'read' | 'write' | 'delete' | 'admin';

export interface CreateApiKeyDTO {
  userId: string;
  name: string;
  permissions?: ApiKeyPermission[];
  rateLimit?: number;
  expiresAt?: Date;
}

export interface ApiKeyWithPlaintext extends ApiKey {
  key: string;
  message: string;
}

export interface ValidateApiKeyResult {
  isValid: boolean;
  user?: any;
  apiKey?: ApiKey;
  reason?: string;
}

export interface ApiKeyUsageStats {
  totalRequests: number;
  requestsToday: number;
  lastUsed: Date | null;
  averageLatency: number;
  errorRate: number;
}
