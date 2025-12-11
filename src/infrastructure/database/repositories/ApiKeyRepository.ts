import { Repository } from 'typeorm';
import { AppDataSource } from '../config';
import { ApiKeyEntity } from '../entities/ApiKeyEntity';
import { ApiKey, CreateApiKeyDTO } from '../../../core/services/api-key/types';

export class ApiKeyRepository {
  private static _repository: Repository<ApiKeyEntity> | null = null;

  static get repository(): Repository<ApiKeyEntity> {
    if (!this._repository) {
      if (!AppDataSource.isInitialized) {
        throw new Error('AppDataSource is not initialized. Call DatabaseService.initialize() first.');
      }
      this._repository = AppDataSource.getRepository(ApiKeyEntity);
    }
    return this._repository;
  }

  static initialize() {
    if (!AppDataSource.isInitialized) {
      throw new Error('AppDataSource must be initialized before ApiKeyRepository');
    }
    this._repository = AppDataSource.getRepository(ApiKeyEntity);
  }

  /**
   * Create new API key
   */
  static async create(data: CreateApiKeyDTO & { 
    keyHash: string; 
    keyPreview: string; 
    rateLimit: any 
  }): Promise<ApiKey> {
    const apiKey = this.repository.create({
      ...data,
      permissions: data.permissions || ['read', 'write'],
      isActive: true,
      lastUsedAt: null
    });

    const saved = await this.repository.save(apiKey);
    return this.toApiKey(saved);
  }

  /**
   * Find API key by hash (for validation)
   */
  static async findByHash(keyHash: string): Promise<ApiKey | null> {
    const apiKey = await this.repository.findOne({
      where: { keyHash }
    });

    return apiKey ? this.toApiKey(apiKey) : null;
  }

  /**
   * Find by ID
   */
  static async findById(id: string): Promise<ApiKey | null> {
    const apiKey = await this.repository.findOne({
      where: { id }
    });

    return apiKey ? this.toApiKey(apiKey) : null;
  }

  /**
   * Find all keys for a user
   */
  static async findByUserId(userId: string): Promise<ApiKey[]> {
    const apiKeys = await this.repository.find({
      where: { userId },
      order: { createdAt: 'DESC' }
    });

    return apiKeys.map(this.toApiKey);
  }

  /**
   * Update API key
   */
  static async update(id: string, data: Partial<ApiKey>): Promise<ApiKey | null> {
    await this.repository.update(id, data);
    return this.findById(id);
  }

  /**
   * Update lastUsedAt timestamp
   */
  static async updateLastUsed(id: string): Promise<void> {
    await this.repository.update(id, {
      lastUsedAt: new Date()
    });
  }

  /**
   * Delete API key (soft delete by setting isActive = false)
   */
  static async softDelete(id: string): Promise<void> {
    await this.repository.update(id, {
      isActive: false
    });
  }

  /**
   * Hard delete API key
   */
  static async delete(id: string): Promise<void> {
    await this.repository.delete(id);
  }

  /**
   * Count active keys for user
   */
  static async countActiveByUserId(userId: string): Promise<number> {
    return this.repository.count({
      where: { userId, isActive: true }
    });
  }

  /**
   * Convert entity to domain model
   * FIX: Converter Date | null para Date | undefined
   */
  private static toApiKey(entity: ApiKeyEntity): ApiKey {
    return {
      id: entity.id,
      userId: entity.userId,
      name: entity.name,
      keyHash: entity.keyHash,
      keyPreview: entity.keyPreview,
      permissions: entity.permissions as any[],
      rateLimit: entity.rateLimit,
      isActive: entity.isActive,
      lastUsedAt: entity.lastUsedAt || undefined,  // ⭐ FIX: null → undefined
      expiresAt: entity.expiresAt || undefined,    // ⭐ FIX: null → undefined
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt
    };
  }
}
