import { SubscriptionService } from '../../../src/core/services/subscription/SubscriptionService';

jest.mock('../../../src/config/logger');

describe('SubscriptionService', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('create', () => {
    it('should create subscription successfully', async () => {
      const userId = 'user_123';
      const plan = 'starter' as const;

      const result = await SubscriptionService.create(userId, plan);

      expect(result).toBeDefined();
      expect(result.userId).toBe(userId);
      expect(result.plan).toBe(plan);
      expect(result.status).toBe('active');
      expect(result.id).toMatch(/^sub_/);
      expect(result.startDate).toBeInstanceOf(Date);
      expect(result.createdAt).toBeInstanceOf(Date);
    });

    it('should create subscription with pro plan', async () => {
      const userId = 'user_456';
      const plan = 'pro' as const;

      const result = await SubscriptionService.create(userId, plan);

      expect(result.plan).toBe('pro');
      expect(result.status).toBe('active');
    });

    it('should create subscription with enterprise plan', async () => {
      const userId = 'user_789';
      const plan = 'enterprise' as const;

      const result = await SubscriptionService.create(userId, plan);

      expect(result.plan).toBe('enterprise');
      expect(result.status).toBe('active');
    });

    it('should generate subscription IDs with correct format', async () => {
      const sub1 = await SubscriptionService.create('user_1', 'starter');
      
      // Aguardar 1ms para garantir timestamp diferente
      await new Promise(resolve => setTimeout(resolve, 1));
      
      const sub2 = await SubscriptionService.create('user_2', 'pro');

      expect(sub1.id).toMatch(/^sub_\d+$/);
      expect(sub2.id).toMatch(/^sub_\d+$/);
      // IDs devem ser diferentes (mesmo que minimamente)
      expect(sub1.id === sub2.id).toBe(false);
    });
  });

  describe('changePlan', () => {
    it('should change plan successfully', async () => {
      const userId = 'user_change_123';
      
      // Create initial subscription
      await SubscriptionService.create(userId, 'starter');

      // Change plan
      const result = await SubscriptionService.changePlan(userId, 'pro');

      expect(result).toBeDefined();
      expect(result.plan).toBe('pro');
      expect(result.userId).toBe(userId);
    });

    it('should throw error when subscription not found', async () => {
      await expect(
        SubscriptionService.changePlan('nonexistent_user', 'pro')
      ).rejects.toThrow('Subscription not found');
    });

    it('should upgrade from starter to pro', async () => {
      const userId = 'user_upgrade_1';
      await SubscriptionService.create(userId, 'starter');

      const result = await SubscriptionService.changePlan(userId, 'pro');

      expect(result.plan).toBe('pro');
    });

    it('should upgrade from pro to enterprise', async () => {
      const userId = 'user_upgrade_2';
      await SubscriptionService.create(userId, 'pro');

      const result = await SubscriptionService.changePlan(userId, 'enterprise');

      expect(result.plan).toBe('enterprise');
    });

    it('should downgrade from enterprise to pro', async () => {
      const userId = 'user_downgrade_1';
      await SubscriptionService.create(userId, 'enterprise');

      const result = await SubscriptionService.changePlan(userId, 'pro');

      expect(result.plan).toBe('pro');
    });
  });

  describe('cancel', () => {
    it('should cancel subscription successfully', async () => {
      const userId = 'user_cancel_123';
      
      // Create subscription first
      await SubscriptionService.create(userId, 'pro');

      // Cancel it
      await SubscriptionService.cancel(userId);

      // Verify it's cancelled
      const subscription = await SubscriptionService.getByUserId(userId);
      expect(subscription.status).toBe('cancelled');
    });

    it('should throw error when subscription not found', async () => {
      await expect(
        SubscriptionService.cancel('nonexistent_user')
      ).rejects.toThrow('Subscription not found');
    });

    it('should set cancellation date', async () => {
      const userId = 'user_cancel_date';
      await SubscriptionService.create(userId, 'starter');

      await SubscriptionService.cancel(userId);

      const subscription = await SubscriptionService.getByUserId(userId);
      expect(subscription.cancelledAt).toBeInstanceOf(Date);
    });
  });

  describe('getByUserId', () => {
    it('should return subscription when found', async () => {
      const userId = 'user_get_123';
      const plan = 'pro' as const;

      await SubscriptionService.create(userId, plan);

      const result = await SubscriptionService.getByUserId(userId);

      expect(result).toBeDefined();
      expect(result.userId).toBe(userId);
      expect(result.plan).toBe(plan);
    });

    it('should return null when subscription not found', async () => {
      const result = await SubscriptionService.getByUserId('nonexistent_user');

      expect(result).toBeNull();
    });

    it('should return complete subscription data', async () => {
      const userId = 'user_complete_data';
      await SubscriptionService.create(userId, 'enterprise');

      const result = await SubscriptionService.getByUserId(userId);

      expect(result).toHaveProperty('id');
      expect(result).toHaveProperty('userId');
      expect(result).toHaveProperty('plan');
      expect(result).toHaveProperty('status');
      expect(result).toHaveProperty('startDate');
      expect(result).toHaveProperty('createdAt');
    });
  });

  describe('isActive', () => {
    it('should return true for active subscription', async () => {
      const userId = 'user_active_123';
      await SubscriptionService.create(userId, 'pro');

      const result = await SubscriptionService.isActive(userId);

      expect(result).toBe(true);
    });

    it('should return false when subscription not found', async () => {
      const result = await SubscriptionService.isActive('nonexistent_user');

      expect(result).toBe(false);
    });

    it('should return false for cancelled subscription', async () => {
      const userId = 'user_cancelled_check';
      await SubscriptionService.create(userId, 'starter');
      await SubscriptionService.cancel(userId);

      const result = await SubscriptionService.isActive(userId);

      expect(result).toBe(false);
    });

    it('should return true after plan change', async () => {
      const userId = 'user_plan_change_active';
      await SubscriptionService.create(userId, 'starter');
      await SubscriptionService.changePlan(userId, 'pro');

      const result = await SubscriptionService.isActive(userId);

      expect(result).toBe(true);
    });
  });

  describe('SubscriptionService methods existence', () => {
    it('should have create method', () => {
      expect(typeof SubscriptionService.create).toBe('function');
    });

    it('should have changePlan method', () => {
      expect(typeof SubscriptionService.changePlan).toBe('function');
    });

    it('should have cancel method', () => {
      expect(typeof SubscriptionService.cancel).toBe('function');
    });

    it('should have getByUserId method', () => {
      expect(typeof SubscriptionService.getByUserId).toBe('function');
    });

    it('should have isActive method', () => {
      expect(typeof SubscriptionService.isActive).toBe('function');
    });
  });

  describe('Subscription lifecycle', () => {
    it('should handle complete subscription lifecycle', async () => {
      const userId = 'user_lifecycle';

      // 1. Create
      const created = await SubscriptionService.create(userId, 'starter');
      expect(created.status).toBe('active');

      // 2. Upgrade
      const upgraded = await SubscriptionService.changePlan(userId, 'pro');
      expect(upgraded.plan).toBe('pro');

      // 3. Check active
      const isActive1 = await SubscriptionService.isActive(userId);
      expect(isActive1).toBe(true);

      // 4. Cancel
      await SubscriptionService.cancel(userId);
      const isActive2 = await SubscriptionService.isActive(userId);
      expect(isActive2).toBe(false);
    });
  });
});
