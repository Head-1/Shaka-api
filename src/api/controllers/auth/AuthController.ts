import { Request, Response } from 'express';
import { AuthService } from '../../../core/services/auth/AuthService';
import { logger } from '../../../config/logger';

export class AuthController {
  static async register(req: Request, res: Response): Promise<void> {
    try {
      const { email, password, name, plan } = req.body;

      const result = await AuthService.register(email, password, name, plan);

      res.status(201).json({
        success: true,
        data: {
          user: result.user,
          tokens: result.tokens
        }
      });
    } catch (error: any) {
      logger.error('[AuthController] Error during registration:', error);
      
      res.status(error.statusCode || 500).json({
        success: false,
        error: error.message
      });
    }
  }

  static async login(req: Request, res: Response): Promise<void> {
    try {
      const { email, password } = req.body;

      const result = await AuthService.login(email, password);

      res.json({
        success: true,
        data: {
          user: result.user,
          tokens: result.tokens
        }
      });
    } catch (error: any) {
      logger.error('[AuthController] Error during login:', error);
      
      res.status(error.statusCode || 500).json({
        success: false,
        error: error.message
      });
    }
  }

  static async refreshToken(req: Request, res: Response): Promise<void> {
    try {
      const { refreshToken } = req.body;

      const result = await AuthService.refreshToken(refreshToken);

      res.json({
        success: true,
        data: {
          user: result.user,
          tokens: result.tokens
        }
      });
    } catch (error: any) {
      logger.error('[AuthController] Error refreshing token:', error);
      
      res.status(error.statusCode || 500).json({
        success: false,
        error: error.message
      });
    }
  }

  static async logout(req: Request, res: Response): Promise<void> {
    try {
      const userId = req.user!.id;

      await AuthService.logout(userId);

      res.json({
        success: true,
        message: 'Logged out successfully'
      });
    } catch (error: any) {
      logger.error('[AuthController] Error during logout:', error);
      
      res.status(error.statusCode || 500).json({
        success: false,
        error: error.message
      });
    }
  }
}
