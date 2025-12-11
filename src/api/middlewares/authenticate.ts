import { Request, Response, NextFunction } from 'express';
import { TokenService } from '../../core/services/auth/TokenService';
import { UserRepository } from '../../infrastructure/database/repositories/UserRepository';
import { logger } from '../../config/logger';

export const authenticate = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      res.status(401).json({
        error: 'Authentication required',
        message: 'Please provide a valid authentication token'
      });
      return;
    }

    const token = authHeader.substring(7);
    const payload = TokenService.verifyAccessToken(token);

    if (!payload) {
      res.status(401).json({
        error: 'Invalid token',
        message: 'The provided token is invalid or expired'
      });
      return;
    }

    // ✅ CORRIGIDO: Buscar usuário completo do banco
    const userEntity = await UserRepository.findById(payload.userId);

    if (!userEntity) {
      res.status(401).json({
        error: 'User not found',
        message: 'The user associated with this token no longer exists'
      });
      return;
    }

    // ✅ CORRIGIDO: Converter UserEntity para User (sem password)
    req.user = {
      id: userEntity.id,
      email: userEntity.email,
      name: userEntity.name,
      plan: userEntity.plan,
      createdAt: userEntity.createdAt,
      updatedAt: userEntity.updatedAt
    };

    next();
  } catch (error: any) {
    logger.error('[authenticate] Error:', error);
    
    res.status(401).json({
      error: 'Authentication failed',
      message: 'An error occurred during authentication'
    });
  }
};
