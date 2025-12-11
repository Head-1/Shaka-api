import { Request, Response } from 'express';
import { ApiKeyService } from '../../../core/services/api-key/ApiKeyService';
import { logger } from '../../../config/logger';

export class ApiKeyController {
  /**
   * POST /api/v1/keys
   * Create new API key
   */
  static async create(req: Request, res: Response): Promise<void> {
    try {
      const { name, permissions, expiresAt } = req.body;
      const userId = req.user!.id;

      logger.info('[ApiKeyController] Creating API key', { userId, name });

      const apiKey = await ApiKeyService.createKey({
        userId,
        name,
        permissions,
        expiresAt: expiresAt ? new Date(expiresAt) : undefined
      });

      res.status(201).json({
        success: true,
        data: apiKey,
        message: 'API key created successfully. Store it securely - it will not be shown again.'
      });
    } catch (error: any) {
      logger.error('[ApiKeyController] Error creating API key:', error);
      
      const statusCode = error.statusCode || 500;
      res.status(statusCode).json({
        success: false,
        error: error.message || 'Failed to create API key'
      });
    }
  }

  /**
   * GET /api/v1/keys
   * List all API keys for authenticated user
   */
  static async list(req: Request, res: Response): Promise<void> {
    try {
      const userId = req.user!.id;

      logger.info('[ApiKeyController] Listing API keys', { userId });

      const apiKeys = await ApiKeyService.listKeys(userId);

      res.status(200).json({
        success: true,
        data: apiKeys,
        count: apiKeys.length
      });
    } catch (error: any) {
      logger.error('[ApiKeyController] Error listing API keys:', error);
      
      res.status(500).json({
        success: false,
        error: error.message || 'Failed to list API keys'
      });
    }
  }

  /**
   * GET /api/v1/keys/:id
   * Get single API key details
   */
  static async getOne(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const userId = req.user!.id;

      logger.info('[ApiKeyController] Getting API key', { userId, keyId: id });

      const apiKey = await ApiKeyService.getKey(userId, id);

      res.status(200).json({
        success: true,
        data: apiKey
      });
    } catch (error: any) {
      logger.error('[ApiKeyController] Error getting API key:', error);
      
      const statusCode = error.statusCode || 500;
      res.status(statusCode).json({
        success: false,
        error: error.message || 'Failed to get API key'
      });
    }
  }

  /**
   * DELETE /api/v1/keys/:id
   * Revoke API key (soft delete)
   */
  static async revoke(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const userId = req.user!.id;

      logger.info('[ApiKeyController] Revoking API key', { userId, keyId: id });

      await ApiKeyService.revokeKey(userId, id);

      res.status(200).json({
        success: true,
        message: 'API key revoked successfully'
      });
    } catch (error: any) {
      logger.error('[ApiKeyController] Error revoking API key:', error);
      
      const statusCode = error.statusCode || 500;
      res.status(statusCode).json({
        success: false,
        error: error.message || 'Failed to revoke API key'
      });
    }
  }

  /**
   * POST /api/v1/keys/:id/rotate
   * Rotate API key (revoke old, create new)
   */
  static async rotate(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const userId = req.user!.id;

      logger.info('[ApiKeyController] Rotating API key', { userId, keyId: id });

      const newApiKey = await ApiKeyService.rotateKey(userId, id);

      res.status(200).json({
        success: true,
        data: newApiKey,
        message: 'API key rotated successfully. Store the new key securely.'
      });
    } catch (error: any) {
      logger.error('[ApiKeyController] Error rotating API key:', error);
      
      const statusCode = error.statusCode || 500;
      res.status(statusCode).json({
        success: false,
        error: error.message || 'Failed to rotate API key'
      });
    }
  }

  /**
   * GET /api/v1/keys/:id/usage
   * Get usage statistics for API key
   */
  static async getUsage(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const userId = req.user!.id;

      logger.info('[ApiKeyController] Getting API key usage', { userId, keyId: id });

      const usage = await ApiKeyService.getUsageStats(userId, id);

      res.status(200).json({
        success: true,
        data: usage
      });
    } catch (error: any) {
      logger.error('[ApiKeyController] Error getting usage:', error);
      
      const statusCode = error.statusCode || 500;
      res.status(statusCode).json({
        success: false,
        error: error.message || 'Failed to get usage statistics'
      });
    }
  }

  /**
   * DELETE /api/v1/keys/:id/permanent
   * Permanently delete API key (DANGEROUS)
   */
  static async deletePermanent(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const userId = req.user!.id;

      logger.warn('[ApiKeyController] Permanently deleting API key', { userId, keyId: id });

      await ApiKeyService.deleteKey(userId, id);

      res.status(200).json({
        success: true,
        message: 'API key permanently deleted'
      });
    } catch (error: any) {
      logger.error('[ApiKeyController] Error deleting API key:', error);
      
      const statusCode = error.statusCode || 500;
      res.status(statusCode).json({
        success: false,
        error: error.message || 'Failed to delete API key'
      });
    }
  }
}
