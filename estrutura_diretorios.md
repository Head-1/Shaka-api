ESTRUTURA DE DIRETÓRIOS COMPLETA (v4.0)
Atualizado: 2025-12-13 | Sprint 1 COMPLETO ✅ | Fases 1-25 Consolidadas

═══════════════════════════════════════════════════════════════════════════════

shaka-api/
│
├── 📂 src/                          # Código-fonte TypeScript
│   ├── 📂 api/                      # PRESENTATION LAYER
│   │   ├── 📂 controllers/          # Controladores REST (static methods)
│   │   │   ├── 📂 auth/
│   │   │   │   └── AuthController.ts        # POST /auth/register, /login, /refresh
│   │   │   │                                # ✅ Fase 3 | Status: Funcional
│   │   │   │
│   │   │   ├── 📂 user/
│   │   │   │   └── UserController.ts        # CRUD de usuários
│   │   │   │                                # ✅ Fase 3 | Status: Funcional
│   │   │   │
│   │   │   ├── 📂 api-key/          # ⭐ NOVO - Sprint 1 (Fases 17-25)
│   │   │   │   └── ApiKeyController.ts      # 7 endpoints REST completos
│   │   │   │                                # - POST /keys (create)
│   │   │   │                                # - GET /keys (list)
│   │   │   │                                # - GET /keys/:id (getOne)
│   │   │   │                                # - GET /keys/:id/usage (getUsage)
│   │   │   │                                # - POST /keys/:id/rotate (rotate)
│   │   │   │                                # - DELETE /keys/:id (revoke)
│   │   │   │                                # - DELETE /keys/:id/permanent (delete)
│   │   │   │                                # ✅ 100% Funcional (22/22 testes)
│   │   │   │
│   │   │   └── 📂 plan/
│   │   │       └── PlanController.ts        # Gestão de planos
│   │   │                                    # ✅ Fase 3 | Status: Funcional
│   │   │
│   │   ├── 📂 middlewares/          # 8 middlewares (Express)
│   │   │   ├── authenticate.ts      # JWT authentication
│   │   │   │                        # ✅ Fase 3 | Bearer token
│   │   │   │
│   │   │   ├── apiKeyAuth.ts        # ⭐ NOVO - X-API-Key authentication
│   │   │   │                        # ✅ Fase 17 | Sprint 1
│   │   │   │                        # Header: X-API-Key
│   │   │   │                        # Validação SHA-256 hash
│   │   │   │                        # ✅ Fase 25: Logger path corrigido
│   │   │   │
│   │   │   ├── trackUsage.ts        # ⭐ NOVO - Usage tracking automático
│   │   │   │                        # ✅ Fase 17 | Sprint 1
│   │   │   │                        # Registra: endpoint, method, statusCode
│   │   │   │                        # responseTime, IP, userAgent
│   │   │   │
│   │   │   ├── errorHandler.ts      # Global error handler
│   │   │   │                        # ✅ Fase 2 | Unificado
│   │   │   │
│   │   │   ├── notFoundHandler.ts   # 404 handler
│   │   │   │                        # ✅ Fase 2
│   │   │   │
│   │   │   ├── rateLimiter.ts       # Rate limiting por tier
│   │   │   │                        # ✅ Fase 3 | Redis-backed
│   │   │   │                        # Atualizado Fase 17 para API keys
│   │   │   │
│   │   │   ├── requestLogger.ts     # Request logging
│   │   │   │                        # ✅ CORRIGIDO Fase 14: req.originalUrl
│   │   │   │                        # Logs: método, path completo, status
│   │   │   │
│   │   │   └── validateRequest.ts   # Request validation (Joi)
│   │   │                            # ✅ Fase 2
│   │   │
│   │   ├── 📂 routes/               # Definição de rotas (base: /api/v1)
│   │   │   ├── auth.routes.ts       # POST /auth/register, /login, /refresh
│   │   │   │                        # ✅ Fase 3 | Autenticação JWT
│   │   │   │
│   │   │   ├── api-keys.routes.ts   # ⭐ NOVO - Sprint 1 (Fase 17)
│   │   │   │                        # 7 endpoints API Key Management
│   │   │   │                        # Auth: JWT (Bearer token)
│   │   │   │                        # ✅ 100% Funcional
│   │   │   │
│   │   │   ├── health.routes.ts     # GET /health
│   │   │   │                        # ✅ Fase 2 | Health checks
│   │   │   │
│   │   │   ├── index.ts             # Router principal
│   │   │   │                        # ✅ Fase 2 | Agrega todas rotas
│   │   │   │
│   │   │   ├── plan.routes.ts       # GET /plans
│   │   │   │                        # ✅ Fase 3 | Planos disponíveis
│   │   │   │
│   │   │   └── user.routes.ts       # CRUD /users
│   │   │                            # ✅ Fase 3 | User management
│   │   │
│   │   └── 📂 validators/           # Joi schemas
│   │       ├── auth.validator.ts    # registerSchema, loginSchema
│   │       │                        # ✅ Fase 2
│   │       │
│   │       ├── user.validator.ts    # updateUserSchema, changePasswordSchema
│   │       │                        # ✅ Fase 2
│   │       │
│   │       └── api-key.validator.ts # ⭐ NOVO - API Key validation
│   │                                # ✅ Fase 17 | Sprint 1
│   │                                # Schemas: create, update, rotate
│   │
│   ├── 📂 core/                     # APPLICATION LAYER
│   │   ├── 📂 services/             # Business logic (static methods)
│   │   │   ├── 📂 auth/
│   │   │   │   ├── AuthService.ts           # Register, login, refresh tokens
│   │   │   │   │                            # ✅ Fase 3 | JWT completo
│   │   │   │   │                            # ✅ Fase 18: PasswordService fixes
│   │   │   │   │
│   │   │   │   ├── PasswordService.ts       # bcrypt hashing
│   │   │   │   │                            # ✅ Fase 3 | 12 salt rounds
│   │   │   │   │                            # ✅ Fase 18: static methods
│   │   │   │   │
│   │   │   │   └── TokenService.ts          # JWT generation/validation
│   │   │   │                                # ✅ Fase 3 | Access + Refresh
│   │   │   │
│   │   │   ├── 📂 api-key/          # ⭐ NOVO - Sprint 1 (Fases 17-25)
│   │   │   │   ├── ApiKeyService.ts         # Business logic completa
│   │   │   │   │                            # - create() → gera key segura
│   │   │   │   │                            # - list() → keys do usuário
│   │   │   │   │                            # - rotate() → nova key, revoga antiga
│   │   │   │   │                            # - revoke() → soft delete
│   │   │   │   │                            # - delete() → hard delete
│   │   │   │   │                            # ✅ 100% Funcional
│   │   │   │   │                            # Formato: sk_live_[32 hex chars]
│   │   │   │   │                            # Hash: SHA-256
│   │   │   │   │
│   │   │   │   └── types.ts                 # Interfaces TypeScript
│   │   │   │                                # CreateApiKeyData, ApiKeyResponse
│   │   │   │                                # ✅ Fase 17
│   │   │   │
│   │   │   ├── 📂 usage-tracking/   # ⭐ NOVO - Sprint 1 (Fase 17)
│   │   │   │   ├── UsageTrackingService.ts  # Analytics & métricas
│   │   │   │   │                            # - trackUsage() → registra chamada
│   │   │   │   │                            # - getStats() → agregações
│   │   │   │   │                            # Métricas: requests, latency, errors
│   │   │   │   │                            # Períodos: day, week, month
│   │   │   │   │                            # ✅ 100% Funcional
│   │   │   │   │
│   │   │   │   └── types.ts                 # UsageData, UsageStats
│   │   │   │                                # ✅ Fase 17
│   │   │   │
│   │   │   ├── 📂 motor-hybrid/     # Motor Híbrido (Fase 16)
│   │   │   │   ├── 📂 auth/
│   │   │   │   │   └── AuthMotor.ts         # ⏳ PLACEHOLDER estruturado
│   │   │   │   │                            # validateToken(), refreshSession()
│   │   │   │   │                            # healthCheck() - ATHOS-ready
│   │   │   │   │                            # Status: Fase 17+ (futuro)
│   │   │   │   │
│   │   │   │   ├── 📂 future-mcp/
│   │   │   │   │   └── README.md            # Documentação MCP Protocol
│   │   │   │   │
│   │   │   │   ├── index.ts                 # Barrel exports
│   │   │   │   ├── types.ts                 # Interfaces TypeScript
│   │   │   │   └── README.md                # Arquitetura do Motor
│   │   │   │
│   │   │   ├── 📂 rate-limiter/
│   │   │   │   └── RateLimiterService.ts    # Rate limit logic
│   │   │   │                                # ✅ Fase 3 | Redis-backed
│   │   │   │                                # ✅ Fase 17: Suporte API keys
│   │   │   │
│   │   │   ├── 📂 subscription/
│   │   │   │   └── SubscriptionService.ts   # Subscription management
│   │   │   │                                # ✅ Fase 3 | PLAN_LIMITS
│   │   │   │
│   │   │   └── 📂 user/
│   │   │       └── UserService.ts           # CRUD + business rules
│   │   │                                    # ✅ Fase 3 | User operations
│   │   │
│   │   └── 📂 types/                # TypeScript interfaces
│   │       ├── auth.types.ts        # LoginCredentials, AuthTokens, JWTPayload
│   │       │                        # ✅ Fase 3
│   │       │
│   │       ├── api-key.types.ts     # ⭐ NOVO - API Key types
│   │       │                        # ✅ Fase 17 | Sprint 1
│   │       │
│   │       ├── usage.types.ts       # ⭐ NOVO - Usage tracking types
│   │       │                        # ✅ Fase 17 | Sprint 1
│   │       │
│   │       ├── rate-limiter.types.ts
│   │       │                        # ✅ Fase 3
│   │       │
│   │       ├── subscription.types.ts
│   │       │                        # ✅ Fase 3 | SubscriptionPlan enum
│   │       │
│   │       └── user.types.ts        # CreateUserData, UserResponse
│   │                                # ✅ Fase 3
│   │
│   ├── 📂 infrastructure/           # INFRASTRUCTURE LAYER
│   │   ├── 📂 database/
│   │   │   ├── config.ts            # TypeORM DataSource config
│   │   │   │                        # ✅ Fase 4 | PostgreSQL 15
│   │   │   │                        # ✅ Fase 25: UsageRecordEntity adicionada
│   │   │   │
│   │   │   ├── DatabaseService.ts   # Connection service (static)
│   │   │   │                        # ✅ Fase 4 | Singleton pattern
│   │   │   │                        # disconnect() method
│   │   │   │
│   │   │   ├── 📂 entities/
│   │   │   │   ├── UserEntity.ts
│   │   │   │   │                    # ✅ Fase 4
│   │   │   │   │                    # ✅ Fase 18: password → passwordHash
│   │   │   │   │
│   │   │   │   ├── SubscriptionEntity.ts
│   │   │   │   │                    # ✅ Fase 4
│   │   │   │   │
│   │   │   │   ├── ApiKeyEntity.ts  # ⭐ NOVO - Sprint 1 (Fase 17)
│   │   │   │   │                    # Colunas: id, userId, name
│   │   │   │   │           keyHash, keyPreview
│   │   │   │   │           permissions, rateLimit
│   │   │   │   │           isActive, lastUsedAt, expiresAt
│   │   │   │   │           createdAt, updatedAt
│   │   │   │   │                    # ✅ Fase 18: Registrada no config
│   │   │   │   │
│   │   │   │   └── UsageRecordEntity.ts # ⭐ NOVO - Sprint 1 (Fase 17)
│   │   │   │                        # Colunas (snake_case):
│   │   │   │                        # api_key_id, user_id
│   │   │   │                        # endpoint, method, status_code
│   │   │   │                        # response_time_ms, ip_address
│   │   │   │                        # user_agent, error_message
│   │   │   │                        # timestamp
│   │   │   │                        # ✅ Fase 25: Mappings snake_case
│   │   │   │
│   │   │   ├── 📂 repositories/
│   │   │   │   ├── BaseRepository.ts        # Generic repository
│   │   │   │   │                            # ✅ Fase 4 | Type-safe
│   │   │   │   │
│   │   │   │   ├── index.ts                 # Factory exports
│   │   │   │   │                            # ✅ Fase 4
│   │   │   │   │
│   │   │   │   ├── UserRepository.ts
│   │   │   │   │                            # ✅ Fase 4
│   │   │   │   │                            # ✅ Fase 20: Lazy initialization
│   │   │   │   │                            # Pattern: getter com caching
│   │   │   │   │
│   │   │   │   ├── SubscriptionRepository.ts
│   │   │   │   │                            # ✅ Fase 4
│   │   │   │   │
│   │   │   │   ├── ApiKeyRepository.ts      # ⭐ NOVO - Sprint 1 (Fase 17)
│   │   │   │   │                            # CRUD methods
│   │   │   │   │                            # - findByUserId()
│   │   │   │   │                            # - findByKeyHash()
│   │   │   │   │                            # - softDelete()
│   │   │   │   │                            # ✅ Fase 20: Lazy initialization
│   │   │   │   │
│   │   │   │   └── UsageRecordRepository.ts # ⭐ NOVO - Sprint 1 (Fase 17)
│   │   │   │                                # Analytics queries
│   │   │   │                                # - getStatsByApiKey()
│   │   │   │                                # - getStatsByPeriod()
│   │   │   │                                # Aggregations: SUM, AVG, COUNT
│   │   │   │                                # ✅ 100% Funcional
│   │   │   │
│   │   │   └── 📂 migrations/
│   │   │       ├── 1700000000001-CreateUsersTable.ts
│   │   │       │                            # ✅ Fase 4
│   │   │       │
│   │   │       ├── 1700000000002-CreateSubscriptionsTable.ts
│   │   │       │                            # ✅ Fase 4
│   │   │       │
│   │   │       ├── 1700000000003-CreateApiKeysTable.ts     # ⭐ NOVO
│   │   │       │                            # ✅ Fase 17 | Sprint 1
│   │   │       │                            # ✅ Fase 19: Aplicada via SQL direto
│   │   │       │
│   │   │       └── 1700000000004-CreateUsageRecordsTable.ts # ⭐ NOVO
│   │   │                                    # ✅ Fase 17 | Sprint 1
│   │   │                                    # ✅ Fase 19: Aplicada via SQL direto
│   │   │                                    # Indexes: api_key_id, timestamp
│   │   │
│   │   └── 📂 cache/
│   │       ├── CacheService.ts              # Redis service (static)
│   │       │                                # ✅ Fase 4 | Redis 7
│   │       │                                # disconnect() method
│   │       │                                # ✅ Fase 9: DB isolation (0,1,2)
│   │       │
│   │       ├── redis.config.ts
│   │       │                                # ✅ Fase 4
│   │       │
│   │       └── RedisRateLimiterService.ts
│   │                                        # ✅ Fase 3 | Token bucket
│   │
│   ├── 📂 shared/                   # SHARED LAYER
│   │   ├── 📂 errors/
│   │   │   └── AppError.ts          # Custom errors
│   │   │                            # ✅ Fase 2 | HTTP status codes
│   │   │
│   │   └── 📂 utils/
│   │       └── logger.ts            # Winston logger
│   │                                # ✅ Fase 2
│   │                                # ✅ Fase 15: paths absolutos (/app/logs)
│   │
│   ├── 📂 config/                   # Configurações
│   │   ├── env.ts                   # Environment variables
│   │   │                            # ✅ Fase 2
│   │   │                            # ✅ Fase 10: export único (fix)
│   │   │
│   │   └── logger.ts                # Winston config
│   │                                # ✅ Fase 2
│   │                                # ✅ Fase 15: paths absolutos
│   │
│   └── server.ts                    # Express app setup
│                                    # ✅ Fase 2
│                                    # ✅ Fase 15: rotas registradas
│
├── 📂 dist/                         # TypeScript build output (gitignored)
│   ├── api/
│   ├── config/
│   ├── core/
│   ├── infrastructure/
│   ├── shared/
│   └── server.js                    # Entry point compilado
│                                    # ✅ Build: 0 erros (Fase 18)
│
├── 📂 tests/                        # Suite de testes
│   │                                # ✅ Fases 7A-7D: Testing completo
│   │                                # ✅ Sprint 1: 22/22 testes passando
│   │
│   ├── 📂 unit/                     # Unit tests
│   │   ├── 📂 controllers/
│   │   │   ├── user.controller.test.ts
│   │   │   │                        # ✅ Fase 7A
│   │   │   │
│   │   │   └── api-key.controller.test.ts   # ⭐ NOVO
│   │   │                            # ✅ Sprint 1 | 7 endpoints
│   │   │
│   │   ├── 📂 services/
│   │   │   ├── password.service.test.ts
│   │   │   │                        # ✅ Fase 7A
│   │   │   │
│   │   │   ├── subscription.service.test.ts
│   │   │   │                        # ✅ Fase 7A
│   │   │   │
│   │   │   ├── token.service.test.ts
│   │   │   │                        # ✅ Fase 7A
│   │   │   │
│   │   │   ├── user.service.test.ts
│   │   │   │                        # ✅ Fase 7A
│   │   │   │
│   │   │   ├── api-key.service.test.ts      # ⭐ NOVO
│   │   │   │                        # ✅ Sprint 1
│   │   │   │
│   │   │   └── usage-tracking.service.test.ts # ⭐ NOVO
│   │   │                            # ✅ Sprint 1
│   │   │
│   │   └── 📂 validators/
│   │       ├── user.validator.test.ts
│   │       │                        # ✅ Fase 7A
│   │       │
│   │       └── api-key.validator.test.ts    # ⭐ NOVO
│   │                                # ✅ Sprint 1
│   │
│   ├── 📂 integration/              # Integration tests
│   │   └── 📂 api/
│   │       ├── auth.test.ts
│   │       │                        # ✅ Fase 7B
│   │       │
│   │       ├── health.test.ts
│   │       │                        # ✅ Fase 7B
│   │       │
│   │       ├── plans.test.ts
│   │       │                        # ✅ Fase 7B
│   │       │
│   │       ├── users.test.ts
│   │       │                        # ✅ Fase 7B
│   │       │
│   │       └── api-keys.test.ts     # ⭐ NOVO - Sprint 1
│   │                                # ✅ 7 endpoints testados
│   │                                # ✅ X-API-Key auth
│   │                                # ✅ Usage tracking
│   │
│   ├── 📂 e2e/                      # E2E tests
│   │   ├── auth-flow.test.ts
│   │   │                            # ✅ Fase 7C
│   │   │
│   │   ├── subscription-flow.test.ts
│   │   │                            # ✅ Fase 7C
│   │   │
│   │   ├── user-flow.test.ts
│   │   │                            # ✅ Fase 7C
│   │   │
│   │   └── api-key-lifecycle.test.ts # ⭐ NOVO - Sprint 1
│   │                                # ✅ Create → Use → Rotate → Revoke
│   │
│   ├── 📂 __mocks__/
│   │   ├── database.mock.ts
│   │   └── cache.mock.ts
│   │
│   ├── jest.setup.js
│   └── .env.test
│
├── 📂 scripts/                      # 120+ automation scripts
│   │
│   ├── 📂 build-fixes/              # 26 scripts (TypeScript build)
│   │   ├── fix-typescript-errors.sh
│   │   │                            # ✅ Fase 10
│   │   │
│   │   ├── fix-services-static.sh
│   │   │                            # ✅ Fase 10
│   │   │
│   │   └── ...
│   │
│   ├── 📂 deployment/               # 70+ scripts (Kubernetes/Docker)
│   │   ├── deploy-api-k8s.sh
│   │   │                            # ✅ Fase 11
│   │   │
│   │   ├── diagnose-crashloop.sh
│   │   │                            # ✅ Fase 11
│   │   │
│   │   ├── fix-database-credentials.sh
│   │   │                            # ✅ Fase 12
│   │   │
│   │   ├── rebuild-no-cache.sh      # ⭐ CRÍTICO
│   │   │                            # ✅ Fase 25: Build sem cache
│   │   │
│   │   ├── force-new-image.sh       # ⭐ CRÍTICO
│   │   │                            # ✅ Fase 25: Force K3s fresh image
│   │   │
│   │   └── 📂 ingress/              # Ingress scripts (Fase 16)
│   │       ├── deploy-ingress.sh
│   │       ├── rollback-ingress.sh
│   │       ├── test-ingress.sh
│   │       └── validate-phase16-light.sh
│   │
│   ├── 📂 docker/                   # 10 scripts (Docker management)
│   │   ├── start.sh
│   │   │                            # ✅ Fase 8
│   │   │
│   │   ├── stop.sh
│   │   │                            # ✅ Fase 8
│   │   │
│   │   ├── logs.sh
│   │   │                            # ✅ Fase 8
│   │   │
│   │   ├── health.sh
│   │   │                            # ✅ Fase 8
│   │   │
│   │   └── ...
│   │
│   ├── 📂 database/                 # Database scripts
│   │   ├── apply-migrations.sh      # TypeORM migrations
│   │   │                            # ✅ Fase 4
│   │   │
│   │   ├── apply-sql-direct.sh      # ⭐ NOVO - SQL direto
│   │   │                            # ✅ Fase 19: Low RAM strategy
│   │   │                            # Tempo: <1s vs 5+ min
│   │   │
│   │   ├── safe-migration-check.sh  # ⭐ NOVO - Pre-flight
│   │   │                            # ✅ Fase 19: Diagnostics
│   │   │
│   │   └── backup.sh
│   │                                # ✅ Fase 4
│   │
│   ├── 📂 validation/               # ⭐ NOVO - Validation scripts
│   │   ├── validate-api-keys-v2.sh  # Sprint 1 complete validation
│   │   │                            # ✅ Fase 25: 22/22 testes
│   │   │                            # Tests:
│   │   │                            # 1. Health check
│   │   │                            # 2. Register user
│   │   │                            # 3. Login
│   │   │                            # 4. Create API Key
│   │   │                            # 5. List API Keys
│   │   │                            # 6. Get API Key
│   │   │                            # 7. Get usage stats
│   │   │                            # 8. Rotate API Key
│   │   │                            # 9. Revoke API Key
│   │   │                            # 10. X-API-Key auth
│   │   │                            # 11. Delete permanent
│   │   │
│   │   ├── health-check.sh
│   │   │                            # Infra validation
│   │   │
│   │   └── test-api-keys-portforward.sh
│   │                                # Manual testing via port-forward
│   │
│   ├── 📂 motor-hybrid/             # Motor Hybrid scripts (Fase 16)
│   │   ├── build-motor.sh           # ⏳ Build TypeScript (adiado)
│   │   ├── test-motor.sh            # ⏳ Testes (futuro)
│   │   └── README.md
│   │
│   └── 📂 quick-fixes/              # 21 scripts (correções rápidas)
│       ├── fix-all-final.sh         # ✅ Script vencedor (Fase 10)
│       └── ...
│
├── 📂 docs/                         # Documentação
│   ├── 📂 memorandos/               # 32 memorandos completos
│   │   ├── INDEX.md
│   │   │
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
│   │   │
│   │   ├── 20-MEMORANDO_MESTRE-1.md         # Consolidação 1-10
│   │   ├── 21-MEMORANDO_MESTRE-2.md         # Consolidação 11-19
│   │   │
│   │   ├── 22-Fase-17-API_Key_Management+Usage_Tracking.md
│   │   ├── 23-Fase-18-Sprint1-Parte_7+8_Completa.md
│   │   │
│   │   ├── 24-Memorando_Único_v1.0.md       # Primeira consolidação
│   │   │
│   │   ├── 25-Fase-19-Database_Migration+Production_Readiness.md
│   │   ├── 26-Fase-20-Deep_Debugging+Repository_Architecture.md
│   │   ├── 27-Fase-21-Sprint1-API_Key_Management-Fix_Implementation.md
│   │   ├── 28-Fase-22-Sprint1-API_Key_Management-Final_Fixes.md
│   │   ├── 29-Fase-23-VALIDAÇÃO_DOS_MEMORANDOS_27+28.md
│   │   ├── 30-Fase-24-Correções_Api_Management.md
│   │   ├── 31-Fase-25-Api_key_Management_Validação_total.md
│   │   │
│   │   ├── 32-MEMORANDO_UNICO_v2.0.0.md     # Fases 19-25
│   │   └── 33-MEMORANDO_UNICO_v3.0_COMPLETO.md # ⭐ NOVO
│   │                                        # ✅ Todas as 25 fases
│   │                                        # ✅ Histórico completo
│   │                                        # ✅ 12 decisões arquiteturais
│   │                                        # ✅ 10 lições aprendidas
│   │                                        # ✅ Troubleshooting expandido
│   │
│   └── 📂 api/                      # API docs (futuro)
│       └── swagger/                 # OpenAPI 3.0 (Fase 26+)
│
├── 📂 docker/                       # Docker configuration
│   ├── 📂 api/
│   │   └── Dockerfile               # Multi-stage (referência)
│   ├── 📂 nginx/
│   ├── 📂 postgres/
│   └── 📂 redis/
│
├── 📂 infrastructure/kubernetes/     # Kubernetes manifests completos
│   │
│   ├── 01-namespace.yaml             # Namespaces + Quotas
│   │                                # ✅ Fase 9: 5 namespaces
│   │
│   ├── 01-namespace-fixed.yaml       # LimitRanges otimizados
│   │                                # ✅ Fase 9: 25m CPU mínimo
│   │
│   ├── 02-configmaps-secrets.yaml    # Configs por ambiente
│   │                                # ✅ Fase 9
│   │
│   ├── 03-postgres.yaml              # PostgreSQL 3 ambientes
│   │                                # ✅ Fase 9: StatefulSets
│   │
│   ├── 03-postgres-prod-fixed.yaml   # Prod sem sidecar
│   │                                # ✅ Fase 9: Economia RAM
│   │
│   ├── 04-redis-simple-scalable.yaml # Redis Shared Architecture
│   │                                # ✅ Fase 9: DB isolation (0,1,2)
│   │
│   ├── 05-api-deployment.yaml        # API deployment
│   │                                # ✅ Fase 9: 1 container clean
│   │                                # ✅ Fase 25: imagePullPolicy: Never
│   │
│   └── 📂 ingress/                   # Ingress configuration (Fase 16)
│       ├── 01-ingress-staging.yaml          # ✅ APLICADO
│       │                                    # Host: staging.shaka.local
│       │                                    # Versão light (sem CRDs)
│       │
│       ├── 01-ingress-staging.yaml.ORIGINAL # BACKUP com middlewares
│       ├── 02-ingress-dev.yaml              # DEV (não aplicado)
│       ├── 04-middleware-ratelimit.yaml     # Rate limiting básico
│       ├── README.md                         # Documentação completa
│       │
│       └── 📂 .future/                       # Features futuras (Fase 26+)
│           └── 03-middleware-cors.yaml      # CORS avançado
│
├── 📂 backups/                      # Backups automáticos
│   ├── configmap-*-backup-*.yaml
│   ├── deployment-*-backup-*.yaml
│   │
│   └── 📂 ingress/                  # Ingress backups (Fase 16)
│       ├── staging-[timestamp].yaml
│       └── dev-[timestamp].yaml
│
├── 📄 .buildignore                  # Exclusões de build (Fase 16)
│                                    # motor-hybrid/ não compilado
│
├── 📄 Dockerfile                    # Multi-stage Dockerfile
│                                    # ✅ Fase 8
│                                    # ✅ Fase 15: mkdir /app/logs
│                                    # Size: ~267MB (otimizado)
│
├── 📄 docker-compose.yml            # Development
│                                    # ✅ Fase 8
│
├── 📄 docker-compose.prod.yml       # Production
│                                    # ✅ Fase 8
│
├── 📄 .dockerignore                 # Docker ignores
│                                    # ✅ Fase 8
│
├── 📄 package.json                  # Dependencies + scripts
│                                    # ✅ Fase 1
│                                    # Dependencies:
│                                    # - express: 4.x
│                                    # - typeorm: 0.3.17
│                                    # - pg: PostgreSQL driver
│                                    # - redis: 7.x
│                                    # - bcrypt: password hashing
│                                    # - jsonwebtoken: JWT
│                                    # - joi: validation
│                                    # - winston: logging
│
├── 📄 package-lock.json             # Lock file
│                                    # ✅ Fase 1
│
├── 📄 tsconfig.json                 # TypeScript config
│                                    # ✅ Fase 1
│                                    # ✅ Fase 10: Path aliases removidos
│                                    # compilerOptions.paths: {} (vazio)
│
├── 📄 jest.config.js                # Jest config
│                                    # ✅ Fase 7A
│                                    # Sprint 1: 22/22 testes passando
│
├── 📄 .env                          # Environment vars (NÃO COMMITAR)
├── 📄 .env.example                  # Template
├── 📄 .env.test                     # Test environment
├── 📄 .env.docker                   # Docker template
│
├── 📄 .gitignore                    # Git ignores
├── 📄 README.md                     # Main docs
├── 📄 PROJECT_STRUCTURE.md          # Project structure v2.1
├── 📄 estrutura_diretorios.md       # ✅ ESTE ARQUIVO (v4.0)
├── 📄 Makefile                      # Make commands
└── 📄 manage-server.sh              # Server management

═══════════════════════════════════════════════════════════════════════════════

📊 ESTATÍSTICAS DO PROJETO (v4.0)

Status Geral:
├─ Build TypeScript: ✅ 0 erros (Fase 18)
├─ Docker Image: ✅ 267MB (otimizada)
├─ Kubernetes Pods: ✅ 4/7 Running
├─ Database: ✅ 3/3 Connected (PostgreSQL 15)
├─ Cache: ✅ 1/1 Connected (Redis 7)
├─ Sprint 1: ✅ 100% Completo (22/22 testes)
└─ Production Ready: ✅ SIM

Arquivos:
├─ Controllers: 4 (auth, user, api-key, plan)
├─ Services: 8 (auth, password, token, user, subscription, api-key, usage-tracking, rate-limiter)
├─ Entities: 4 (User, Subscription, ApiKey, UsageRecord)
├─ Repositories: 5 (Base, User, Subscription, ApiKey, UsageRecord)
├─ Middlewares: 8 (authenticate, apiKeyAuth, trackUsage, errorHandler, etc)
├─ Routes: 6 (auth, user, plan, api-keys, health, index)
├─ Validators: 3 (auth, user, api-key)
├─ Migrations: 4 (users, subscriptions, api_keys, usage_records)
└─ Scripts: 120+ (automation)

Testing:
├─ Unit Tests: 9 arquivos
├─ Integration Tests: 5 arquivos
├─ E2E Tests: 4 arquivos
└─ Status: ✅ 22/22 passando (100%)

Features Implementadas:
├─ ✅ Autenticação JWT (Fase 3)
├─ ✅ Multi-tenancy (4 planos) (Fase 3)
├─ ✅ API Key Management (7 endpoints) (Fases 17-25)
├─ ✅ Usage Tracking & Analytics (Fase 17)
├─ ✅ Rate Limiting (por plano + por API key) (Fases 3, 17)
├─ ✅ Containerização Docker (Fase 8)
├─ ✅ Kubernetes Production (Fase 9)
└─ ⏳ Ingress Light (Fase 16 - sem middlewares CRD)

Fases Concluídas:
├─ Fases 1-8: Fundação (estrutura, services, database, tests, docker)
├─ Fases 9-15: Kubernetes (infra, deploys, troubleshooting, staging)
├─ Fases 16: Ingress + Motor Hybrid (versão light)
├─ Fases 17-18: Sprint 1 inicial (API Keys + Usage Tracking)
└─ Fases 19-25: Correções e validação (100% funcional)

Memorandos:
├─ Implementação: 28 memorandos (Fases 1-25)
├─ Consolidação: 4 memorandos (Mestres 1, 2, Único v1, v2)
└─ Único v3.0: ✅ COMPLETO (todas as 25 fases)

Próximos Passos:
├─ Fase 26: Observabilidade (Prometheus + Grafana)
├─ Fase 27: TLS/HTTPS (Cert-Manager + Let's Encrypt)
├─ Fase 28: CI/CD Pipeline (GitHub Actions)
├─ Fase 29: Rate Limiting Avançado
└─ Fase 30: Stripe Integration

═══════════════════════════════════════════════════════════════════════════════

🔑 DECISÕES ARQUITETURAIS CRÍTICAS

1. Static Methods (Fase 3)
   └─ Services usam static methods (simplicidade > DI)

2. Path Aliases Removed (Fase 10)
   └─ Imports relativos (runtime compatibility)

3. Redis Shared Architecture (Fase 9)
   └─ 1 Redis, DB isolation: 0=dev, 1=staging, 2=prod

4. PostgreSQL sem Backup Sidecar (Fase 9)
   └─ CronJob para backups (economia de RAM)

5. Logger com Paths Absolutos (Fase 15)
   └─ /app/logs (container compatibility)

6. RequestLogger req.originalUrl (Fase 14)
   └─ Path completo nos logs

7. Database Migration via SQL Direto (Fase 19) ⭐
   └─ Performance em RAM limitada (<1s vs 5+ min)

8. Lazy Initialization Repositories (Fase 20) ⭐
   └─ Getter pattern com caching

9. TypeORM Column Mappings Snake_Case (Fase 25) ⭐
   └─ Mapeamento explícito: api_key_id, response_time_ms

10. No-Cache Docker Builds (Fase 25) ⭐
    └─ Sempre --no-cache para garantir fresh builds

11. Multi-stage Docker Build (Fase 8)
    └─ Imagem 60% menor (~300MB)

12. Ingress Versão Light (Fase 16)
    └─ Sem middlewares CRD (limitação temporária)

═══════════════════════════════════════════════════════════════════════════════

📝 NOTAS IMPORTANTES

- Este arquivo documenta a estrutura REAL do projeto após 25 fases
- Todos os caminhos foram validados no servidor
- Marcações ✅ indicam implementação concluída e testada
- Marcações ⭐ indicam novas features do Sprint 1
- Marcações ⏳ indicam features adiadas para fases futuras
- Versão 4.0 sincronizada com Memorando Único v3.0

Para navegar no projeto:
1. Consulte este arquivo para localização de arquivos
2. Consulte MEMORANDO_UNICO_v3.0_COMPLETO.md para contexto histórico
3. Consulte PROJECT_STRUCTURE.md para visão arquitetural

Última atualização: 2025-12-13
Status: ✅ PRODUCTION READY | Sprint 1 COMPLETO
