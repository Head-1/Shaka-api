# 📋 SHAKA API - DEVELOPER KNOWLEDGE BASE
## Sistema Completo em 1 Documento

```yaml
---
document: Shaka API Knowledge Base
version: 1.0.0
last_updated: 2025-12-06
system_status:
  build: clean (0 errors)
  deployment: staging (running)
  coverage: 81.9%
  features: [auth, api-keys, usage-tracking, rate-limiting]
tech_stack:
  runtime: Node.js 20 + TypeScript
  api: Express 4.x
  database: PostgreSQL 15 + TypeORM
  cache: Redis 7
  orchestration: Kubernetes (K3s)
---
```

---

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

### Estrutura de Diretorios

```
shaka-api/
├── src/                    # Codigo-fonte
│   ├── api/               # Presentation Layer
│   │   ├── controllers/   # HTTP handlers
│   │   ├── middlewares/   # Auth, validation, logging
│   │   ├── routes/        # Express routers
│   │   └── validators/    # Joi schemas
│   ├── core/              # Business Logic
│   │   ├── services/      # Domain services
│   │   └── types/         # TypeScript interfaces
│   ├── infrastructure/    # External integrations
│   │   ├── database/      # TypeORM entities + repos
│   │   └── cache/         # Redis client
│   └── config/            # Env vars + logger
├── tests/                 # Test suites (143 tests)
├── scripts/               # Automation (43 scripts)
├── infrastructure/        # Kubernetes manifests
│   └── kubernetes/
├── docker/                # Docker configs
└── docs/                  # Documentation
```

### Comandos Essenciais

```bash
# Desenvolvimento
npm run dev              # Hot reload
npm run build            # Compile TypeScript
npm test                 # Run all tests
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
kubectl get pods -A | grep shaka
kubectl logs -f <pod-name> -n shaka-dev
kubectl exec -it <pod-name> -n shaka-dev -- sh
```

---

## SECAO 2: ARQUITETURA CORE

### Clean Architecture

```
┌─────────────────────────────────────────────┐
│  PRESENTATION LAYER                         │
│  Controllers, Routes, Middlewares           │
│  - AuthController, UserController           │
│  - authenticate, apiKeyAuth, trackUsage     │
│  - Joi validators                           │
├─────────────────────────────────────────────┤
│  APPLICATION LAYER                          │
│  Services (Business Logic)                  │
│  - AuthService, UserService, ApiKeyService  │
│  - UsageTrackingService, RateLimiterService │
├─────────────────────────────────────────────┤
│  DOMAIN LAYER                               │
│  Entities, Types, Business Rules            │
│  - User, Subscription, ApiKey interfaces    │
│  - PLAN_LIMITS, validation rules            │
├─────────────────────────────────────────────┤
│  INFRASTRUCTURE LAYER                       │
│  External Services & Data Access            │
│  - TypeORM repositories                     │
│  - Redis cache                              │
│  - PostgreSQL connection                    │
└─────────────────────────────────────────────┘
```

### Fluxo de Requisicao

```
Client Request
    ↓
Ingress Controller (Traefik) - HTTPS
    ↓
Kubernetes Service (Load Balancer)
    ↓
API Pod (Express)
    ├→ Logger Middleware (registro)
    ├→ CORS Middleware (headers)
    ├→ Rate Limiter (Redis check)
    ├→ Auth Middleware (JWT ou API Key)
    │   ├→ Verify token/key
    │   └→ Decode payload
    ├→ Validator (Joi schema)
    ├→ Controller (HTTP handler)
    │   └→ Service (business logic)
    │       ├→ Repository (data access)
    │       └→ Cache (Redis)
    ├→ Database Query (PostgreSQL)
    └→ Response
        ├→ Error Handler (if error)
        └→ JSON Response
```

### Database Schema

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
  ├── apiKeyId (UUID)
  ├── userId (UUID, FK -> users)
  ├── endpoint (VARCHAR)
  ├── method (VARCHAR)
  ├── statusCode (INT)
  ├── responseTime (INT)        -- milliseconds
  ├── ipAddress (VARCHAR)
  ├── userAgent (TEXT)
  ├── errorMessage (TEXT)
  └── timestamp (TIMESTAMP)

-- INDEXES (Performance)
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_api_keys_userId ON api_keys(userId);
CREATE UNIQUE INDEX idx_api_keys_keyHash ON api_keys(keyHash);
CREATE INDEX idx_usage_apiKeyId_timestamp ON usage_records(apiKeyId, timestamp);
```

### Decisoes Arquiteturais

| Decisao                | Opcao Escolhida           | Trade-off                  | Justificativa                      |
|------------------------|---------------------------|----------------------------|------------------------------------|
| **K8s Distribution**   | K3s single-node           | HA sacrificada             | Custo baixo, suficiente para MVP   |
| **Database per Env**   | 3 PostgreSQL instances    | ~75MB RAM cada             | Isolamento total de dados          |
| **Redis Architecture** | 1 instancia compartilhada | Single point of failure    | Economia de 256MB RAM              |
| **Ingress Controller** | Traefik (nativo K3s)      | CRDs nao instalados        | Pre-instalado, suficiente          |
| **Container User**     | Non-root (nodejs:1001)    | Setup de permissoes        | Security best practice             |
| **Docker Build**       | Multi-stage               | 2x build time              | Imagem 60% menor (~300MB)          |
| **Path Aliases**       | Removidos em producao     | Imports longos             | Elimina runtime dependency         |
| **npm install vs ci**  | npm install               | Build menos deterministico | package-lock.json no .dockerignore |

---

## SECAO 3: FEATURES IMPLEMENTADAS

### Autenticacao JWT

**Metodos:**
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

**Tokens:**
- **Access Token:** JWT, 15 minutos, Bearer authentication
- **Refresh Token:** JWT, 7 dias, rotacao automatica

**Endpoints:**
```
POST /api/v1/auth/register  - Criar conta
POST /api/v1/auth/login     - Autenticar
POST /api/v1/auth/refresh   - Renovar tokens
```

### Multi-tenancy (Planos)

| Plano          | Requests/Dia | Requests/Min | API Keys  | Preco/Mes |
|----------------|--------------|--------------|-----------|-----------|
| **Starter**    | 100          | 10           | 1         | Gratis    |
| **Pro**        | 1,000        | 50           | 5         | $29       |
| **Business**   | 10,000       | 200          | 20        | $99       |
| **Enterprise** | Unlimited    | 1,000        | Unlimited | Custom    |

**PLAN_LIMITS (codigo):**
```typescript
export const PLAN_LIMITS: Record<SubscriptionPlan, PlanLimits> = {
  starter: {
    requestsPerDay: 100,
    requestsPerMinute: 10,
    concurrentRequests: 2,
    maxApiKeys: 1,
    features: ['basic_api', 'email_support']
  },
  pro: {
    requestsPerDay: 1000,
    requestsPerMinute: 50,
    concurrentRequests: 10,
    maxApiKeys: 5,
    features: ['basic_api', 'advanced_api', 'webhooks', 'priority_support']
  },
  // ... business, enterprise
};
```

### API Key Management

**Formato da Key:**
```
sk_live_EXAMPLE_DOCUMENTATION_ONLY
│  │    └────────────────────────────────────────────────┘
│  │                     48 caracteres hex
│  └─ Ambiente (live ou test)
└─ Prefixo (secret key)
```

**Security:**
- Keys armazenadas como **SHA256 hash** (64 chars)
- Plaintext mostrado **apenas 1 vez** na criacao
- Preview armazenado (primeiros 12 chars) para identificacao

**Endpoints:**
```
POST   /api/v1/keys              - Criar API key
GET    /api/v1/keys              - Listar keys
GET    /api/v1/keys/:id          - Detalhes de uma key
GET    /api/v1/keys/:id/usage    - Estatisticas de uso
POST   /api/v1/keys/:id/rotate   - Rotacionar key (seguranca)
DELETE /api/v1/keys/:id          - Revogar key (soft delete)
DELETE /api/v1/keys/:id/permanent - Deletar permanentemente
```

**Metodos Service:**
```typescript
class ApiKeyService {
  // Gerar chave com crypto
  static generateKey(prefix: 'live' | 'test'): {
    key: string;      // sk_live_...
    hash: string;     // SHA256 hash
    preview: string;  // sk_live_abc1
  }
  
  // Criar e salvar
  static async createKey(data: CreateApiKeyDTO): Promise<ApiKeyWithPlaintext>
  
  // Validar em requests
  static async validateKey(key: string): Promise<ValidateApiKeyResult>
  
  // CRUD operations
  static async listKeys(userId: string): Promise<ApiKey[]>
  static async getKey(userId: string, keyId: string): Promise<ApiKey>
  static async revokeKey(userId: string, keyId: string): Promise<void>
  static async rotateKey(userId: string, keyId: string): Promise<ApiKeyWithPlaintext>
  
  // Analytics
  static async getUsageStats(userId: string, keyId: string): Promise<UsageStats>
}
```

**Middleware de Autenticacao:**
```typescript
// Header: X-API-Key: sk_live_...
export const apiKeyAuth = async (req, res, next) => {
  // 1. Extrair API key do header
  const apiKey = req.headers['x-api-key'];
  
  // 2. Validar key (hash lookup)
  const validation = await ApiKeyService.validateKey(apiKey);
  
  // 3. Verificar rate limiting
  const rateLimitResult = await RateLimiterService.checkLimit(
    validation.apiKey.id,
    validation.apiKey.rateLimit
  );
  
  // 4. Anexar ao request
  req.user = validation.user;
  req.apiKey = validation.apiKey;
  
  // 5. Headers de rate limit
  res.setHeader('X-RateLimit-Limit', rateLimitResult.limit);
  res.setHeader('X-RateLimit-Remaining', rateLimitResult.remaining);
  res.setHeader('X-RateLimit-Reset', rateLimitResult.resetAt);
  
  next();
};
```

### Usage Tracking (Analytics)

**Dados Coletados:**
```typescript
interface UsageRecord {
  apiKeyId: string;
  userId: string;
  endpoint: string;        // /api/v1/data
  method: string;          // GET, POST, etc
  statusCode: number;      // 200, 404, 500
  responseTime: number;    // milliseconds
  ipAddress?: string;      // Cliente IP
  userAgent?: string;      // Browser/client
  errorMessage?: string;   // Se statusCode >= 400
  timestamp: Date;
}
```

**Estatisticas Disponiveis:**
```json
{
  "totalRequests": 15432,
  "requestsToday": 234,
  "requestsThisWeek": 1823,
  "requestsThisMonth": 8912,
  "lastUsed": "2025-12-06T09:45:23Z",
  "averageLatency": 120,
  "errorRate": 1.2,
  "mostUsedEndpoints": [
    {
      "endpoint": "/api/v1/data",
      "method": "GET",
      "count": 8234,
      "averageLatency": 95,
      "errorCount": 23
    }
  ],
  "statusCodeDistribution": {
    "200": 14123,
    "201": 890,
    "400": 156,
    "404": 98,
    "500": 165
  }
}
```

**Metodos Service:**
```typescript
class UsageTrackingService {
  // Registrar uso (chamado do middleware)
  static async trackUsage(data: TrackUsageDTO): Promise<void>
  
  // Estatisticas
  static async getStats(apiKeyId: string): Promise<UsageStats>
  
  // Dados para graficos
  static async getDailyUsage(apiKeyId: string, days: number): Promise<DailyUsage[]>
  
  // Cleanup (cron job)
  static async cleanupOldRecords(retentionDays: number): Promise<number>
}
```

**Middleware de Tracking:**
```typescript
export const trackUsage = (req, res, next) => {
  const startTime = Date.now();
  
  // Hook no evento 'finish' da response
  res.on('finish', () => {
    const responseTime = Date.now() - startTime;
    
    if (req.apiKey && req.user) {
      UsageTrackingService.trackUsage({
        apiKeyId: req.apiKey.id,
        userId: req.user.id,
        endpoint: req.originalUrl,
        method: req.method,
        statusCode: res.statusCode,
        responseTime,
        ipAddress: req.ip,
        userAgent: req.get('user-agent')
      }).catch(err => {
        logger.error('[trackUsage] Error:', err);
        // Nao bloquear request se tracking falhar
      });
    }
  });
  
  next();
};
```

### Rate Limiting

**Algoritmo:** Sliding Window (em memoria, migrar para Redis em producao)

**Implementacao:**
```typescript
class RateLimiterService {
  private static usageCounters: Map<string, {
    count: number;
    resetAt: Date;
  }> = new Map();
  
  // Verificar limite
  static async checkLimit(
    identifier: string,      // API key ID ou User ID
    limits: RateLimitConfig  // requestsPerDay, requestsPerMinute
  ): Promise<RateLimitResult> {
    const key = identifier;
    const now = new Date();
    
    let counter = this.usageCounters.get(key);
    
    // Reset se passou 24h
    if (!counter || counter.resetAt < now) {
      counter = {
        count: 0,
        resetAt: new Date(now.getTime() + 86400000) // +24h
      };
      this.usageCounters.set(key, counter);
    }
    
    const allowed = counter.count < limits.requestsPerDay;
    const remaining = Math.max(0, limits.requestsPerDay - counter.count);
    
    return {
      allowed,
      limit: limits.requestsPerDay,
      remaining,
      resetAt: counter.resetAt
    };
  }
  
  // Incrementar contador
  static async incrementUsage(
    identifier: string,
    limits: RateLimitConfig
  ): Promise<void> {
    const counter = this.usageCounters.get(identifier);
    if (counter) {
      counter.count++;
    }
  }
}
```

**Response Headers:**
```
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 2025-12-07T00:00:00Z
```

**429 Too Many Requests:**
```json
{
  "error": "Rate limit exceeded",
  "message": "Limit: 1000 requests/day",
  "limit": 1000,
  "remaining": 0,
  "resetAt": "2025-12-07T00:00:00Z"
}
```

---

## SECAO 4: INFRASTRUCTURE

### Kubernetes Namespaces

```yaml
# 5 Namespaces criados
shaka-dev          # Desenvolvimento (pausado)
shaka-staging      # Homologacao (ATIVO)
shaka-prod         # Producao (preparado)
shaka-monitoring   # Observability (futuro)
shaka-shared       # Servicos compartilhados (Redis)
```

**Resource Quotas:**

| Namespace | CPU      | RAM  | Pods | Status          |
|-----------|----------|------|------|-----------------|
| dev       | 1 core   | 2GB  | 10   | Scaled to 0     |
| staging   | 8 cores  | 16GB | 50   | Running (1 pod) |
| prod      | 32 cores | 64GB | 200  | Ready (0 pods)  |
| shared    | 2 cores  | 2GB  | 20   | Running (Redis) |

### PostgreSQL Multi-Ambiente

**Arquitetura:** StatefulSets com persistent storage

```
PostgreSQL 15 Alpine:
├── shaka-dev/postgres-0        (5GB,  256MB RAM) - Scaled to 0
├── shaka-staging/postgres-0    (10GB, 512MB RAM) - RUNNING
└── shaka-prod/postgres-0       (20GB, 256MB RAM) - RUNNING

Databases:
- shaka_dev (dev)
- shaka_staging (staging)
- shaka_production (prod)
```

**Conexao Testada:**
```bash
# Staging
kubectl exec -n shaka-staging postgres-0 -- \
  psql -U shaka_staging -d shaka_staging -c "SELECT 'STAGING OK';"
```

### Redis Shared Architecture

**Decisao:** 1 instancia Redis com isolamento por database

```
Redis 7 Alpine Shared:
├── Namespace: shaka-shared
├── Storage: 5GB persistent
├── RAM: 128MB request / 256MB limit
└── Databases:
    ├── DB 0: Development (prefix: dev:)
    ├── DB 1: Staging (prefix: staging:)
    └── DB 2: Production (prefix: prod:)
```

**Beneficios:**
- Economia de 200-300MB RAM (1 pod vs 3 pods)
- Isolamento garantido por database Redis nativo
- ExternalName Services facilitam migracao cloud

**ExternalName Services:**
```yaml
shaka-dev/redis-dev       -> redis.shaka-shared.svc.cluster.local
shaka-staging/redis-staging -> redis.shaka-shared.svc.cluster.local
shaka-prod/redis-prod     -> redis.shaka-shared.svc.cluster.local
```

### Docker Multi-stage Build

```dockerfile
# Stage 1: Builder
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build
RUN npm prune --production

# Stage 2: Runtime
FROM node:20-alpine
WORKDIR /app

# Criar usuario non-root
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Copiar com ownership correto
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist

# CRITICO: Criar diretorios ANTES de trocar usuario
RUN mkdir -p /app/logs /app/uploads /app/temp && \
    chown -R nodejs:nodejs /app

# Trocar para non-root
USER nodejs

EXPOSE 3000
HEALTHCHECK CMD node -e "require('http').get('http://localhost:3000/health')"
CMD ["node", "dist/server.js"]
```

**Beneficios:**
- Imagem 60% menor (~300MB vs ~800MB)
- Mais segura (sem devDependencies)
- Startup mais rapido

### Ingress Controller

**Traefik (K3s nativo):**
```yaml
Status: RUNNING
Namespace: kube-system
Pod: traefik-865bd56545-wbbh8
External IP: 91.99.184.67
```

**Ingress Rules (Staging):**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: shaka-api
  namespace: shaka-staging
spec:
  ingressClassName: traefik
  rules:
  - host: staging.shaka.local
    http:
      paths:
      - path: /health
        pathType: Prefix
        backend:
          service:
            name: shaka-api
            port:
              number: 3000
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: shaka-api
            port:
              number: 3000
```

**Acesso Externo:**
```bash
curl http://staging.shaka.local/health
# Response: {"status":"ok","environment":"staging"}
```

### Kubernetes Manifests

```
infrastructure/kubernetes/
├── 01-namespace.yaml              # Namespaces + Quotas + Policies
├── 01-namespace-fixed.yaml        # LimitRanges otimizados
├── 02-configmaps-secrets.yaml     # Configs + Secrets
├── 03-postgres-prod-fixed.yaml    # PostgreSQL (3 ambientes)
├── 04-redis-simple-scalable.yaml  # Redis Shared
└── ingress/
    ├── 01-ingress-staging.yaml    # Ingress Staging (ATIVO)
    ├── 02-ingress-dev.yaml        # Ingress Dev
    └── .future/
        ├── 03-middleware-cors.yaml     # CORS (Fase 17)
        └── 04-middleware-ratelimit.yaml # Rate limit granular
```

### Database Migrations

**Migrations Aplicadas:**
```sql
-- 1. Extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. Tabela: users
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email VARCHAR(255) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  plan VARCHAR(20) NOT NULL DEFAULT 'starter',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Tabela: subscriptions
CREATE TABLE subscriptions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  plan VARCHAR(20) NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'active',
  stripe_customer_id VARCHAR(100),
  stripe_subscription_id VARCHAR(100),
  current_period_start TIMESTAMP,
  current_period_end TIMESTAMP,
  cancel_at_period_end BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. Tabela: api_keys
CREATE TABLE api_keys (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(100) NOT NULL,
  key_hash VARCHAR(64) NOT NULL UNIQUE,
  key_preview VARCHAR(16) NOT NULL,
  permissions TEXT NOT NULL DEFAULT 'read,write',
  rate_limit JSONB NOT NULL,
  is_active BOOLEAN DEFAULT true,
  last_used_at TIMESTAMP,
  expires_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. Tabela: usage_records
CREATE TABLE usage_records (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  api_key_id UUID NOT NULL,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  endpoint VARCHAR(200) NOT NULL,
  method VARCHAR(10) NOT NULL,
  status_code INT NOT NULL,
  response_time INT NOT NULL,
  ip_address VARCHAR(45),
  user_agent TEXT,
  error_message TEXT,
  timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- INDEXES (Performance)
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_api_keys_user_id ON api_keys(user_id);
CREATE UNIQUE INDEX idx_api_keys_key_hash ON api_keys(key_hash);
CREATE INDEX idx_usage_api_key_timestamp ON usage_records(api_key_id, timestamp);
CREATE INDEX idx_usage_user_timestamp ON usage_records(user_id, timestamp);
```

**Aplicar Migrations:**
```bash
kubectl exec -n shaka-staging postgres-0 -- \
  psql -U shaka_staging -d shaka_staging < migrations.sql
```

---

## SECAO 5: TROUBLESHOOTING PLAYBOOK

### Top 10 Problemas e Solucoes

#### 1. Entity metadata not found

**Sintoma:**
```
Entity metadata for UserEntity#apiKeys was not found
```

**Causa:** Entity nao registrada no DataSource

**Solucao:**
```typescript
// src/infrastructure/database/config.ts
import { ApiKeyEntity } from './entities/ApiKeyEntity';

export const AppDataSource = new DataSource({
  // ...
  entities: [
    UserEntity, 
    SubscriptionEntity, 
    ApiKeyEntity  // ADICIONAR
  ],
});
```

#### 2. Pod CrashLoopBackOff

**Diagnostico:**
```bash
# Ver logs atuais
kubectl logs <pod-name> -n <namespace> --tail=50

# Ver logs anteriores (se crashou)
kubectl logs <pod-name> -n <namespace> --previous

# Ver eventos
kubectl describe pod <pod-name> -n <namespace>
```

**Causas Comuns:**
- Database connection failed (credenciais incorretas)
- Entity nao registrada
- Variavel de ambiente faltando
- Erro de runtime no codigo

**Solucoes:**
```bash
# 1. Verificar env vars
kubectl exec <pod-name> -n <namespace> -- env | grep DB_

# 2. Testar database connection
kubectl exec postgres-0 -n <namespace> -- \
  psql -U <user> -d <database> -c "SELECT 1"

# 3. Restart pod
kubectl delete pod <pod-name> -n <namespace> --force
```

#### 3. TypeScript Build Errors

**Problema:** 48+ erros TypeScript

**Solucao Sistematica:**
```bash
# 1. Verificar tsconfig.json
cat tsconfig.json | grep -A 5 "experimentalDecorators"

# Deve ter:
# "experimentalDecorators": true,
# "emitDecoratorMetadata": true,

# 2. Verificar imports
grep -rn "from '@" src/ | head -20

# 3. Build incremental
npm run build 2>&1 | grep "error TS" | wc -l

# 4. Corrigir erros em lotes
# Ordem: Types -> Entities -> Repositories -> Services -> Controllers
```

#### 4. Docker Image Not Found (K3s)

**Sintoma:**
```
Error: ErrImageNeverPull
```

**Solucao:**
```bash
# 1. Salvar imagem como tarball
docker save <image>:latest -o /tmp/image.tar

# 2. Importar para K3s
sudo k3s ctr images import /tmp/image.tar

# 3. Verificar
sudo k3s ctr images ls | grep <image>

# 4. Restart deployment
kubectl rollout restart deployment/<name> -n <namespace>
```

#### 5. Database Vazio (0 tabelas)

**Diagnostico:**
```bash
kubectl exec postgres-0 -n <namespace> -- \
  psql -U <user> -d <database> -c "\dt"

# Output: Did not find any relations.
```

**Solucao:**
```bash
# Aplicar migrations manualmente
kubectl exec postgres-0 -n <namespace> -- \
  psql -U <user> -d <database> << 'EOSQL'
-- Cole SQL das migrations aqui
CREATE TABLE users (...);
EOSQL
```

#### 6. Rate Limit Nao Funciona

**Problema:** Consegue fazer 200+ requests sem bloqueio

**Verificacoes:**
```bash
# 1. Middleware registrado?
cat src/api/routes/index.ts | grep rateLimiter

# 2. Redis funcionando?
kubectl exec redis-0 -n shaka-shared -- redis-cli PING

# 3. Usuario tem plano?
kubectl exec postgres-0 -n <namespace> -- \
  psql -U <user> -d <db> -c \
  "SELECT id, email, plan FROM users WHERE email='test@example.com';"
```

#### 7. Health Check Failing

**Diagnostico:**
```bash
# 1. Testar localmente
kubectl port-forward <pod> -n <namespace> 3000:3000 &
curl http://localhost:3000/health

# 2. Ver logs
kubectl logs <pod> -n <namespace> | grep health

# 3. Verificar probe config
kubectl get pod <pod> -n <namespace> -o yaml | grep -A 5 livenessProbe
```

#### 8. High Memory Usage

**Problema:** Pod usando 90%+ de memoria

**Diagnostico:**
```bash
# Ver uso de recursos
kubectl top pods -n <namespace>

# Ver limits
kubectl describe pod <pod> -n <namespace> | grep -A 10 "Limits:"
```

**Solucao:**
```yaml
# Ajustar limits no deployment
resources:
  requests:
    memory: 128Mi
  limits:
    memory: 256Mi
```

#### 9. Slow Queries

**Problema:** Latencia alta (>500ms)

**Verificacoes:**
```sql
-- Verificar indexes
SELECT tablename, indexname 
FROM pg_indexes 
WHERE schemaname = 'public';

-- Slow queries
SELECT query, mean_exec_time 
FROM pg_stat_statements 
ORDER BY mean_exec_time DESC 
LIMIT 10;
```

**Solucao:** Criar indexes para queries frequentes

#### 10. API Key Invalid

**Problema:** X-API-Key retorna 403

**Diagnostico:**
```bash
# 1. Verificar formato
echo "sk_live_abc123..." | wc -c
# Deve ter 54 caracteres

# 2. Verificar hash no banco
kubectl exec postgres-0 -n <namespace> -- \
  psql -U <user> -d <db> -c \
  "SELECT key_preview, is_active FROM api_keys WHERE key_preview='sk_live_abc1';"

# 3. Verificar expiracao
SELECT expires_at FROM api_keys WHERE id='<uuid>';
```

### Debugging Workflow (Flowchart)

```
Problema Identificado
    |
    v
[1] Ver Logs Atuais
    kubectl logs <pod> --tail=50
    |
    v
Erro Identificado?
    |-- NAO --> [2] Ver Logs Anteriores
    |              kubectl logs <pod> --previous
    |
    YES
    |
    v
[3] Classificar Erro
    |
    |-- Database --> Verificar credenciais, migrations, connectivity
    |-- TypeScript --> Verificar build, types, imports
    |-- Runtime --> Verificar env vars, dependencies
    |-- Network --> Verificar NetworkPolicies, Services, Ingress
    |
    v
[4] Aplicar Fix
    |
    v
[5] Rebuild & Redeploy
    npm run build
    docker build ...
    kubectl set image ...
    |
    v
[6] Monitorar
    kubectl logs -f <pod>
    kubectl get events --watch
    |
    v
Problema Resolvido?
    |-- NAO --> Voltar para [1]
    |
    YES --> Documentar Solucao
```

### Health Check Commands

```bash
# Pod status
kubectl get pods -A | grep shaka

# Health endpoint
curl http://staging.shaka.local/health

# Database connection
kubectl exec postgres-0 -n <namespace> -- \
  psql -U <user> -d <db> -c "SELECT 'DB OK';"

# Redis connection
kubectl exec redis-0 -n shaka-shared -- redis-cli PING

# API response time
time curl http://staging.shaka.local/health

# Resource usage
kubectl top pods -n <namespace>

# Logs clean (sem erros)
kubectl logs <pod> -n <namespace> --tail=100 | grep -i error
```

### Rollback Procedures

```bash
# SEMPRE fazer backup antes de deploy
kubectl get deployment <name> -n <namespace> -o yaml \
  > backups/deployment-$(date +%Y%m%d-%H%M%S).yaml

# Rollback para versao anterior
kubectl rollout undo deployment/<name> -n <namespace>

# Rollback para revisao especifica
kubectl rollout history deployment/<name> -n <namespace>
kubectl rollout undo deployment/<name> -n <namespace> --to-revision=<N>

# Verificar rollback
kubectl rollout status deployment/<name> -n <namespace>

# Se rollback falhar, restaurar backup
kubectl apply -f backups/deployment-<timestamp>.yaml
```

---

## SECAO 6: DEVELOPMENT WORKFLOW

### Branch Strategy

```
main (producao)
    |
    ├── develop (staging)
    │   |
    │   ├── feature/api-key-management
    │   ├── feature/webhooks
    │   └── feature/user-dashboard
    |
    ├── hotfix/critical-bug
    └── release/v1.1.0
```

**Fluxo:**
1. Criar branch: `git checkout -b feature/nome`
2. Desenvolver e testar localmente
3. PR para `develop` (review obrigatorio)
4. Merge para `develop` -> deploy staging
5. Teste em staging
6. PR de `develop` para `main` -> deploy production

### Testing Pyramid

```
         /\
        /  \  E2E Tests (10)
       /____\  - Full user flows
      /      \
     / Integ. \ Integration Tests (29)
    /  Tests   \ - API endpoints + DB
   /____________\
  /              \
 /   Unit Tests   \ Unit Tests (44)
/     (Fastest)    \ - Services, validators
\__________________/

Total: 143 tests | Coverage: 81.9%
```

**Comandos:**
```bash
npm test                  # Todos (143 tests)
npm run test:unit         # Unit apenas (44 tests)
npm run test:integration  # Integration (29 tests)
npm run test:e2e          # E2E (10 tests)
npm run test:coverage     # Com relatorio
npm run test:watch        # Watch mode
```

### Code Review Checklist

**Pre-PR:**
- [ ] Build limpo: `npm run build` (0 erros)
- [ ] Testes passando: `npm test` (100%)
- [ ] Coverage >= 70%: `npm run test:coverage`
- [ ] Lint clean: `npm run lint`
- [ ] Commits semanticos: `feat:`, `fix:`, `refactor:`

**Review:**
- [ ] Codigo segue Clean Architecture
- [ ] Services isolados (sem acesso direto a DB)
- [ ] Validacao de inputs (Joi schemas)
- [ ] Error handling adequado
- [ ] Logs estruturados (Winston)
- [ ] Comentarios onde necessario
- [ ] Sem secrets hardcoded
- [ ] Testes para novos metodos

### Deployment Checklist

**Pre-Deploy:**
- [ ] Branch atualizada com `develop`
- [ ] Build local funciona
- [ ] Testes passam (local + CI)
- [ ] Migrations criadas (se necessario)
- [ ] Environment vars atualizadas
- [ ] Backup do deployment atual

**Deploy:**
- [ ] Build Docker image
- [ ] Import para K3s
- [ ] Aplicar migrations (se necessario)
- [ ] Update deployment
- [ ] Monitorar rollout
- [ ] Verificar health checks

**Post-Deploy:**
- [ ] Smoke tests (endpoints criticos)
- [ ] Verificar logs (sem erros)
- [ ] Monitorar metricas (RAM, CPU)
- [ ] Testar features novas
- [ ] Comunicar equipe (Slack)

---

## SECAO 7: CODE PATTERNS

### Service Layer Template

```typescript
// src/core/services/example/ExampleService.ts

import { logger } from '@config/logger';
import { AppError } from '@core/errors/AppError';
import { ExampleRepository } from '@infrastructure/database/repositories/ExampleRepository';
import { CreateExampleDTO, Example } from './types';

export class ExampleService {
  /**
   * Descricao do metodo
   * @param param1 - Descricao do parametro
   * @returns Descricao do retorno
   * @throws AppError se validacao falhar
   */
  static async methodName(param1: string): Promise<Example> {
    try {
      logger.info('[ExampleService] Starting operation', { param1 });
      
      // 1. Validar input
      if (!param1) {
        throw new AppError('Invalid param1', 400);
      }
      
      // 2. Business logic
      const result = await this.processData(param1);
      
      // 3. Repository call
      const saved = await ExampleRepository.create(result);
      
      // 4. Return
      logger.info('[ExampleService] Operation completed', { id: saved.id });
      return saved;
      
    } catch (error: any) {
      logger.error('[ExampleService] Error in operation:', {
        error: error.message,
        param1
      });
      throw error;
    }
  }
  
  private static async processData(data: string): Promise<any> {
    // Logica privada
    return data;
  }
}
```

### Controller Template

```typescript
// src/api/controllers/example/ExampleController.ts

import { Request, Response } from 'express';
import { ExampleService } from '@core/services/example/ExampleService';
import { logger } from '@config/logger';

export class ExampleController {
  static async create(req: Request, res: Response): Promise<void> {
    try {
      const { param1 } = req.body;
      
      // Call service
      const result = await ExampleService.methodName(param1);
      
      // Return success
      res.status(201).json({
        success: true,
        data: result
      });
      
    } catch (error: any) {
      logger.error('[ExampleController] Error:', {
        error: error.message,
        body: req.body
      });
      
      // Error middleware will handle this
      res.status(error.statusCode || 500).json({
        success: false,
        error: error.message
      });
    }
  }
  
  static async list(req: Request, res: Response): Promise<void> {
    try {
      const userId = req.user!.id;
      const results = await ExampleService.listAll(userId);
      
      res.json({
        success: true,
        data: results,
        count: results.length
      });
    } catch (error: any) {
      logger.error('[ExampleController] Error listing:', error);
      res.status(500).json({
        success: false,
        error: 'Internal server error'
      });
    }
  }
}
```

### Repository Template

```typescript
// src/infrastructure/database/repositories/ExampleRepository.ts

import { AppDataSource } from '../config';
import { ExampleEntity } from '../entities/ExampleEntity';
import { Repository } from 'typeorm';
import { logger } from '@config/logger';

export class ExampleRepository {
  private static repository: Repository<ExampleEntity> = 
    AppDataSource.getRepository(ExampleEntity);
  
  static async create(data: Partial<ExampleEntity>): Promise<ExampleEntity> {
    try {
      const entity = this.repository.create(data);
      return await this.repository.save(entity);
    } catch (error: any) {
      logger.error('[ExampleRepository] Error creating:', error);
      throw error;
    }
  }
  
  static async findById(id: string): Promise<ExampleEntity | null> {
    return await this.repository.findOne({ where: { id } });
  }
  
  static async findAll(): Promise<ExampleEntity[]> {
    return await this.repository.find();
  }
  
  static async update(
    id: string, 
    data: Partial<ExampleEntity>
  ): Promise<ExampleEntity> {
    await this.repository.update(id, data);
    const updated = await this.findById(id);
    if (!updated) {
      throw new Error('Entity not found after update');
    }
    return updated;
  }
  
  static async delete(id: string): Promise<void> {
    await this.repository.delete(id);
  }
}
```

### Middleware Template

```typescript
// src/api/middlewares/exampleMiddleware.ts

import { Request, Response, NextFunction } from 'express';
import { logger } from '@config/logger';

export const exampleMiddleware = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    // 1. Extract data
    const data = req.headers['x-custom-header'];
    
    if (!data) {
      res.status(400).json({
        error: 'Missing required header'
      });
      return;
    }
    
    // 2. Validate/process
    const processed = await processData(data);
    
    // 3. Attach to request
    (req as any).customData = processed;
    
    // 4. Continue
    next();
    
  } catch (error: any) {
    logger.error('[exampleMiddleware] Error:', error);
    res.status(500).json({
      error: 'Internal server error'
    });
  }
};
```

### Validator Template

```typescript
// src/api/validators/example.validator.ts

import Joi from 'joi';

export const createExampleSchema = Joi.object({
  name: Joi.string().min(3).max(100).required(),
  email: Joi.string().email().required(),
  age: Joi.number().integer().min(18).max(120).optional(),
  tags: Joi.array().items(Joi.string()).default([])
});

export const updateExampleSchema = Joi.object({
  name: Joi.string().min(3).max(100).optional(),
  email: Joi.string().email().optional(),
  age: Joi.number().integer().min(18).max(120).optional()
}).min(1); // Pelo menos 1 campo

export const exampleIdSchema = Joi.object({
  id: Joi.string().uuid().required()
});
```

### Error Handling Pattern

```typescript
// src/core/errors/AppError.ts

export class AppError extends Error {
  constructor(
    public message: string,
    public statusCode: number = 500,
    public code?: string
  ) {
    super(message);
    this.name = 'AppError';
    Error.captureStackTrace(this, this.constructor);
  }
}

// Uso:
throw new AppError('User not found', 404, 'USER_NOT_FOUND');
throw new AppError('Invalid credentials', 401, 'INVALID_CREDENTIALS');
throw new AppError('Rate limit exceeded', 429, 'RATE_LIMIT_EXCEEDED');

// src/api/middlewares/errorHandler.ts

export const errorHandler = (
  err: any,
  req: Request,
  res: Response,
  next: NextFunction
): void => {
  logger.error('[ErrorHandler]', {
    message: err.message,
    statusCode: err.statusCode,
    code: err.code,
    stack: err.stack,
    path: req.path
  });
  
  res.status(err.statusCode || 500).json({
    success: false,
    error: err.message,
    code: err.code,
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
};
```

---

## SECAO 8: API REFERENCE

### Todos os Endpoints

| Metodo             | Endpoint                   | Auth | Descricao               |
|--------------------|----------------------------|------|-------------------------|
| **Authentication** |                            |      |                         |
| POST               | /api/v1/auth/register      |  -   | Criar conta             |
| POST               | /api/v1/auth/login         |  -   | Autenticar              |
| POST               | /api/v1/auth/refresh       |  -   | Renovar tokens          |
| **Users**          |                            |      |                         |
| GET                | /api/v1/users/profile      | JWT  | Perfil do usuario       |
| PUT                | /api/v1/users/profile      | JWT  | Atualizar perfil        |
| PUT                | /api/v1/users/password     | JWT  | Mudar senha             |
| GET                | /api/v1/users              | JWT  | Listar usuarios (admin) |
| **Subscriptions**  |                            |      |                         |
| GET                | /api/v1/plans              | JWT  | Listar planos           |
| PUT                | /api/v1/plans              | JWT  | Mudar plano             |
| DELETE             | /api/v1/plans              | JWT  | Cancelar assinatura     |
| **API Keys**       |                            |      |                         |
| POST               | /api/v1/keys               | JWT  | Criar API key           |
| GET                | /api/v1/keys               | JWT  | Listar keys             |
| GET                | /api/v1/keys/:id           | JWT  | Detalhes de key         |
| GET                | /api/v1/keys/:id/usage     | JWT  | Estatisticas            |
| POST               | /api/v1/keys/:id/rotate    | JWT  | Rotacionar key          |
| DELETE             | /api/v1/keys/:id           | JWT  | Revogar key             |
| DELETE             | /api/v1/keys/:id/permanent | JWT  | Deletar permanente      |

### Authentication Methods

**JWT Bearer Token:**
```bash
curl -X GET http://api.shaka.com/api/v1/users/profile \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIs..."
```

**API Key:**
```bash
curl -X GET http://api.shaka.com/api/v1/data \
  -H "X-API-Key: sk_live_abc123def456..."
```

### Rate Limit Headers

**Request:**
```
GET /api/v1/data
X-API-Key: sk_live_abc123...
```

**Response:**
```
200 OK
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 2025-12-07T00:00:00Z
```

**429 Too Many Requests:**
```json
{
  "error": "Rate limit exceeded",
  "message": "Limit: 1000 requests/day",
  "limit": 1000,
  "remaining": 0,
  "resetAt": "2025-12-07T00:00:00Z"
}
```

### Error Codes

| Code                | HTTP | Descricao                    |
|---------------------|------|------------------------------|
| USER_NOT_FOUND      | 404  | Usuario nao existe           |
| INVALID_CREDENTIALS | 401  | Email/senha incorretos       |
| TOKEN_EXPIRED       | 401  | Access token expirado        |
| INVALID_TOKEN       | 401  | Token malformado             |
| RATE_LIMIT_EXCEEDED | 429  | Limite de requests excedido  |
| PLAN_LIMIT_EXCEEDED | 403  | Limite do plano atingido     |
| API_KEY_INVALID     | 403  | API key invalida ou revogada |
| API_KEY_EXPIRED     | 403  | API key expirada             |
| VALIDATION_ERROR    | 400  | Dados de entrada invalidos   |

### Response Formats

**Success (200/201):**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "name": "Example",
    "createdAt": "2025-12-06T10:00:00Z"
  }
}
```

**Success (List):**
```json
{
  "success": true,
  "data": [...],
  "count": 10,
  "page": 1,
  "totalPages": 5
}
```

**Error (4xx/5xx):**
```json
{
  "success": false,
  "error": "Error message",
  "code": "ERROR_CODE",
  "details": { ... }
}
```

---

## APENDICES

### A. Glossario de Termos

| Termo                  | Definicao                                                       |
|------------------------|-----------------------------------------------------------------|
| **API Key**            | Chave de autenticacao no formato `sk_live_...`                  |
| **JWT**                | JSON Web Token, token de autenticacao stateless                 |
| **Multi-tenancy**      | Arquitetura onde multiplos usuarios compartilham infraestrutura |
| **Rate Limiting**      | Limitar numero de requests por periodo                          |
| **Soft Delete**        | Marcar registro como inativo ao inves de deletar                |
| **StatefulSet**        | Recurso K8s para aplicacoes com estado (ex: DB)                 |
| **Ingress**            | Roteamento HTTP/HTTPS externo para servicos K8s                 |
| **Clean Architecture** | Separacao de codigo em camadas independentes                    |
| **TypeORM**            | ORM (Object-Relational Mapping) para TypeScript                 |

### B. Environment Variables

```bash
# Server
NODE_ENV=development|staging|production
PORT=3000

# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=shaka_dev
DB_USER=shaka
DB_PASSWORD=<SENHA_FORTE>

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=<SENHA_FORTE>

# JWT
JWT_SECRET=<64_CHARS_MINIMO>
JWT_REFRESH_SECRET=<64_CHARS_MINIMO>
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=7d

# Rate Limiter
RATE_LIMITER_BACKEND=memory|redis
USAGE_TRACKING_ENABLED=true|false
USAGE_RETENTION_DAYS=90

# Stripe (futuro)
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...

# SMTP (futuro)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=noreply@shaka.com
SMTP_PASSWORD=<SENHA_APP>
```

### C. Database Indexes

```sql
-- Performance critical indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_plan ON users(plan);

CREATE INDEX idx_subscriptions_user_id ON subscriptions(user_id);
CREATE INDEX idx_subscriptions_stripe_customer_id ON subscriptions(stripe_customer_id);

CREATE INDEX idx_api_keys_user_id ON api_keys(user_id);
CREATE UNIQUE INDEX idx_api_keys_key_hash ON api_keys(key_hash);

-- Analytics indexes (composite)
CREATE INDEX idx_usage_api_key_timestamp ON usage_records(api_key_id, timestamp);
CREATE INDEX idx_usage_user_timestamp ON usage_records(user_id, timestamp);
CREATE INDEX idx_usage_timestamp ON usage_records(timestamp);
```

### D. Kubernetes Resources

**Current State:**
```
NAMESPACE       POD                         STATUS    RAM     CPU
shaka-staging   shaka-api-xxx               Running   150MB   50m
shaka-staging   postgres-0                  Running   512MB   200m
shaka-shared    redis-0                     Running   128MB   100m
kube-system     traefik-xxx                 Running   29MB    50m
```

**Resource Allocation:**
```
Component          CPU Request   CPU Limit   RAM Request   RAM Limit
PostgreSQL Dev     200m          400m        256Mi         512Mi
PostgreSQL Staging 500m          1000m       512Mi         1Gi
PostgreSQL Prod    200m          400m        256Mi         512Mi
Redis Shared       100m          200m        128Mi         256Mi
API Staging        250m          500m        128Mi         256Mi
```

### E. Scripts Inventory

```bash
# Docker
scripts/docker/
├── start.sh              # Iniciar containers
├── stop.sh               # Parar containers
├── logs.sh               # Ver logs
├── health.sh             # Health checks
└── docker.sh             # Gerenciador principal

# Database
scripts/database/
├── apply-migrations.sh   # Aplicar migrations
├── backup.sh             # Backup PostgreSQL
└── restore.sh            # Restore backup

# Kubernetes
scripts/kubernetes/
├── deploy.sh             # Deploy completo
├── rollback.sh           # Rollback deployment
└── health-check.sh       # Validar cluster

# Sprint 1
scripts/sprint1/
├── fix-final-7-errors.sh           # Fix PasswordService
├── fix-last-4-errors.sh            # Fix AuthService
├── complete-deploy.sh              # Deploy com migrations
└── verify-build-status.sh          # Validacao de build
```

---

## CHANGELOG

### v1.0.0 (2025-12-06) - INITIAL RELEASE

**Added:**
- Sistema completo de autenticacao JWT
- Multi-tenancy com 4 planos (Starter -> Enterprise)
- API Key Management completo (7 endpoints)
- Usage Tracking com analytics
- Rate Limiting dinamico por plano
- Kubernetes infrastructure (K3s)
- Docker containerization
- 143 testes automatizados (81.9% coverage)

**Infrastructure:**
- PostgreSQL 15 (3 instancias isoladas)
- Redis 7 (arquitetura compartilhada)
- Traefik Ingress Controller
- 5 namespaces Kubernetes
- 4 tabelas database (users, subscriptions, api_keys, usage_records)

**Documentation:**
- Knowledge Base completo (este documento)
- 10 memorandos de handoff arquivados
- 43 scripts de automacao documentados

---

## PROXIMOS PASSOS

### Fase 19: Observabilidade Completa

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

### Fase 20: TLS/HTTPS

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

### Fase 21: CI/CD Pipeline

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
    - docker build
    - docker push
    - kubectl set image
```

---

**FIM DA KNOWLEDGE BASE**

```
Documento: Shaka API Developer Knowledge Base
Versao: 1.0.0
Linhas: ~3.500
Reducao: 84% vs documentos originais (22.000 linhas)
Tempo de leitura: 1-1.5 horas
Ultima atualizacao: 2025-12-06
Status: PRODUCTION READY
```

---

*Este documento e a fonte unica de verdade para desenvolvimento, deployment e troubleshooting do Shaka API. Mantenha-o atualizado a cada mudanca significativa no sistema.*
