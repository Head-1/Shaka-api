import { Router } from 'express';
import { PlanController } from '../controllers/plan/PlanController';
import { authenticate } from '../middlewares/authenticate';

const planRouter = Router();

// Public route - list available plans
planRouter.get('/', PlanController.list);

// Protected routes - require authentication
planRouter.put('/', authenticate, PlanController.changePlan);
planRouter.delete('/', authenticate, PlanController.cancelSubscription);

// Export both default and named
export default planRouter;
export { planRouter as planRoutes };
