import { SubscriptionPlan } from '../../types/subscription.types';
import logger from '../../../config/logger';

// Mock database
const subscriptions = new Map<string, any>();

export class SubscriptionService {
  static async create(userId: string, plan: SubscriptionPlan): Promise<any> {
    try {
      const subscription = {
        id: `sub_${Date.now()}`,
        userId,
        plan,
        status: 'active',
        startDate: new Date(),
        createdAt: new Date(),
      };

      subscriptions.set(userId, subscription);

      return subscription;
    } catch (error) {
      logger.error('Error creating subscription:', error);
      throw error;
    }
  }

  static async changePlan(userId: string, newPlan: SubscriptionPlan): Promise<any> {
    try {
      const subscription = subscriptions.get(userId);

      if (!subscription) {
        throw new Error('Subscription not found');
      }

      subscription.plan = newPlan;
      subscription.updatedAt = new Date();

      subscriptions.set(userId, subscription);

      return subscription;
    } catch (error) {
      logger.error('Error changing plan:', error);
      throw error;
    }
  }

  static async cancel(userId: string): Promise<void> {
    try {
      const subscription = subscriptions.get(userId);

      if (!subscription) {
        throw new Error('Subscription not found');
      }

      subscription.status = 'cancelled';
      subscription.cancelledAt = new Date();
      subscription.updatedAt = new Date();

      subscriptions.set(userId, subscription);
    } catch (error) {
      logger.error('Error cancelling subscription:', error);
      throw error;
    }
  }

  static async getByUserId(userId: string): Promise<any> {
    try {
      const subscription = subscriptions.get(userId);
      return subscription || null;
    } catch (error) {
      logger.error('Error getting subscription:', error);
      throw error;
    }
  }

  static async isActive(userId: string): Promise<boolean> {
    try {
      const subscription = subscriptions.get(userId);
      return subscription?.status === 'active';
    } catch (error) {
      logger.error('Error checking subscription status:', error);
      return false;
    }
  }
}
