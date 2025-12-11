#!/bin/bash
# Fix FINAL - Baseado na investigação real do código

cd ~/shaka-api

echo "🔧 CORREÇÃO FINAL - Baseado no código existente"
echo ""

# ============================================================================
# 1. DELETAR auth.ts (arquivo novo que causou conflito)
# ============================================================================
echo "📝 1/5 - Removendo auth.ts (conflito)..."
rm -f src/api/middlewares/auth.ts

# ============================================================================
# 2. ATUALIZAR authenticate.ts (arquivo original correto)
# ============================================================================
echo "📝 2/5 - Atualizando authenticate.ts com TokenService..."

cat > src/api/middlewares/authenticate.ts << 'EOF'
import { Request, Response, NextFunction } from 'express';
import { TokenService } from '../../core/services/auth/TokenService';
import { AppError } from '../../shared/errors/AppError';
import { UserService } from '../../core/services/user/UserService';

interface JwtPayload {
  userId: string;
  email: string;
  plan: string;
}

declare global {
  namespace Express {
    interface Request {
      user?: JwtPayload;
    }
  }
}

export async function authenticate(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new AppError('No token provided', 401);
    }

    const token = authHeader.substring(7);
    const payload = TokenService.verifyAccessToken(token);

    // Buscar dados completos do usuário para ter email e plan
    const user = await UserService.getUserById(payload.userId);

    if (!user) {
      throw new AppError('User not found', 401);
    }

    // Adicionar dados completos ao request
    req.user = {
      userId: user.id,
      email: user.email,
      plan: user.plan,
    };

    next();
  } catch (error) {
    next(error);
  }
}
EOF

# ============================================================================
# 3. FIX user.routes.ts - Usar schemas corretos (Joi)
# ============================================================================
echo "📝 3/5 - Corrigindo user.routes.ts (schemas Joi)..."

cat > src/api/routes/user.routes.ts << 'EOF'
import { Router } from 'express';
import { UserController } from '../controllers/user/UserController';
import { authenticate } from '../middlewares/authenticate';
import { validateRequest } from '../middlewares/validateRequest';
import { updateUserSchema, changePasswordSchema, listUsersSchema } from '../validators/user.validator';

const userRouter = Router();

/**
 * @route   GET /api/v1/users/profile
 * @desc    Get current user profile
 * @access  Private
 */
userRouter.get('/profile', authenticate, UserController.getProfile);

/**
 * @route   PUT /api/v1/users/profile
 * @desc    Update user profile
 * @access  Private
 */
userRouter.put('/profile', authenticate, validateRequest(updateUserSchema), UserController.updateProfile);

/**
 * @route   POST /api/v1/users/change-password
 * @desc    Change password
 * @access  Private
 */
userRouter.post('/change-password', authenticate, validateRequest(changePasswordSchema), UserController.changePassword);

/**
 * @route   GET /api/v1/users/:id
 * @desc    Get user by ID
 * @access  Private (Admin)
 */
userRouter.get('/:id', authenticate, UserController.getUserById);

/**
 * @route   GET /api/v1/users
 * @desc    List all users
 * @access  Private (Admin)
 */
userRouter.get('/', authenticate, validateRequest(listUsersSchema), UserController.listUsers);

export default userRouter;
EOF

# ============================================================================
# 4. FIX PasswordService - Usar require para bcryptjs
# ============================================================================
echo "📝 4/5 - Corrigindo PasswordService (bcryptjs require)..."

cat > src/core/services/auth/PasswordService.ts << 'EOF'
const bcrypt = require('bcryptjs');

export class PasswordService {
  private static readonly SALT_ROUNDS = 10;

  /**
   * Hash password
   */
  static async hashPassword(password: string): Promise<string> {
    return await bcrypt.hash(password, this.SALT_ROUNDS);
  }

  /**
   * Verify password
   */
  static async verifyPassword(
    plainPassword: string,
    hashedPassword: string
  ): Promise<boolean> {
    return await bcrypt.compare(plainPassword, hashedPassword);
  }

  /**
   * Compare password (alias for verifyPassword)
   */
  static async comparePassword(
    plainPassword: string,
    hashedPassword: string
  ): Promise<boolean> {
    return await this.verifyPassword(plainPassword, hashedPassword);
  }

  /**
   * Validate password strength
   */
  static validatePasswordStrength(password: string): boolean {
    // At least 8 characters
    if (password.length < 8) {
      return false;
    }

    // At least one uppercase letter
    if (!/[A-Z]/.test(password)) {
      return false;
    }

    // At least one lowercase letter
    if (!/[a-z]/.test(password)) {
      return false;
    }

    // At least one number
    if (!/[0-9]/.test(password)) {
      return false;
    }

    return true;
  }
}
EOF

# ============================================================================
# 5. FIX auth.routes.ts - Usar authenticate correto
# ============================================================================
echo "📝 5/5 - Verificando auth.routes.ts..."

# Verificar se auth.routes usa o middleware correto
if grep -q "from '../middlewares/auth'" src/api/routes/auth.routes.ts 2>/dev/null; then
  sed -i "s/from '..\/middlewares\/auth'/from '..\/middlewares\/authenticate'/g" src/api/routes/auth.routes.ts
fi

echo ""
echo "✅ Todas as correções aplicadas!"
echo ""
echo "📋 Correções realizadas:"
echo "  ✅ Removido auth.ts (conflito)"
echo "  ✅ Atualizado authenticate.ts (busca user completo)"
echo "  ✅ Corrigido user.routes.ts (schemas Joi corretos)"
echo "  ✅ Corrigido PasswordService (require bcryptjs)"
echo "  ✅ Verificado auth.routes.ts"
echo ""


