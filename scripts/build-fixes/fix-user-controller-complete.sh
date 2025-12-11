#!/bin/bash

echo "🔧 SCRIPT 15: Completando UserController"
echo "========================================"
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}📝 Recriando UserController com todos os métodos static...${NC}"

cat > src/api/controllers/users/UserController.ts << 'EOF'
import { Request, Response } from 'express';
import { UserService } from '@core/services/user/UserService';
import { AuthRequest } from '../../middlewares/auth';

export class UserController {
  static async getProfile(req: AuthRequest, res: Response): Promise<void> {
    try {
      const userId = req.userId!;
      const user = await UserService.getUserById(userId);
      
      if (!user) {
        res.status(404).json({ error: 'User not found' });
        return;
      }
      
      res.json({ user });
    } catch (error) {
      res.status(500).json({ error: (error as Error).message });
    }
  }

  static async updateProfile(req: AuthRequest, res: Response): Promise<void> {
    try {
      const userId = req.userId!;
      const user = await UserService.updateUser(userId, req.body);
      res.json({ user });
    } catch (error) {
      res.status(400).json({ error: (error as Error).message });
    }
  }

  static async changePassword(req: AuthRequest, res: Response): Promise<void> {
    try {
      const userId = req.userId!;
      const { currentPassword, newPassword } = req.body;
      await UserService.changePassword(userId, currentPassword, newPassword);
      res.json({ message: 'Password changed successfully' });
    } catch (error) {
      res.status(400).json({ error: (error as Error).message });
    }
  }

  static async getUserById(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const user = await UserService.getUserById(id);
      
      if (!user) {
        res.status(404).json({ error: 'User not found' });
        return;
      }
      
      res.json({ user });
    } catch (error) {
      res.status(500).json({ error: (error as Error).message });
    }
  }

  static async listUsers(req: Request, res: Response): Promise<void> {
    try {
      const page = parseInt(req.query.page as string) || 1;
      const limit = parseInt(req.query.limit as string) || 10;
      
      const result = await UserService.listUsers(page, limit);
      res.json(result);
    } catch (error) {
      res.status(500).json({ error: (error as Error).message });
    }
  }

  static async updateUser(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const user = await UserService.updateUser(id, req.body);
      res.json({ user });
    } catch (error) {
      res.status(400).json({ error: (error as Error).message });
    }
  }

  static async deactivateUser(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      await UserService.deactivateUser(id);
      res.json({ message: 'User deactivated successfully' });
    } catch (error) {
      res.status(400).json({ error: (error as Error).message });
    }
  }
}
EOF

echo -e "${GREEN}✓ UserController.ts recriado com todos os métodos static${NC}"
echo ""
echo -e "${GREEN}✅ SCRIPT 15 CONCLUÍDO!${NC}"
echo ""
echo "📊 UserController completo com:"
echo "   • getProfile (static)"
echo "   • updateProfile (static)"
echo "   • changePassword (static)"
echo "   • getUserById (static)"
echo "   • listUsers (static)"
echo "   • updateUser (static)"
echo "   • deactivateUser (static)"
echo ""
echo "🧪 Validação FINAL:"
echo "   npm run build"
echo ""
echo "🎯 Resultado esperado: BUILD SUCCESS! ✅"
echo ""
