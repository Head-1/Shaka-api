export type SubscriptionPlan = 'starter' | 'pro' | 'business' | 'enterprise';

export type SubscriptionStatus = 'active' | 'canceled' | 'past_due' | 'trialing';

export interface Subscription {
  id: string;
  userId: string;
  plan: SubscriptionPlan;
  status: SubscriptionStatus;
  stripeSubscriptionId?: string;
  stripeCustomerId?: string;
  currentPeriodStart: Date;
  currentPeriodEnd: Date;
  cancelAtPeriodEnd: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export interface PlanLimits {
  requestsPerDay: number;
  requestsPerMinute: number;
  concurrentRequests: number;
  maxApiKeys: number;  // ⭐ NOVO - Limite de API keys por plano
  features: string[];
}

export const PLAN_LIMITS: Record<SubscriptionPlan, PlanLimits> = {
  starter: {
    requestsPerDay: 100,
    requestsPerMinute: 10,
    concurrentRequests: 2,
    maxApiKeys: 1,  // ⭐ NOVO - Apenas 1 API key
    features: ['Basic API Access', 'Email Support']
  },
  pro: {
    requestsPerDay: 1000,
    requestsPerMinute: 50,
    concurrentRequests: 10,
    maxApiKeys: 5,  // ⭐ NOVO - Até 5 API keys
    features: ['Advanced API Access', 'Webhooks', 'Priority Support']
  },
  business: {
    requestsPerDay: 10000,
    requestsPerMinute: 200,
    concurrentRequests: 50,
    maxApiKeys: 20,  // ⭐ NOVO - Até 20 API keys
    features: ['Custom API Endpoints', 'SLA', 'Dedicated Support', 'White Label']
  },
  enterprise: {
    requestsPerDay: -1, // unlimited
    requestsPerMinute: 1000,
    concurrentRequests: 500,
    maxApiKeys: -1,  // ⭐ NOVO - Ilimitado
    features: ['Everything', 'Custom Integrations', 'Dedicated Account Manager']
  }
};

export interface CreateSubscriptionDTO {
  userId: string;
  plan: SubscriptionPlan;
  stripeSubscriptionId?: string;
  stripeCustomerId?: string;
}

export interface UpdateSubscriptionDTO {
  plan?: SubscriptionPlan;
  status?: SubscriptionStatus;
  cancelAtPeriodEnd?: boolean;
}
