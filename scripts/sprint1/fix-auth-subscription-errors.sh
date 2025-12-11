#!/bin/bash

# ============================================================================
# SHAKA API - Fix Auth + Subscription Errors
# Corrige 7 erros finais
# ============================================================================

set -e

PROJECT_ROOT=~/shaka-api
cd "$PROJECT_ROOT"

echo "=========================================="
echo "🔧 FIX AUTH + SUBSCRIPTION - 7 ERROS"
echo "=========================================="
echo ""

# ============================================================================
# FIX 1: Corrigir AuthController (passar parâmetros corretos)
# ============================================================================

echo "[1/3] Corrigindo AuthController..."

cat > src/api/controllers/auth/AuthController.ts << 'EOF'
import { Request, Response } from 'express';
import { AuthService } from '../../../core/services/auth/AuthService';
import { logger } from '../../../config/logger';

export class AuthController {
  static async register(req: Request, res: Response): Promise<void> {
    try {
      const { email, password, plan } = req.body;

      const result = await AuthService.register(email, password, plan);

      res.status(201).json({
        success: true,
        data: {
          user: result.user,
          tokens: result.tokens
        }
      });
    } catch (error: any) {
      logger.error('[AuthController] Error during registration:', error);
      
      res.status(error.statusCode || 500).json({
        success: false,
        error: error.message
      });
    }
  }

  static async login(req: Request, res: Response): Promise<void> {
    try {
      const { email, password } = req.body;

      const result = await AuthService.login(email, password);

      res.json({
        success: true,
        data: {
          user: result.user,
          tokens: result.tokens
        }
      });
    } catch (error: any) {
      logger.error('[AuthController] Error during login:', error);
      
      res.status(error.statusCode || 500).json({
        success: false,
        error: error.message
      });
    }
  }

  static async refreshToken(req: Request, res: Response): Promise<void> {
    try {
      const { refreshToken } = req.body;

      const result = await AuthService.refreshToken(refreshToken);

      res.json({
        success: true,
        data: {
          user: result.user,
          tokens: result.tokens
        }
      });
    } catch (error: any) {
      logger.error('[AuthController] Error refreshing token:', error);
      
      res.status(error.statusCode || 500).json({
        success: false,
        error: error.message
      });
    }
  }

  static async logout(req: Request, res: Response): Promise<void> {
    try {
      const userId = req.user!.id;

      await AuthService.logout(userId);

      res.json({
        success: true,
        message: 'Logged out successfully'
      });
    } catch (error: any) {
      logger.error('[AuthController] Error during logout:', error);
      
      res.status(error.statusCode || 500).json({
        success: false,
        error: error.message
      });
    }
  }
}
EOF

echo "✅ AuthController corrigido"

# ============================================================================
# FIX 2: Corrigir SubscriptionRepository (alinhar com SubscriptionEntity)
# ============================================================================

echo "[2/3] Corrigindo SubscriptionRepository..."

cat > src/infrastructure/database/repositories/SubscriptionRepository.ts << 'EOF'
import { Repository } from 'typeorm';
import { AppDataSource } from '../config';
import { SubscriptionEntity } from '../entities/SubscriptionEntity';

export interface CreateSubscriptionData {
  userId: string;
  plan: 'starter' | 'pro' | 'business' | 'enterprise';
  stripeCustomerId?: string;
  stripeSubscriptionId?: string;
  currentPeriodStart?: Date;
  currentPeriodEnd?: Date;
}

export interface UpdateSubscriptionData {
  plan?: 'starter' | 'pro' | 'business' | 'enterprise';
  status?: 'active' | 'cancelled' | 'past_due' | 'trialing';
  stripeSubscriptionId?: string;
  currentPeriodStart?: Date;
  currentPeriodEnd?: Date;
  cancelAtPeriodEnd?: boolean;
}

export class SubscriptionRepository {
  private static repository: Repository<SubscriptionEntity>;

  static initialize() {
    this.repository = AppDataSource.getRepository(SubscriptionEntity);
  }

  static async create(data: CreateSubscriptionData): Promise<SubscriptionEntity> {
    const subscription = this.repository.create({
      userId: data.userId,
      plan: data.plan,
      status: 'active',
      stripeCustomerId: data.stripeCustomerId,
      stripeSubscriptionId: data.stripeSubscriptionId,
      currentPeriodStart: data.currentPeriodStart || new Date(),
      currentPeriodEnd: data.currentPeriodEnd,
      cancelAtPeriodEnd: false
    });

    return this.repository.save(subscription);
  }

  static async findByUserId(userId: string): Promise<SubscriptionEntity | null> {
    return this.repository.findOne({
      where: { userId }
    });
  }

  static async findById(id: string): Promise<SubscriptionEntity | null> {
    return this.repository.findOne({
      where: { id }
    });
  }

  static async update(id: string, data: UpdateSubscriptionData): Promise<SubscriptionEntity | null> {
    const updateData: any = {};

    if (data.plan !== undefined) {
      updateData.plan = data.plan;
    }

    if (data.status !== undefined) {
      updateData.status = data.status;
    }

    if (data.stripeSubscriptionId !== undefined) {
      updateData.stripeSubscriptionId = data.stripeSubscriptionId;
    }

    if (data.currentPeriodStart !== undefined) {
      updateData.currentPeriodStart = data.currentPeriodStart;
    }

    if (data.currentPeriodEnd !== undefined) {
      updateData.currentPeriodEnd = data.currentPeriodEnd;
    }

    if (data.cancelAtPeriodEnd !== undefined) {
      updateData.cancelAtPeriodEnd = data.cancelAtPeriodEnd;
    }

    if (Object.keys(updateData).length > 0) {
      await this.repository.update(id, updateData);
    }

    return this.findById(id);
  }

  static async cancel(id: string): Promise<void> {
    await this.repository.update(id, {
      cancelAtPeriodEnd: true
    });
  }

  static async delete(id: string): Promise<void> {
    await this.repository.delete(id);
  }

  static async list(limit: number = 100, offset: number = 0): Promise<SubscriptionEntity[]> {
    return this.repository.find({
      take: limit,
      skip: offset,
      order: { createdAt: 'DESC' }
    });
  }
}
EOF

echo "✅ SubscriptionRepository corrigido (alinhado com SubscriptionEntity)"

# ============================================================================
# FIX 3: Validar Build Final
# ============================================================================

echo ""
echo "[3/3] Validando build final..."
echo ""

npm run build > /tmp/build-absolute-final.log 2>&1

ERROR_COUNT=$(grep -c "error TS" /tmp/build-absolute-final.log || echo "0")

echo "=========================================="
if [ "$ERROR_COUNT" -eq "0" ]; then
    echo "🎉🎉🎉 BUILD PERFEITO! ZERO ERROS! 🎉🎉🎉"
    echo "=========================================="
    echo ""
    echo "Correções finais aplicadas:"
    echo "  ✅ AuthController.register() - 3 parâmetros corretos"
    echo "  ✅ AuthController.login() - 2 parâmetros corretos"
    echo "  ✅ SubscriptionRepository.create() - campos corretos"
    echo "  ✅ SubscriptionRepository - removido 'autoRenew'"
    echo "  ✅ SubscriptionRepository - removido status 'expired'"
    echo "  ✅ SubscriptionRepository - corrigido retorno de create()"
    echo ""
    
    JS_COUNT=$(find dist -name "*.js" 2>/dev/null | wc -l)
    echo "📦 Total de arquivos compilados: $JS_COUNT"
    echo ""
    
    echo "🎊🎊🎊 COMPILAÇÃO 100% SUCESSO! 🎊🎊🎊"
    echo ""
    echo "════════════════════════════════════════════════"
    echo "🚀 DEPLOY READY - EXECUTAR PARTE 7/8 AGORA!"
    echo "════════════════════════════════════════════════"
    echo ""
    echo "Execute:"
    echo ""
    echo "  bash scripts/sprint1/setup-build-deploy-test.sh"
    echo ""
    echo "Duração estimada: 3-5 minutos"
    echo ""
    echo "Etapas:"
    echo "  1/6 ✅ Migrations PostgreSQL"
    echo "  2/6 🐳 Docker Build"
    echo "  3/6 ☸️  Kubernetes Deploy"
    echo "  4/6 🏥 Health Check"
    echo "  5/6 📝 Criar Testes E2E"
    echo "  6/6 🧪 Executar Testes"
    echo ""
else
    echo "⚠️  AINDA HÁ $ERROR_COUNT ERRO(S)"
    echo "=========================================="
    echo ""
    grep "error TS" /tmp/build-absolute-final.log
    echo ""
    echo "Detalhes: cat /tmp/build-absolute-final.log"
    echo ""
fi
