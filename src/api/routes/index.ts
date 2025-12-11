import { Router } from 'express';
import authRoutes from './auth.routes';
import userRoutes from './user.routes';
import planRoutes from './plan.routes';
import healthRoutes from './health.routes';
import apiKeysRoutes from './api-keys.routes';

const router = Router();

// Health check (no auth required)
router.use('/health', healthRoutes);

// Authentication routes
router.use('/auth', authRoutes);

// User management routes
router.use('/users', userRoutes);

// Plan/subscription routes
router.use('/plans', planRoutes);

// API Key management routes (NEW)
router.use('/keys', apiKeysRoutes);

export default router;
