#!/bin/bash

echo "🔧 SCRIPT 11: Corrigindo Routes (Instâncias → Static)"
echo "====================================================="
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 1. Corrigir auth.routes.ts
echo -e "${YELLOW}📝 Recriando auth.routes.ts completamente...${NC}"
cat > src/api/routes/auth.routes.ts << 'EOF'
import { Router } from 'express';
import { AuthController } from '../controllers/auth/AuthController';
import { validateRequest } from '../middlewares/validator';
import { registerSchema, loginSchema } from '../validators/auth.validator';

const authRouter = Router();

authRouter.post('/register', validateRequest(registerSchema), AuthController.register);
authRouter.post('/login', validateRequest(loginSchema), AuthController.login);
authRouter.post('/refresh', AuthController.refreshToken);

export default authRouter;
EOF
echo -e "${GREEN}✓ auth.routes.ts recriado${NC}"

echo ""

# 2. Corrigir user.routes.ts
echo -e "${YELLOW}📝 Recriando user.routes.ts completamente...${NC}"
cat > src/api/routes/user.routes.ts << 'EOF'
import { Router } from 'express';
import { UserController } from '../controllers/users/UserController';
import { authenticate } from '../middlewares/auth';
import { validateRequest } from '../middlewares/validator';
import { updateUserSchema, changePasswordSchema } from '../validators/user.validator';

const userRouter = Router();

userRouter.get('/profile', authenticate, UserController.getProfile);
userRouter.put('/profile', authenticate, validateRequest(updateUserSchema), UserController.updateProfile);
userRouter.post('/change-password', authenticate, validateRequest(changePasswordSchema), UserController.changePassword);
userRouter.get('/:id', authenticate, UserController.getUserById);
userRouter.get('/', authenticate, UserController.listUsers);
userRouter.put('/:id', authenticate, validateRequest(updateUserSchema), UserController.updateUser);
userRouter.delete('/:id', authenticate, UserController.deactivateUser);

export default userRouter;
EOF
echo -e "${GREEN}✓ user.routes.ts recriado${NC}"

echo ""

# 3. Corrigir plan.routes.ts
echo -e "${YELLOW}📝 Recriando plan.routes.ts completamente...${NC}"
cat > src/api/routes/plan.routes.ts << 'EOF'
import { Router } from 'express';

const planRouter = Router();

planRouter.get('/', (req, res) => {
  res.json({ message: 'Plans endpoint - To be implemented' });
});

export default planRouter;
EOF
echo -e "${GREEN}✓ plan.routes.ts recriado${NC}"

echo ""
echo -e "${GREEN}✅ SCRIPT 11 CONCLUÍDO!${NC}"
echo ""
echo "📊 Routes recriadas com static methods"
echo ""
echo "🧪 Validação:"
echo "   npm run build 2>&1 | grep -c 'error TS'"
echo ""
