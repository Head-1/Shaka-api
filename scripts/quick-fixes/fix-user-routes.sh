#!/bin/bash
# Fix user routes - Align method names

cd ~/shaka-api

echo "📝 Fixing user routes..."

cat > src/api/routes/user.routes.ts << 'EOF'
import { Router } from 'express';
import { UserController } from '../controllers/user/UserController';
import { authenticate } from '../middlewares/auth';
import { validateRequest } from '../middlewares/validateRequest';
import { updateProfileSchema, changePasswordSchema, listUsersSchema } from '../validators/user.validator';

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
userRouter.put('/profile', authenticate, validateRequest(updateProfileSchema), UserController.updateProfile);

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

echo "✅ User routes fixed"
