# 📋 MEMORANDO MESTRE 1 DE HANDOFF/ONBOARDING - SHAKA API

## 🎯 INFORMAÇÕES DO DOCUMENTO

**Para:** Equipe de Desenvolvimento / Novos Integrantes 
**De:** Headmaster CTO Integrador  
**Data:** 01 de Dezembro de 2025  
**Assunto:** Documentação Completa do Projeto Shaka API (Fases 1-9)  
**Status:** 📘 DOCUMENTO MESTRE - CONSOLIDAÇÃO COMPLETA  
**Versão:** 2.0  

---

## 📖 ÍNDICE EXECUTIVO

### Estrutura deste Memorando

1. **Visão Geral do Projeto**   - O que é o Shaka API
2. **Jornada Completa**         - Todas as 9 fases implementadas
3. **Arquitetura Final**        - Stack tecnológica completa
4. **Guia de Onboarding**       - Como começar no projeto
5. **Metodologia Comprovada**   - Padrões e práticas estabelecidas
6. **Comandos Essenciais**      - Referência rápida
7. **Troubleshooting**          - Problemas comuns e soluções
8. **Próximos Passos**          - Roadmap futuro

---

## 🚀 VISÃO GERAL DO PROJETO

### O que é o Shaka API?

**Shaka API** é uma plataforma **multi-tenant enterprise-grade** 
de gerenciamento de APIs SaaS, projetada para escalar de 0 a 1000+ usuários com:

```
┌─────────────────────────────────────────────────────┐
│  SHAKA API - CARACTERÍSTICAS PRINCIPAIS             │
├─────────────────────────────────────────────────────┤
│  ✅ Multi-tenancy com isolamento completo           │
│  ✅ 4 planos de assinatura (Starter → Enterprise)   │
│  ✅ Rate limiting dinâmico por plano                │
│  ✅ Autenticação JWT robusta                        │
│  ✅ Arquitetura cloud-native (Docker + K8s)         │
│  ✅ 143 testes automatizados (81.9% coverage)       │
│  ✅ Multi-ambiente (dev, staging, prod)             │
│  ✅ Production-ready e enterprise-grade             │
└─────────────────────────────────────────────────────┘
```

### Planos de Assinatura

| Plano          | Requests/Dia | Requests/Min | Concurrent | Features                    |
|----------------|--------------|--------------|------------|-----------------------------|
| **Starter**    | 100          | 10           | 2          | Basic API + Email Support   |
| **Pro**        | 1,000        | 50           | 10         | + Advanced API + Webhooks   |
| **Business**   | 10,000       | 200          | 50         | + Priority Support + Custom |
| **Enterprise** | Unlimited    | 1,000        | 500        | + White Label + Dedicated   |

### Público-Alvo

- **Startups** que precisam de API management desde o MVP
- **SaaS Companies** que querem monetizar APIs
- **Enterprises** que precisam de multi-tenancy robusto
- **Desenvolvedores** aprendendo arquitetura enterprise

---

## 🗺️ JORNADA COMPLETA - TODAS AS FASES

### Resumo Executivo das Fases

```
┌────────────────────────────────────────────────────────────┐
│  PROGRESSO DO PROJETO: 9/10 FASES COMPLETAS (90%)          │
├────────────────────────────────────────────────────────────┤
│  Fase 1: Estrutura Base                    ✅ 100%         │
│  Fase 2: API Base                          ✅ 100%         │
│  Fase 3: Services Layer                    ✅ 100%         │
│  Fase 4: Infrastructure Layer              ✅ 100%         │
│  Fase 5: Build Fixes                       ✅ 100%         │
│  Fase 6: Runtime & Deployment              ✅ 100%         │
│  Fase 7: Testing Layer (4 subfases)        ✅ 100%         │
│  Fase 8: Docker Containerization           ✅ 100%         │
│  Fase 9: Kubernetes Infrastructure         ✅ 92%          │
│  Fase 10: Monitoring (PRÓXIMO)             ⏳ 0%           │
├────────────────────────────────────────────────────────────┤
│  Tempo Total Investido: ~25 horas                          │
│  Scripts Criados: 43 scripts modulares                     │
│  Linhas de Código: ~8,000+                                 │
│  Testes Implementados: 143 (100% passing)                  │
└────────────────────────────────────────────────────────────┘
```

---

### FASE 1: ESTRUTURA BASE (CONCLUÍDA ✅)

**Duração:** 1 hora  
**Scripts:** 1 script de setup  
**Memorando:** #1

#### Objetivos
Estabelecer a estrutura de diretórios profissional e arquivos base do projeto.

#### O que foi Criado

```
shaka-api/
├── src/                    # Código-fonte
│   ├── api/               # Presentation Layer
│   ├── core/              # Business Logic
│   ├── domain/            # Domain Entities
│   ├── infrastructure/    # External Services
│   └── config/            # Configurações
├── tests/                 # Testes automatizados
├── scripts/               # Scripts de automação
├── docs/                  # Documentação
├── k8s/                   # Kubernetes manifests
├── docker/                # Docker configs
├── monitoring/            # Observability
├── .env.example           # Template de ambiente
├── Makefile              # Comandos make
├── package.json          # Dependencies
└── tsconfig.json         # TypeScript config
```

#### Decisões Arquiteturais

✅ **Clean Architecture** escolhida para separação clara de responsabilidades  
✅ **TypeScript** para type-safety e manutenibilidade  
✅ **Makefile** para automatização de comandos  

---

### FASE 2: API BASE (CONCLUÍDA ✅)

**Duração:** 2 horas  
**Scripts:** 1 script de setup  
**Memorando:** #1

#### Objetivos
Implementar servidor Express com rotas, middlewares e controllers base.

#### O que foi Criado

**Servidor Express:**
```typescript
src/
├── server.ts              # Entry point
├── api/
│   ├── routes/
│   │   ├── index.ts       # Router principal
│   │   ├── auth.routes.ts # Autenticação
│   │   ├── user.routes.ts # Usuários
│   │   └── plan.routes.ts # Planos
│   ├── controllers/
│   │   ├── auth/          # AuthController
│   │   ├── user/          # UserController
│   │   └── plan/          # PlanController
│   ├── middlewares/
│   │   ├── authenticate.ts    # JWT verification
│   │   ├── rateLimiter.ts     # Rate limiting
│   │   ├── errorHandler.ts    # Global error handler
│   │   └── logger.ts          # Request logging
│   └── validators/
│       └── user.validator.ts  # Joi schemas
```

#### Endpoints Implementados

| Método | Endpoint                 | Descrição           |
|--------|--------------------------|---------------------|
| GET    | `/health`                | Health check        |
| POST   | `/api/v1/auth/register`  | Registro de usuário |
| POST   | `/api/v1/auth/login`     | Login               |
| POST   | `/api/v1/auth/refresh`   | Refresh token       |
| GET    | `/api/v1/users/profile`  | Perfil do usuário   |
| PUT    | `/api/v1/users/profile`  | Atualizar perfil    |
| PUT    | `/api/v1/users/password` | Mudar senha         |
| GET    | `/api/v1/users`          | Listar usuários     |
| GET    | `/api/v1/plans`          | Listar planos       |
| PUT    | `/api/v1/plans`          | Mudar plano         |
| DELETE | `/api/v1/plans`          | Cancelar assinatura |

---

### FASE 3: SERVICES LAYER (CONCLUÍDA ✅)

**Duração:** 3h45min  
**Scripts:** 4 scripts modulares  
**Memorando:** #2

#### Objetivos
Implementar lógica de negócio em services isolados e testáveis.

#### O que foi Criado

**Services Implementados:**

```typescript
src/core/services/
├── auth/
│   ├── PasswordService.ts       # Validação e hash
│   ├── TokenService.ts          # JWT generation/validation
│   └── AuthService.ts           # Login, registro, refresh
├── user/
│   └── UserService.ts           # CRUD de usuários
├── subscription/
│   └── SubscriptionService.ts   # Gestão de planos
└── rate-limiter/
    └── RateLimiterService.ts    # Rate limiting
```

**Types Definidos:**

```typescript
src/core/types/
├── auth.types.ts              # JWTPayload, TokenType, etc
├── user.types.ts              # User, UserRole, etc
├── subscription.types.ts      # Subscription, PLAN_LIMITS
└── rate-limiter.types.ts      # RateLimitConfig, etc
```

#### Funcionalidades Principais

**PasswordService:**
- ✅ Validação de força (8+ chars, maiúscula, minúscula, número, especial)
- ✅ Hash com bcrypt (12 salt rounds)
- ✅ Comparação segura
- ✅ Geração de senhas aleatórias

**TokenService:**
- ✅ Access tokens (15min)
- ✅ Refresh tokens (7 dias)
- ✅ Verificação e decodificação
- ✅ Detecção de expiração

**AuthService:**
- ✅ Registro com validação de email único
- ✅ Login com verificação de credenciais
- ✅ Refresh de tokens
- ✅ Validação de access tokens

**SubscriptionService:**
- ✅ Criação de assinaturas
- ✅ Mudança de planos (upgrade/downgrade)
- ✅ Cancelamento
- ✅ Verificação de status ativo

**RateLimiterService:**
- ✅ Verificação de limites diários
- ✅ Incremento de uso com detecção de excesso
- ✅ Reset de contadores
- ✅ Monitoramento de uso

#### Metodologia Aplicada

✅ **Scripts modulares** (4 partes) ao invés de 1 gigante  
✅ **Validação incremental** após cada script  
✅ **Types definidos antes** dos services  
✅ **Mock database** para desenvolvimento rápido  

---

### FASE 4: INFRASTRUCTURE LAYER (CONCLUÍDA ✅)

**Duração:** 2 horas  
**Scripts:** 5 scripts modulares  
**Memorando:** #3

#### Objetivos
Implementar camada de infraestrutura com PostgreSQL, Redis e TypeORM.

#### O que foi Criado

**Database Layer:**

```typescript
src/infrastructure/database/
├── config.ts                  # TypeORM config
├── DatabaseService.ts         # Connection service
├── entities/
│   ├── UserEntity.ts          # User entity (TypeORM)
│   └── SubscriptionEntity.ts  # Subscription entity
├── repositories/
│   ├── BaseRepository.ts      # Generic CRUD
│   ├── UserRepository.ts      # User-specific queries
│   └── SubscriptionRepository.ts
└── migrations/
    ├── 1700000000001-CreateUsersTable.ts
    └── 1700000000002-CreateSubscriptionsTable.ts
```

**Cache Layer:**

```typescript
src/infrastructure/cache/
├── redis.config.ts            # Redis config
├── CacheService.ts            # Cache abstraction
└── RedisRateLimiterService.ts # Rate limiter with Redis
```

#### Tecnologias Utilizadas

| Tecnologia | Versão | Propósito             |
|------------|--------|-----------------------|
| PostgreSQL | 15     | Banco principal       |
| TypeORM    | 0.3.17 | ORM                   |
| Redis      | 7      | Cache + Rate limiting |
| ioredis    | 5.3.2  | Cliente Redis         |

#### Funcionalidades

**DatabaseService:**
- ✅ Conexão PostgreSQL com connection pooling
- ✅ Health checks automáticos
- ✅ Graceful shutdown
- ✅ Migrations automáticas

**Repositories:**
- ✅ BaseRepository com CRUD genérico
- ✅ UserRepository com queries específicas
- ✅ SubscriptionRepository com gestão de planos
- ✅ Paginação implementada

**CacheService:**
- ✅ Operações get/set/delete/exists
- ✅ TTL automático
- ✅ Health checks

**RedisRateLimiterService:**
- ✅ Rate limiting distribuído
- ✅ Contadores por usuário
- ✅ Sliding window algorithm

---

### FASE 5: BUILD FIXES (CONCLUÍDA ✅)

**Duração:** 2 horas  
**Scripts:** 17 scripts de correção  
**Memorando:** #4

#### Objetivos
Resolver 63 erros TypeScript e garantir build limpo.

#### Jornada de Correções

| Script  | Objetivo               | Erros Antes | Erros Depois | Impacto      |
|---------|------------------------|-------------|--------------|--------------|
| Inicial | -                      | 63          | 63           | -            |
| 1       | Dependências de tipos  | 63          | 59           | -4           |
| 2A      | Config env.ts          | 59          | 58           | -1           |
| 2B      | Config logger.ts       | 58          | 43           | **-15 ⭐**   |
| 3       | tsconfig.json          | 43          | 12           | **-31 ⭐⭐** |
| 4-6     | Imports e estrutura    | 12          | 12           | 0            |
| 7-9     | Controllers e services | 12          | 12           | 0            |
| 10-12   | Métodos e tipos        | 12          | 15           | +3*          |
| 13-15   | Arquivos faltantes     | 15          | 1            | **-14 ⭐**   |
| 16-17   | Correções finais       | 2           | **0**        | **-2 ✅**    |

**Resultado:** 63 → 0 erros (100% sucesso)

#### Problemas Principais Resolvidos

1. **Dependências de Tipos Faltantes**
   ```bash
   npm install --save-dev @types/jsonwebtoken @types/cors @types/bcrypt
   ```

2. **Path Resolution (Build vs Runtime)**
   ```javascript
   // tsconfig.json
   "baseUrl": "./src",
   "paths": {
     "@config/*": ["./config/*"],
     "@core/*": ["./core/*"],
     "@infrastructure/*": ["./infrastructure/*"]
   }
   ```

3. **Static vs Instance Methods**
   ```typescript
   // ANTES: authService.login() ❌
   // DEPOIS: AuthService.login() ✅
   ```

4. **TypeORM Generics Constraints**
   ```typescript
   // ANTES: BaseRepository<T> ❌
   // DEPOIS: BaseRepository<T extends ObjectLiteral> ✅
   ```

---

### FASE 6: RUNTIME & DEPLOYMENT (CONCLUÍDA ✅)

**Duração:** 40 minutos  
**Scripts:** 8 scripts de correção  
**Memorando:** #4

#### Objetivos
Garantir que o sistema rode em runtime e performance seja excelente.

#### O que foi Corrigido

**Runtime Dependencies:**
```bash
npm install bcrypt jsonwebtoken express cors winston joi
npm install --save-dev ts-node tsconfig-paths
```

**Performance Validada:**

```
┌───────────────────────────────────────────────┐
│  MÉTRICAS DE PERFORMANCE                      │
├───────────────────────────────────────────────┤
│  Latência média:     9.3ms   ⭐⭐⭐⭐⭐      │
│  Throughput:         245+ req/s ⭐⭐⭐⭐     │
│  Disponibilidade:    100%    ⭐⭐⭐⭐⭐      │
│  Concorrência:       50 simultâneas ⭐⭐⭐⭐ │
└──────────────────────────────────────────────┘
```

#### Sistema de Gerenciamento

**Script:** `manage-server.sh`

```bash
./manage-server.sh start    # Iniciar em background
./manage-server.sh status   # Ver status
./manage-server.sh stop     # Parar
./manage-server.sh restart  # Reiniciar
./manage-server.sh logs     # Ver logs
./manage-server.sh test     # Testar endpoints
```

---

### FASE 7: TESTING LAYER (CONCLUÍDA ✅)

**Duração:** 9 horas (4 subfases)  
**Scripts:** 11 scripts de setup + 6 de correção  
**Memorandos:** #5, #5.2, #5.3, #5.4

#### Subfase 7A: Unit Tests (3h45min)

**Testes Criados:** 44 testes unitários

```typescript
tests/unit/
├── services/
│   ├── password.service.test.ts    # 7 testes
│   └── token.service.test.ts       # 11 testes
└── validators/
    └── user.validator.test.ts      # 18 testes
```

**Cobertura:** ~90% dos services testados

#### Subfase 7B: Integration Tests (4h23min)

**Testes Criados:** 29 testes de integração

```typescript
tests/integration/api/
├── health.test.ts       # 4 testes
├── auth.test.ts         # 9 testes
├── users.test.ts        # 10 testes
└── plans.test.ts        # 6 testes
```

**Validação:** Todos endpoints REST funcionando

#### Subfase 7C: E2E Tests (40min)

**Testes Criados:** 10 testes end-to-end

```typescript
tests/e2e/
├── auth-flow.test.ts         # 4 testes
├── user-flow.test.ts         # 3 testes
└── subscription-flow.test.ts # 3 testes
```

**Fluxos Validados:**
- ✅ Registro → Login → Acesso protegido
- ✅ CRUD completo de usuário
- ✅ Mudança de plano → Cancelamento

#### Subfase 7D: Coverage Improvement (30min)

**Scripts Criados:** 3 scripts de melhoria

**Coverage Resultado:**

| Métrica    | Antes  | Depois | Melhoria |
|------------|--------|--------|----------|
| Statements | 58.37% | 81.90% | +23.53%  |
| Branches   | 46.37% | 76.81% | +30.44%  |
| Functions  | 60.71% | 85.71% | +25.00%  |
| Lines      | 58.46% | 82.59% | +24.13%  |

**Status Final:**
```
✅ 143 testes passando (100%)
✅ 81.9% coverage (threshold: 70%)
✅ 4/4 métricas acima de 70%
✅ Production-ready
```

#### Tecnologias de Teste

| Ferramenta  | Versão  | Propósito              |
|-------------|---------|------------------------|
| Jest        | 29.7.0  | Test runner            |
| ts-jest     | 29.1.1  | TypeScript transformer |
| Supertest   | 6.3.3   | HTTP assertions        |
| @types/jest | 29.5.11 | Tipos TypeScript       |

#### Metodologia Comprovada

✅ **Scripts modulares** (11 setup + 6 fix)  
✅ **Validação incremental** (0 → 44 → 73 → 83 → 143)  
✅ **Test-Driven Debugging** (criar testes → corrigir código)  
✅ **AAA Pattern** (Arrange-Act-Assert)  
✅ **Coverage como ferramenta de diagnóstico**  

---

### FASE 8: DOCKER CONTAINERIZATION (CONCLUÍDA ✅)

**Duração:** 20 minutos  
**Scripts:** 3 scripts de setup  
**Memorando:** #6

#### Objetivos
Containerizar aplicação para portabilidade total.

#### O que foi Criado

**Dockerfile Multi-stage:**

```dockerfile
# Stage 1: Builder
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build
RUN npm prune --production

# Stage 2: Runtime
FROM node:20-alpine
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
USER nodejs:nodejs
HEALTHCHECK CMD node -e "require('http').get('http://localhost:3000/health')"
CMD ["node", "dist/server.js"]
```

**Benefícios:**
- 🎯 Imagem 60% menor (~300MB vs ~800MB)
- 🔒 Mais segura (sem devDependencies)
- ⚡ Startup mais rápido
- 📦 Cache de layers otimizado

**Docker Compose (Dev):**

```yaml
services:
  api:
    build: ./docker/api
    ports: ["3000:3000"]
    volumes: ["./src:/app/src"]  # Hot reload
    depends_on: [postgres, redis]
    
  postgres:
    image: postgres:15-alpine
    volumes: ["postgres_data:/var/lib/postgresql/data"]
    
  redis:
    image: redis:7-alpine
    volumes: ["redis_data:/data"]
```

**Docker Compose (Prod):**

```yaml
services:
  api:
    image: registry/shaka-api:latest
    restart: always
    deploy:
      resources:
        limits: {cpus: '1', memory: 512M}
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"
```

#### Scripts de Gestão

```bash
scripts/docker/
├── start.sh              # Iniciar containers
├── stop.sh               # Parar containers
├── logs.sh               # Ver logs
├── reset.sh              # Reset completo
├── health.sh             # Health checks
├── migrate.sh            # Migrations
├── test-docker.sh        # Suite de testes (17 testes)
└── docker.sh             # Gerenciador principal
```

**Comando Principal:**
```bash
./docker.sh start         # Dev mode
./docker.sh start prod    # Production mode
./docker.sh health        # Validar saúde
./docker.sh test          # Rodar suite completa
```

#### Testes Automatizados

**Suite de Testes (test-docker.sh):**

1. ✅ Validação de Arquivos (5 testes)
2. ✅ Build da Imagem       (1 teste)
3. ✅ Inicialização         (1 teste)
4. ✅ Health Checks         (3 testes)
5. ✅ Conectividade         (2 testes)
6. ✅ Endpoints API         (2 testes)
7. ✅ Volumes               (2 testes)
8. ✅ Networks              (1 teste)

**Total:** 17 testes (100% passing)

#### Documentação Criada

- **DOCKER_QUICKSTART.md** - Guia rápido (4 passos)
- **docs/DOCKER_ARCHITECTURE.md** - Arquitetura técnica
- **README.md** - Atualizado com Docker setup

---

### FASE 9: KUBERNETES INFRASTRUCTURE (92% COMPLETA ✅)

**Duração:** 4 horas  
**Scripts:** 5 manifests YAML  
**Memorando:** #10

#### Objetivos
Implementar infraestrutura Kubernetes enterprise-grade.

#### Cluster Implementado

**Tecnologia:** K3s v1.33.6  
**Servidor:** microsaas-server (2 CPU, 2GB RAM)

```
Cluster Architecture:
├── Control Plane (K3s)
├── Node: microsaas-server
│   ├── CPU: 2 cores
│   ├── RAM: ~2GB
│   └── Storage: Local path provisioner
└── Network: Cluster interno
```

#### Namespaces Criados

```yaml
Estrutura de Isolamento:
├── shaka-dev          # Ambiente de desenvolvimento
├── shaka-staging      # Ambiente de homologação
├── shaka-prod         # Ambiente de produção
├── shaka-monitoring   # Observability (futuro)
└── shaka-shared       # Serviços compartilhados
```

**Resource Quotas:**

| Namespace | CPU | RAM  | Pods |
|-----------|-----|------|------|
| dev       | 1   | 2GB  | 10   |
| staging   | 8   | 16GB | 50   |
| prod      | 32  | 64GB | 200  |
| shared    | 2   | 2GB  | 20   |

#### PostgreSQL Multi-Ambiente

**Implementação:** StatefulSets com persistent storage

```
PostgreSQL 15 Alpine:
├── Dev:     1 replica, 5GB,  256MB RAM, backup manual
├── Staging: 1 replica, 10GB, 512MB RAM, backup manual
└── Prod:    1 replica, 20GB, 256MB RAM, backup diário (2 AM)
```

**Status:** ✅ **3/3 ambientes operacionais e validados**

**Conexões Testadas:**
```bash
# Dev
kubectl exec -n shaka-dev postgres-0 -- psql -U shaka_dev -c "SELECT 'DEV OK';"
# Staging
kubectl exec -n shaka-staging postgres-0 -- psql -U shaka_staging -c "SELECT 'STAGING OK';"
# Production
kubectl exec -n shaka-prod postgres-0 -- psql -U shaka_production -c "SELECT 'PROD OK';"
```

#### Redis Shared Architecture

**Decisão Arquitetural:** Redis único com isolamento por database

```
Redis 7 Alpine Shared:
├── Namespace: shaka-shared
├── Storage: 5GB persistent
├── RAM: 128MB request / 256MB limit
├── CPU: 100m request / 200m limit
└── Databases:
   ├── DB 0: Development (prefix: dev:)
   ├── DB 1: Staging (prefix: staging:)
   └── DB 2: Production (prefix: prod:)
```

**Benefícios:**
- ✅ Economia de 200-300MB RAM (1 pod vs 3 pods)
- ✅ Isolamento garantido por database Redis nativo
- ✅ ExternalName Services facilitam migração cloud
- ✅ Padrão enterprise antes de escala horizontal

**ExternalName Services (Multi-Cloud Ready):**
```yaml
shaka-dev/redis-dev       → redis.shaka-shared.svc.cluster.local
shaka-staging/redis-staging → redis.shaka-shared.svc.cluster.local
shaka-prod/redis-prod     → redis.shaka-shared.svc.cluster.local
```

**Status:** ✅ **Validado com isolamento confirmado**

#### Segurança Implementada

**Network Policies:**
- Dev: Permissivo (facilita debugging)
- Staging: Restritivo (deny by default + allowlist)
- Prod: Zero-trust (deny all + explicit allows)

**Secrets Management:**
```yaml
Secrets por Ambiente:
├── Database (user, password, host, port)
├── Redis (password, host, port, database)
├── JWT (secret, refresh_secret)
├── Stripe (secret_key, webhook_secret)
└── SMTP (host, port, user, password)
```

⚠️ **CRÍTICO:** Secrets contêm placeholders. 
**DEVEM ser atualizados antes de produção.**

#### Manifests Kubernetes

```
infrastructure/kubernetes/
├── 01-namespace.yaml              # Namespaces + Quotas + Policies
├── 01-namespace-fixed.yaml        # LimitRanges otimizados
├── 02-configmaps-secrets.yaml     # Configs + Secrets
├── 03-postgres-prod-fixed.yaml    # PostgreSQL (3 ambientes)
└── 04-redis-simple-scalable.yaml  # Redis Shared (ATIVO)
```

#### Recursos Alocados

```
Component          CPU Request   CPU Limit   RAM Request   RAM Limit
──────────────────────────────────────────────────────────────────────
PostgreSQL Dev     200m          400m        256Mi         512Mi
PostgreSQL Staging 500m          1000m       512Mi         1Gi
PostgreSQL Prod    200m          400m        256Mi         512Mi
Redis Shared       100m          200m        128Mi         256Mi
──────────────────────────────────────────────────────────────────────
TOTAL              1000m         2000m       1152Mi        2.25Gi
```

#### Status Atual

```
┌─────────────────────────────────────────┐
│  KUBERNETES STATUS                      │
├─────────────────────────────────────────┤
│  Namespaces:     5/5 ✅                 │
│  PostgreSQL:     3/3 pods running ✅    │
│  Redis:          1/1 pod running ✅     │
│  Storage:        60Gi provisioned ✅    │
│  Health Checks:  All passing ✅         │
│  API Deploy:     Pending (next) ⏳      │
│  Ingress:        Pending (next) ⏳      │
└─────────────────────────────────────────┘
```

#### Próximos Passos da Fase 9

- [ ] API Deployment (3 ambientes)
- [ ] Ingress Controller + TLS
- [ ] Cert-Manager (Let's Encrypt)
- [ ] HPA (Horizontal Pod Autoscaler)

---

## 🏗️ ARQUITETURA FINAL DO SISTEMA

### Stack Tecnológica Completa

```
┌─────────────────────────────────────────────────────────────┐
│               SHAKA API - FULL STACK                        │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│  Frontend (Client)                                          │
│    ↓ HTTPS/TLS                                              │
│  Ingress Controller (Traefik/NGINX) + Cert-Manager          │
│    ↓ Internal                                               │
│  Kubernetes Services                                        │
│    ├─ shaka-api (Node.js 20 + TypeScript)                   │
│    │   ├─ Express 4.x                                       │
│    │   ├─ JWT Authentication                                │
│    │   ├─ Rate Limiting                                     │
│    │   └─ Logging (Winston)                                 │
│    ├─ PostgreSQL 15 (TypeORM)                               │
│    │   ├─ User data                                         │
│    │   ├─ Subscriptions                                     │
│    │   └─ Usage tracking                                    │
│    └─ Redis 7                                               │
│        ├─ Cache                                             │
│        ├─ Rate limiting counters                            │
│        └─ Session storage                                   │
│                                                             │
│  Infrastructure:                                            │
│    ├─ Docker (containerization)                             │
│    ├─ Kubernetes (orchestration)                            │
│    ├─ K3s (lightweight K8s)                                 │
│    └─ Local Path Provisioner (storage)                      │
│                                                             │
│  Testing:                                                   │
│    ├─ Jest (test runner)                                    │
│    ├─ Supertest (HTTP assertions)                           │
│    └─ 143 tests (81.9% coverage)                            │
│                                                             │
│  Monitoring (Futuro):                                       │
│    ├─ Prometheus (metrics)                                  │
│    ├─ Grafana (dashboards)                                  │
│    └─ Loki (logs)                                           │
└─────────────────────────────────────────────────────────────┘
```

### Camadas de Arquitetura (Clean Architecture)

```
┌──────────────────────────────────────────────────────┐
│  PRESENTATION LAYER                                  │
│  ├─ Controllers (AuthController, UserController)     │
│  ├─ Routes (Express routers)                         │
│  ├─ Middlewares (auth, rate limit, error)            │
│  └─ Validators (Joi schemas)                         │
├──────────────────────────────────────────────────────┤
│  APPLICATION LAYER                                   │
│  ├─ Services (AuthService, UserService)              │
│  ├─ Use Cases (business logic)                       │
│  └─ DTOs (Data Transfer Objects)                     │
├──────────────────────────────────────────────────────┤
│  DOMAIN LAYER                                        │
│  ├─ Entities (User, Subscription)                    │
│  ├─ Value Objects (Email, Password)                  │
│  └─ Domain Rules (PLAN_LIMITS, rate rules)           │
├──────────────────────────────────────────────────────┤
│  INFRASTRUCTURE LAYER                                │
│  ├─ Database (TypeORM, Repositories)                 │
│  ├─ Cache (Redis, CacheService)                      │
│  ├─ External Services (Stripe, SMTP)                 │
│  └─ Config (env, logger, constants)                  │
└──────────────────────────────────────────────────────┘
```

### Fluxo de Requisição Completo

```
1. Client Request
   ↓
2. Ingress Controller (HTTPS)
   ↓
3. Kubernetes Service (Load Balancer)
   ↓
4. API Pod
   ├→ Logger Middleware (registro)
   ├→ CORS Middleware (headers)
   ├→ Rate Limiter Middleware (Redis)
   │   ├→ Check counter
   │   └→ Increment/block
   ├→ Auth Middleware (JWT)
   │   ├→ Verify token
   │   └→ Decode payload
   ├→ Validator (Joi)
   │   └→ Validate input
   ├→ Controller
   │   └→ Call Service
   ├→ Service
   │   ├→ Business logic
   │   ├→ Call Repository (DB)
   │   └→ Call Cache (Redis)
   ├→ Repository
   │   └→ TypeORM query
   ├→ PostgreSQL
   │   └→ Data persistence
   └→ Response
       ├→ Error Handler (if error)
       └→ JSON Response
```

---

## 📚 GUIA DE ONBOARDING

### Pré-requisitos

**Software Necessário:**
```bash
# Essenciais
Node.js 20+
npm 10+
Docker 24+
kubectl 1.28+
Git 2.40+

# Opcionais (mas recomendados)
k9s (Kubernetes UI)
Postman/Insomnia (API testing)
VSCode (com extensões TS/Docker/K8s)
```

**Hardware Recomendado:**
```
CPU: 4+ cores
RAM: 8GB+ (16GB ideal)
Disk: 20GB+ free space
```

### Setup Inicial (30 minutos)

#### 1. Clonar Repositório

```bash
git clone <repository-url> shaka-api
cd shaka-api
```

#### 2. Instalar Dependências

```bash
npm install
```

#### 3. Configurar Ambiente

```bash
# Copiar template
cp .env.example .env

# Editar variáveis
nano .env
```

**Variáveis Críticas:**
```env
NODE_ENV=development
PORT=3000

# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=shaka_api
DB_USER=shaka
DB_PASSWORD=<SENHA_FORTE>

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=<SENHA_FORTE>

# JWT (NUNCA use padrão em prod)
JWT_SECRET=<64_CHARS_MINIMO>
JWT_REFRESH_SECRET=<64_CHARS_MINIMO>
```

#### 4. Iniciar com Docker

```bash
# Modo desenvolvimento (hot reload)
./docker.sh start

# Aguardar healthy (30-60s)
./docker.sh health

# Ver logs
./docker.sh logs api
```

#### 5. Executar Migrations

```bash
# Rodar migrations
./docker.sh migrate run

# Verificar
docker-compose exec api npm run migration:show
```

#### 6. Testar API

```bash
# Health check
curl http://localhost:3000/health

# Registro de usuário
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "password": "Test@123",
    "plan": "starter"
  }'

# Login
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Test@123"
  }'
```

#### 7. Executar Testes

```bash
# Todos os testes
npm test

# Com coverage
npm run test:coverage

# Apenas unit
npm run test:unit

# Watch mode
npm run test:watch
```

### Estrutura de Pastas (Navegação)

```
shaka-api/
├── src/                    # 👈 COMEÇAR AQUI (código-fonte)
│   ├── api/               # Controllers, routes, middlewares
│   ├── core/              # Services (lógica de negócio)
│   ├── infrastructure/    # Database, cache, external services
│   └── config/            # Configurações (env, logger)
│
├── tests/                 # 🧪 Testes (unit, integration, e2e)
│   ├── unit/
│   ├── integration/
│   └── e2e/
│
├── scripts/               # 🔧 Scripts de automação
│   ├── docker/
│   └── kubernetes/
│
├── infrastructure/        # ☸️ Kubernetes manifests
│   └── kubernetes/
│
├── docs/                  # 📚 Documentação
│   └── memorandos/       # Memorandos de handoff
│
└── docker/                # 🐳 Docker configs
```

### Comandos Diários

```bash
# Desenvolvimento
npm run dev              # Modo desenvolvimento (hot reload)
npm run build            # Build TypeScript
npm run lint             # Lint código
npm test                 # Rodar testes

# Docker
./docker.sh start        # Iniciar ambiente
./docker.sh stop         # Parar ambiente
./docker.sh logs api     # Ver logs da API
./docker.sh shell api    # Shell no container

# Database
./docker.sh migrate run  # Rodar migrations
npm run db:seed          # Seed database (futuro)

# Kubernetes (quando usar)
kubectl get pods -n shaka-dev
kubectl logs -f <pod-name> -n shaka-dev
kubectl exec -it <pod-name> -n shaka-dev -- /bin/sh
```

---

## 🎓 METODOLOGIA COMPROVADA

### Princípios Fundamentais

#### 1. Scripts Modulares > Script Monolítico

**Descoberta:**
- ✅ Scripts pequenos (50-100 linhas) funcionam melhor
- ✅ Validação incremental detecta problemas cedo
- ✅ Facilita debugging e rollback
- ✅ Permite paralelização e reuso

**Exemplo:**
```bash
# ❌ Ruim: 1 script gigante (1000 linhas)
./setup-everything.sh  # Falha na linha 800, perde tudo

# ✅ Bom: 10 scripts modulares (100 linhas cada)
./setup-part-1.sh  # ✅ OK
./setup-part-2.sh  # ✅ OK
./setup-part-3.sh  # ❌ Falhou - só refazer este
```

#### 2. Validação Incremental Sempre

**Pattern:**
```bash
# Após cada mudança
npm run build 2>&1 | grep -c "error TS"  # Contar erros
npm test                                  # Rodar testes
./docker.sh health                        # Validar saúde
```

**Benefícios:**
- ✅ Detecta regressões imediatamente
- ✅ Mantém progresso visível
- ✅ Evita "quebrar tudo de uma vez"

#### 3. Método Nano para Arquivos Grandes

**Problema:**
```bash
# Terminal trunca código longo ao colar
cat > arquivo.ts << 'EOF'
[1000 linhas aqui]
EOF
# Resultado: Arquivo incompleto ❌
```

**Solução:**
```bash
# Usar nano para arquivos > 100 linhas
nano arquivo.ts
# Colar código completo
# Ctrl+O, Enter, Ctrl+X
```

#### 4. Test-Driven Debugging

**Fluxo:**
```
1. Criar testes primeiro (define comportamento esperado)
2. Executar testes (falham)
3. Implementar código
4. Executar testes (passam)
5. Refatorar (testes garantem não quebrou)
```

**Exemplo:**
```typescript
// 1. Criar teste
it('should validate strong password', () => {
  const result = PasswordService.validatePasswordStrength('Test@123');
  expect(result.isValid).toBe(true);
});

// 2. Implementar serviço para passar
class PasswordService {
  static validatePasswordStrength(password: string) {
    // Implementação aqui
  }
}

// 3. Refatorar com confiança (testes protegem)
```

#### 5. Logs São Aliados, Não Inimigos

**Anti-pattern:**
```typescript
try {
  // código
} catch (error) {
  console.log('Error');  // ❌ Inútil
}
```

**Pattern correto:**
```typescript
try {
  // código
} catch (error) {
  logger.error('[MODULE] Error doing X:', {
    error: error.message,
    stack: error.stack,
    context: { userId, operation }
  });
}
```

### Padrões de Código Estabelecidos

#### Estrutura de Service

```typescript
// src/core/services/example/ExampleService.ts

import { logger } from '@config/logger';
import { AppError } from '@core/errors/AppError';

export class ExampleService {
  /**
   * Description of what this method does
   * @param param1 - Description
   * @returns Description of return
   * @throws AppError if validation fails
   */
  static async methodName(param1: string): Promise<ReturnType> {
    try {
      logger.info('[ExampleService] Starting operation', { param1 });
      
      // 1. Validate input
      if (!param1) {
        throw new AppError('Invalid param1', 400);
      }
      
      // 2. Business logic
      const result = await this.doSomething(param1);
      
      // 3. Return
      logger.info('[ExampleService] Operation completed', { result });
      return result;
      
    } catch (error) {
      logger.error('[ExampleService] Error in operation:', {
        error: error.message,
        param1
      });
      throw error;
    }
  }
  
  private static async doSomething(param: string): Promise<any> {
    // Implementation
  }
}
```

#### Estrutura de Controller

```typescript
// src/api/controllers/example/ExampleController.ts

import { Request, Response } from 'express';
import { ExampleService } from '@core/services/example/ExampleService';
import { logger } from '@config/logger';

export class ExampleController {
  static async handleRequest(req: Request, res: Response): Promise<void> {
    try {
      const { param1 } = req.body;
      
      // Call service
      const result = await ExampleService.methodName(param1);
      
      // Return success
      res.status(200).json({
        success: true,
        data: result
      });
      
    } catch (error) {
      logger.error('[ExampleController] Error handling request:', {
        error: error.message,
        body: req.body
      });
      
      // Error middleware will handle this
      throw error;
    }
  }
}
```

#### Estrutura de Teste

```typescript
// tests/unit/services/example.service.test.ts

import { ExampleService } from '@core/services/example/ExampleService';

describe('ExampleService', () => {
  describe('methodName', () => {
    it('should process valid input successfully', async () => {
      // Arrange
      const input = 'valid-input';
      
      // Act
      const result = await ExampleService.methodName(input);
      
      // Assert
      expect(result).toBeDefined();
      expect(result.status).toBe('success');
    });
    
    it('should throw error for invalid input', async () => {
      // Arrange
      const input = '';
      
      // Act & Assert
      await expect(
        ExampleService.methodName(input)
      ).rejects.toThrow('Invalid param1');
    });
  });
});
```

### Anti-Patterns Evitados

❌ **Não fazer:**
```typescript
// God classes (classes com muitas responsabilidades)
class UserService {
  login() {}
  register() {}
  sendEmail() {}  // Deveria ser EmailService
  processPayment() {}  // Deveria ser PaymentService
  generateReport() {}  // Deveria ser ReportService
}

// Código sem tipos
function process(data) {  // ❌ any implícito
  return data.map(x => x.value);
}

// Error handling genérico
try {
  // código
} catch (error) {
  console.log(error);  // ❌ Não útil
}

// Secrets hardcoded
const JWT_SECRET = 'my-secret-key';  // ❌ NUNCA

// Comentários óbvios
// Incrementa contador
counter++;  // ❌ Desnecessário
```

✅ **Fazer:**
```typescript
// Single Responsibility Principle
class UserService {
  register() {}
  login() {}
}
class EmailService {
  send() {}
}

// Tipos explícitos
function process(data: Data[]): ProcessedData[] {
  return data.map(x => ({ value: x.value }));
}

// Error handling específico
try {
  // código
} catch (error) {
  if (error instanceof ValidationError) {
    // handle validation
  } else if (error instanceof DatabaseError) {
    // handle database
  }
  logger.error('Context:', error);
}

// Environment variables
const JWT_SECRET = process.env.JWT_SECRET!;

// Comentários úteis
// Uses Sliding Window algorithm to prevent abuse
// See: https://redis.io/docs/manual/patterns/rate-limiting/
```

---

## 🔧 COMANDOS ESSENCIAIS

### Comandos Make (Atalhos)

```bash
# Ver todos comandos
make help

# Desenvolvimento
make dev              # Iniciar modo dev
make build            # Build TypeScript
make test             # Rodar todos testes
make coverage         # Coverage report
make lint             # Lint código

# Docker
make start            # Iniciar containers
make stop             # Parar containers
make restart          # Reiniciar
make logs             # Ver logs
make health           # Health checks
make shell            # Shell no container API

# Database
make migrate-run      # Rodar migrations
make migrate-revert   # Reverter migration
make db-seed          # Seed database

# Kubernetes
make k8s-apply        # Apply all manifests
make k8s-status       # Ver status
make k8s-logs         # Ver logs
make k8s-shell        # Shell em pod

# Limpeza
make clean            # Limpar build
make reset            # Reset completo (CUIDADO!)
```

### Comandos NPM

```bash
# Desenvolvimento
npm run dev               # Hot reload
npm run build             # Build production
npm run start             # Start production

# Testes
npm test                  # Todos testes
npm run test:unit         # Apenas unit
npm run test:integration  # Apenas integration
npm run test:e2e          # Apenas E2E
npm run test:watch        # Watch mode
npm run test:coverage     # Com coverage

# Database
npm run migration:run      # Rodar migrations
npm run migration:revert   # Reverter
npm run migration:generate # Gerar nova

# Qualidade
npm run lint               # ESLint
npm run format             # Prettier
npm run type-check         # TypeScript check
```

### Comandos Docker

```bash
# Básico
docker-compose up -d              # Iniciar
docker-compose down               # Parar
docker-compose logs -f api        # Logs
docker-compose ps                 # Status
docker-compose exec api sh        # Shell

# Build
docker-compose build              # Build todas imagens
docker-compose build api          # Build apenas API
docker-compose build --no-cache   # Force rebuild

# Limpeza
docker-compose down -v            # Parar + remover volumes
docker system prune -a            # Limpar tudo (CUIDADO!)
```

### Comandos Kubernetes

```bash
# Básico
kubectl get pods -n shaka-dev     # Listar pods
kubectl get all -n shaka-dev      # Listar tudo
kubectl describe pod <name> -n shaka-dev  # Detalhes

# Logs
kubectl logs -f <pod> -n shaka-dev        # Follow logs
kubectl logs --tail=50 <pod> -n shaka-dev # Últimas 50 linhas

# Execução
kubectl exec -it <pod> -n shaka-dev -- sh # Shell interativo
kubectl exec <pod> -n shaka-dev -- ls     # Comando único

# Database (PostgreSQL)
kubectl exec -it postgres-0 -n shaka-dev -- \
  psql -U shaka_dev -d shaka_dev

# Redis
kubectl exec -it redis-0 -n shaka-shared -- \
  redis-cli -a <password>

# Aplicar manifests
kubectl apply -f infrastructure/kubernetes/01-namespace.yaml
kubectl apply -f infrastructure/kubernetes/  # Todos

# Deletar recursos
kubectl delete pod <name> -n shaka-dev    # Delete pod
kubectl delete -f manifest.yaml           # Delete por arquivo

# Port forwarding (acesso local)
kubectl port-forward svc/postgres -n shaka-dev 5432:5432
kubectl port-forward svc/redis -n shaka-shared 6379:6379
```

### Comandos Git (Workflow)

```bash
# Início do dia
git pull origin main              # Atualizar
git checkout -b feature/nova-funcionalidade

# Durante desenvolvimento
git status                        # Ver mudanças
git add .                         # Stage tudo
git commit -m "feat: nova funcionalidade"

# Antes de push
npm test                          # Garantir testes passam
npm run build                     # Garantir build limpo
npm run lint                      # Garantir sem erros lint

# Push
git push origin feature/nova-funcionalidade

# Após merge
git checkout main
git pull origin main
git branch -d feature/nova-funcionalidade
```

---

## 🔥 TROUBLESHOOTING - PROBLEMAS COMUNS

### Problema 1: Build TypeScript Falha

**Sintomas:**
```bash
npm run build
# Error: Cannot find module '@config/env'
```

**Diagnóstico:**
```bash
# Verificar tsconfig.json
cat tsconfig.json | grep -A 5 "paths"

# Verificar estrutura
ls -la src/config/
```

**Soluções:**

**Causa A: Paths incorretos**
```json
// tsconfig.json
{
  "compilerOptions": {
    "baseUrl": "./src",
    "paths": {
      "@config/*": ["./config/*"],  // ✅ Correto
      "@core/*": ["./core/*"]
    }
  }
}
```

**Causa B: Arquivo faltando**
```bash
# Verificar se arquivo existe
ls src/config/env.ts
# Se não existe, criar
```

**Causa C: Dependências desatualizadas**
```bash
rm -rf node_modules package-lock.json
npm install
```

---

### Problema 2: Testes Falhando

**Sintomas:**
```bash
npm test
# FAIL tests/unit/services/auth.service.test.ts
# Cannot find module '@core/services/auth/AuthService'
```

**Diagnóstico:**
```bash
# Verificar jest.config.js
cat jest.config.js | grep -A 10 "moduleNameMapper"

# Verificar estrutura
ls tests/unit/services/
```

**Soluções:**

**Causa A: moduleNameMapper incorreto**
```javascript
// jest.config.js
moduleNameMapper: {
  '^@config/(.*)$': '<rootDir>/src/config/$1',
  '^@core/(.*)$': '<rootDir>/src/core/$1',
  '^@infrastructure/(.*)$': '<rootDir>/src/infrastructure/$1'
}
```

**Causa B: Import incorreto no teste**
```typescript
// ❌ Errado
import { AuthService } from '../../../../src/core/services/auth/AuthService';

// ✅ Correto
import { AuthService } from '@core/services/auth/AuthService';
```

**Causa C: Setup do Jest**
```bash
# Verificar se ts-jest instalado
npm list ts-jest
# Se não, instalar
npm install --save-dev ts-jest @types/jest
```

---

### Problema 3: Docker Containers Não Sobem

**Sintomas:**
```bash
docker-compose up -d
# postgres exited with code 1
```

**Diagnóstico:**
```bash
# Ver logs detalhados
docker-compose logs postgres
# Ver eventos
docker-compose events
```

**Soluções:**

**Causa A: Porta em uso**
```bash
# Verificar porta
sudo lsof -i :5432
# Matar processo
sudo lsof -ti:5432 | xargs kill -9
# Ou mudar porta no docker-compose.yml
```

**Causa B: Volume corrompido**
```bash
# Remover volumes
docker-compose down -v
# Recriar
docker-compose up -d
```

**Causa C: Memória insuficiente**
```bash
# Verificar recursos
docker stats
# Ajustar limits no docker-compose.yml
services:
  postgres:
    deploy:
      resources:
        limits:
          memory: 512M  # Reduzir se necessário
```

**Causa D: Credenciais incorretas**
```bash
# Verificar .env
cat .env | grep DB_PASSWORD
# Garantir match com docker-compose.yml
```

---

### Problema 4: Kubernetes Pods em Pending

**Sintomas:**
```bash
kubectl get pods -n shaka-dev
# NAME         STATUS    AGE
# postgres-0   Pending   5m
```

**Diagnóstico:**
```bash
# Ver por que está pending
kubectl describe pod postgres-0 -n shaka-dev
# Ver eventos
kubectl get events -n shaka-dev --sort-by='.lastTimestamp'
```

**Soluções:**

**Causa A: Recursos insuficientes**
```bash
# Ver recursos do node
kubectl describe node | grep -A 8 "Allocated resources"

# Reduzir requests do pod
# Edit: infrastructure/kubernetes/03-postgres.yaml
resources:
  requests:
    memory: "128Mi"  # Era 256Mi
    cpu: "100m"      # Era 200m
```

**Causa B: PVC não pode ser provisionado**
```bash
# Ver PVCs
kubectl get pvc -n shaka-dev

# Se pending, verificar StorageClass
kubectl get storageclass

# Instalar local-path-provisioner se necessário
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
```

**Causa C: LimitRange conflito**
```bash
# Ver LimitRanges
kubectl get limitrange -n shaka-dev

# Ajustar se necessário
# Edit: infrastructure/kubernetes/01-namespace.yaml
```

---

### Problema 5: API Retorna 500 Error

**Sintomas:**
```bash
curl http://localhost:3000/api/v1/auth/login
# {"error": "Internal Server Error"}
```

**Diagnóstico:**
```bash
# Ver logs da API
docker-compose logs api
# Ou no Kubernetes
kubectl logs -f <api-pod> -n shaka-dev
```

**Soluções:**

**Causa A: Database não conecta**
```bash
# Testar conexão manualmente
docker-compose exec postgres \
  psql -U shaka -d shaka_api -c "SELECT 1;"

# Verificar variáveis ambiente
docker-compose exec api env | grep DB_
```

**Causa B: Redis não conecta**
```bash
# Testar conexão
docker-compose exec redis redis-cli ping
# Resultado esperado: PONG

# Verificar password
docker-compose exec api env | grep REDIS_PASSWORD
```

**Causa C: JWT_SECRET não configurado**
```bash
# Verificar
docker-compose exec api env | grep JWT_SECRET
# Se vazio, configurar no .env
```

**Causa D: Erro de código**
```bash
# Ver stack trace no log
docker-compose logs api | grep -A 20 "Error:"

# Reproduzir localmente
npm run dev
# Testar endpoint que falha
```

---

### Problema 6: Coverage Abaixo do Threshold

**Sintomas:**
```bash
npm run test:coverage
# Jest: "coverage" 55% < threshold 70%
```

**Diagnóstico:**
```bash
# Ver relatório HTML
open coverage/index.html

# Identificar arquivos com baixo coverage
npm run test:coverage | grep -A 20 "File"
```

**Soluções:**

**Causa A: Arquivos sem testes**
```bash
# Ver quais arquivos não têm testes
find src -name "*.ts" -not -path "*/node_modules/*" | while read file; do
  testfile=$(echo $file | sed 's/src/tests\/unit/' | sed 's/.ts/.test.ts/')
  if [ ! -f "$testfile" ]; then
    echo "Missing test: $testfile"
  fi
done
```

**Causa B: Testes superficiais**
```typescript
// ❌ Teste superficial (não testa comportamento)
it('should exist', () => {
  expect(AuthService).toBeDefined();
});

// ✅ Teste real
it('should login with valid credentials', async () => {
  const result = await AuthService.login('user@example.com', 'Pass@123');
  expect(result.accessToken).toBeDefined();
});
```

**Causa C: Código não alcançável**
```typescript
// Se este código nunca executa em testes, coverage será baixo
if (process.env.NODE_ENV === 'production') {
  // Código aqui nunca testado
}

// Solução: Mock ambiente
process.env.NODE_ENV = 'production';
// Testar código
```

---

### Problema 7: Hot Reload Não Funciona

**Sintomas:**
```bash
npm run dev
# Mudança em arquivo não recarrega
```

**Diagnóstico:**
```bash
# Verificar se nodemon está rodando
ps aux | grep nodemon

# Verificar nodemon.json
cat nodemon.json
```

**Soluções:**

**Causa A: nodemon.json mal configurado**
```json
// nodemon.json
{
  "watch": ["src"],
  "ext": "ts",
  "ignore": ["src/**/*.test.ts"],
  "exec": "ts-node -r tsconfig-paths/register src/server.ts"
}
```

**Causa B: ts-node-dev não instalado**
```bash
npm install --save-dev ts-node-dev nodemon
```

**Causa C: Volume mount incorreto (Docker)**
```yaml
# docker-compose.yml
services:
  api:
    volumes:
      - ./src:/app/src     # ✅ Mount source
      - /app/node_modules  # ✅ Não sobrescrever node_modules
```

---

### Problema 8: Rate Limiting Não Funciona

**Sintomas:**
```bash
# Consegue fazer 200 requests sem ser bloqueado
# Deveria bloquear em 100 (plano starter)
```

**Diagnóstico:**
```bash
# Ver configuração
cat src/core/types/subscription.types.ts | grep -A 10 "PLAN_LIMITS"

# Testar Redis
docker-compose exec redis redis-cli -n 0 KEYS "rate:*"
```

**Soluções:**

**Causa A: Middleware não registrado**
```typescript
// src/api/routes/index.ts
import { rateLimiter } from '../middlewares/rateLimiter';

// ✅ Aplicar ANTES das rotas
router.use(rateLimiter);
router.use('/auth', authRoutes);
```

**Causa B: Redis database incorreto**
```typescript
// src/infrastructure/cache/RedisRateLimiterService.ts
const client = redis.createClient({
  db: 0  // ✅ Database correta
});
```

**Causa C: Usuário não tem plano**
```bash
# Verificar no database
docker-compose exec postgres \
  psql -U shaka -d shaka_api \
  -c "SELECT id, email, plan FROM users WHERE email='test@example.com';"
```

---

## 🗺️ PRÓXIMOS PASSOS - ROADMAP

### Fase 10: Monitoring & Observability (PRÓXIMO)

**Duração Estimada:** 2-3 horas  
**Prioridade:** 🔴 Alta

#### Objetivos
- Prometheus para coleta de métricas
- Grafana para visualização
- Loki para agregação de logs
- Alertmanager para alertas

#### Deliverables
```
monitoring/
├── prometheus/
│   ├── prometheus.yml         # Config Prometheus
│   ├── alerts.yml             # Regras de alerta
│   └── recording-rules.yml    # Recording rules
├── grafana/
│   ├── dashboards/
│   │   ├── api-overview.json
│   │   ├── database.json
│   │   └── redis.json
│   └── provisioning/
├── loki/
│   └── loki-config.yml
└── docker-compose-monitoring.yml
```

#### Métricas a Coletar
```
Application:
- Request rate (req/s)
- Response time (p50, p95, p99)
- Error rate (5xx)
- Active users
- API calls por plano

Database:
- Connections (active, idle)
- Query duration
- Slow queries (>100ms)
- Database size

Redis:
- Hit rate
- Memory usage
- Keys por database
- Command rate

Infrastructure:
- CPU usage
- Memory usage
- Disk I/O
- Network traffic
```

#### Alertas Críticos
```yaml
- API down (5xx > 10%)
- High latency (p95 > 500ms)
- Database connections > 80%
- Redis memory > 90%
- Disk space < 10%
- Pod crashes > 3 in 5min
```

---

### Fase 11: CI/CD Pipeline

**Duração Estimada:** 3-4 horas  
**Prioridade:** 🟡 Média-Alta

#### Objetivos
- GitHub Actions para CI/CD
- Testes automatizados em PR
- Deploy automático por ambiente
- Rollback strategy

#### Pipeline Proposto

```yaml
# .github/workflows/ci-cd.yml

name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
      - run: npm ci
      - run: npm run build
      - run: npm run lint
      - run: npm test
      - run: npm run test:coverage
      
  build-docker:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: docker/build-push-action@v4
        with:
          push: true
          tags: registry/shaka-api:${{ github.sha }}
          
  deploy-dev:
    needs: build-docker
    if: github.ref == 'refs/heads/develop'
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to dev
        run: |
          kubectl set image deployment/shaka-api \
            shaka-api=registry/shaka-api:${{ github.sha }} \
            -n shaka-dev
            
  deploy-prod:
    needs: build-docker
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to prod
        run: |
          kubectl set image deployment/shaka-api \
            shaka-api=registry/shaka-api:${{ github.sha }} \
            -n shaka-prod
```

---

### Fase 12: API Deployment Completo

**Duração Estimada:** 2 horas  
**Prioridade:** 🔴 Alta (bloqueador para K8s completo)

#### Objetivos
- Deployments API em 3 ambientes
- HPA (Horizontal Pod Autoscaler)
- PodDisruptionBudgets
- Liveness/Readiness probes

#### Deliverables
```
infrastructure/kubernetes/
└── 05-api-deployment.yaml    # Deployments + Services + HPA
```

---

### Fase 13: Ingress & TLS

**Duração Estimada:** 2 horas  
**Prioridade:** 🟡 Média-Alta

#### Objetivos
- Ingress Controller (Traefik ou NGINX)
- Cert-Manager para TLS automático
- DNS configuration
- Rate limiting no Ingress level

---

### Fase 14: Advanced Features

**Duração Estimada:** 8-10 horas  
**Prioridade:** 🟢 Baixa

#### Features Planejadas
- **Webhooks:** Notificações de eventos
- **API Versioning:** v1, v2, etc
- **GraphQL Layer:** Alternativa ao REST
- **WebSockets:** Real-time updates
- **File Upload:** S3/MinIO integration
- **Email Service:** Templates + SMTP
- **SMS Service:** Twilio integration
- **Payment Processing:** Stripe completo

---

## 📋 CHECKLIST DE QUALIDADE

### Build & Tests

- [x] ✅ TypeScript build sem erros
- [x] ✅ 143 testes passando (100%)
- [x] ✅ Coverage 81.9% (threshold 70%)
- [x] ✅ ESLint sem erros críticos
- [ ] ⏳ E2E tests end-to-end reais (mock atualmente)

### Infrastructure

- [x] ✅ Docker multi-stage otimizado
- [x] ✅ Docker Compose dev + prod
- [x] ✅ Kubernetes namespaces configurados
- [x] ✅ PostgreSQL multi-ambiente
- [x] ✅ Redis shared funcionando
- [ ] ⏳ API deployments K8s
- [ ] ⏳ Ingress + TLS configurado

### Security

- [x] ✅ JWT authentication
- [x] ✅ Rate limiting por plano
- [x] ✅ Password hashing (bcrypt)
- [x] ✅ Environment variables
- [x] ✅ Non-root Docker user
- [ ] ⏳ Sealed Secrets (K8s)
- [ ] ⏳ Network Policies completas
- [ ] ⏳ Security scanning (Snyk/Trivy)

### Monitoring

- [ ] ⏳ Prometheus instalado
- [ ] ⏳ Grafana dashboards
- [ ] ⏳ Log aggregation (Loki)
- [ ] ⏳ Alerting configurado
- [ ] ⏳ Uptime monitoring
- [ ] ⏳ APM (Application Performance Monitoring)

### Documentation

- [x] ✅ 10 Memorandos de handoff
- [x] ✅ DOCKER_QUICKSTART.md
- [x] ✅ DOCKER_ARCHITECTURE.md
- [x] ✅ README.md atualizado
- [ ] ⏳ API documentation (Swagger/OpenAPI)
- [ ] ⏳ Architecture Decision Records (ADRs)
- [ ] ⏳ Runbooks operacionais

### DevOps

- [x] ✅ Scripts de automação (43 scripts)
- [x] ✅ Makefile commands
- [x] ✅ Docker management scripts
- [ ] ⏳ CI/CD pipeline
- [ ] ⏳ Automated deployments
- [ ] ⏳ Rollback automation

---

## 📊 MÉTRICAS DO PROJETO

### Estatísticas de Desenvolvimento

```
┌─────────────────────────────────────────────┐
│  SHAKA API - PROJECT METRICS                │
├─────────────────────────────────────────────┤
│  Tempo Investido:        ~25 horas          │
│  Fases Completas:        9/10 (90%)         │
│  Scripts Criados:        43 scripts         │
│  Linhas de Código:       ~8,000+            │
│  Arquivos TypeScript:    ~80 files          │
│  Testes:                 143 (100% pass)    │
│  Coverage:               81.9%              │
│  Memorandos:             10 documentos      │
│  Commits:                ~50+               │
│  Branches:               main + feature/*   │
└─────────────────────────────────────────────┘
```

### Breakdown por Fase

| Fase              | Duração  | Scripts | LOC        | Status  |
|-------------------|----------|---------|------------|---------|
| 1. Estrutura      | 1h       | 1       | ~500       | ✅ 100% |
| 2. API Base       | 2h       | 1       | ~1,000     | ✅ 100% |
| 3. Services       | 3h45     | 4       | ~1,200     | ✅ 100% |
| 4. Infrastructure | 2h       | 5       | ~800       | ✅ 100% |
| 5. Build Fixes    | 2h       | 17      | ~200       | ✅ 100% |
| 6. Runtime        | 40min    | 8       | ~300       | ✅ 100% |
| 7. Testing        | 9h       | 17      | ~2,000     | ✅ 100% |
| 8. Docker         | 20min    | 3       | ~500       | ✅ 100% |
| 9. Kubernetes     | 4h       | 5       | ~1,500     | ✅ 92%  |
| **TOTAL**         | **~25h** | **43**  | **~8,000** | **90%** |

### Qualidade de Código

```
Complexity:        Baixa-Média (bem estruturado)
Maintainability:   Alta (Clean Architecture)
Testability:       Muito Alta (81.9% coverage)
Scalability:       Excelente (K8s + microservices ready)
Security:          Boa (JWT + rate limit + env vars)
Documentation:     Excelente (10 memorandos completos)
```

---

## 🎓 CONCLUSÃO E PRÓXIMOS PASSOS IMEDIATOS

### Status Atual do Projeto

O Shaka API está **90% completo** e **production-ready** com ressalvas:

✅ **Completo e Funcional:**
- Código-fonte completo e testado
- 143 testes automatizados (81.9% coverage)
- Docker containerizado
- Kubernetes infrastructure core

⏳ **Pendente para Produção Real:**
- API deployments no Kubernetes
- Ingress + TLS configurado
- Monitoring stack (Prometheus + Grafana)
- CI/CD pipeline

### Recomendação Imediata

**Para desenvolvimento local:**
```bash
# Sistema 100% funcional com Docker
./docker.sh start
./docker.sh health
./docker.sh test
```

**Para ambiente de staging/produção:**
```bash
# Implementar Fase 10 (Monitoring) primeiro
# Depois Fase 12 (API Deployment)
# Finalmente Fase 13 (Ingress + TLS)
```

### Próximas 3 Ações

1. **Implementar API Deployment no Kubernetes** (2h)
   - Criar `05-api-deployment.yaml`
   - Deploy em dev, staging, prod
   - Validar comunicação com PostgreSQL/Redis

2. **Setup Monitoring Básico** (2h)
   - Prometheus + Grafana via Docker Compose
   - Dashboards básicos
   - Alertas críticos

3. **Configurar CI/CD Pipeline** (3h)
   - GitHub Actions
   - Automated testing em PR
   - Deploy automático

---

## 📞 SUPORTE E RECURSOS

### Contatos

**CTO Integrador:** Headmaster  
**Repositório:** github.com/[seu-usuario]/shaka-api  
**Documentação:** docs/memorandos/  
**Servidor K8s:** microsaas-server  

### Recursos Adicionais

**Documentação Oficial:**
- Express.js: https://expressjs.com
- TypeScript: https://www.typescriptlang.org
- Docker: https://docs.docker.com
- Kubernetes: https://kubernetes.io/docs
- Jest: https://jestjs.io
- PostgreSQL: https://www.postgresql.org/docs
- Redis: https://redis.io/docs

**Comunidades:**
- Stack Overflow: [nodejs], [typescript], [kubernetes]
- Reddit: r/node, r/typescript, r/kubernetes
- Discord: NodeJS, TypeScript, Kubernetes

---

## ✅ ASSINATURA E APROVAÇÃO

**Documento Criado Por:** Headmaster CTO Integrador  
**Data de Criação:** 01 de Dezembro de 2025  
**Última Atualização:** 01 de Dezembro de 2025  
**Versão:** 2.0  
**Status:** ✅ **APROVADO PARA TREINAMENTO E ONBOARDING**  

**Fases Documentadas:** 1-9 (90% do projeto)  
**Próxima Atualização:** Após Fase 10 (Monitoring)  

---

**FIM DO MEMORANDO MESTRE DE HANDOFF/ONBOARDING**

---

*Este documento consolida 10 memorandos individuais em um guia completo para onboarding e treinamento. 
Use-o como referência única para entender toda a jornada do projeto Shaka API.*

Continua no MEMORANDO MESTRE 2 que consolida + 9 Memorandos de Handoff
