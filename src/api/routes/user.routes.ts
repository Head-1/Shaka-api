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
