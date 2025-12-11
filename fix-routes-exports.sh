#!/bin/bash

echo "🔧 SCRIPT 27: Fix Routes Exports for Integration Tests"
echo "======================================================"
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# ====================
# 1. Criar health.routes.ts
# ====================
echo -e "${YELLOW}📝 Criando src/api/routes/health.routes.ts...${NC}"

cat > src/api/routes/health.routes.ts << 'EOF'
import { Router, Request, Response } from 'express';

const healthRouter = Router();

healthRouter.get('/health', async (req: Request, res: Response) => {
  try {
    const uptime = process.uptime();
    
    // Basic health check
    const healthData = {
      status: 'ok',
      timestamp: new Date().toISOString(),
      uptime: uptime,
      environment: process.env.NODE_ENV || 'development',
      services: {
        database: 'healthy', // TODO: Add real database check
        redis: 'healthy'     // TODO: Add real redis check
      }
    };

    res.status(200).json(healthData);
  } catch (error) {
    res.status(503).json({
      status: 'error',
      timestamp: new Date().toISOString(),
      error: 'Service unhealthy'
    });
  }
});

// Export both default and named
export default healthRouter;
export { healthRouter as healthRoutes };
EOF

echo -e "${GREEN}✓ health.routes.ts criado${NC}"
echo ""

# ====================
# 2. Atualizar auth.routes.ts
# ====================
echo -e "${YELLOW}📝 Atualizando src/api/routes/auth.routes.ts...${NC}"

cat > src/api/routes/auth.routes.ts << 'EOF'
import { Router } from 'express';
import { AuthController } from '../controllers/auth/AuthController';
import { validateRequest } from '../middlewares/validator';
import { registerSchema, loginSchema } from '../validators/auth.validator';

const authRouter = Router();

authRouter.post('/register', validateRequest(registerSchema), AuthController.register);
authRouter.post('/login', validateRequest(loginSchema), AuthController.login);
authRouter.post('/refresh', AuthController.refreshToken);

// Export both default and named
export default authRouter;
export { authRouter as authRoutes };
EOF

echo -e "${GREEN}✓ auth.routes.ts atualizado${NC}"
echo ""

# ====================
# 3. Atualizar user.routes.ts
# ====================
echo -e "${YELLOW}📝 Atualizando src/api/routes/user.routes.ts...${NC}"

cat > src/api/routes/user.routes.ts << 'EOF'
import { Router } from 'express';
import { UserController } from '../controllers/user/UserController';
import { authenticate } from '../middlewares/auth';
import { validateRequest } from '../middlewares/validator';
import {
  updateUserSchema,
  changePasswordSchema,
  listUsersSchema,
} from '../validators/user.validator';

const userRouter = Router();

// Todas as rotas de usuários requerem autenticação
userRouter.use(authenticate);

// Profile routes
userRouter.get('/profile', UserController.getProfile);
userRouter.put('/profile', validateRequest(updateUserSchema), UserController.updateProfile);
userRouter.put('/password', validateRequest(changePasswordSchema), UserController.changePassword);

// Admin routes
userRouter.get('/:id', UserController.getById);
userRouter.get('/', validateRequest(listUsersSchema), UserController.list);

// Export both default and named
export default userRouter;
export { userRouter as userRoutes };
EOF

echo -e "${GREEN}✓ user.routes.ts atualizado${NC}"
echo ""

# ====================
# 4. Atualizar plan.routes.ts
# ====================
echo -e "${YELLOW}📝 Atualizando src/api/routes/plan.routes.ts...${NC}"

cat > src/api/routes/plan.routes.ts << 'EOF'
import { Router } from 'express';
import { PlanController } from '../controllers/plan/PlanController';
import { authenticate } from '../middlewares/auth';

const planRouter = Router();

// Public route - list available plans
planRouter.get('/plans', PlanController.list);

// Protected routes - require authentication
planRouter.put('/subscriptions/plan', authenticate, PlanController.changePlan);
planRouter.delete('/subscriptions', authenticate, PlanController.cancelSubscription);

// Export both default and named
export default planRouter;
export { planRouter as planRoutes };
EOF

echo -e "${GREEN}✓ plan.routes.ts atualizado${NC}"
echo ""

# ====================
# 5. Atualizar index.ts
# ====================
echo -e "${YELLOW}📝 Atualizando src/api/routes/index.ts...${NC}"

cat > src/api/routes/index.ts << 'EOF'
import { Router } from 'express';
import authRouter from './auth.routes';
import userRouter from './user.routes';
import planRouter from './plan.routes';
import healthRouter from './health.routes';

const router = Router();

// Mount routers
router.use('/auth', authRouter);
router.use('/users', userRouter);
router.use('/', planRouter); // Plans routes already have /plans and /subscriptions prefixes
router.use('/', healthRouter); // Health route has /health prefix

export default router;
EOF

echo -e "${GREEN}✓ index.ts atualizado${NC}"
echo ""

# ====================
# Validação
# ====================
echo -e "${YELLOW}🧪 Validando arquivos criados...${NC}"

if [ -f "src/api/routes/health.routes.ts" ] && \
   [ -f "src/api/routes/auth.routes.ts" ] && \
   [ -f "src/api/routes/user.routes.ts" ] && \
   [ -f "src/api/routes/plan.routes.ts" ]; then
    echo -e "${GREEN}✓ Todos os arquivos de routes atualizados${NC}"
else
    echo -e "${RED}✗ Alguns arquivos podem estar faltando${NC}"
    exit 1
fi

# Verificar exports
echo -e "${YELLOW}🔍 Verificando exports...${NC}"
grep -q "export { healthRouter as healthRoutes }" src/api/routes/health.routes.ts && \
  echo -e "${GREEN}✓ health.routes.ts: named export OK${NC}"
  
grep -q "export { authRouter as authRoutes }" src/api/routes/auth.routes.ts && \
  echo -e "${GREEN}✓ auth.routes.ts: named export OK${NC}"
  
grep -q "export { userRouter as userRoutes }" src/api/routes/user.routes.ts && \
  echo -e "${GREEN}✓ user.routes.ts: named export OK${NC}"
  
grep -q "export { planRouter as planRoutes }" src/api/routes/plan.routes.ts && \
  echo -e "${GREEN}✓ plan.routes.ts: named export OK${NC}"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ ROUTES EXPORTS CORRIGIDO!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}📊 Resumo das correções:${NC}"
echo "  ✓ health.routes.ts criado"
echo "  ✓ auth.routes.ts atualizado com named export"
echo "  ✓ user.routes.ts atualizado com named export"
echo "  ✓ plan.routes.ts atualizado com named export"
echo "  ✓ index.ts atualizado"
echo ""
echo -e "${YELLOW}📝 Próximos passos:${NC}"
echo "  1. Testar build: npm run build"
echo "  2. Rodar integration tests: npm run test:integration"
echo "  3. Verificar se todos os testes passam"
echo ""
echo -e "${BLUE}💡 O que mudou:${NC}"
echo "  • Todos os routers agora exportam default + named export"
echo "  • health.routes.ts foi criado do zero"
echo "  • Testes de integração podem importar com nomes específicos"
echo "  • Mantida compatibilidade com código existente (default export)"
echo ""
