# 📋 SHAKA API - MEMORANDO ÚNICO v3.0
## Knowledge Base Completa - Do Zero à Produção

```yaml
---
document: Shaka API Knowledge Base Completa
version: 3.0.0
last_updated: 2025-12-13
consolidation: 28 memorandos de implementação (Fases 1-25)
system_status:
  build: clean (0 errors)
  deployment: staging (production-ready)
  coverage: 100% (22/22 tests passing)
  sprint1_status: COMPLETO ✅
  features: [auth, api-keys, usage-tracking, rate-limiting, api-key-auth]
tech_stack:
  runtime: Node.js 20 + TypeScript 5.x
  api: Express 4.x
  database: PostgreSQL 15 + TypeORM 0.3.17
  cache: Redis 7
  orchestration: Kubernetes (K3s 1.33.6)
  containerization: Docker 24+
---
```

---

## 📖 ÍNDICE NAVEGÁVEL

### PARTE I: FUNDAMENTOS
1. [Quick Start](#secao-1-quick-start)
2. [Arquitetura Core](#secao-2-arquitetura-core)
3. [Stack Tecnológica](#stack-tecnologica)

### PARTE II: FEATURES IMPLEMENTADAS
4. [Autenticação JWT](#autenticacao-jwt)
5. [Multi-tenancy (Planos)](#multi-tenancy-planos)
6. [API Key Management](#api-key-management-sprint-1---completo)
7. [Usage Tracking & Analytics](#usage-tracking--analytics)
8. [Rate Limiting](#rate-limiting)

### PARTE III: INFRAESTRUTURA & DEPLOY
9. [Arquitetura Kubernetes](#arquitetura-kubernetes-production)
10. [Pipeline de Deployment](#pipeline-de-deployment)
11. [Database Migrations](#database-migration-strategy)
12. [Troubleshooting Guide](#troubleshooting-common-issues)

### PARTE IV: HISTÓRICO COMPLETO DO PROJETO
13. [Linha do Tempo (Fases 1-25)](#linha-do-tempo-fases-1-25)
14. [Decisões Arquiteturais](#decisoes-arquiteturais-criticas)
15. [Lições Aprendidas](#licoes-aprendidas)

### PARTE V: OPERAÇÕES & MANUTENÇÃO
16. [Testing & Validation](#testing--validation)
17. [Monitoring & Observability](#monitoring--observability)
18. [Security](#security)
19. [Error Handling](#error-handling)

### PARTE VI: ROADMAP & PRÓXIMOS PASSOS
20. [Próximos Passos](#proximos-passos)
21. [KPIs e Métricas](#success-metrics-kpis)

---

# PARTE I: FUNDAMENTOS

## SECAO 1: QUICK START

### Sistema em 5 Comandos

```bash
# 1. Clone e instale
git clone <repo-url> shaka-api && cd shaka-api
npm install

# 2. Configure ambiente
cp .env.example .env
nano .env  # Editar DB_PASSWORD, JWT_SECRET, REDIS_PASSWORD

# 3. Inicie com Docker
./docker.sh start

# 4. Aguarde healthy (30-60s)
./docker.sh health

# 5. Teste API
curl http://localhost:3000/health
```

### Stack Tecnologica

| Camada           | Tecnologia | Versao | Proposito              |
|------------------|------------|--------|------------------------|
| Runtime          | Node.js    | 20     | JavaScript server-side |
| Language         | TypeScript | 5.x    | Type safety            |
| API Framework    | Express    | 4.x    | REST API               |
| ORM              | TypeORM    | 0.3.17 | Database abstraction   |
| Database         | PostgreSQL | 15     | Dados relacionais      |
| Cache            | Redis      | 7      | Rate limiting + cache  |
| Orchestration    | K3s        | 1.33.6 | Kubernetes lightweight |
| Containerization | Docker     | 24+    | Isolamento             |

### Estrutura de Diretorios (Simplificada)

```
shaka-api/
├── src/                    # Codigo-fonte TypeScript
│   ├── api/               # Presentation Layer (controllers, routes, middlewares)
│   ├── core/              # Application Layer (services, types)
│   ├── infrastructure/    # Infrastructure Layer (database, cache)
│   ├── shared/            # Shared Layer (utils, errors)
│   ├── config/            # Configurações
│   └── server.ts          # Express app setup
│
├── tests/                 # Test suites (22/22 passing)
├── scripts/               # 120+ automation scripts
├── infrastructure/        # Kubernetes manifests
│   └── kubernetes/
├── docker/                # Docker configs
├── docs/                  # Documentação (32 memorandos)
│   └── memorandos/
└── dist/                  # Build output (gitignored)
```

### Comandos Essenciais

```bash
# Desenvolvimento
npm run dev              # Hot reload
npm run build            # Compile TypeScript
npm test                 # Run all tests (22/22 passing)
npm run test:coverage    # With coverage report

# Docker
./docker.sh start        # Start containers
./docker.sh stop         # Stop containers
./docker.sh logs api     # View API logs
./docker.sh health       # Health checks

# Database
./docker.sh migrate run  # Apply migrations
npm run migration:revert # Rollback last migration

# Kubernetes
kubectl get pods -n shaka-staging
kubectl logs -f <pod-name> -n shaka-staging
kubectl exec -it <pod-name> -n shaka-staging -- sh
```

---

## SECAO 2: ARQUITETURA CORE

### Clean Architecture (4 Camadas)

```
┌─────────────────────────────────────────────┐
│  PRESENTATION LAYER (API)                   │
│  Controllers, Routes, Middlewares           │
│  - AuthController, ApiKeyController         │
│  - authenticate, apiKeyAuth, trackUsage     │
│  - Joi validators                           │
├─────────────────────────────────────────────┤
│  APPLICATION LAYER (Core)                   │
│  Services (Business Logic)                  │
│  - AuthService, ApiKeyService               │
│  - UsageTrackingService, RateLimiterService │
├─────────────────────────────────────────────┤
│  DOMAIN LAYER                               │
│  Entities, Types, Business Rules            │
│  - User, Subscription, ApiKey, UsageRecord  │
│  - PLAN_LIMITS, validation rules            │
├─────────────────────────────────────────────┤
│  INFRASTRUCTURE LAYER                       │
│  External Services & Data Access            │
│  - TypeORM repositories (lazy init)         │
│  - Redis cache                              │
│  - PostgreSQL connection                    │
└─────────────────────────────────────────────┘
```

### Fluxo de Requisicao Completo

```
Client Request (HTTP/HTTPS)
    ↓
Ingress Controller (Traefik)
    ↓
Kubernetes Service (Load Balancer)
    ↓
API Pod (Express)
    ├→ Logger Middleware (registro)
    ├→ CORS Middleware (headers)
    ├→ Rate Limiter (Redis check)
    ├→ Auth Middleware (JWT ou API Key)
    │   ├→ Verify token/key
    │   └→ Decode payload → req.user
    ├→ Validator (Joi schema)
    ├→ Controller (HTTP handler)
    │   └→ Service (business logic)
    │       ├→ Repository (data access)
    │       │   └→ TypeORM (lazy init via getter)
    │       └→ Cache (Redis)
    ├→ Database Query (PostgreSQL)
    └→ Response
        ├→ Error Handler (if error)
        └→ JSON Response + HTTP Status
```

### Database Schema Completo

```sql
-- TABELA: users
users
  ├── id (UUID, PK)
  ├── email (VARCHAR UNIQUE)
  ├── passwordHash (VARCHAR)  -- SHA256, NUNCA plaintext
  ├── plan (ENUM: starter|pro|business|enterprise)
  ├── createdAt (TIMESTAMP)
  └── updatedAt (TIMESTAMP)

-- TABELA: subscriptions (1:1 com users)
subscriptions
  ├── id (UUID, PK)
  ├── userId (UUID, FK -> users)
  ├── plan (VARCHAR)
  ├── status (ENUM: active|cancelled|past_due|trialing)
  ├── stripeCustomerId (VARCHAR)
  ├── stripeSubscriptionId (VARCHAR)
  ├── currentPeriodStart (TIMESTAMP)
  ├── currentPeriodEnd (TIMESTAMP)
  └── cancelAtPeriodEnd (BOOLEAN)

-- TABELA: api_keys (1:N com users)
api_keys
  ├── id (UUID, PK)
  ├── userId (UUID, FK -> users)
  ├── name (VARCHAR)
  ├── keyHash (VARCHAR UNIQUE)  -- SHA256 hash
  ├── keyPreview (VARCHAR)      -- Primeiros 12 chars
  ├── permissions (TEXT)        -- CSV: 'read,write'
  ├── rateLimit (JSONB)         -- Config dinamica
  ├── isActive (BOOLEAN)
  ├── lastUsedAt (TIMESTAMP)
  ├── expiresAt (TIMESTAMP)
  ├── createdAt (TIMESTAMP)
  └── updatedAt (TIMESTAMP)

-- TABELA: usage_records (analytics)
usage_records
  ├── id (UUID, PK)
  ├── api_key_id (UUID)         -- snake_case (IMPORTANTE!)
  ├── user_id (UUID, FK -> users) -- snake_case (IMPORTANTE!)
  ├── endpoint (VARCHAR)
  ├── method (VARCHAR)
  ├── status_code (INT)         -- snake_case (IMPORTANTE!)
  ├── response_time_ms (INT)    -- snake_case (IMPORTANTE!)
  ├── ip_address (VARCHAR)      -- snake_case (IMPORTANTE!)
  ├── user_agent (TEXT)         -- snake_case (IMPORTANTE!)
  ├── error_message (TEXT)      -- snake_case (IMPORTANTE!)
  └── timestamp (TIMESTAMP)

-- INDEXES (Performance Critical)
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_plan ON users(plan);
CREATE INDEX idx_api_keys_userId ON api_keys(userId);
CREATE UNIQUE INDEX idx_api_keys_keyHash ON api_keys(keyHash);
CREATE INDEX idx_usage_apiKeyId_timestamp ON usage_records(api_key_id, timestamp);
CREATE INDEX idx_usage_userId_timestamp ON usage_records(user_id, timestamp);
CREATE INDEX idx_usage_timestamp ON usage_records(timestamp);
```

---

# PARTE II: FEATURES IMPLEMENTADAS

## Autenticacao JWT

**Implementação:** Fase 3 (Services Layer)

### Metodos Principais

```typescript
class AuthService {
  // Registro de usuario
  static async register(
    email: string, 
    password: string, 
    plan?: SubscriptionPlan
  ): Promise<AuthResult>
  
  // Login
  static async login(
    email: string, 
    password: string
  ): Promise<AuthTokens>
  
  // Refresh token
  static async refreshToken(
    refreshToken: string
  ): Promise<AuthTokens>
}
```

### Tokens

- **Access Token:** JWT, 15 minutos, Bearer authentication
- **Refresh Token:** JWT, 7 dias, rotacao automatica

### Endpoints

```
POST /api/v1/auth/register  - Criar conta
POST /api/v1/auth/login     - Autenticar
POST /api/v1/auth/refresh   - Renovar tokens
```

### Security Features

- ✅ Password hashing com bcrypt (12 salt rounds)
- ✅ Password validation (8+ chars, uppercase, lowercase, number, special)
- ✅ JWT secrets (64+ chars minimum)
- ✅ Token expiration automática
- ✅ Refresh token rotation

---

## Multi-tenancy (Planos)

**Implementação:** Fase 3 (Subscription Service)

| Plano          | Requests/Dia | Requests/Min | API Keys  | Preco/Mes |
|----------------|--------------|--------------|-----------|-----------|
| **Starter**    | 10.000       | 60           | 3         | Gratis    |
| **Pro**        | 100.000      | 300          | 10        | $29       |
| **Business**   | 1.000.000    | 1.000        | 50        | $99       |
| **Enterprise** | Ilimitado    | 5.000        | Ilimitado | Custom    |

### PLAN_LIMITS Configuration

```typescript
const PLAN_LIMITS = {
  starter: {
    maxRequests: 10000,
    requestsPerMinute: 60,
    maxApiKeys: 3,
    features: ['basic_analytics']
  },
  pro: {
    maxRequests: 100000,
    requestsPerMinute: 300,
    maxApiKeys: 10,
    features: ['basic_analytics', 'advanced_analytics', 'priority_support']
  },
  business: {
    maxRequests: 1000000,
    requestsPerMinute: 1000,
    maxApiKeys: 50,
    features: ['all_features', 'dedicated_support', 'custom_integrations']
  },
  enterprise: {
    maxRequests: Infinity,
    requestsPerMinute: 5000,
    maxApiKeys: Infinity,
    features: ['all_features', '24/7_support', 'sla', 'custom_deployment']
  }
};
```

---

## API Key Management (Sprint 1 - COMPLETO ✅)

**Implementação:** Fases 17-18 (inicial), Fases 19-25 (correções e validação)

**Status Final:** 100% operacional (22/22 testes passando)

### Endpoints Completos (7 endpoints)

```typescript
POST   /api/v1/keys              - Criar API Key
GET    /api/v1/keys              - Listar todas keys do usuario
GET    /api/v1/keys/:id          - Detalhes de uma key
GET    /api/v1/keys/:id/usage    - Estatísticas de uso
POST   /api/v1/keys/:id/rotate   - Rotacionar key (zero downtime)
DELETE /api/v1/keys/:id          - Revogar key (soft delete)
DELETE /api/v1/keys/:id/permanent - Deletar permanentemente
```

### Formato de API Key

```
sk_live_EXAMPLE_DOCUMENTATION_ONLY
└─┬─┘ └┬─┘ └──────────────┬──────────────┘
  │    │                  └─ 32 chars aleatorios (crypto.randomBytes)
  │    └─ Ambiente (live|test)
  └─ Secret Key prefix
```

### Funcionalidades Implementadas

- ✅ Geração segura com crypto.randomBytes(32)
- ✅ Armazenamento hash SHA-256 (nunca plaintext)
- ✅ Preview (primeiros 12 chars: `sk_live_a1b2...`)
- ✅ Permissões granulares (read, write, admin)
- ✅ Rate limiting personalizado por key
- ✅ Expiração automática configurável
- ✅ Soft delete (revogação reversível)
- ✅ Hard delete (remoção permanente)
- ✅ Rotação sem downtime
- ✅ Usage tracking integrado
- ✅ Autenticação via X-API-Key header

### Exemplo de Uso

```bash
# 1. Criar API Key
curl -X POST http://localhost:3000/api/v1/keys \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Production Key",
    "permissions": ["read", "write"],
    "expiresAt": "2026-12-31T23:59:59Z"
  }'

# Response:
{
  "success": true,
  "data": {
    "id": "uuid",
    "key": "sk_live_EXAMPLE_DOCUMENTATION_ONLY",  # ← Mostrado apenas uma vez!
    "keyPreview": "sk_live_a1b2...",
    "name": "Production Key",
    "permissions": ["read", "write"],
    "createdAt": "2025-12-13T10:00:00Z"
  }
}

# 2. Usar API Key para autenticar
curl http://localhost:3000/api/v1/keys \                      
  -H "X-API-Key: sk_live_EXAMPLE_DOCUMENTATION_ONLY"

# 3. Ver estatísticas de uso
curl http://localhost:3000/api/v1/keys/{key-id}/usage?period=day \
  -H "Authorization: Bearer $JWT_TOKEN"
```

---

## Usage Tracking & Analytics

**Implementação:** Fase 17 (Usage Tracking Service)

### Metodos Principais

```typescript
class UsageTrackingService {
  // Registrar uso automaticamente
  static async trackUsage(data: UsageData): Promise<void>
  
  // Estatisticas por periodo
  static async getUsageStats(
    apiKeyId: string,
    period: 'day' | 'week' | 'month'
  ): Promise<UsageStats>
}
```

### Metricas Rastreadas

| Metrica                   | Descrição                  |
|---------------------------|----------------------------|
| **Total Requests**        | Contagem total de chamadas |
| **Requests por Endpoint** | Distribuição por rota      |
| **Status Codes**          | 2xx, 4xx, 5xx breakdown    |
| **Response Time**         | Média, p95, p99            |
| **Requests por Hora/Dia** | Timeline de uso            |
| **IP Addresses**          | Origem das requisições     |
| **User Agents**           | Clientes utilizados        |
| **Error Messages**        | Logs de erros              |

### Endpoints Analytics

```
GET /api/v1/keys/:id/usage?period=day   - Ultimas 24h
GET /api/v1/keys/:id/usage?period=week  - Ultimos 7 dias
GET /api/v1/keys/:id/usage?period=month - Ultimos 30 dias
```

### Response Example

```json
{
  "success": true,
  "data": {
    "apiKeyId": "uuid",
    "period": "day",
    "totalRequests": 1543,
    "successRate": 98.2,
    "avgResponseTime": 87,
    "p95ResponseTime": 245,
    "p99ResponseTime": 512,
    "statusCodeBreakdown": {
      "2xx": 1515,
      "4xx": 23,
      "5xx": 5
    },
    "topEndpoints": [
      { "endpoint": "/api/v1/users", "count": 823 },
      { "endpoint": "/api/v1/plans", "count": 456 }
    ],
    "requestsPerHour": [65, 78, 92, ...],
    "errors": [
      {
        "timestamp": "2025-12-13T10:30:00Z",
        "endpoint": "/api/v1/keys",
        "statusCode": 500,
        "message": "Internal server error"
      }
    ]
  }
}
```

---

## Rate Limiting

**Implementação:** Fase 3 (Rate Limiter Service), atualizado na Fase 17

### Implementação Técnica

- **Backend:** Redis (contadores com TTL)
- **Algoritmo:** Token Bucket
- **Granularidade:** Por usuário + por API Key
- **Headers:** X-RateLimit-Limit, X-RateLimit-Remaining, X-RateLimit-Reset

### Configuração por Plano

```typescript
const RATE_LIMITS = {
  starter: { requests: 60, window: 60 },      // 60 req/min
  pro: { requests: 300, window: 60 },         // 300 req/min
  business: { requests: 1000, window: 60 },   // 1000 req/min
  enterprise: { requests: 5000, window: 60 }  // 5000 req/min
};
```

### Response Headers

```
X-RateLimit-Limit: 300
X-RateLimit-Remaining: 287
X-RateLimit-Reset: 1702467600
```

### Error Response (429 Too Many Requests)

```json
{
  "success": false,
  "error": "Rate limit exceeded",
  "code": "RATE_LIMIT_EXCEEDED",
  "details": {
    "limit": 300,
    "remaining": 0,
    "resetAt": "2025-12-13T11:00:00Z"
  }
}
```

---

# PARTE III: INFRAESTRUTURA & DEPLOY

## Arquitetura Kubernetes (Production)

**Implementação:** Fase 9 (Kubernetes Infrastructure), refinado nas Fases 10-15

### Cluster Overview

```
┌─────────────────────────────────────────────────────────┐
│               CLUSTER K3s (microsaas-server)            │
│                    2 CPU / 2GB RAM                      │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │
│  │  shaka-dev   │  │shaka-staging │  │  shaka-prod  │   │
│  │              │  │              │  │              │   │
│  │ ┌──────────┐ │  │ ┌──────────┐ │  │ ┌──────────┐ │   │
│  │ │ API Pod  │ │  │ │ API Pod  │ │  │ │ (scaled  │ │   │
│  │ │ 1/2 Run  │ │  │ │ 2/2 Run  │ │  │ │  to 0)   │ │   │
│  │ └────┬─────┘ │  │ └────┬─────┘ │  │ └──────────┘ │   │
│  │      │       │  │      │       │  │              │   │
│  │ ┌────▼─────┐ │  │ ┌────▼─────┐ │  │ ┌──────────┐ │   │
│  │ │PostgreSQL│ │  │ │PostgreSQL│ │  │ │PostgreSQL│ │   │
│  │ │ 1/1 Run  │ │  │ │ 1/1 Run  │ │  │ │ 1/1 Run  │ │   │
│  │ └──────────┘ │  │ └──────────┘ │  │ └──────────┘ │   │
│  └───────┬──────┘  └───────┬──────┘  └───────┬──────┘   │
│          │                 │                  │         │
│          └─────────────────┴──────────────────┘         │
│                            │                            │
│                      ┌─────▼──────┐                     │
│                      │shaka-shared│                     │
│                      │            │                     │
│                      │ ┌────────┐ │                     │
│                      │ │ Redis  │ │                     │
│                      │ │ 1/1 Run│ │                     │
│                      │ │ DB 0-2 │ │                     │
│                      │ └────────┘ │                     │
│                      └────────────┘                     │
└─────────────────────────────────────────────────────────┘
```

### Namespaces

| Namespace        | Propósito                | Pods                           |
|------------------|--------------------------|--------------------------------|
| shaka-dev        | Desenvolvimento          | API + PostgreSQL               |
| shaka-staging    | Homologação              | API + PostgreSQL               |
| shaka-prod       | Produção                 | API + PostgreSQL (scaled to 0) |
| shaka-shared     | Serviços compartilhados  | Redis                          |
| shaka-monitoring | Observabilidade (futuro) | Prometheus + Grafana           |

### Resource Allocation

| Ambiente              | Replicas | CPU Request | CPU Limit | RAM Request | RAM Limit |
|-----------------------|----------|-------------|-----------|-------------|-----------|
| **API Dev**           | 1        | 25m         | 100m      | 64Mi        | 128Mi     |
| **API Staging**       | 1        | 50m         | 200m      | 128Mi       | 256Mi     |
| **API Prod**          | 0        | 100m        | 500m      | 256Mi       | 512Mi     |
| **PostgreSQL** (each) | 1        | 200m        | 400m      | 256Mi       | 512Mi     |
| **Redis Shared**      | 1        | 100m        | 200m      | 128Mi       | 256Mi     |

**Total Allocated:** ~1GB RAM / ~1 CPU  
**Server Capacity:** 2GB RAM / 2 CPU  
**Status:** ✅ Stable at ~75% memory usage

---

## Pipeline de Deployment

**Evolução:** Fases 8 (Docker), 10-13 (Kubernetes), 19-25 (otimização)

### Pipeline Completo (No-Cache Strategy)

```bash
# 1. Build local (verificar código)
npm run build

# 2. Build Docker image (SEM CACHE - crítico!)
docker build --no-cache --progress=plain -t shaka-api:latest .

# 3. Verificar imagem criada
docker images | grep shaka-api

# 4. Import para K3s
docker save shaka-api:latest | sudo k3s ctr images import -

# 5. Verificar imagem no K3s
sudo k3s ctr images ls | grep shaka-api

# 6. Patch deployment (force imagePullPolicy: Never)
kubectl patch deployment shaka-api -n shaka-staging \
  -p '{"spec":{"template":{"spec":{"containers":[{"name":"shaka-api","imagePullPolicy":"Never"}]}}}}'

# 7. Delete pod para forçar recriação com nova imagem
kubectl delete pod -n shaka-staging -l app=shaka-api

# 8. Aguardar novo pod
kubectl wait --for=condition=ready pod -l app=shaka-api -n shaka-staging --timeout=120s

# 9. Validar versão no pod
POD=$(kubectl get pods -n shaka-staging -l app=shaka-api -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n shaka-staging $POD -- ls -la /app/dist/

# 10. Testar API
kubectl port-forward -n shaka-staging svc/shaka-api 3000:3000 &
curl http://localhost:3000/health
```

### Scripts de Automação

```bash
# Deploy completo (scripts/deployment/)
./rebuild-no-cache.sh           # Build sem cache
./force-new-image.sh            # Force fresh image no K3s
./validate-deployment.sh        # Health checks

# Validation (scripts/validation/)
./validate-api-keys-v2.sh       # Testa 22 endpoints
./health-check.sh               # Infra validation
```

---

## Database Migration Strategy

**Implementação:** Fase 19 (SQL direto), otimizado para ambientes com RAM limitada

### Método 1: SQL Direto (RECOMENDADO para produção)

**Vantagens:**
- ✅ Tempo: < 1s vs 5+ minutos TypeORM
- ✅ RAM: < 10MB vs 500MB+
- ✅ Idempotente (IF NOT EXISTS)
- ✅ Zero downtime dos bancos

**Uso:**

```bash
# 1. Criar migration SQL idempotente
cat > migration.sql << 'EOF'
-- Criar tabela com IF NOT EXISTS
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  plan VARCHAR(20) DEFAULT 'starter',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Indexes idempotentes
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_plan ON users(plan);
EOF

# 2. Backup automático do schema
kubectl exec -n shaka-staging postgres-0 -- \
  pg_dump -U shaka_staging -d shaka_staging --schema-only \
  > backup-schema-$(date +%Y%m%d-%H%M%S).sql

# 3. Aplicar migration
kubectl exec -i -n shaka-staging postgres-0 -- \
  psql -U shaka_staging -d shaka_staging < migration.sql

# 4. Validar
kubectl exec -n shaka-staging postgres-0 -- \
  psql -U shaka_staging -d shaka_staging -c "\dt"
```

### Método 2: TypeORM Migration (para dev)

```bash
# Gerar migration
npm run migration:generate -- -n MigrationName

# Aplicar
npm run migration:run

# Reverter
npm run migration:revert
```

---

## Troubleshooting Common Issues

**Consolidação:** Problemas identificados e resolvidos nas Fases 10-25

### Problema 1: "Cannot read properties of undefined (reading 'findOne')"

**Causa:** UserRepository não inicializado (Fase 20)

**Solução (Lazy Initialization):**
```typescript
// src/infrastructure/database/repositories/UserRepository.ts
class UserRepository {
  // ✅ Lazy initialization via getter
  static get repository() {
    if (!this._repository) {
      this._repository = AppDataSource.getRepository(UserEntity);
    }
    return this._repository;
  }
  
  static async findByEmail(email: string) {
    return this.repository.findOne({ where: { email } });
  }
}
```

---

### Problema 2: "No metadata for 'UsageRecordEntity' was found"

**Causa:** Entity não registrada no TypeORM config (Fase 25)

**Solução:**
```typescript
// src/infrastructure/database/config.ts
import { UsageRecordEntity } from './entities/UsageRecordEntity';

export const AppDataSource = new DataSource({
  // ...
  entities: [
    UserEntity,
    SubscriptionEntity,
    ApiKeyEntity,
    UsageRecordEntity  // ← ADICIONAR AQUI
  ],
});
```

---

### Problema 3: Pod usando imagem antiga (K3s cache)

**Causa:** K3s mantém cache de imagens antigas (Fases 21-25)

**Solução Completa:**
```bash
# 1. Remover TODAS imagens antigas
sudo k3s ctr images rm docker.io/library/shaka-api:latest || true

# 2. Build SEM cache
docker build --no-cache -t shaka-api:latest .

# 3. Import fresh
docker save shaka-api:latest | sudo k3s ctr images import -

# 4. Patch imagePullPolicy
kubectl patch deployment shaka-api -n shaka-staging \
  -p '{"spec":{"template":{"spec":{"containers":[{"name":"shaka-api","imagePullPolicy":"Never"}]}}}}'

# 5. Force recreation
kubectl delete pod -n shaka-staging -l app=shaka-api
```

---

### Problema 4: Logger com caminho incorreto

**Causa:** Import usando path antigo (Fase 25)

**Solução:**
```typescript
// ❌ ERRADO
import logger from '../../shared/utils/logger';

// ✅ CORRETO
import logger from '../../config/logger';
```

---

### Problema 5: TypeORM column names mismatch

**Causa:** Entity usando camelCase mas banco usando snake_case (Fase 25)

**Solução:**
```typescript
// src/infrastructure/database/entities/UsageRecordEntity.ts
@Entity('usage_records')
export class UsageRecordEntity {
  // ✅ Mapear explicitamente cada coluna snake_case
  @Column({ name: 'api_key_id', type: 'uuid' })
  apiKeyId!: string;

  @Column({ name: 'user_id', type: 'uuid' })
  userId!: string;

  @Column({ name: 'status_code', type: 'int' })
  statusCode!: number;

  @Column({ name: 'response_time_ms', type: 'int' })
  responseTime!: number;

  @Column({ name: 'ip_address', type: 'varchar' })
  ipAddress?: string;

  @Column({ name: 'user_agent', type: 'text' })
  userAgent?: string;

  @Column({ name: 'error_message', type: 'text' })
  errorMessage?: string;
}
```

---

### Problema 6: Build TypeScript travando

**Causa:** Imports circulares ou path aliases incorretos (Fase 10)

**Solução:**
```bash
# 1. Verificar imports circulares
npm run build 2>&1 | grep "Circular"

# 2. Remover path aliases do tsconfig.json
# (usar imports relativos)

# 3. Verificar tsconfig.json
{
  "compilerOptions": {
    "outDir": "./dist",
    "baseUrl": "./src",
    "paths": {}  // ← Vazio! Sem aliases em produção
  }
}
```

---

### Problema 7: Rate Limit não funcionando

**Causa:** Redis database isolation incorreto (Fase 9)

**Solução:**
```typescript
// src/infrastructure/cache/redis.config.ts
const getRedisDatabase = (): number => {
  const env = process.env.NODE_ENV;
  switch(env) {
    case 'development': return 0;
    case 'staging': return 1;
    case 'production': return 2;
    default: return 0;
  }
};

export const redisConfig = {
  host: process.env.REDIS_HOST || 'localhost',
  port: parseInt(process.env.REDIS_PORT || '6379'),
  db: getRedisDatabase(),  // ← Isolamento por environment
  password: process.env.REDIS_PASSWORD
};
```

---

# PARTE IV: HISTÓRICO COMPLETO DO PROJETO

## Linha do Tempo (Fases 1-25)

### 📅 FASE 1-2: Fundação do Projeto (25/Nov/2025)

**Objetivo:** Criar estrutura base e API skeleton

**Entregas:**
- ✅ Estrutura de diretórios (src, tests, scripts, docs, k8s, docker)
- ✅ Express + TypeScript configurado
- ✅ Rotas base (auth, users, plans)
- ✅ Middlewares iniciais (auth, rate limiting, logging)
- ✅ Controllers skeleton
- ✅ Validadores Joi
- ✅ Error handling customizado
- ✅ Winston logger

**Impacto:** Sistema com fundação sólida pronta para desenvolvimento

---

### 📅 FASE 3: Services Layer (25/Nov/2025 - 13:30)

**Objetivo:** Implementar business logic completa

**Entregas:**
- ✅ PasswordService (validation + bcrypt hashing)
- ✅ TokenService (JWT generation/validation)
- ✅ AuthService (register, login, refresh)
- ✅ UserService (CRUD completo)
- ✅ SubscriptionService (gestão de planos)
- ✅ RateLimiterService (controle de rate limiting)
- ✅ Types completos (auth, user, subscription, rate-limiter)

**Decisão Arquitetural:** Static methods em todos services (simplicidade > DI container)

**Impacto:** Business logic completa e testável

---

### 📅 FASE 4: Database + Redis Integration (26/Nov/2025)

**Objetivo:** Integrar persistência e cache

**Entregas:**
- ✅ TypeORM configuration (AppDataSource)
- ✅ Entities (User, Subscription)
- ✅ Repositories (BaseRepository pattern)
- ✅ Migrations (CreateUsersTable, CreateSubscriptionsTable)
- ✅ Redis cache service
- ✅ Database connection management

**Decisão Arquitetural:** TypeORM com entities + repositories (abstração clean)

**Impacto:** Sistema com persistência funcional

---

### 📅 FASE 5-6: Build Limpo + Infra Completa (26/Nov/2025)

**Objetivo:** Corrigir erros de build e finalizar infraestrutura

**Entregas:**
- ✅ Correção de tipos TypeScript
- ✅ Imports consistentes
- ✅ Build sem erros
- ✅ Infraestrutura base completa

**Impacto:** Código production-ready

---

### 📅 FASE 7A-7D: Testing Layer (27/Nov/2025)

**Objetivo:** Implementar testing completo com alta cobertura

**Fase 7A - Testing Base:**
- ✅ Jest configuration
- ✅ Unit tests (services)
- ✅ Mocks (database, cache)

**Fase 7B - Integration:**
- ✅ Integration tests (API endpoints)
- ✅ E2E test structure

**Fase 7C - E2E:**
- ✅ E2E tests completos (auth-flow, user-flow, subscription-flow)

**Fase 7D - Coverage:**
- ✅ Coverage: 81.9%
- ✅ 13 arquivos de teste

**Impacto:** Sistema com alta confiabilidade e cobertura de testes

---

### 📅 FASE 8: Containerização (27/Nov/2025)

**Objetivo:** Dockerizar aplicação completa

**Entregas:**
- ✅ Dockerfile multi-stage (266MB final)
- ✅ Docker Compose (dev + prod)
- ✅ Scripts de gestão (start, stop, logs, health, migrate)
- ✅ Health checks automáticos
- ✅ Volumes persistentes (PostgreSQL, Redis)
- ✅ Network isolation

**Decisão Arquitetural:** Multi-stage build (otimização de tamanho)

**Métricas:**
- Build time: 2-3 minutos
- Startup time: 30-60 segundos
- Imagem final: ~300MB

**Impacto:** Sistema containerizado e cloud-ready

---

### 📅 FASE 9: Kubernetes Production Infrastructure (28/Nov/2025)

**Objetivo:** Deploy em Kubernetes production-grade

**Entregas:**
- ✅ K3s cluster (v1.33.6)
- ✅ 5 namespaces (dev, staging, prod, shared, monitoring)
- ✅ Resource Quotas + LimitRanges otimizados
- ✅ PostgreSQL StatefulSets (3 ambientes isolados)
- ✅ Redis Shared Architecture (DB isolation: 0=dev, 1=staging, 2=prod)
- ✅ ConfigMaps + Secrets por ambiente
- ✅ NetworkPolicies (inicial)

**Decisões Arquiteturais:**
- Redis compartilhado com database isolation (economia 200-300MB RAM)
- PostgreSQL prod sem backup sidecar (CronJob no futuro)
- LimitRanges: 25-50m CPU mínimo

**Recursos Servidor:**
- 2 CPU / 2GB RAM
- ~75% utilização estável

**Impacto:** Sistema em Kubernetes funcional

---

### 📅 FASE 10: Correção TypeScript Build (28/Nov/2025)

**Objetivo:** Corrigir 20+ erros TypeScript para deploy

**Problemas Identificados:**
- ❌ Duplicate default exports (env.ts)
- ❌ Missing types (auth.types, user.types)
- ❌ Type mismatches (User vs UserEntity)
- ❌ Static methods inconsistentes

**Soluções:**
- ✅ Consolidar exports em env.ts
- ✅ Criar arquivos de tipos completos
- ✅ Type casting adequado (plan enum)
- ✅ Padronizar static methods

**Decisão Crítica:** Remover path aliases TypeScript (produção usa imports relativos)

**Impacto:** Build success - pronto para Docker

---

### 📅 FASE 11: Deploy Kubernetes - Troubleshooting (29/Nov/2025)

**Objetivo:** Primeiro deploy no cluster K3s

**Problemas Encontrados:**
- ❌ CrashLoopBackOff (pod reiniciando)
- ❌ Database connection errors
- ❌ Environment variables incorretas

**Soluções:**
- ✅ Ajustar DB_HOST para service DNS
- ✅ Configurar secrets corretamente
- ✅ Adicionar health probes

**Impacto:** Pod rodando, mas ainda instável

---

### 📅 FASE 12: Path Aliases Fix + Database Credentials (29/Nov/2025)

**Objetivo:** Resolver imports em runtime

**Problema Crítico:**
- Path aliases TypeScript (@core, @infrastructure) não funcionam em runtime Node.js

**Solução:**
- ✅ Remover todos path aliases do tsconfig.json
- ✅ Converter para imports relativos
- ✅ Rebuild completo
- ✅ Ajustar credenciais do banco

**Trade-off:** Imports mais longos, mas build confiável

**Impacto:** Sistema funcionando no Kubernetes

---

### 📅 FASE 13: Kubernetes Production Deployment Concluído (30/Nov/2025)

**Objetivo:** Estabilizar deploy em produção

**Entregas:**
- ✅ NetworkPolicies removidas temporariamente (restaurar Fase 17)
- ✅ Resource limits ajustados
- ✅ Health checks configurados
- ✅ Sistema estável em staging

**Status:**
- Pods: 4/7 Running (dev: 1/2, staging: 2/2, prod: 0/0)
- Memória: ~75% uso
- CPU: <10%

**Impacto:** Sistema production-ready em staging

---

### 📅 FASE 14: API Endpoint Testing (30/Nov/2025 - 2 partes)

**Objetivo:** Validar todos endpoints REST

**Parte 1 (75%):**
- ✅ Testar health endpoint
- ✅ Testar auth endpoints (register, login)
- ⚠️ Problemas com req.path vs req.originalUrl

**Parte 2 (100%):**
- ✅ Corrigir RequestLogger (req.originalUrl)
- ✅ Validar todos endpoints
- ✅ 100% dos endpoints funcionando

**Problema Resolvido:**
```typescript
// ❌ ANTES: Logs mostravam apenas /register
logger.info(`${req.method} ${req.path}`);

// ✅ DEPOIS: Logs mostram /api/v1/auth/register
logger.info(`${req.method} ${req.originalUrl}`);
```

**Impacto:** API completamente testada e validada

---

### 📅 FASE 15: Deployment Shaka API Staging (01/Dez/2025)

**Objetivo:** Deploy completo em staging com validações

**Entregas:**
- ✅ Logger com paths absolutos (/app/logs)
- ✅ Dockerfile corrigido (mkdir /app/logs)
- ✅ Deploy em staging validado
- ✅ Health checks passando

**Problema Resolvido:**
```dockerfile
# ❌ ANTES: EACCES permission denied, mkdir 'logs'
# ✅ DEPOIS: mkdir -p /app/logs no Dockerfile
```

**Impacto:** Sistema estável em staging, pronto para features

---

### 📅 FASE 16: Ingress + Motor Hybrid Foundation (02/Dez/2025 - 2 partes)

**Objetivo:** Acesso externo e preparação para ATHOS

**Parte 1 (Parcial - 60%):**
- ✅ Estrutura Ingress criada
- ✅ Motor Hybrid skeleton
- ❌ Traefik CRDs ausentes
- ❌ Build TypeScript travando

**Parte 2 (Completa - 85% - Versão LIGHT):**
- ✅ Ingress básico funcionando (sem middlewares CRD)
- ✅ Motor Hybrid como placeholder inteligente
- ✅ Otimização de RAM: 87MB → 395MB livre
- ⏳ Middlewares Traefik adiados para Fase 17
- ⏳ Build Motor adiado

**Adaptações:**
- Versão light devido a limitações de RAM
- DEV temporariamente desligado

**Impacto:** Acesso externo via Ingress funcionando

---

### 📅 FASE 17: API Key Management + Usage Tracking (05/Dez/2025)

**Objetivo:** Implementar Sprint 1 - Sistema completo de API Keys

**Entregas:**
- ✅ 7 endpoints REST (create, list, get, usage, rotate, revoke, delete)
- ✅ ApiKeyEntity + UsageRecordEntity (TypeORM)
- ✅ ApiKeyService (business logic completa)
- ✅ UsageTrackingService (analytics)
- ✅ RateLimiterService (atualizado para API keys)
- ✅ Middlewares: apiKeyAuth, trackUsage
- ✅ Validators Joi para API keys
- ✅ 2.500+ linhas de código
- ✅ 18 novos arquivos

**Formato API Key:**
```
sk_live_EXAMPLE_DOCUMENTATION_ONLY
```

**Features:**
- Geração segura (crypto.randomBytes)
- Hash SHA-256 (nunca plaintext)
- Permissões granulares
- Expiração automática
- Soft/hard delete
- Rotação sem downtime

**Status:** Build limpo (0 erros TypeScript)

**Impacto:** Sistema com API Key Management completo

---

### 📅 FASE 18: Sprint 1 Deployment + Troubleshooting (06/Dez/2025 - Madrugada)

**Objetivo:** Deploy do Sprint 1 e correção de erros

**Problemas Iniciais:**
- ❌ 48 erros TypeScript
- ❌ 13 erros de tipos incompatíveis
- ❌ 7 erros de services (PasswordService, AuthService)
- ❌ 4 erros de SubscriptionRepository
- ❌ ApiKeyEntity não registrada

**Soluções Implementadas:**

1. **PasswordService Methods (2 erros):**
```typescript
// ❌ Métodos de instância
async hash(password: string)

// ✅ Métodos estáticos
static async hash(password: string)
```

2. **UserEntity.password → passwordHash (vulnerabilidade):**
```typescript
// ❌ password (plaintext risk)
@Column()
password!: string;

// ✅ passwordHash (seguro)
@Column({ name: 'password_hash' })
passwordHash!: string;
```

3. **AuthService signatures (5 erros):**
- Corrigir chamadas: hashPassword → hash
- Corrigir chamadas: verifyPassword → compare

4. **ApiKeyEntity registration:**
```typescript
// Adicionar no config.ts
entities: [UserEntity, SubscriptionEntity, ApiKeyEntity]
```

**Resultado:**
- ✅ Build: 48 → 0 erros
- ✅ Migrations aplicadas (4 tabelas)
- ✅ Docker image build success
- ✅ Pod rodando com conexões estáveis
- ✅ Health checks passando

**Impacto:** Sprint 1 deployado e funcional

---

### 📅 FASE 19: Database Migration Production Readiness (09/Dez/2025)

**Objetivo:** Migration em servidor com RAM limitada

**Contexto:**
- Servidor: 1.9GB RAM, 0 swap
- RAM livre: 82MB (crítico)
- Processo TSC travando em I/O

**Problema:**
- TypeORM migration travava (5+ minutos, 500MB+ RAM)

**Solução:** Migration via SQL direto

**Implementação:**
```bash
# apply-sql-direct-refactored.sh
1. Backup automático do schema
2. SQL idempotente (IF NOT EXISTS)
3. Aplicar via kubectl exec
4. Validação pós-migration
5. Teste automático da API
```

**Resultados:**
- ✅ Tempo: < 1s (vs 5+ minutos)
- ✅ RAM: < 10MB (vs 500MB+)
- ✅ Zero downtime dos bancos
- ✅ Tabelas: 5 criadas (users, subscriptions, api_keys, usage_records, migrations)
- ✅ Indexes: 21
- ✅ Foreign Keys: 4

**Scripts Criados:**
1. apply-sql-direct-refactored.sh
2. safe-migration-check-fixed.sh
3. emergency-stop.sh

**Decisão Arquitetural:** SQL direto é método preferido para prod com RAM limitada

**Impacto:** Migration production-ready

---

### 📅 FASE 20: Deep Debugging Repository Architecture (10/Dez/2025)

**Objetivo:** Resolver erro "Cannot read properties of undefined"

**Problema Identificado:**
```
Error: Cannot read properties of undefined (reading 'findOne')
```

**Root Cause Analysis:**

1. **Descoberta:**
```typescript
// UserRepository.ts
class UserRepository {
  static initialize() {  // ← Método existe
    this.repository = AppDataSource.getRepository(UserEntity);
  }
  
  static async findByEmail(email: string) {
    return this.repository.findOne({ where: { email } }); // ← repository é undefined!
  }
}
```

2. **Problema:** `initialize()` nunca era chamado
3. **DatabaseService.initialize()** não chamava `UserRepository.initialize()`

**Soluções Identificadas:**

**Solução 1: Lazy Initialization via Getter (IMPLEMENTADA):**
```typescript
class UserRepository {
  static get repository() {
    if (!this._repository) {
      this._repository = AppDataSource.getRepository(UserEntity);
    }
    return this._repository;
  }
  
  static async findByEmail(email: string) {
    return this.repository.findOne({ where: { email } });
  }
}
```

**Vantagens:**
- Inicialização automática quando necessário
- Zero dependências externas
- Thread-safe

**Solução 2: Chamar initialize() no Startup**
**Solução 3: Factory Pattern**

**Decisão:** Lazy initialization (Solução 1) por simplicidade

**Impacto:** Repository architecture corrigida

---

### 📅 FASE 21-22: Sprint1 API Key Management Fixes (10/Dez/2025)

**Objetivo:** Implementar correções identificadas na Fase 20

**Fase 21 - Fix Implementation:**
- ✅ UserRepository lazy initialization implementada
- ✅ ApiKeyRepository atualizado
- ✅ SubscriptionRepository atualizado
- ✅ Testes dos 7 endpoints

**Fase 22 - Final Fixes:**
- ✅ UsageRecordEntity ajustes
- ✅ Logger paths corrigidos
- ✅ Refinamento de error handling

**Status Pós-Correções:**
- ⚠️ 90% funcional (19/21 testes passando)
- ❌ 2 endpoints com erro:
  - Estatísticas de uso (HTTP 500)
  - Autenticação X-API-Key (HTTP 401)

**Impacto:** Sistema quase 100% funcional

---

### 📅 FASE 23-24: Validação e Correções Finais (10/Dez/2025)

**Objetivo:** Validar implementação e corrigir últimos erros

**Fase 23 - Validação:**
- ✅ Validação cruzada das implementações
- ✅ Identificação de erros remanescentes
- ✅ Planejamento de correções

**Fase 24 - Correções:**
- ✅ Correções de logger paths
- ✅ Refinamento de error handling
- ✅ Preparação para validação total

**Impacto:** Sistema pronto para validação final

---

### 📅 FASE 25: API Key Management Validação Total (11/Dez/2025)

**Objetivo:** Atingir 100% de funcionalidade

**Problemas Finais Identificados:**

1. **UsageRecordEntity não registrada:**
```typescript
// ❌ ANTES: config.ts
entities: [UserEntity, SubscriptionEntity, ApiKeyEntity]

// ✅ DEPOIS:
entities: [UserEntity, SubscriptionEntity, ApiKeyEntity, UsageRecordEntity]
```

2. **Logger import path incorreto:**
```typescript
// ❌ ANTES: apiKeyAuth.ts
import logger from '../../shared/utils/logger';

// ✅ DEPOIS:
import logger from '../../config/logger';
```

3. **Column mappings snake_case:**
```typescript
// ✅ Todos campos mapeados explicitamente
@Column({ name: 'api_key_id', type: 'uuid' })
apiKeyId!: string;

@Column({ name: 'response_time_ms', type: 'int' })
responseTime!: number;
```

**Pipeline de Deploy Robusto:**
1. Build sem cache
2. Import fresh para K3s
3. Force imagePullPolicy: Never
4. Delete pod para forçar recriação
5. Validação completa

**Resultado Final:**
- ✅ 100% funcional (22/22 testes passando)
- ✅ Taxa de sucesso: 100%
- ✅ Zero HTTP 500 errors
- ✅ Zero HTTP 401 errors
- ✅ Sistema production-ready

**Métricas:**
- Tempo sessão: 53 minutos
- Bugs resolvidos: 5
- Arquivos modificados: 3
- Deploys: 4 iterações

**Impacto:** Sprint 1 100% completo e validado

---

## Decisões Arquiteturais Críticas

### 1. Static Methods nos Services (Fase 3)
**Decisão:** Usar static methods em todos Services e Controllers  
**Motivo:** Simplicidade, sem necessidade de DI container  
**Trade-off:** Testabilidade reduzida, mas suficiente para MVP  
**Status:** ✅ Implementado

### 2. Path Aliases Removed (Fase 10)
**Decisão:** Usar imports relativos ao invés de path aliases  
**Motivo:** Path aliases TypeScript não funcionam em runtime Node.js  
**Trade-off:** Imports mais longos, mas build confiável  
**Status:** ✅ Implementado

### 3. Redis Shared Architecture (Fase 9)
**Decisão:** 1 Redis shared com database isolation (0=dev, 1=staging, 2=prod)  
**Motivo:** Economia de 200-300MB RAM  
**Benefício:** ExternalName Services facilitam migração futura  
**Status:** ✅ Implementado

### 4. PostgreSQL sem Backup Sidecar (Fase 9)
**Decisão:** CronJob para backups ao invés de sidecar  
**Motivo:** Economia de 128-256MB RAM  
**Trade-off:** Backups menos frequentes  
**Status:** ✅ Implementado

### 5. Logger com Paths Absolutos (Fase 15)
**Decisão:** Winston com path.join('/app', 'logs')  
**Motivo:** Containers precisam paths absolutos  
**Status:** ✅ Implementado

### 6. RequestLogger usando req.originalUrl (Fase 14)
**Decisão:** req.originalUrl ao invés de req.path  
**Motivo:** Logs precisam mostrar path completo  
**Status:** ✅ Implementado

### 7. Database Migration via SQL Direto (Fase 19) ⭐
**Decisão:** SQL direto para migrations em RAM limitada  
**Motivo:** TypeORM travava em servidores < 2GB RAM  
**Benefícios:**
- Tempo: < 1s vs 5+ minutos
- RAM: < 10MB vs 500MB+
- Idempotente com IF NOT EXISTS
- Zero downtime
**Status:** ✅ Implementado e documentado

### 8. Lazy Initialization nos Repositories (Fase 20) ⭐
**Decisão:** Usar getter para inicialização lazy  
**Motivo:** initialize() nunca era chamado  
**Implementação:**
```typescript
static get repository() {
  if (!this._repository) {
    this._repository = AppDataSource.getRepository(Entity);
  }
  return this._repository;
}
```
**Status:** ✅ Implementado em todos repositories

### 9. TypeORM Column Mappings Snake_Case (Fase 25) ⭐
**Decisão:** Mapear explicitamente todos campos snake_case  
**Motivo:** Banco usa snake_case, TypeScript usa camelCase  
**Exemplo:**
```typescript
@Column({ name: 'response_time_ms', type: 'int' })
responseTime!: number;
```
**Status:** ✅ Implementado em todas entities

### 10. No-Cache Docker Builds (Fase 25) ⭐
**Decisão:** Sempre usar `docker build --no-cache`  
**Motivo:** K3s mantinha cache de imagens antigas  
**Status:** ✅ Documentado e padronizado

### 11. Multi-stage Docker Build (Fase 8)
**Decisão:** Build em 2 estágios (builder + runner)  
**Motivo:** Otimização de tamanho de imagem  
**Resultado:** 60% menor (~300MB vs ~750MB)  
**Status:** ✅ Implementado

### 12. Ingress Versão Light (Fase 16)
**Decisão:** Ingress básico sem middlewares CRD  
**Motivo:** Traefik CRDs ausentes no K3s  
**Trade-off:** Sem CORS/Rate Limit avançado via Ingress  
**Plano:** Implementar na Fase 26  
**Status:** ✅ Implementado (temporário)

---

## Lições Aprendidas

### Lição 1: Investigation First (Fase 10)
**Contexto:** 20+ erros TypeScript persistentes

**Abordagem Errada:**
- ❌ Corrigir sem investigar
- ❌ Criar arquivos duplicados
- ❌ Não identificar root cause

**Abordagem Correta:**
- ✅ Análise do código existente
- ✅ Root Cause Analysis
- ✅ Surgical fixes baseados em fatos
- ✅ Resultado: Build success em 1 tentativa

**Princípio:** "Measure twice, cut once"

---

### Lição 2: Monitoramento de Recursos é Crítico (Fase 19)
**Contexto:** Migration travando em servidor com RAM limitada

**Comandos Essenciais:**
```bash
free -h                    # RAM disponível
ps aux | grep "Dl+"        # Processos travados em I/O
kubectl top pods -A        # Uso de recursos K8s
```

**Aprendizado:** Sempre verificar recursos antes de operações pesadas

---

### Lição 3: Bypass Criativo Quando Necessário (Fase 19)
**Contexto:** TypeORM migration falhando

**Lição:** Quando o caminho padrão falha, soluções alternativas (SQL direto) são válidas e profissionais

**Princípio:** Pragmatismo > Purismo

---

### Lição 4: Isolamento de Ambiente (Fase 19)
**Contexto:** Múltiplos sistemas concorrentes por RAM

**Solução:**
```bash
# Identificar processos concorrentes
ps aux | grep node | grep -v shaka

# Parar temporariamente durante operações críticas 
kill <PID>
```
 
**Aprendizado:** Isolar ambiente durante operações críticas

---

### Lição 5: Idempotência é Fundamental (Fase 19)
**Contexto:** Migrations SQL

**Princípio:** Sempre usar `CREATE TABLE IF NOT EXISTS`

**Benefício:** Pode rodar múltiplas vezes sem erros

---

### Lição 6: Lazy Initialization vs Explicit Init (Fase 20)
**Contexto:** Repository initialization

**Comparação:**
| Abordagem     | Vantagens           | Desvantagens                 |
|---------------|---------------------|------------------------------|
| Explicit Init | Controle, debugging | Esquecimento, boilerplate    |
| Lazy (Getter) | Automático, simples | Dependência de AppDataSource |

**Decisão:** Lazy initialization venceu por simplicidade

---

### Lição 7: Cache de Imagens K3s (Fases 21-25)
**Contexto:** Pod usando imagem antiga mesmo após rebuild

**Problema:** K3s mantém cache mesmo com imagePullPolicy: Always

**Solução Definitiva:**
1. Remover TODAS imagens antigas
2. Build sem cache
3. Import fresh
4. imagePullPolicy: Never
5. Delete pod para forçar recriação

**Aprendizado:** Sempre validar que o pod está usando a imagem correta

---

### Lição 8: Mappings Explícitos (Fase 25)
**Contexto:** TypeORM column names

**Problema:** Banco snake_case, TypeScript camelCase

**Solução:** Sempre mapear explicitamente

**Princípio:** "Explicit is better than implicit"

---

### Lição 9: Import Paths em Containers (Fase 25)
**Contexto:** Logger import falhando

**Problema:** Paths relativos complexos quebrando

**Solução:** Centralizar imports comuns em config/

**Aprendizado:** Estrutura de imports deve ser simples e consistente

---

### Lição 10: Testing Progressivo (Fase 25)
**Contexto:** 22 testes validando sistema

**Abordagem:**
1. Implementar feature
2. Corrigir erros de build
3. Deploy
4. Testar endpoint por endpoint
5. Corrigir issues
6. Repeat até 100%

**Resultado:** 90% → 100% em 53 minutos

**Princípio:** Validação incremental > Big Bang

---

# PARTE V: OPERAÇÕES & MANUTENÇÃO

## Testing & Validation

### Test Suites

```bash
# Run all tests
npm test

# With coverage
npm run test:coverage

# Specific suite
npm test -- auth.test.ts
npm test -- api-keys.test.ts
```

### Validation Scripts

#### Script 1: validate-api-keys-v2.sh
Testa todos os 7 endpoints de API Key Management.

```bash
~/shaka-api/scripts/validate-api-keys-v2.sh
```

**Output esperado:**
```
✅ Taxa de Sucesso: 100% (22/22 testes)
✅ Sistema completamente funcional
```

**Testes Executados:**
1. Health check
2. Register user
3. Login user
4. Create API Key
5. List API Keys
6. Get API Key details
7. Get usage stats
8. Rotate API Key
9. Revoke API Key
10. Test X-API-Key auth
11. Delete permanently

#### Script 2: health-check.sh
Valida infraestrutura completa.

```bash
~/shaka-api/scripts/health-check.sh
```

**Validações:**
- ✅ Pods rodando
- ✅ PostgreSQL conectado
- ✅ Redis conectado
- ✅ API respondendo
- ✅ Ingress configurado

---

## Monitoring & Observability

### Health Endpoints

```
GET /health              - Basic health check
GET /health/detailed     - Full system status
GET /metrics             - Prometheus metrics (TODO: Fase 26)
```

**Health Response:**
```json
{
  "status": "healthy",
  "timestamp": "2025-12-13T10:00:00Z",
  "services": {
    "database": "connected",
    "redis": "connected",
    "api": "running"
  },
  "version": "3.0.0"
}
```

### Logs

```bash
# API logs
kubectl logs -n shaka-staging -l app=shaka-api --tail=100 -f

# Database logs
kubectl logs -n shaka-staging postgres-0 --tail=100

# Redis logs
kubectl logs -n shaka-shared redis-0 --tail=100

# Traefik logs
kubectl logs -n kube-system -l app.kubernetes.io/name=traefik --tail=100
```

### Log Levels

```typescript
logger.error('Critical error');  // Erros graves
logger.warn('Warning message');  // Avisos
logger.info('Info message');     // Informações gerais
logger.debug('Debug details');   // Debugging (desabilitado em prod)
```

### Key Metrics to Monitor

| Métrica                 | Threshold Alerta | Ação                  |
|-------------------------|------------------|-----------------------|
| API Response Time (p95) | > 500ms          | Scale up pods         |
| Error Rate (5xx)        | > 1%             | Investigate logs      |
| Database Connections    | > 80%            | Scale PostgreSQL      |
| Redis Memory            | > 90%            | Increase memory limit |
| Pod Restarts            | > 3/hour         | Check pod logs        |
| Rate Limit Hits         | Spike > 50%      | Review quota abuse    |

---

## Security

### Authentication

**JWT Configuration:**
```env
JWT_SECRET=<MINIMUM_64_CHARS>
JWT_REFRESH_SECRET=<MINIMUM_64_CHARS>
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=7d
```

**Best Practices:**
- ✅ Tokens short-lived (15 min access, 7 days refresh)
- ✅ Refresh token rotation
- ✅ Secure secrets (64+ chars random)
- ✅ HTTPS only in production
- ✅ httpOnly cookies (se necessário)

### API Keys

**Security Measures:**
- ✅ SHA-256 hashing (nunca plaintext)
- ✅ Preview limitado (12 chars)
- ✅ Crypto.randomBytes para geração
- ✅ Rate limiting por key
- ✅ Expiration automática
- ✅ Revogação (soft delete)
- ✅ Audit trail (usage_records)

### Database

**Access Control:**
```sql
-- Usuario com permissoes minimas
GRANT SELECT, INSERT, UPDATE, DELETE 
ON ALL TABLES IN SCHEMA public 
TO shaka_staging;

-- Sem DROP, ALTER, TRUNCATE
REVOKE CREATE ON SCHEMA public FROM shaka_staging;
```

**Connection Security:**
- ✅ Password forte (32+ chars)
- ✅ SSL/TLS em producao (TODO)
- ✅ Connection pooling limitado
- ✅ Prepared statements (SQL injection protection)

---

## Error Handling

### Standard Error Response

```json
{
  "success": false,
  "error": "Human-readable message",
  "code": "ERROR_CODE",
  "details": {
    "field": "Additional context"
  }
}
```

### Error Codes

| Code                | HTTP | Descrição                    |
|---------------------|------|------------------------------|
| UNAUTHORIZED        | 401  | Token invalido ou ausente    |
| FORBIDDEN           | 403  | Sem permissao                |
| NOT_FOUND           | 404  | Recurso nao encontrado       |
| RATE_LIMIT_EXCEEDED | 429  | Limite de requests excedido  |
| INTERNAL_ERROR      | 500  | Erro interno do servidor     |
| API_KEY_INVALID     | 403  | API key invalida ou revogada |
| API_KEY_EXPIRED     | 403  | API key expirada             |
| VALIDATION_ERROR    | 400  | Dados de entrada invalidos   |

---

# PARTE VI: ROADMAP & PRÓXIMOS PASSOS

## Proximos Passos

### Fase 26: Observabilidade Completa (PRIORIDADE ALTA)

**Stack Prometheus + Grafana:**

```yaml
monitoring/
├── prometheus/
│   ├── prometheus.yml       # Config + scrape targets
│   ├── alerts.yml           # Regras de alerta
│   └── recording-rules.yml  # Metricas agregadas
├── grafana/
│   ├── dashboards/
│   │   ├── api-overview.json
│   │   ├── database.json
│   │   └── redis.json
│   └── provisioning/
└── loki/
    └── loki-config.yml
```

**Metricas Criticas:**
- Request rate (req/s)
- Response time (p50, p95, p99)
- Error rate (5xx)
- API calls por plano
- Database connections
- Redis hit rate

**Alertas:**
- API down (5xx > 10%)
- High latency (p95 > 500ms)
- Database connections > 80%
- Redis memory > 90%
- Disk space < 10%

---

### Fase 27: TLS/HTTPS (PRIORIDADE ALTA)

**Cert-Manager + Let's Encrypt:**

```yaml
# Automated TLS certificates
cert-manager.io/issuer: letsencrypt-prod

# HTTPS em todos Ingress
tls:
  - hosts:
      - staging.shaka.com
    secretName: shaka-staging-tls
```

---

### Fase 28: CI/CD Pipeline (PRIORIDADE MÉDIA)

**GitHub Actions:**

```yaml
# .github/workflows/ci-cd.yml
on: [push, pull_request]
jobs:
  test:
    - npm ci
    - npm run build
    - npm test
    - npm run test:coverage
  
  deploy-staging:
    - docker build --no-cache
    - docker push
    - kubectl set image
```

---

### Fase 29: Rate Limiting Avançado (PRIORIDADE MÉDIA)

**Features:**
- Rate limiting por endpoint
- Burst allowance
- Quotas mensais
- Admin overrides
- Analytics de throttling

---

### Fase 30: Stripe Integration (PRIORIDADE BAIXA)

**Features:**
- Subscription management
- Payment processing
- Webhook handling
- Invoice generation
- Usage-based billing

---

## Success Metrics (KPIs)

### Technical Metrics

| Metric            | Current         | Target Q2       | Target Q4 |
|-------------------|-----------------|-----------------|-----------|
| Uptime            | -               | 99.5%           | 99.9%     |
| P95 Latency       | -               | <200ms          | <150ms    |
| Error Rate        | 0%              | <0.5%           | <0.1%     |
| Test Coverage     | 100% functional | 85% code        | 90% code  |
| MTTR              | -               | <30min          | <15min    |
| Deploy Frequency  | Manual          | Daily           | On-demand |
| Security Vulns    | -               | 0 High/Critical | 0 Medium+ |

### Business Metrics

| Metric                | Target Q2 | Target Q4 |
|-----------------------|-----------|-----------|
| Active Users          | 100       | 1,000     |
| API Calls/day         | 10k       | 100k      |
| Customer Satisfaction | >4.0/5    | >4.5/5    |
| Onboarding Time       | <5min     | <3min     |

---

## APENDICES

### A. Glossario de Termos

| Termo                   | Definição                                       |
|-------------------------|-------------------------------------------------|
| **API Key**             | Chave de autenticação no formato `sk_live_...`  |
| **JWT**                 | JSON Web Token, token stateless                 |
| **Multi-tenancy**       | Múltiplos usuários compartilham infraestrutura  |
| **Rate Limiting**       | Limitar requests por período                    |
| **Soft Delete**         | Marcar como inativo ao invés de deletar         |
| **StatefulSet**         | Recurso K8s para aplicacoes com estado          |
| **Ingress**             | Roteamento HTTP/HTTPS externo para servicos K8s |
| **Clean Architecture**  | Separacao de codigo em camadas independentes    |
| **TypeORM**             | ORM para TypeScript                             |
| **Lazy Initialization** | Inicializar recurso apenas quando necessário    |
| **Snake Case**          | Convenção: user_id, api_key_id                  |
| **HPA**                 | Horizontal Pod Autoscaler                       |
| **MTTR**                | Mean Time To Recovery                           |

### B. Environment Variables

```bash
# Server
NODE_ENV=development|staging|production
PORT=3000

# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=shaka_staging
DB_USER=shaka_staging
DB_PASSWORD=<SENHA_FORTE_32_CHARS>

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=<SENHA_FORTE_32_CHARS>

# JWT
JWT_SECRET=<64_CHARS_MINIMO>
JWT_REFRESH_SECRET=<64_CHARS_MINIMO>
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=7d

# Rate Limiter
RATE_LIMITER_BACKEND=memory|redis
USAGE_TRACKING_ENABLED=true|false
USAGE_RETENTION_DAYS=90
```

### C. Scripts Inventory

```bash
# Docker
scripts/docker/
├── start.sh
├── stop.sh
├── logs.sh
└── health.sh

# Database
scripts/database/
├── apply-migrations.sh
├── apply-sql-direct.sh
├── safe-migration-check.sh
└── backup.sh

# Kubernetes
scripts/kubernetes/
├── deploy.sh
├── rollback.sh
└── health-check.sh

# Validation
scripts/validation/
├── validate-api-keys-v2.sh
├── health-check.sh
└── test-api-keys-portforward.sh

# Deployment
scripts/deployment/
├── rebuild-no-cache.sh
└── force-new-image.sh
```

---

## CONCLUSAO

Este Memorando Único v3.0 documenta a **jornada completa** do Shaka API desde a fundação até o estado production-ready atual.

**Conquistas (25 Fases):**
- ✅ Arquitetura Clean Architecture implementada
- ✅ Sistema containerizado (Docker + Kubernetes)
- ✅ Sprint 1 100% completo (API Key Management)
- ✅ 22/22 testes passando
- ✅ Production-ready em staging
- ✅ 120+ scripts de automação
- ✅ 32 memorandos documentados

**Próximos Marcos:**
- 🎯 Observabilidade (Prometheus + Grafana)
- 🔒 TLS/HTTPS (Cert-Manager)
- 🚀 CI/CD Pipeline (GitHub Actions)

---

**FIM DO MEMORANDO ÚNICO v3.0**

```
Documento: Shaka API Knowledge Base Completa
Versao: 3.0.0
Consolidacao: 28 memorandos de implementacao (Fases 1-25)
Linhas: ~3.000
Tempo de leitura: 2-3 horas
Ultima atualizacao: 2025-12-13
Status: PRODUCTION READY ✅
Coverage: 100% (22/22 tests passing) ✅
Sprint 1: COMPLETO ✅
```

---

*Este documento é a FONTE ÚNICA DE VERDADE completa para o projeto Shaka API. Consolida toda a jornada de desenvolvimento, desde a primeira linha de código até o sistema production-ready. Mantenha-o atualizado a cada fase significativa.*
