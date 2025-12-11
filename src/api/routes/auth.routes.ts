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
