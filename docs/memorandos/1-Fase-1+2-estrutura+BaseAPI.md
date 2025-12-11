# 📋 MEMORANDO DE HANDOFF/ONBOARDING - Projeto Shaka API

**Para:** Equipe de Desenvolvimento / Futuro Eu  
**De:** Headmaster CTO Integrador  
**Data:** 25 de Novembro de 2025  
**Assunto:** Estrutura Base e Próximos Passos - Shaka API Multi-Tenant  
**Status:** Fase 1 Completa (Estrutura + API Base)

---

## 🎯 CONTEXTO DO PROJETO

### O Que É o Shaka API?
Uma **API multi-tenant robusta** projetada para escalar de 0 a 1000+ usuários com:
- **3 planos de assinatura** (Starter, Pro, Business)
- **Arquitetura híbrida** (Node.js + Go para processamento pesado)
- **Kubernetes-native** (pronto para deploy em K8s)
- **Rate limiting por plano**
- **Observabilidade completa** (Prometheus + Grafana)

---

## ✅ O QUE FOI FEITO ATÉ AGORA

### Fase 1: Estrutura de Diretórios (CONCLUÍDA ✓)
```bash
shaka-api/
├── src/               # Código-fonte da aplicação
├── k8s/               # Configurações Kubernetes
├── docker/            # Dockerfiles
├── scripts/           # Scripts de automação
├── config/            # Configurações
├── tests/             # Testes automatizados
├── docs/              # Documentação
└── monitoring/        # Prometheus/Grafana configs
```

**Arquivos criados:**
- `.env.example` - Template de variáveis de ambiente
- `Makefile` - Comandos para automação
- `README.md` - Documentação inicial
- `PROJECT_STRUCTURE.md` - Mapa visual do projeto

### Fase 2: API Base (CONCLUÍDA ✓)
**Estrutura criada:**
- ✅ Servidor Express com TypeScript
- ✅ Sistema de rotas (auth, users, plans)
- ✅ Middlewares (autenticação, rate limiting, logging)
- ✅ Controllers para cada domínio
- ✅ Validadores com Joi
- ✅ Sistema de errors customizados
- ✅ Logger com Winston

---

## 🚀 COMO TRABALHAR COM ESTE PROJETO (GUIA PRÁTICO)

### Método de Trabalho: Usando `nano` para Criar Scripts

**Por que usar nano?**
- Terminal pode quebrar com código muito longo
- Scripts permitem replicar passos
- Facilita versionamento e documentação

### Passo a Passo para Criar Novos Arquivos:

#### 1️⃣ Criar um script no nano
```bash
cd ~/shaka-api
nano setup-minha-feature.sh
```

#### 2️⃣ Colar o conteúdo do script
- Copie todo o código do script
- Cole no nano (Ctrl+Shift+V ou botão direito)
- **Importante:** Verifique se colou completamente

#### 3️⃣ Salvar e sair
```bash
# Salvar: Ctrl+O
# Confirmar: Enter
# Sair: Ctrl+X
```

#### 4️⃣ Dar permissão de execução
```bash
chmod +x setup-minha-feature.sh
```

#### 5️⃣ Executar o script
```bash
./setup-minha-feature.sh
```

#### 6️⃣ Verificar se funcionou
```bash
# Listar arquivos criados
ls -la src/core/services/

# Ver conteúdo de um arquivo
cat src/core/services/auth/AuthService.ts
```

---

## 📦 O QUE FALTA IMPLEMENTAR (PRÓXIMOS PASSOS)

### **Prioridade 1: Services (Lógica de Negócio)**
Criar os serviços que implementam as regras de negócio:

```
src/core/services/
├── auth/
│   ├── AuthService.ts          # Login, registro, JWT
│   └── UserService.ts          # CRUD de usuários
├── subscription/
│   └── SubscriptionService.ts  # Gestão de planos
└── rate-limiter/
    └── RateLimiterService.ts   # Controle de rate limiting
```

**O que cada service faz:**
- **AuthService**: Autenticação (login/registro/tokens)
- **UserService**: Gerenciamento de usuários
- **SubscriptionService**: Controle de planos e billing
- **RateLimiterService**: Limita requisições por plano

---

### **Prioridade 2: Database Layer**
Configurar conexões e models:

```
src/infrastructure/database/
├── connection.ts               # Conexão PostgreSQL
├── repositories/
│   ├── UserRepository.ts       # CRUD de users
│   └── SubscriptionRepository.ts
└── migrations/
    ├── 001_create_users.sql
    └── 002_create_subscriptions.sql
```

**Tecnologias:**
- **PostgreSQL** (dados principais)
- **TypeORM** ou **Prisma** (ORM)

---

### **Prioridade 3: Cache Layer (Redis)**
Implementar cache para performance:

```
src/infrastructure/cache/
├── redis.ts                    # Conexão Redis
└── CacheService.ts             # Abstração do cache
```

**Usos do Redis:**
- Cache de tokens JWT
- Rate limiting (contadores)
- Sessions de usuários

---

### **Prioridade 4: Domain Entities**
Criar as entidades de domínio:

```
src/domain/entities/
├── User.ts                     # Entidade usuário
├── Subscription.ts             # Entidade assinatura
└── Usage.ts                    # Entidade uso da API
```

---

### **Prioridade 5: Docker & Docker Compose**
Containerizar a aplicação:

```
docker/
├── api/Dockerfile              # Dockerfile da API
├── postgres/Dockerfile
└── redis/Dockerfile

docker-compose.yml              # Orquestração local
```

---

### **Prioridade 6: Kubernetes Manifests**
Preparar deploy em K8s:

```
k8s/base/
├── api/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── hpa.yaml               # Auto-scaling
├── postgres/
│   ├── statefulset.yaml
│   └── pvc.yaml
└── redis/
    ├── deployment.yaml
    └── service.yaml
```

---

## 🛠️ COMANDOS ÚTEIS DO MAKEFILE

```bash
# Ver todos os comandos disponíveis
make help

# Iniciar ambiente de desenvolvimento
make dev

# Build das imagens Docker
make build

# Ver logs da API
make logs

# Limpar ambiente
make clean

# Deploy no Kubernetes (dev/staging/prod)
make k8s-apply-dev
make k8s-apply-staging
make k8s-apply-prod
```

---

## 📚 PRÓXIMO SCRIPT A CRIAR: Services Layer

### Script: `setup-services.sh`
**O que ele vai criar:**
1. **AuthService** - Autenticação completa
2. **UserService** - CRUD de usuários
3. **RateLimiterService** - Rate limiting por plano
4. **SubscriptionService** - Gestão de planos

**Como proceder:**
```bash
nano setup-services.sh
# [Colar o script que vou te passar]
# Ctrl+O, Enter, Ctrl+X
chmod +x setup-services.sh
./setup-services.sh
```

---

## 🎓 CONCEITOS IMPORTANTES PARA ENTENDER

### 1. **Clean Architecture (Arquitetura Limpa)**
```
┌─────────────────────────────────────┐
│   API Layer (Controllers/Routes)   │ ← Interface com usuário
├─────────────────────────────────────┤
│   Core Layer (Services/UseCases)   │ ← Lógica de negócio
├─────────────────────────────────────┤
│   Domain Layer (Entities/Models)   │ ← Regras de domínio
├─────────────────────────────────────┤
│   Infrastructure (DB/Cache/Queue)  │ ← Integrações externas
└─────────────────────────────────────┘
```

**Por que essa estrutura?**
- **Testabilidade**: Cada camada pode ser testada isoladamente
- **Manutenibilidade**: Fácil localizar e modificar código
- **Escalabilidade**: Adicionar features sem quebrar o existente

---

### 2. **Multi-Tenant (Multi-Inquilino)**
Significa que **múltiplos clientes** usam a mesma infraestrutura, mas com **dados isolados**.

**Exemplo:**
- Cliente A (Starter) → 100 req/dia
- Cliente B (Pro) → 1000 req/dia
- Cliente C (Business) → 10000 req/dia

Todos usam a mesma API, mas com **limites diferentes**.

---

### 3. **Rate Limiting (Limitação de Taxa)**
Controla quantas requisições um usuário pode fazer.

**Implementação:**
```typescript
// Pseudocódigo
async checkLimit(userId, plan) {
  const limit = PLAN_LIMITS[plan]; // 100, 1000 ou 10000
  const current = await redis.get(`rate:${userId}`);
  
  if (current >= limit) {
    throw new Error('Rate limit exceeded');
  }
  
  await redis.incr(`rate:${userId}`);
  return true;
}
```

---

### 4. **JWT (JSON Web Token)**
Token seguro para autenticação.

**Fluxo:**
1. Usuário faz login → API retorna JWT
2. Requisições futuras → Header: `Authorization: Bearer <JWT>`
3. API valida JWT → Libera acesso

---

## 🔐 VARIÁVEIS DE AMBIENTE IMPORTANTES

Sempre configure o `.env` antes de rodar:

```bash
# Copiar template
cp .env.example .env

# Editar (use nano ou vi)
nano .env
```

**Variáveis críticas:**
- `JWT_SECRET` - NUNCA use o padrão em produção
- `DB_PASSWORD` - Senha forte
- `REDIS_PASSWORD` - Senha forte
- `NODE_ENV` - development/staging/production

---

## 🐛 TROUBLESHOOTING (Problemas Comuns)

### Problema 1: Script não executa
```bash
# Solução: Dar permissão
chmod +x nome-do-script.sh
```

### Problema 2: Porta já em uso
```bash
# Ver o que está usando a porta
lsof -i :3000

# Matar o processo
kill -9 <PID>
```

### Problema 3: Docker não sobe
```bash
# Ver logs
docker-compose logs

# Recriar containers
docker-compose down -v
docker-compose up -d --build
```

### Problema 4: Makefile não funciona
```bash
# Makefiles usam TABS, não espaços
# Se copiou de algum lugar, refaça os tabs
```

---

## 📋 CHECKLIST DE PROGRESSO

### Fase 1: Estrutura Base
- [x] Diretórios criados
- [x] Arquivos de config (.env, Makefile, etc)
- [x] Documentação inicial

### Fase 2: API Base
- [x] Server.ts
- [x] Routes
- [x] Middlewares
- [x] Controllers
- [x] Validators
- [x] Error handling

### Fase 3: Services (PRÓXIMO)
- [ ] AuthService
- [ ] UserService
- [ ] RateLimiterService
- [ ] SubscriptionService

### Fase 4: Infrastructure
- [ ] Database connection
- [ ] Repositories
- [ ] Migrations
- [ ] Redis connection
- [ ] Cache service

### Fase 5: Domain
- [ ] User entity
- [ ] Subscription entity
- [ ] Usage entity

### Fase 6: Docker
- [ ] Dockerfiles
- [ ] docker-compose.yml
- [ ] Teste local

### Fase 7: Kubernetes
- [ ] Manifests base
- [ ] Overlays (dev/staging/prod)
- [ ] Deploy em cluster

### Fase 8: Monitoring
- [ ] Prometheus
- [ ] Grafana dashboards
- [ ] Alertas

---

## 🎯 PRÓXIMA SESSÃO: O QUE FAZER

1. **Ler este memorando completamente**
2. **Verificar se os scripts anteriores rodaram:**
   ```bash
   cd ~/shaka-api
   ls -la src/
   cat src/server.ts
   ```

3. **Pedir o próximo script:**
   - "Me passe o script `setup-services.sh`"
   
4. **Executar seguindo o método nano:**
   ```bash
   nano setup-services.sh
   # [Colar script]
   # Ctrl+O, Enter, Ctrl+X
   chmod +x setup-services.sh
   ./setup-services.sh
   ```

5. **Testar se funcionou:**
   ```bash
   cat src/core/services/auth/AuthService.ts
   ```

---

## 💡 DICAS PARA INICIANTES

### 1. **Não tenha medo de errar**
- Scripts podem ser reexecutados
- Git pode reverter mudanças
- Docker pode recriar containers

### 2. **Use o método nano sempre que:**
- Arquivo > 50 linhas
- Código com caracteres especiais
- Terminal trava com Ctrl+V

### 3. **Leia os logs sempre**
```bash
# Logs ajudam a debugar
docker-compose logs -f api
```

### 4. **Teste incrementalmente**
- Não crie tudo de uma vez
- Teste cada script antes do próximo
- Valide se os arquivos foram criados

### 5. **Documente suas mudanças**
```bash
# Mantenha um log pessoal
nano CHANGELOG.md

# Exemplo:
# 2025-11-25 - Estrutura base criada
# 2025-11-25 - API routes implementadas
```

---

## 📞 RECURSOS DE APOIO

### Documentação Oficial:
- **Express.js**: https://expressjs.com
- **TypeScript**: https://www.typescriptlang.org
- **Docker**: https://docs.docker.com
- **Kubernetes**: https://kubernetes.io/docs

### Comandos Linux Essenciais:
```bash
ls -la          # Listar arquivos
cd <dir>        # Mudar diretório
cat <file>      # Ver conteúdo
nano <file>     # Editar arquivo
chmod +x        # Dar permissão de execução
./script.sh     # Executar script
```

---

## ✅ CONCLUSÃO

Você está no **caminho certo**! 

**O que já temos:**
- ✅ Estrutura profissional
- ✅ API base funcional
- ✅ Padrões de código
- ✅ Documentação clara

**Próximos passos:**
1. Implementar Services
2. Conectar Database
3. Configurar Redis
4. Dockerizar aplicação

**Tempo estimado para MVP:**
- Services: 2-3 horas
- Database: 1-2 horas
- Docker: 1 hora
- **Total: ~1 semana** (trabalhando algumas horas/dia)

---

**Assinatura Digital:**  
🔷 Headmaster CTO Integrador  
📅 25/11/2025  12:44
🚀 Projeto: Shaka API v1.0  
📍 Status: Fase 2/8 Completa

---

**P.S.:** Mantenha este documento sempre à mão. Ele é seu **mapa do tesouro** para desenvolver a Shaka API! 🗺️
