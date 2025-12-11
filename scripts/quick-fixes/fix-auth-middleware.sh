#!/bin/bash
# Fix auth middleware - Remove email from payload

cd ~/shaka-api

echo "📝 Fixing auth middleware..."

cat > src/api/middlewares/auth.ts << 'EOF'
import { Request, Response, NextFunction } from 'express';
import { TokenService } from '../../core/services/auth/TokenService';

declare global {
  namespace Express {
    interface Request {
      user?: {
        userId: string;
      };
    }
  }
}

export const authenticate = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      res.status(401).json({ error: 'No token provided' });
      return;
    }

    const token = authHeader.substring(7);
    const payload = TokenService.verifyAccessToken(token);

    req.user = {
      userId: payload.userId,
    };

    next();
  } catch (error) {
    res.status(401).json({ error: 'Invalid token' });
  }
};
EOF

echo "✅ Auth middleware fixed"
