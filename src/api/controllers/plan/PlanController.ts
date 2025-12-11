import { Request, Response } from 'express';
import { SubscriptionService } from '../../../core/services/subscription/SubscriptionService';
import { PLAN_LIMITS } from '../../../core/types/subscription.types';
import logger from '../../../config/logger';

export class PlanController {
  static async list(req: Request, res: Response): Promise<void> {
    try {
      const plans = Object.entries(PLAN_LIMITS).map(([id, limits]) => ({
        id,
        name: id.charAt(0).toUpperCase() + id.slice(1),
        limits
      }));

      res.status(200).json({ plans });
    } catch (error) {
      logger.error('Error listing plans:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  static async changePlan(req: Request, res: Response): Promise<void> {
    try {
      const userId = (req as any).user?.id;
      
      if (!userId) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }

      const { plan } = req.body;
      
      const updatedSubscription = await SubscriptionService.changePlan(userId, plan);
      
      res.status(200).json({ subscription: updatedSubscription });
    } catch (error) {
      logger.error('Error changing plan:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  static async cancelSubscription(req: Request, res: Response): Promise<void> {
    try {
      const userId = (req as any).user?.id;
      
      if (!userId) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }

      await SubscriptionService.cancel(userId);
      
      res.status(200).json({ message: 'Subscription cancelled successfully' });
    } catch (error) {
      logger.error('Error cancelling subscription:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  }
}
