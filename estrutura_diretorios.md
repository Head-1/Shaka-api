ESTRUTURA DE DIRETÓRIOS COMPLETA (v3.0)

shaka-api/
│
├── 📂 src/                          # Código-fonte TypeScript
│   ├── 📂 api/                      # PRESENTATION LAYER
│   │   ├── 📂 controllers/          # Controladores REST (static methods)
│   │   │   ├── 📂 auth/
│   │   │   │   └── AuthController.ts        # POST /auth/register, /login, /refresh
│   │   │   ├── 📂 user/
│   │   │   │   └── UserController.ts        # CRUD de usuários
│   │   │   └── 📂 plan/
│   │   │       └── PlanController.ts        # Gestão de planos
│   │   │
│   │   ├── 📂 middlewares/          # 7 middlewares (Express)
│   │   │   ├── authenticate.ts      # JWT authentication
│   │   │   ├── errorHandler.ts      # Global error handler
│   │   │   ├── notFoundHandler.ts   # 404 handler
│   │   │   ├── rateLimiter.ts       # Rate limiting por tier
│   │   │   ├── requestLogger.ts     # ✅ CORRIGIDO: req.originalUrl (Fase 15)
│   │   │   ├── validateRequest.ts   # Request validation
│   │   │   └── validator.ts         # Joi validator
│   │   │
│   │   ├── 📂 routes/               # Definição de rotas (base: /api/v1)
│   │   │   ├── auth.routes.ts       # POST /auth/register, /login, /refresh
│   │   │   ├── health.routes.ts     # GET /health
│   │   │   ├── index.ts             # Router principal
│   │   │   ├── plan.routes.ts       # GET /plans
│   │   │   └── user.routes.ts       # CRUD /users
│   │   │
│   │   └── 📂 validators/           # Joi schemas
│   │       ├── auth.validator.ts    # registerSchema, loginSchema, refreshSchema
│   │       └── user.validator.ts    # updateUserSchema, changePasswordSchema
│   │
│   ├── 📂 core/                     # APPLICATION LAYER
│   │   ├── 📂 services/             # Business logic (static methods)
│   │   │   ├── 📂 auth/
│   │   │   │   ├── AuthService.ts           # Register, login, refresh tokens
│   │   │   │   ├── PasswordService.ts       # bcrypt hashing
│   │   │   │   └── TokenService.ts          # JWT generation/validation
│   │   │   │
│   │   │   ├── 📂 motor-hybrid/     # ⭐ NOVO - Motor Híbrido (Fase 16)
│   │   │   │   ├── 📂 auth/
│   │   │   │   │   └── AuthMotor.ts         # ⏳ PLACEHOLDER estruturado
│   │   │   │   │                            # validateToken(), refreshSession()
│   │   │   │   │                            # healthCheck() - ATHOS-ready
│   │   │   │   ├── 📂 future-mcp/
│   │   │   │   │   └── README.md            # Documentação MCP Protocol
│   │   │   │   ├── index.ts                 # Barrel exports
│   │   │   │   ├── types.ts                 # Interfaces TypeScript
│   │   │   │   └── README.md                # Arquitetura do Motor
│   │   │   │
│   │   │   ├── 📂 rate-limiter/
│   │   │   │   └── RateLimiterService.ts    # Rate limit logic
│   │   │   ├── 📂 subscription/
│   │   │   │   └── SubscriptionService.ts   # Subscription management
│   │   │   └── 📂 user/
│   │   │       └── UserService.ts           # CRUD + business rules
│   │   │
│   │   └── 📂 types/                # TypeScript interfaces
│   │       ├── auth.types.ts        # LoginCredentials, AuthTokens, JWTPayload
│   │       ├── rate-limiter.types.ts
│   │       ├── subscription.types.ts
│   │       └── user.types.ts        # CreateUserData, UserResponse
│   │
│   ├── 📂 infrastructure/           # INFRASTRUCTURE LAYER
│   │   ├── 📂 database/
│   │   │   ├── config.ts            # TypeORM DataSource config
│   │   │   ├── DatabaseService.ts   # Connection service (static, com disconnect())
│   │   │   ├── 📂 entities/
│   │   │   │   ├── SubscriptionEntity.ts
│   │   │   │   └── UserEntity.ts
│   │   │   ├── 📂 repositories/
│   │   │   │   ├── BaseRepository.ts        # Generic repository
│   │   │   │   ├── index.ts                 # Factory
│   │   │   │   ├── SubscriptionRepository.ts
│   │   │   │   └── UserRepository.ts
│   │   │   └── 📂 migrations/
│   │   │       ├── 1700000000001-CreateUsersTable.ts
│   │   │       └── 1700000000002-CreateSubscriptionsTable.ts
│   │   │
│   │   └── 📂 cache/
│   │       ├── CacheService.ts              # Redis service (static, com disconnect())
│   │       ├── redis.config.ts
│   │       └── RedisRateLimiterService.ts
│   │
│   ├── 📂 shared/                   # SHARED LAYER
│   │   ├── 📂 errors/
│   │   │   └── AppError.ts          # Custom errors
│   │   └── 📂 utils/
│   │       └── logger.ts            # ✅ CORRIGIDO: paths absolutos (Fase 15)
│   │
│   ├── 📂 config/                   # Configurações
│   │   ├── env.ts                   # ✅ CORRIGIDO: export único
│   │   └── logger.ts                # Winston config (paths absolutos)
│   │
│   └── server.ts                    # Express app setup ✅ CORRIGIDO: rotas registradas
│
├── 📂 dist/                         # TypeScript build output (gitignored)
│   ├── api/
│   ├── config/
│   ├── core/
│   ├── infrastructure/
│   ├── shared/
│   └── server.js                    # Entry point compilado
│
├── 📂 tests/                        # Suite de testes (13 arquivos)
│   ├── 📂 unit/                     # 6 arquivos
│   │   ├── 📂 controllers/
│   │   │   └── user.controller.test.ts
│   │   ├── 📂 services/
│   │   │   ├── password.service.test.ts
│   │   │   ├── subscription.service.test.ts
│   │   │   ├── token.service.test.ts
│   │   │   └── user.service.test.ts
│   │   └── 📂 validators/
│   │       └── user.validator.test.ts
│   │
│   ├── 📂 integration/              # 4 arquivos
│   │   └── 📂 api/
│   │       ├── auth.test.ts
│   │       ├── health.test.ts
│   │       ├── plans.test.ts
│   │       └── users.test.ts
│   │
│   ├── 📂 e2e/                      # 3 arquivos
│   │   ├── auth-flow.test.ts
│   │   ├── subscription-flow.test.ts
│   │   └── user-flow.test.ts
│   │
│   ├── 📂 __mocks__/
│   │   ├── database.mock.ts
│   │   └── cache.mock.ts
│   │
│   ├── jest.setup.js
│   └── .env.test
│
├── 📂 scripts/                      # 113 automation scripts
│   ├── 📂 build-fixes/              # 26 scripts (TypeScript build)
│   │   ├── fix-typescript-errors.sh
│   │   ├── fix-services-static.sh
│   │   └── ...
│   │
│   ├── 📂 deployment/               # 67 scripts (Kubernetes/Docker)
│   │   ├── deploy-api-k8s.sh
│   │   ├── diagnose-crashloop.sh
│   │   ├── fix-database-credentials.sh
│   │   ├── fix-dns-issue.sh
│   │   ├── remove-default-deny.sh
│   │   ├── validate-deployment.sh
│   │   │
│   │   └── 📂 ingress/              # ⭐ NOVO - Scripts Ingress (Fase 16)
│   │       ├── deploy-ingress.sh          # Deploy automatizado
│   │       ├── rollback-ingress.sh        # Rollback configs
│   │       ├── test-ingress.sh            # Suite E2E tests
│   │       ├── validate-phase16-light.sh  # Validação versão LIGHT
│   │       └── README.md                  # Documentação scripts
│   │
│   ├── 📂 docker/                   # 10 scripts (Docker management)
│   │   ├── start.sh
│   │   ├── stop.sh
│   │   ├── logs.sh
│   │   ├── health.sh
│   │   ├── migrate.sh
│   │   ├── reset.sh
│   │   └── test-docker.sh
│   │
│   ├── 📂 motor-hybrid/             # ⭐ NOVO - Scripts Motor (Fase 16)
│   │   ├── build-motor.sh                 # ⏳ Build TypeScript (adiado)
│   │   ├── test-motor.sh                  # ⏳ Testes unitários (futuro)
│   │   └── README.md                      # Documentação
│   │
│   └── 📂 quick-fixes/              # 21 scripts (correções rápidas)
│       ├── fix-all-final.sh         # ✅ Script vencedor (Fase 10)
│       ├── fix-auth-middleware.sh
│       └── ...
│
├── 📂 docs/                         # Documentação
│   ├── 📂 memorandos/               # 20 memorandos de handoff
│   │   ├── INDEX.md
│   │   ├── 1-Fase-1+2-estrutura+BaseAPI.md
│   │   ├── 2-Fase-3-Services+Types.md
│   │   ├── 3-Fase-4-Database+Redis+Integration.md
│   │   ├── 4-Fase-5+6-Build_Limpo+Infra_Completa.md
│   │   ├── 5-Fase-7A-Testing_Layer.md
│   │   ├── 6-Fase-7B-Integration+E2E.md
│   │   ├── 7-Fase-7C-E2E_Tests.md
│   │   ├── 8-Fase-7D-Coverage_Improvement.md
│   │   ├── 9-Fase-8-Containerização.md
│   │   ├── 10-Fase-9-Kubernetes_Production-Grade_Infrastructure.md
│   │   ├── 11-Fase-10-Correção_TypeScript_Build+Preparação_Docker.md
│   │   ├── 12-Fase-11-Deploy_Kubernetes-Troubleshooting_Session.md
│   │   ├── 13-Fase-12-Deploy_Kubernetes-Path_Aliases_Fix+Database_Credentials.md
│   │   ├── 14-Fase-13-Kubernetes_Production_Deployment_concluido.md
│   │   ├── 15-Fase-14-API_Endpoint_Testing+Route_Debugging_75.md
│   │   ├── 16-Fase-14-API_Endpoint_Testing+Route_Debugging_100.md
│   │   ├── 17-Fase-15-Deployment_Shaka_API_Staging.md
│   │   ├── 18-Fase-16-Ingress+MotorHybrid_PARCIAL.md
│   │   ├── 19-Fase-16-Ingress+MotorHybrid_COMPLETO.md
│   │   ├── 20-MEMORANDO_MESTRE-1.md (Consolidação Memorandos 1 ao 10)
│   │   └── 21-MEMORANDO_MESTRE-2.md (Consolidação Memorandos 11 ao 19)
│   │
│   └── 📂 api/                      # API docs (futuro)
│       └── swagger/
│
├── 📂 docker/                       # Docker configuration
│   ├── 📂 api/
│   │   └── Dockerfile               # Multi-stage (referência, usar raiz)
│   ├── 📂 nginx/
│   ├── 📂 postgres/
│   └── 📂 redis/
│
├── 📂 infrastructure/kubernetes/     # ⭐ KUBERNETES MANIFESTS COMPLETOS
│   ├── 01-namespace.yaml             # Namespaces + Quotas + LimitRanges
│   ├── 01-namespace-fixed.yaml       # LimitRanges otimizados (25m CPU mínimo)
│   ├── 02-configmaps-secrets.yaml    # Configs por ambiente
│   ├── 03-postgres.yaml              # PostgreSQL 3 ambientes
│   ├── 03-postgres-prod-fixed.yaml   # ✅ Prod sem sidecar
│   ├── 04-redis-simple-scalable.yaml # ✅ Redis Shared Architecture
│   ├── 05-api-deployment.yaml        # ✅ API deployment (1 container clean)
│   │
│   └── 📂 ingress/                   # ⭐ NOVO - Ingress Configuration (Fase 16)
│       ├── 01-ingress-staging.yaml          # ✅ APLICADO - Ingress minimalista
│       │                                      # Host: staging.shaka.local
│       │                                      # Paths: /, /api, /health
│       │
│       ├── 01-ingress-staging.yaml.ORIGINAL  # ✅ BACKUP - Versão com middlewares
│       │                                      # Restaurar quando CRDs disponíveis
│       │
│       ├── 02-ingress-dev.yaml               # ✅ CRIADO - Pronto para aplicar
│       │                                      # Host: dev.shaka.local
│       │
│       ├── 04-middleware-ratelimit.yaml      # 📦 ORIGINAL - Rate limiting básico
│       │                                      # Sem dependência CRD
│       │
│       ├── README.md                          # ✅ Documentação completa
│       │                                      # Troubleshooting + exemplos
│       │
│       └── 📂 .future/                        # 🔮 FEATURES FUTURAS (Fase 17)
│           ├── 03-middleware-cors.yaml        # ⏳ CORS avançado
│           │                                   # Requer Traefik CRD
│           └── 04-middleware-ratelimit.yaml   # (duplicado, ignorar)
│
├── 📂 k8s/                          # Kubernetes adicional (futuro)
├── 📂 monitoring/                   # Observability (futuro)
│   ├── prometheus/
│   └── grafana/
│
├── 📂 backups/                      # Backups automáticos
│   ├── configmap-*-backup-*.yaml
│   ├── deployment-*-backup-*.yaml
│   ├── networkpolicy-*-backup-*.yaml
│   │
│   └── 📂 ingress/                  # ⭐ NOVO - Backups Ingress (Fase 16)
│       ├── staging-[timestamp].yaml
│       └── dev-[timestamp].yaml
│
├── 📄 .buildignore                  # ⭐ NOVO - Exclusões de build (Fase 16)
│   └── src/core/services/motor-hybrid/  # Motor não compilado (intencional)
│
├── 📄 Dockerfile                    # ✅ CORRIGIDO (raiz, com mkdir /app/logs)
├── 📄 docker-compose.yml            # Development
├── 📄 docker-compose.prod.yml       # Production
├── 📄 .dockerignore                 # Ignores (package-lock.json incluído)
│
├── 📄 package.json                  # Dependencies + scripts
├── 📄 package-lock.json             # Lock file
├── 📄 tsconfig.json                 # TypeScript config (sem path aliases)
├── 📄 jest.config.js                # Jest config (81.9% coverage)
│
├── 📄 .env                          # Environment vars (NÃO COMMITAR)
├── 📄 .env.example                  # Template
├── 📄 .env.test                     # Test environment
├── 📄 .env.docker                   # Docker template
│
├── 📄 .gitignore                    # Git ignores
├── 📄 README.md                     # Main docs
├── 📄 PROJECT_STRUCTURE.md          # ✅ ESTE ARQUIVO (v3.0)
├── 📄 Makefile                      # Make commands
└── 📄 manage-server.sh              # Server management
