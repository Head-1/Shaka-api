#!/bin/bash

echo "🚀 FASE 3 - PARTE 4: SubscriptionService + RateLimiterService"
echo "=============================================================="

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# SubscriptionService
cat > src/core/services/subscription/SubscriptionService.ts << 'EOF'
import { v4 as uuidv4 } from 'uuid';
import { Subscription, ChangePlanData, PLAN_LIMITS } from '../../types/subscription.types';
import { logger } from '../../../config/logger';

export class SubscriptionService {
  private static subscriptions: Map<string, Subscription> = new Map();

  static async createSubscription(
    userId: string,
    plan: 'starter' | 'pro' | 'business' = 'starter'
  ): Promise<Subscription> {
    const subscription: Subscription = {
      id: uuidv4(),
      userId,
      plan,
      status: 'active',
      startDate: new Date(),
      endDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
      autoRenew: true,
      createdAt: new Date(),
      updatedAt: new Date()
    };

    this.subscriptions.set(subscription.id, subscription);
    logger.info(`Subscription created: ${subscription.id}`);
    return subscription;
  }

  static async getSubscriptionByUserId(userId: string): Promise<Subscription | null> {
    return Array.from(this.subscriptions.values())
      .find(s => s.userId === userId && s.status === 'active') || null;
  }

  static getPlanLimits(plan: 'starter' | 'pro' | 'business') {
    return PLAN_LIMITS[plan];
  }

  static async changePlan(userId: string, data: ChangePlanData): Promise<Subscription> {
    const subscription = await this.getSubscriptionByUserId(userId);
    if (!subscription) throw new Error('No active subscription');

    subscription.plan = data.newPlan;
    subscription.updatedAt = new Date();
    this.subscriptions.set(subscription.id, subscription);

    logger.info(`Plan changed: ${userId} -> ${data.newPlan}`);
    return subscription;
  }

  static async cancelSubscription(userId: string): Promise<void> {
    const subscription = await this.getSubscriptionByUserId(userId);
    if (!subscription) throw new Error('No active subscription');

    subscription.status = 'cancelled';
    subscription.autoRenew = false;
    subscription.updatedAt = new Date();
    this.subscriptions.set(subscription.id, subscription);
  }

  static async isSubscriptionActive(userId: string): Promise<boolean> {
    const subscription = await this.getSubscriptionByUserId(userId);
    if (!subscription) return false;
    if (subscription.status !== 'active') return false;
    if (subscription.endDate < new Date()) return false;
    return true;
  }
}
EOF

# RateLimiterService
cat > src/core/services/rate-limiter/RateLimiterService.ts << 'EOF'
import { RateLimitInfo, RateLimitExceeded } from '../../types/rate-limiter.types';
import { PLAN_LIMITS } from '../../types/subscription.types';
import { logger } from '../../../config/logger';

export class RateLimiterService {
  private static storage: Map<string, { count: number; resetAt: Date }> = new Map();

  static async checkLimit(
    userId: string,
    plan: 'starter' | 'pro' | 'business'
  ): Promise<RateLimitInfo> {
    const limits = PLAN_LIMITS[plan];
    const key = `ratelimit:${userId}:daily`;
    const current = this.storage.get(key);
    const now = new Date();

    if (!current || current.resetAt < now) {
      const resetAt = new Date();
      resetAt.setHours(24, 0, 0, 0);
      this.storage.set(key, { count: 0, resetAt });
      
      return {
        limit: limits.requestsPerDay,
        remaining: limits.requestsPerDay,
        reset: resetAt
      };
    }

    const remaining = Math.max(0, limits.requestsPerDay - current.count);
    return {
      limit: limits.requestsPerDay,
      remaining,
      reset: current.resetAt,
      retryAfter: remaining === 0 
        ? Math.ceil((current.resetAt.getTime() - now.getTime()) / 1000)
        : undefined
    };
  }

  static async incrementUsage(
    userId: string,
    plan: 'starter' | 'pro' | 'business'
  ): Promise<RateLimitExceeded> {
    const info = await this.checkLimit(userId, plan);
    const key = `ratelimit:${userId}:daily`;

    if (info.remaining === 0) {
      return {
        exceeded: true,
        limit: info.limit,
        current: info.limit,
        resetAt: info.reset
      };
    }

    const current = this.storage.get(key);
    if (current) {
      current.count++;
      this.storage.set(key, current);
    }

    return {
      exceeded: false,
      limit: info.limit,
      current: (current?.count || 0) + 1,
      resetAt: info.reset
    };
  }

  static async resetLimit(userId: string): Promise<void> {
    const key = `ratelimit:${userId}:daily`;
    this.storage.delete(key);
    logger.info(`Rate limit reset: ${userId}`);
  }

  static async getCurrentUsage(userId: string): Promise<number> {
    const key = `ratelimit:${userId}:daily`;
    const current = this.storage.get(key);
    return current?.count || 0;
  }
}
EOF

echo -e "${GREEN}✅ PARTE 4 CONCLUÍDA!${NC}"
echo ""
echo "Arquivos criados:"
echo "  ✓ src/core/services/subscription/SubscriptionService.ts"
echo "  ✓ src/core/services/rate-limiter/RateLimiterService.ts"
echo ""
echo -e "${GREEN}🎉 FASE 3 COMPLETA! Todos os services foram criados!${NC}"
echo ""
echo "📋 Próximos passos:"
echo "  1. Testar os services"
echo "  2. Criar testes unitários"
echo "  3. Integrar com banco de dados real"
echo ""
EOF

chmod +x setup-services-part4.sh
