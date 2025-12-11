import { Request, Response } from 'express';
import { UserService } from '../../../core/services/user/UserService';
import { logger } from '../../../config/logger';

export class UserController {
  /**
   * Get current user profile
   */
  static async getProfile(req: Request, res: Response): Promise<void> {
    try {
      const userId = req.user!.id;

      const user = await UserService.getUserById(userId);

      res.json({
        success: true,
        data: UserService.toUserResponse(user)
      });
    } catch (error: any) {
      logger.error('[UserController] Error getting profile:', error);
      
      res.status(error.statusCode || 500).json({
        success: false,
        error: error.message
      });
    }
  }

  /**
   * Get user by ID (admin only)
   */
  static async getUserById(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;

      const user = await UserService.getUserById(id);

      res.json({
        success: true,
        data: UserService.toUserResponse(user)
      });
    } catch (error: any) {
      logger.error('[UserController] Error getting user:', error);
      
      res.status(error.statusCode || 500).json({
        success: false,
        error: error.message
      });
    }
  }

  /**
   * List users (admin only)
   */
  static async listUsers(req: Request, res: Response): Promise<void> {
    try {
      const limit = parseInt(req.query.limit as string) || 100;
      const offset = parseInt(req.query.offset as string) || 0;

      const users = await UserService.listUsers(limit, offset);

      res.json({
        success: true,
        data: users.map(UserService.toUserResponse),
        pagination: {
          limit,
          offset,
          total: users.length
        }
      });
    } catch (error: any) {
      logger.error('[UserController] Error listing users:', error);
      
      res.status(error.statusCode || 500).json({
        success: false,
        error: error.message
      });
    }
  }

  /**
   * Update user profile
   */
  static async updateProfile(req: Request, res: Response): Promise<void> {
    try {
      const userId = req.user!.id;
      const updateData = req.body;

      const user = await UserService.updateUser(userId, updateData);

      res.json({
        success: true,
        data: UserService.toUserResponse(user),
        message: 'Profile updated successfully'
      });
    } catch (error: any) {
      logger.error('[UserController] Error updating profile:', error);
      
      res.status(error.statusCode || 500).json({
        success: false,
        error: error.message
      });
    }
  }

  /**
   * Change password
   */
  static async changePassword(req: Request, res: Response): Promise<void> {
    try {
      const userId = req.user!.id;
      const { currentPassword, newPassword } = req.body;

      await UserService.changePassword(userId, currentPassword, newPassword);

      res.json({
        success: true,
        message: 'Password changed successfully'
      });
    } catch (error: any) {
      logger.error('[UserController] Error changing password:', error);
      
      res.status(error.statusCode || 500).json({
        success: false,
        error: error.message
      });
    }
  }

  /**
   * Delete user account
   */
  static async deleteAccount(req: Request, res: Response): Promise<void> {
    try {
      const userId = req.user!.id;

      await UserService.deleteUser(userId);

      res.json({
        success: true,
        message: 'Account deleted successfully'
      });
    } catch (error: any) {
      logger.error('[UserController] Error deleting account:', error);
      
      res.status(error.statusCode || 500).json({
        success: false,
        error: error.message
      });
    }
  }
}
