#!/bin/bash
# Fix UserController - Align method names

cd ~/shaka-api

echo "📝 Fixing UserController..."

cat > src/api/controllers/user/UserController.ts << 'EOF'
import { Request, Response } from 'express';
import { UserService } from '../../../core/services/user/UserService';

export class UserController {
  /**
   * Get current user profile
   */
  static async getProfile(req: Request, res: Response): Promise<void> {
    try {
      const userId = req.user?.userId;

      if (!userId) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }

      const user = await UserService.getUserById(userId);

      res.json({
        id: user.id,
        email: user.email,
        name: user.name,
        plan: user.plan,
        isActive: user.isActive,
      });
    } catch (error) {
      res.status(500).json({ error: 'Failed to get profile' });
    }
  }

  /**
   * Get user by ID (admin)
   */
  static async getUserById(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;

      const user = await UserService.getUserById(id);

      res.json({
        id: user.id,
        email: user.email,
        name: user.name,
        plan: user.plan,
        isActive: user.isActive,
      });
    } catch (error) {
      res.status(404).json({ error: 'User not found' });
    }
  }

  /**
   * Update user profile
   */
  static async updateProfile(req: Request, res: Response): Promise<void> {
    try {
      const userId = req.user?.userId;

      if (!userId) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }

      const updateData = req.body;

      const updatedUser = await UserService.updateUser(userId, updateData);

      res.json({
        id: updatedUser.id,
        email: updatedUser.email,
        name: updatedUser.name,
      });
    } catch (error) {
      res.status(500).json({ error: 'Failed to update profile' });
    }
  }

  /**
   * Change password
   */
  static async changePassword(req: Request, res: Response): Promise<void> {
    try {
      const userId = req.user?.userId;

      if (!userId) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }

      const { currentPassword, newPassword } = req.body;

      await UserService.changePassword(userId, currentPassword, newPassword);

      res.json({ message: 'Password changed successfully' });
    } catch (error) {
      res.status(400).json({ error: 'Failed to change password' });
    }
  }

  /**
   * List users (admin)
   */
  static async listUsers(req: Request, res: Response): Promise<void> {
    try {
      const page = parseInt(req.query.page as string) || 1;
      const limit = parseInt(req.query.limit as string) || 20;

      const result = await UserService.listUsers(page, limit);

      res.json(result);
    } catch (error) {
      res.status(500).json({ error: 'Failed to list users' });
    }
  }
}
EOF

echo "✅ UserController fixed"

