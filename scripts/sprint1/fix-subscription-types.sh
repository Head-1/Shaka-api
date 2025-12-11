#!/bin/bash

# ============================================================================
# FIX: Localizar e corrigir subscription types
# ============================================================================

set -e

PROJECT_ROOT=~/shaka-api
cd "$PROJECT_ROOT"

echo "=========================================="
echo "🔍 INVESTIGANDO ESTRUTURA DE ARQUIVOS"
echo "=========================================="
echo ""

# Encontrar onde está o arquivo de types de subscription
echo "[1/3] Procurando arquivos de subscription..."

find src -name "*subscription*" -type f 2>/dev/null || true
find src/core -name "*.types.ts" -type f 2>/dev/null || true

echo ""
echo "[2/3] Verificando estrutura real..."

# Verificar estrutura de types
if [ -d "src/core/types" ]; then
    echo "✅ Diretório src/core/types/ existe"
    ls -la src/core/types/
else
    echo "❌ Diretório src/core/types/ NÃO existe"
fi

echo ""

# Verificar se subscription.types.ts existe em src/core/types/
if [ -f "src/core/types/subscription.types.ts" ]; then
    echo "✅ Arquivo src/core/types/subscription.types.ts encontrado"
    echo ""
    echo "Conteúdo atual:"
    head -50 src/core/types/subscription.types.ts
else
    echo "❌ Arquivo src/core/types/subscription.types.ts NÃO encontrado"
fi

echo ""
echo "[3/3] Criando/Atualizando subscription.types.ts na localização correta..."

# Criar diretório se não existir
mkdir -p src/core/types

# Criar arquivo atualizado com maxApiKeys
cat > src/core/types/subscription.types.ts << 'EOF'
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
EOF

echo "✅ Arquivo src/core/types/subscription.types.ts criado/atualizado"

# Corrigir import no ApiKeyService
echo ""
echo "[4/4] Corrigindo import no ApiKeyService..."

if [ -f "src/core/services/api-key/ApiKeyService.ts" ]; then
    # Substituir import
    sed -i "s|from '../subscription/types'|from '../../types/subscription.types'|g" \
        src/core/services/api-key/ApiKeyService.ts
    
    echo "✅ Import corrigido no ApiKeyService"
else
    echo "⚠️  ApiKeyService não encontrado (será criado depois)"
fi

echo ""
echo "=========================================="
echo "✅ CORREÇÃO COMPLETA"
echo "=========================================="
echo ""
echo "Arquivo atualizado:"
echo "  ✅ src/core/types/subscription.types.ts (com maxApiKeys)"
echo ""
echo "Próximo passo:"
echo "  npm run build 2>&1 | grep -c 'error TS'"
echo ""
