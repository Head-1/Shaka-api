import { Router } from 'express';
import { DatabaseService } from '../../infrastructure/database/DatabaseService';

const router = Router();

router.get('/', async (req, res) => {
  try {
    const dbHealthy = await DatabaseService.healthCheck();

    const health = {
      status: dbHealthy ? 'healthy' : 'unhealthy',
      timestamp: new Date().toISOString(),
      service: 'shaka-api',
      version: '1.0.0',
      database: dbHealthy ? 'connected' : 'disconnected'
    };

    const statusCode = dbHealthy ? 200 : 503;
    res.status(statusCode).json(health);
  } catch (error) {
    res.status(503).json({
      status: 'unhealthy',
      timestamp: new Date().toISOString(),
      service: 'shaka-api',
      version: '1.0.0',
      database: 'error',
      error: error instanceof Error ? error.message : 'Unknown error'
    });
  }
});

export default router;
