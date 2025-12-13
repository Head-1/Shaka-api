# 📋 MEMORANDO DE HANDOFF/ONBOARDING - SESSION 31 API KEY MANAGEMENT 100% VALIDADA

## 🎯 INFORMAÇÕES DA SESSÃO

**Data:** 2025-12-11  
**Horário:** 07:04 - 07:57 (53 minutos)            
**Responsável:** Headmaster  
**Status:** ✅ CONCLUÍDO COM SUCESSO  
**Resultado:** 90% → 100% (22/22 testes passando)

---

## 📝 RESUMO EXECUTIVO

### Situação Inicial
- **Status:** 90% funcional (19/21 testes passando)
- **Problemas:** 2 falhas críticas em endpoints essenciais
- **Impacto:** Sistema não production-ready

### Resultado Final
- **Status:** 100% funcional (22/22 testes passando)
- **Problemas:** Zero falhas
- **Impacto:** Sistema completamente operacional e production-ready

### Métricas da Sessão
- ⏱️ **Tempo Total:** 53 minutos
- 🐛 **Bugs Resolvidos:** 5 problemas identificados e corrigidos
- 📝 **Arquivos Modificados:** 3 arquivos principais
- 🔄 **Deploys:** 4 iterações de rebuild/deploy
- 🎯 **Taxa de Sucesso:** +10 pontos percentuais (90% → 100%)

---

## 🔍 1. DIAGNÓSTICO INICIAL

### 1.1 Validação Pré-Correção

**Comando Executado:**
```bash
~/shaka-api/scripts/validate-api-keys-v2.sh
```

**Resultado:**
```
Taxa de Sucesso: 90% (19/21 testes)
⚠ Sistema funcionando com ressalvas

Falhas Identificadas:
✗ TESTE 6: ESTATÍSTICAS DE USO (HTTP 500)
✗ TESTE 10: AUTENTICAÇÃO X-API-KEY (HTTP 401)
```

### 1.2 Análise dos Logs

**Comando de Investigação:**
```bash
kubectl logs -n shaka-staging -l app=shaka-api --tail=200 | grep -i "error\|usage\|metadata"
```

**Erros Encontrados:**

#### Erro 1: UsageRecordEntity Não Reconhecida
```
[error]: [UsageTrackingService] Error getting stats:
[error]: No metadata for "UsageRecordEntity" was found.
```

**Causa Raiz:** Entity não registrada no TypeORM DataSource

#### Erro 2: Logger com Caminho Incorreto
```javascript
const logger_1 = __importDefault(require("../../shared/utils/logger"));
//                                          ❌ Caminho errado
```

**Causa Raiz:** Middleware usando caminho antigo do logger

---

## 🛠️ 2. INVESTIGAÇÃO PROFUNDA

### 2.1 Verificação no Pod em Execução

**Objetivo:** Confirmar se os arquivos no pod estavam atualizados

**Comandos Executados:**
```bash
POD_NAME=$(kubectl get pods -n shaka-staging -l app=shaka-api -o jsonpath='{.items[0].metadata.name}')

# Verificar config.js
kubectl exec -n shaka-staging $POD_NAME -- cat /app/dist/infrastructure/database/config.js | grep -i "usage"

# Verificar apiKeyAuth.js
kubectl exec -n shaka-staging $POD_NAME -- cat /app/dist/api/middlewares/apiKeyAuth.js | grep -i "logger"
```

**Descoberta Crítica:**
```javascript
// config.js no pod (ANTIGO)
entities: [UserEntity_1.UserEntity, SubscriptionEntity_1.SubscriptionEntity, ApiKeyEntity_1.ApiKeyEntity]
//        ❌ FALTANDO UsageRecordEntity!

// apiKeyAuth.js no pod (ANTIGO)
const logger_1 = __importDefault(require("../../shared/utils/logger"));
//                                          ❌ Caminho errado!
```

**Conclusão:** Os pods estavam usando imagens antigas do registry, não as correções aplicadas.

### 2.2 Análise do Schema do Banco de Dados

**Comando:**
```bash
kubectl exec -n shaka-staging postgres-0 -- psql -U shaka_staging -d shaka_staging -c "\d usage_records"
```

**Schema Real da Tabela:**
```sql
                                Table "public.usage_records"
      Column      |            Type             | Collation | Nullable |      Default       
------------------+-----------------------------+-----------+----------+--------------------
 id               | uuid                        |           | not null | uuid_generate_v4()
 user_id          | uuid                        |           | not null | 
 api_key_id       | uuid                        |           | not null | 
 endpoint         | character varying(255)      |           | not null | 
 method           | character varying(10)       |           | not null | 
 status_code      | integer                     |           | not null | 
 response_time_ms | integer                     |           |          |  ← IMPORTANTE!
 ip_address       | inet                        |           |          | 
 user_agent       | text                        |           |          | 
 timestamp        | timestamp without time zone |           | not null | now()
 error_message    | text                        |           |          |  ← IMPORTANTE!
```

**Descobertas:**
1. ✅ Coluna é `response_time_ms` (não `response_time`)
2. ✅ Coluna `error_message` existe no banco
3. ✅ Todas as colunas usam `snake_case`

---

## 🔧 3. CORREÇÕES IMPLEMENTADAS

### 3.1 Correção 1: Registrar UsageRecordEntity

**Arquivo:** `src/infrastructure/database/config.ts`

**Problema:** Entity não registrada no TypeORM

**Solução:**
```typescript
// ANTES
import { UserEntity } from './entities/UserEntity';
import { SubscriptionEntity } from './entities/SubscriptionEntity';
import { ApiKeyEntity } from './entities/ApiKeyEntity';

entities: [
  UserEntity, 
  SubscriptionEntity, 
  ApiKeyEntity
],

// DEPOIS
import { UserEntity } from './entities/UserEntity';
import { SubscriptionEntity } from './entities/SubscriptionEntity';
import { ApiKeyEntity } from './entities/ApiKeyEntity';
import { UsageRecordEntity } from './entities/UsageRecordEntity';  // ← ADICIONADO

entities: [
  UserEntity, 
  SubscriptionEntity, 
  ApiKeyEntity,
  UsageRecordEntity  // ← ADICIONADO
],
```

**Resultado:** TypeORM agora reconhece a entity UsageRecordEntity

### 3.2 Correção 2: Corrigir Caminho do Logger

**Arquivo:** `src/api/middlewares/apiKeyAuth.ts`

**Problema:** Import do logger usando caminho antigo

**Solução:**
```typescript
// ANTES
import logger from '../../shared/utils/logger';  // ❌ Caminho errado

// DEPOIS
import logger from '../../config/logger';  // ✅ Caminho correto
```

**Resultado:** Middleware de autenticação agora loga corretamente

### 3.3 Correção 3: Mappings Snake_Case Completos

**Arquivo:** `src/infrastructure/database/entities/UsageRecordEntity.ts`

**Problema:** Campos sem mapeamento para snake_case do banco

**Solução Completa:**
```typescript
import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  Index
} from 'typeorm';

@Entity('usage_records')
@Index(['apiKeyId', 'timestamp'])
@Index(['userId', 'timestamp'])
@Index(['timestamp'])
export class UsageRecordEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  // ✅ CORRIGIDO: Mapeamento snake_case
  @Column({ name: 'api_key_id', type: 'uuid' })
  apiKeyId!: string;

  // ✅ CORRIGIDO: Mapeamento snake_case
  @Column({ name: 'user_id', type: 'uuid' })
  userId!: string;

  @Column({ type: 'varchar', length: 200 })
  endpoint!: string;

  @Column({ type: 'varchar', length: 10 })
  method!: string;

  // ✅ CORRIGIDO: Mapeamento snake_case
  @Column({ name: 'status_code', type: 'int' })
  statusCode!: number;

  // ✅ CORRIGIDO: Nome correto da coluna response_time_ms
  @Column({ name: 'response_time_ms', type: 'int' })
  responseTime!: number;

  // ✅ CORRIGIDO: Mapeamento snake_case
  @Column({ name: 'ip_address', type: 'varchar', length: 45, nullable: true })
  ipAddress?: string;

  // ✅ CORRIGIDO: Mapeamento snake_case
  @Column({ name: 'user_agent', type: 'text', nullable: true })
  userAgent?: string;

  // ✅ CORRIGIDO: Mapeamento snake_case
  @Column({ name: 'error_message', type: 'text', nullable: true })
  errorMessage?: string;

  @CreateDateColumn()
  timestamp!: Date;
}
```

**Mudanças Críticas:**
1. ✅ `apiKeyId` → `api_key_id`
2. ✅ `userId` → `user_id`
3. ✅ `statusCode` → `status_code`
4. ✅ `responseTime` → `response_time_ms` (nome correto!)
5. ✅ `ipAddress` → `ip_address`
6. ✅ `userAgent` → `user_agent`
7. ✅ `errorMessage` → `error_message`

### 3.4 Correção 4: Coluna error_message no Banco

**Problema:** Coluna já existia mas foi verificada por segurança

**Comando Executado:**
```sql
ALTER TABLE usage_records ADD COLUMN IF NOT EXISTS error_message TEXT;
```

**Resultado:**
```
NOTICE: column "error_message" of relation "usage_records" already exists, skipping
ALTER TABLE
```

**Conclusão:** Coluna já estava presente, mas a verificação garantiu consistência.

---

## 🚀 4. PROCESSO DE DEPLOY

### 4.1 Entendendo o Problema de Deploy

**Descoberta:** Copiar arquivos manualmente com `kubectl cp` não funciona porque:
- Node.js usa cache dos módulos carregados
- O pod não recarrega automaticamente
- K3s usa containerd, não Docker diretamente

**Solução Correta:** Rebuild completo da imagem Docker

### 4.2 Pipeline de Deploy Completo

#### Passo 1: Build Local
```bash
cd ~/shaka-api
npm run build
```

#### Passo 2: Build da Imagem Docker
```bash
docker build -t shaka-api:latest .
```

#### Passo 3: Export da Imagem
```bash
docker save shaka-api:latest -o /tmp/shaka-api-latest.tar
```

#### Passo 4: Import no K3s Containerd
```bash
sudo k3s ctr images import /tmp/shaka-api-latest.tar
```

#### Passo 5: Verificar Import
```bash
sudo k3s ctr images ls | grep shaka-api
```

**Output Esperado:**
```
docker.io/library/shaka-api:latest    application/vnd.oci.image.manifest.v1+json
```

#### Passo 6: Forçar Recreação dos Pods
```bash
kubectl delete pod -n shaka-staging -l app=shaka-api
```

#### Passo 7: Aguardar Novo Pod
```bash
kubectl wait --for=condition=ready pod -n shaka-staging -l app=shaka-api --timeout=60s
```

#### Passo 8: Verificar Arquivos no Novo Pod
```bash
POD_NAME=$(kubectl get pods -n shaka-staging -l app=shaka-api -o jsonpath='{.items[0].metadata.name}')

echo "Verificando UsageRecordEntity no config.js:"
kubectl exec -n shaka-staging $POD_NAME -- cat /app/dist/infrastructure/database/config.js | grep -c "UsageRecordEntity"

echo "Verificando logger no apiKeyAuth.js:"
kubectl exec -n shaka-staging $POD_NAME -- cat /app/dist/api/middlewares/apiKeyAuth.js | grep "config/logger"
```

**Output Esperado:**
```
Verificando UsageRecordEntity no config.js:
2  ← ✅ (1 import + 1 no array)

Verificando logger no apiKeyAuth.js:
const logger_1 = require("../../config/logger");  ← ✅ Correto!
```

### 4.3 Script Automatizado de Deploy

**Arquivo:** `scripts/rebuild-and-deploy.sh`

```bash
#!/bin/bash
set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 REBUILD E DEPLOY - SHAKA API"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 1. Build TypeScript
echo ""
echo "▸ Building TypeScript..."
cd ~/shaka-api
npm run build

# 2. Build Docker Image
echo ""
echo "▸ Building Docker Image..."
docker build -t shaka-api:latest .

# 3. Export Image
echo ""
echo "▸ Exporting Image..."
docker save shaka-api:latest -o /tmp/shaka-api-latest.tar

# 4. Import to K3s
echo ""
echo "▸ Importing to K3s..."
sudo k3s ctr images import /tmp/shaka-api-latest.tar

# 5. Verify Import
echo ""
echo "▸ Verifying Import..."
sudo k3s ctr images ls | grep shaka-api

# 6. Delete Old Pods
echo ""
echo "▸ Deleting Old Pods..."
kubectl delete pod -n shaka-staging -l app=shaka-api

# 7. Wait for New Pod
echo ""
echo "▸ Waiting for New Pod..."
kubectl wait --for=condition=ready pod -n shaka-staging -l app=shaka-api --timeout=60s

# 8. Verify New Pod
echo ""
echo "▸ Verifying New Pod..."
POD_NAME=$(kubectl get pods -n shaka-staging -l app=shaka-api -o jsonpath='{.items[0].metadata.name}')
echo "Pod: $POD_NAME"

echo ""
echo "✓ Deploy Completo!"
echo ""
echo "Execute a validação:"
echo "  ~/shaka-api/scripts/validate-api-keys-v2.sh"
```

**Uso:**
```bash
chmod +x ~/shaka-api/scripts/rebuild-and-deploy.sh
~/shaka-api/scripts/rebuild-and-deploy.sh
```

---

## 🎯 5. VALIDAÇÃO FINAL

### 5.1 Comando de Validação
```bash
~/shaka-api/scripts/validate-api-keys-v2.sh
```

### 5.2 Resultado Final - 100% SUCCESS! 🎉

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 VALIDAÇÃO API KEY MANAGEMENT - V2
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

▸ TESTE 1: REGISTRO DE USUÁRIO
✓ Registro bem-sucedido (HTTP 201)

▸ TESTE 2: LOGIN
✓ Login bem-sucedido (HTTP 200)
✓ Token JWT extraído

▸ TESTE 3: CRIAR API KEY
✓ API Key criada (HTTP 201)
✓ Key ID extraído
✓ Key extraída

▸ TESTE 4: LISTAR API KEYS
✓ Listagem bem-sucedida (HTTP 200)
✓ Keys retornadas na listagem

▸ TESTE 5: DETALHES DA API KEY
✓ Detalhes obtidos (HTTP 200)
✓ ID correto
✓ Key ativa

▸ TESTE 6: ESTATÍSTICAS DE USO  ← ✅ CORRIGIDO!
✓ Estatísticas obtidas (HTTP 200)
✓ Campo totalRequests presente

▸ TESTE 7: ROTACIONAR API KEY
✓ Key rotacionada (HTTP 200)
✓ Nova key com ID diferente

▸ TESTE 8: REVOGAR API KEY
✓ Key revogada (HTTP 200)
✓ Key marcada como inativa

▸ TESTE 9: DELETE PERMANENTE
✓ Key deletada permanentemente (HTTP 200)
✓ Key não existe mais (HTTP 404)

▸ TESTE 10: AUTENTICAÇÃO X-API-KEY  ← ✅ CORRIGIDO!
✓ Key de teste criada
✓ Autenticação X-API-Key funcionando (HTTP 200)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RELATÓRIO FINAL
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Resumo:
  Total:    22
  Passou:   22
  Falhou:   0

Taxa de Sucesso: 100%

🎉 SISTEMA 100% FUNCIONAL!

✅ Todos os 7 Endpoints Validados:
  • POST   /api/v1/keys                  - Criar
  • GET    /api/v1/keys                  - Listar
  • GET    /api/v1/keys/:id              - Detalhes
  • GET    /api/v1/keys/:id/usage        - Estatísticas ⭐
  • POST   /api/v1/keys/:id/rotate       - Rotacionar ⭐
  • DELETE /api/v1/keys/:id              - Revogar ⭐
  • DELETE /api/v1/keys/:id/permanent    - Deletar ⭐

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Timestamp: 2025-12-11 07:57:38
Namespace: shaka-staging
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 5.3 Comparativo Antes/Depois

| Métrica | Antes | Depois | Diferença |
|---------|-------|--------|-----------|
| Taxa de Sucesso | 90% | 100% | +10% |
| Testes Passando | 19/21 | 22/22 | +3 |
| Testes Falhando | 2 | 0 | -2 |
| HTTP 500 Errors | 1 | 0 | -1 |
| HTTP 401 Errors | 1 | 0 | -1 |
| Status | ⚠️ Com Ressalvas | ✅ Production Ready | 🎉 |

---

## 📚 6. LIÇÕES APRENDIDAS

### 6.1 TypeORM Entity Registration

**Problema:** Entity criada mas não registrada no DataSource

**Lição:** Sempre que criar uma nova entity:
1. ✅ Criar arquivo da entity
2. ✅ **REGISTRAR no config.ts** (passo crítico!)
3. ✅ Verificar import correto
4. ✅ Testar imediatamente

**Checklist:**
```typescript
// 1. Criar entity
export class MinhaEntity { ... }

// 2. Importar no config.ts
import { MinhaEntity } from './entities/MinhaEntity';

// 3. Adicionar no array entities
entities: [
  // ... outras entities
  MinhaEntity  // ← NÃO ESQUECER!
]
```

### 6.2 Snake_Case vs CamelCase Mapping

**Problema:** TypeORM usa camelCase, PostgreSQL usa snake_case

**Lição:** Sempre mapear explicitamente:

```typescript
// ❌ ERRADO - Vai procurar coluna "userId" e falhar
@Column({ type: 'uuid' })
userId!: string;

// ✅ CORRETO - Mapeia para coluna "user_id"
@Column({ name: 'user_id', type: 'uuid' })
userId!: string;
```

**Padrão:**
- Banco de dados: `snake_case` (user_id, api_key_id, response_time_ms)
- TypeScript: `camelCase` (userId, apiKeyId, responseTime)
- Decorator: `@Column({ name: 'snake_case' })`

### 6.3 Deploy em Kubernetes/K3s

**Problema:** `kubectl cp` não atualiza código em execução

**Lição:** Sempre fazer rebuild completo da imagem:

**❌ NÃO FUNCIONA:**
```bash
kubectl cp file.js pod:/app/dist/file.js  # Pod continua usando cache
```

**✅ FUNCIONA:**
```bash
# 1. Build completo
npm run build
docker build -t app:latest .

# 2. Import no K3s
docker save app:latest -o /tmp/app.tar
sudo k3s ctr images import /tmp/app.tar

# 3. Recreate pods
kubectl delete pod -l app=myapp
```

**Por que?**
- Node.js carrega módulos na inicialização
- Containerd tem seu próprio image store
- Pods precisam reiniciar para carregar novo código

### 6.4 Verificação de Schema do Banco

**Problema:** Assumir nomes de colunas sem verificar

**Lição:** Sempre verificar schema real primeiro:

```bash
# PostgreSQL
kubectl exec -it postgres-pod -- psql -U user -d database -c "\d table_name"

# MySQL
kubectl exec -it mysql-pod -- mysql -u user -p database -e "DESCRIBE table_name;"
```

**Checklist de Validação:**
1. ✅ Verificar nomes exatos das colunas
2. ✅ Verificar tipos de dados
3. ✅ Verificar constraints (NOT NULL, defaults)
4. ✅ Verificar índices
5. ✅ Mapear corretamente na entity

### 6.5 Debugging Iterativo

**Lição:** Processo sistemático de debugging:

```
1. 🔍 SINTOMA
   └─> Ver logs de erro
   
2. 🎯 HIPÓTESE
   └─> Formar teoria do problema
   
3. ✅ VALIDAÇÃO
   └─> Verificar hipótese com comandos
   
4. 🔧 CORREÇÃO
   └─> Aplicar fix específico
   
5. 🚀 DEPLOY
   └─> Rebuild + redeploy completo
   
6. 🧪 TESTE
   └─> Validar se resolveu
   
7. 🔄 REPETIR
   └─> Se não resolveu, voltar ao passo 1
```

**Exemplo desta sessão:**
- Iteração 1: Corrigir imports → Still 90%
- Iteração 2: Rebuild imagem → Still 90% (descobriu problema de deploy)
- Iteração 3: Import K3s correto → 95% (descobriu response_time_ms)
- Iteração 4: Corrigir mappings → 100% ✅

### 6.6 Logs vs Realidade

**Problema:** Logs podem não refletir código atual do pod

**Lição:** Sempre verificar arquivos DENTRO do pod:

```bash
# ❌ Ver arquivo local (pode estar desatualizado)
cat ~/app/dist/file.js

# ✅ Ver arquivo no pod (verdade absoluta)
kubectl exec pod-name -- cat /app/dist/file.js
```

**Comandos Úteis:**
```bash
# Ver arquivo específico
kubectl exec -n namespace pod-name -- cat /path/to/file

# Buscar string em arquivo
kubectl exec -n namespace pod-name -- cat /path/to/file | grep "search"

# Ver múltiplos arquivos
kubectl exec -n namespace pod-name -- find /app/dist -name "*.js" -exec cat {} \;
```

---

## 🔧 7. COMANDOS ÚTEIS

### 7.1 Debugging de Pods

```bash
# Listar pods
kubectl get pods -n shaka-staging

# Ver logs em tempo real
kubectl logs -n shaka-staging -l app=shaka-api -f

# Ver logs com timestamp
kubectl logs -n shaka-staging -l app=shaka-api --timestamps

# Ver últimas N linhas
kubectl logs -n shaka-staging -l app=shaka-api --tail=100

# Filtrar logs
kubectl logs -n shaka-staging -l app=shaka-api | grep -i "error\|warning"

# Describe pod (eventos, status)
kubectl describe pod -n shaka-staging pod-name

# Shell interativo no pod
kubectl exec -it -n shaka-staging pod-name -- /bin/sh

# Executar comando no pod
kubectl exec -n shaka-staging pod-name -- comando
```

### 7.2 Docker e K3s Images

```bash
# Build imagem
docker build -t app:latest .

# Listar imagens Docker
docker images | grep app

# Salvar imagem
docker save app:latest -o /tmp/app.tar

# Carregar imagem
docker load -i /tmp/app.tar

# Importar no K3s
sudo k3s ctr images import /tmp/app.tar

# Listar imagens K3s
sudo k3s ctr images ls | grep app

# Remover imagem K3s
sudo k3s ctr images rm docker.io/library/app:latest
```

### 7.3 Database Operations

```bash
# Conectar PostgreSQL
kubectl exec -it -n shaka-staging postgres-0 -- psql -U user -d database

# Comandos úteis no psql:
# \l              - Listar databases
# \c database     - Conectar database
# \dt             - Listar tabelas
# \d table_name   - Descrever tabela
# \q              - Sair

# Query direto da linha de comando
kubectl exec -n shaka-staging postgres-0 -- psql -U user -d database -c "SELECT * FROM table LIMIT 10;"

# Backup database
kubectl exec -n shaka-staging postgres-0 -- pg_dump -U user database > backup.sql

# Restore database
kubectl exec -i -n shaka-staging postgres-0 -- psql -U user database < backup.sql
```

### 7.4 Port Forwarding

```bash
# Port forward para API
kubectl port-forward -n shaka-staging svc/shaka-api 3000:3000

# Port forward para Database
kubectl port-forward -n shaka-staging postgres-0 5432:5432

# Port forward em background
kubectl port-forward -n shaka-staging svc/shaka-api 3000:3000 &

# Matar port-forward
kill $(lsof -t -i:3000)
```

### 7.5 Deployment Management

```bash
# Ver deployments
kubectl get deployments -n shaka-staging

# Describe deployment
kubectl describe deployment -n shaka-staging shaka-api

# Editar deployment
kubectl edit deployment -n shaka-staging shaka-api

# Scale deployment
kubectl scale deployment -n shaka-staging shaka-api --replicas=3

# Restart deployment (recreate pods)
kubectl rollout restart deployment -n shaka-staging shaka-api

# Ver status do rollout
kubectl rollout status deployment -n shaka-staging shaka-api

# Ver histórico
kubectl rollout history deployment -n shaka-staging shaka-api

# Rollback
kubectl rollout undo deployment -n shaka-staging shaka-api
```

---

## 📊 8. ESTRUTURA DE ARQUIVOS MODIFICADOS

### 8.1 Estrutura do Projeto

```
shaka-api/
├── src/
│   ├── api/
│   │   └── middlewares/
│   │       └── apiKeyAuth.ts          ← MODIFICADO (logger path)
│   │
│   ├── infrastructure/
│   │   └── database/
│   │       ├── config.ts              ← MODIFICADO (add entity)
│   │       └── entities/
│   │           └── UsageRecordEntity.ts  ← MODIFICADO (mappings)
│   │
│   └── config/
│       └── logger.ts                  ← REFERENCIADO
│
├── scripts/
│   ├── validate-api-keys-v2.sh       ← USADO PARA VALIDAÇÃO
│   └── rebuild-and-deploy.sh         ← CRIADO NESTA SESSÃO
│
└── Dockerfile                         ← USADO PARA BUILD
```

### 8.2 Fluxo de Dados

```
HTTP Request
     │
     ├─> apiKeyAuth.ts (middleware)
     │   └─> logger.ts ✅
     │   └─> Valida API Key
     │
     ├─> Controller
     │   └─> Service
     │       └─> Repository
     │           └─> TypeORM
     │               └─> config.ts
     │                   └─> entities: [UsageRecordEntity] ✅
     │                       └─> UsageRecordEntity.ts
     │                           └─> Mappings snake_case ✅
     │
     └─> PostgreSQL
         └─> usage_records table
             └─> Colunas em snake_case ✅
```

---

## 🎓 9. GUIA DE TROUBLESHOOTING

### 9.1 Problemas Comuns e Soluções

#### Problema: "No metadata for Entity was found"

**Sintoma:**
```
[error]: No metadata for "UsageRecordEntity" was found.
```

**Causa:** Entity não registrada no TypeORM DataSource

**Solução:**
```typescript
// src/infrastructure/database/config.ts
import { UsageRecordEntity } from './entities/UsageRecordEntity';

entities: [
  // ... outras entities
  UsageRecordEntity  // ← Adicionar aqui
]
```

**Validação:**
```bash
# Ver entities registradas no pod
kubectl exec pod-name -- cat /app/dist/infrastructure/database/config.js | grep -A 5 "entities:"
```

---

#### Problema: "Column X does not exist"

**Sintoma:**
```
error: column "apiKeyId" of relation "usage_records" does not exist
```

**Causa:** Mapeamento incorreto entre camelCase (TypeScript) e snake_case (SQL)

**Solução:**
```typescript
// ❌ ERRADO
@Column({ type: 'uuid' })
apiKeyId!: string;

// ✅ CORRETO
@Column({ name: 'api_key_id', type: 'uuid' })
apiKeyId!: string;
```

**Validação:**
```bash
# Ver schema real da tabela
kubectl exec -it postgres-0 -- psql -U user -d db -c "\d table_name"
```

---

#### Problema: Pod Não Atualiza Após Correção

**Sintoma:** Código corrigido localmente, mas pod ainda tem erro

**Causa:** Pod usando imagem antiga do cache/registry

**Solução:**
```bash
# 1. Build completo
npm run build
docker build -t app:latest .

# 2. Import no K3s
docker save app:latest -o /tmp/app.tar
sudo k3s ctr images import /tmp/app.tar

# 3. Forçar recreação
kubectl delete pod -l app=myapp

# 4. Aguardar novo pod
kubectl wait --for=condition=ready pod -l app=myapp --timeout=60s
```

**Validação:**
```bash
# Verificar arquivo no POD
kubectl exec pod-name -- cat /app/dist/file.js | grep "correção"
```

---

#### Problema: Rate Limit ou Performance Issues

**Sintoma:** Requisições lentas ou timeouts

**Investigação:**
```bash
# Ver uso de recursos do pod
kubectl top pod -n namespace

# Ver logs de performance
kubectl logs -n namespace pod-name | grep -i "slow\|timeout\|latency"

# Describe pod (ver limits)
kubectl describe pod -n namespace pod-name | grep -A 5 "Limits"
```

**Solução:** Ajustar resources no deployment
```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

---

#### Problema: Database Connection Issues

**Sintoma:**
```
[error]: Connection terminated unexpectedly
```

**Investigação:**
```bash
# Testar conexão
kubectl exec -n namespace pod-name -- nc -zv postgres-host 5432

# Ver variáveis de ambiente
kubectl exec -n namespace pod-name -- env | grep DB_

# Ver secrets
kubectl get secret -n namespace db-secrets -o yaml
```

**Soluções:**
1. Verificar credenciais
2. Verificar network policies
3. Verificar se database está up
4. Verificar connection pool settings

---

### 9.2 Checklist de Debugging

```
□ Ver logs recentes
  kubectl logs -n namespace pod-name --tail=100

□ Verificar status do pod
  kubectl get pods -n namespace
  kubectl describe pod -n namespace pod-name

□ Verificar arquivos no pod
  kubectl exec pod-name -- cat /path/to/file

□ Verificar variáveis de ambiente
  kubectl exec pod-name -- env

□ Verificar conexão database
  kubectl exec pod-name -- nc -zv db-host 5432

□ Verificar imagem usada
  kubectl get pod pod-name -o yaml | grep image:

□ Verificar events
  kubectl get events -n namespace --sort-by='.lastTimestamp'

□ Testar endpoint manualmente
  kubectl port-forward pod-name 3000:3000
  curl http://localhost:3000/health
```

---

## 🚀 10. PRÓXIMOS PASSOS

### 10.1 Melhorias Recomendadas (Prioridade Alta)

#### 1. Monitoring e Observability

**Objetivo:** Detectar problemas antes que afetem usuários

**Implementar:**
- [ ] Prometheus + Grafana para métricas
- [ ] Loki para agregação de logs
- [ ] Alerts para erros críticos (HTTP 500, database down)
- [ ] Dashboard com métricas de API Keys (criação, uso, rotação)

**Métricas Importantes:**
- Taxa de erro por endpoint
- Latência p50, p95, p99
- API Keys ativas vs inativas
- Taxa de rotação de keys
- Requisições por usuário/key

---

#### 2. CI/CD Pipeline

**Objetivo:** Automatizar testes e deploys

**Pipeline Proposto:**
```yaml
# .gitlab-ci.yml ou .github/workflows/deploy.yml

stages:
  - test
  - build
  - deploy

test:
  script:
    - npm run test
    - npm run lint
    - npm run validate-schema

build:
  script:
    - docker build -t app:$CI_COMMIT_SHA .
    - docker tag app:$CI_COMMIT_SHA app:latest

deploy-staging:
  script:
    - docker save app:latest -o app.tar
    - k3s ctr images import app.tar
    - kubectl rollout restart deployment app -n staging
    - ./scripts/validate-api-keys-v2.sh

deploy-production:
  when: manual
  only: [main]
  script:
    # Same as staging but to production namespace
```

---

#### 3. Testes Automatizados

**Objetivo:** Prevenir regressões

**Implementar:**

```typescript
// tests/integration/api-keys.test.ts
describe('API Key Management', () => {
  it('should register UsageRecordEntity', async () => {
    const entities = AppDataSource.entityMetadatas;
    const usageEntity = entities.find(e => e.name === 'UsageRecordEntity');
    expect(usageEntity).toBeDefined();
  });

  it('should map camelCase to snake_case', async () => {
    const repo = AppDataSource.getRepository(UsageRecordEntity);
    const metadata = repo.metadata;
    
    expect(metadata.findColumnWithPropertyName('apiKeyId').databaseName)
      .toBe('api_key_id');
    expect(metadata.findColumnWithPropertyName('responseTime').databaseName)
      .toBe('response_time_ms');
  });

  it('should track usage on API key usage', async () => {
    const apiKey = await createTestApiKey();
    await makeRequestWithApiKey(apiKey.key);
    
    const stats = await getApiKeyStats(apiKey.id);
    expect(stats.totalRequests).toBeGreaterThan(0);
  });
});
```

**Executar:**
```bash
npm run test:integration
```

---

#### 4. Database Migrations Management

**Objetivo:** Versionar mudanças de schema

**Implementar TypeORM Migrations:**

```bash
# Gerar migration
npm run migration:generate -- -n AddErrorMessageColumn

# Aplicar migrations
npm run migration:run

# Reverter migration
npm run migration:revert
```

**Exemplo de Migration:**
```typescript
// migrations/1234567890-AddErrorMessageColumn.ts
import { MigrationInterface, QueryRunner, TableColumn } from 'typeorm';

export class AddErrorMessageColumn1234567890 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.addColumn('usage_records', new TableColumn({
      name: 'error_message',
      type: 'text',
      isNullable: true
    }));
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.dropColumn('usage_records', 'error_message');
  }
}
```

---

### 10.2 Melhorias Recomendadas (Prioridade Média)

#### 5. Rate Limiting por API Key

**Objetivo:** Prevenir abuso

```typescript
// src/api/middlewares/rateLimitApiKey.ts
export const rateLimitApiKey = async (req, res, next) => {
  const apiKey = req.headers['x-api-key'];
  const keyInfo = await getApiKeyInfo(apiKey);
  
  // Verificar limite (ex: 1000 req/hora)
  const usageLastHour = await getUsageLastHour(keyInfo.id);
  
  if (usageLastHour >= keyInfo.rateLimit) {
    return res.status(429).json({
      error: 'Rate limit exceeded',
      limit: keyInfo.rateLimit,
      resetAt: getResetTime()
    });
  }
  
  next();
};
```

---

#### 6. API Key Expiration

**Objetivo:** Forçar rotação periódica

```typescript
// Adicionar na ApiKeyEntity
@Column({ name: 'expires_at', type: 'timestamp', nullable: true })
expiresAt?: Date;

// Middleware de validação
if (apiKey.expiresAt && apiKey.expiresAt < new Date()) {
  return res.status(401).json({
    error: 'API key expired',
    message: 'Please rotate your API key'
  });
}
```

---

#### 7. Audit Log

**Objetivo:** Rastreabilidade completa

```typescript
// AuditLogEntity
@Entity('audit_logs')
export class AuditLogEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'user_id', type: 'uuid' })
  userId!: string;

  @Column({ type: 'varchar' })
  action!: string; // CREATE_KEY, ROTATE_KEY, REVOKE_KEY

  @Column({ type: 'jsonb', nullable: true })
  metadata?: object;

  @CreateDateColumn()
  timestamp!: Date;
}
```

---

### 10.3 Documentação

#### 8. API Documentation

**Objetivo:** Facilitar integração

**Ferramentas:**
- Swagger/OpenAPI
- Postman Collection
- Code examples

**Exemplo:**
```yaml
# openapi.yaml
/api/v1/keys:
  post:
    summary: Create API Key
    security:
      - BearerAuth: []
    requestBody:
      content:
        application/json:
          schema:
            type: object
            properties:
              name:
                type: string
              scopes:
                type: array
                items:
                  type: string
    responses:
      201:
        description: API Key created
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/ApiKey'
```

---

#### 9. Runbooks

**Objetivo:** Resposta rápida a incidentes

**Templates:**

```markdown
# Runbook: API 500 Errors

## Sintomas
- HTTP 500 em endpoints de API Keys
- Logs mostrando "Entity not found"

## Diagnóstico
1. Verificar logs: `kubectl logs -n staging pod-name`
2. Verificar entities: `kubectl exec pod -- cat /app/dist/.../config.js`
3. Verificar database: `kubectl exec postgres -- psql ...`

## Resolução
1. Se entity faltando: adicionar em config.ts
2. Rebuild: `./scripts/rebuild-and-deploy.sh`
3. Validar: `./scripts/validate-api-keys-v2.sh`

## Prevenção
- Adicionar teste de integração
- CI/CD validar entities antes de deploy
```

---

## 📋 11. RESUMO DE COMANDOS CRÍTICOS

### Build e Deploy Completo
```bash
cd ~/shaka-api
npm run build
docker build -t shaka-api:latest .
docker save shaka-api:latest -o /tmp/shaka-api.tar
sudo k3s ctr images import /tmp/shaka-api.tar
kubectl delete pod -n shaka-staging -l app=shaka-api
kubectl wait --for=condition=ready pod -n shaka-staging -l app=shaka-api --timeout=60s
```

### Validação
```bash
~/shaka-api/scripts/validate-api-keys-v2.sh
```

### Verificar Correções no Pod
```bash
POD=$(kubectl get pods -n shaka-staging -l app=shaka-api -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n shaka-staging $POD -- cat /app/dist/infrastructure/database/config.js | grep UsageRecordEntity
```

### Database Schema
```bash
kubectl exec -it -n shaka-staging postgres-0 -- psql -U shaka_staging -d shaka_staging -c "\d usage_records"
```

---

## 🎯 12. KPIs DE SUCESSO

### Antes da Sessão
- ⚠️ Taxa de Sucesso: **90%**
- ⚠️ Endpoints com Erro: **2/7**
- ⚠️ Production Ready: **NÃO**

### Depois da Sessão
- ✅ Taxa de Sucesso: **100%**
- ✅ Endpoints com Erro: **0/7**
- ✅ Production Ready: **SIM**

### Impacto no Negócio
- ✅ Sistema completo de gerenciamento de API Keys
- ✅ Tracking de uso operacional
- ✅ Autenticação via X-API-Key funcional
- ✅ Rotação e revogação de keys operacional
- ✅ Base sólida para implementar rate limiting
- ✅ Auditoria de uso disponível

---

## 📞 13. CONTATOS E RECURSOS

### Equipe Responsável
- **CTO Integrador:** Correções e deploys
- **DevOps:** Infraestrutura K8s/K3s
- **Backend:** Manutenção do código TypeScript
- **QA:** Validações e testes

### Recursos Importantes
- **Repositório:** `~/shaka-api`
- **Namespace:** `shaka-staging`
- **Database:** `shaka_staging` no pod `postgres-0`
- **Scripts:** `~/shaka-api/scripts/`
- **Logs:** `kubectl logs -n shaka-staging -l app=shaka-api`

### Documentação
- TypeORM: https://typeorm.io
- Kubernetes: https://kubernetes.io/docs
- K3s: https://k3s.io

---

## ✅ 14. CHECKLIST DE ACEITE

- [x] Todos os testes passando (22/22)
- [x] Taxa de sucesso 100%
- [x] Zero HTTP 500 errors
- [x] Zero HTTP 401 errors
- [x] UsageRecordEntity registrada
- [x] Logger com caminho correto
- [x] Mappings snake_case completos
- [x] Schema do banco validado
- [x] Deploy pipeline documentado
- [x] Scripts de validação funcionando
- [x] Lições aprendidas documentadas
- [x] Próximos passos definidos

---

## 🎉 15. CONCLUSÃO

Esta sessão demonstrou um **processo completo de debugging profissional**:

1. ✅ **Diagnóstico Preciso:** Identificação exata dos problemas
2. ✅ **Investigação Sistemática:** Verificação em múltiplas camadas
3. ✅ **Correções Cirúrgicas:** Fixes específicos e testados
4. ✅ **Deploy Confiável:** Pipeline reproduzível
5. ✅ **Validação Completa:** Confirmação de 100% de sucesso
6. ✅ **Documentação Detalhada:** Knowledge base completo

**Resultado Final:** Sistema de API Key Management **100% operacional** e **production-ready**! 🚀

---

**Elaborado por:** CTO Integrador  
**Data:** 2025-12-11  
**Versão:** 1.0  
**Status:** ✅ Aprovado para Produção
