# 📋 **MEMORANDO DE HANDOFF/ONBOARDING - SESSION 26**

## 🏷️ **INFORMAÇÕES BÁSICAS**
```
Documento: M26 - Deep Debugging & Repository Architecture Analysis
Data: 10/12/2025
Duração: ~90 minutos
Status: DIAGNÓSTICO COMPLETO - PROBLEMA IDENTIFICADO
Sistema: SHAKA API v1.0.0
Ambiente: Staging (shaka-staging)
Fase: Sprint 1 - API Key Management (Debugging)
```

---

## 🎯 **OBJETIVO DA SESSÃO**

**Meta Principal:** Completar Sprint 1 - API Key Management, validando e implementando os 4 endpoints faltantes.

**Contexto Inicial:** Após o sucesso da migration do banco (M25), descobrimos que o sistema de autenticação estava falhando com erro `"Cannot read properties of undefined (reading 'findOne')"`.

---

## 📊 **SITUAÇÃO INICIAL (ANTES)**

### **Status do Sistema:**
- ✅ Database: PostgreSQL com schema completo (5 tabelas)
- ✅ Cache: Redis conectado
- ✅ API: Pod rodando, health check respondendo
- ❌ Autenticação: Falhando com erro de repository

### **Erro Reportado:**
```json
{
  "success": false,
  "error": "Cannot read properties of undefined (reading 'findOne')"
}
```

### **Logs do Sistema:**
```
[error]: [UserService] Error creating user: Cannot read properties of undefined (reading 'findOne')
[error]: [AuthService] Error during registration: Cannot read properties of undefined (reading 'findOne')
[error]: [AuthController] Error during registration: Cannot read properties of undefined (reading 'findOne')
```

---

## 🔍 **PROCESSO DE INVESTIGAÇÃO**

### **FASE 1: Validação Inicial (15 min)**

**Script Criado:** `validate-api-keys-sprint1.sh`

**Descobertas:**
1. ✅ Infraestrutura OK (pod rodando, PostgreSQL conectado)
2. ✅ Tabela `api_keys` existe com todas as 12 colunas
3. ❌ Controladores não encontrados (`ApiKeyController.js`, `ApiKeyService.js`)
4. ❌ Autenticação falhando

**Conclusão Fase 1:** Arquivos compilados diferentes do código-fonte.

---

### **FASE 2: Investigação de Estrutura (20 min)**

**Script Criado:** `investigate-api-structure.sh`

**Descobertas Críticas:**
```bash
# Arquivos ENCONTRADOS:
✅ /app/dist/api/controllers/api-key/ApiKeyController.js
✅ /app/dist/core/services/api-key/ApiKeyService.js
✅ /app/dist/api/routes/api-keys.routes.js

# Rotas TODAS registradas:
✅ POST   /api/v1/keys              - create
✅ GET    /api/v1/keys              - list
✅ GET    /api/v1/keys/:id          - getOne
✅ GET    /api/v1/keys/:id/usage    - getUsage
✅ POST   /api/v1/keys/:id/rotate   - rotate
✅ DELETE /api/v1/keys/:id          - revoke
✅ DELETE /api/v1/keys/:id/permanent - deletePermanent
```

**Conclusão Fase 2:** Todos os endpoints já estavam implementados! O problema era outro.

---

### **FASE 3: Teste Via Port-Forward (10 min)**

**Script Criado:** `test-api-keys-portforward.sh`

**Resultado:**
- ✅ Health check: 200 OK
- ❌ Registro de usuário: 500 Internal Server Error
- ❌ Login: 500 Internal Server Error

**Erro Persistente:**
```
Cannot read properties of undefined (reading 'findOne')
```

**Conclusão Fase 3:** Problema no `UserRepository`, não nos endpoints de API Keys.

---

### **FASE 4: Tentativas de Hotfix (30 min)**

#### **Tentativa 1: Hotfix UserRepository**
**Script:** `hotfix-user-repository.sh`

**Ação:** Reescrever `UserRepository.js` e `UserService.js` no pod rodando.

**Resultado:** ❌ Causou regressão - código ficou inconsistente.

**Lição Aprendida:** Nunca fazer hotfix em código compilado sem rebuild completo.

---

#### **Tentativa 2: Rebuild Completo**
**Script:** `rebuild-and-redeploy-correct.sh`

**Ação:**
1. Verificar código-fonte TypeScript
2. Compilar com `npm run build`
3. Criar imagem Docker
4. Importar para K3s
5. Restart deployment

**Descoberta Crítica:**
```
Data do UserService.ts (fonte):    2025-12-05 18:07 ✅
Data do UserService.js (local):    2025-12-09 13:51 ✅
Data do UserService.js (pod):      2025-12-09 03:03 ❌ DESATUALIZADO!
```

**Conclusão:** Pod estava usando imagem Docker antiga (cache).

---

#### **Tentativa 3: Rebuild Sem Cache**
**Script:** `rebuild-no-cache.sh`

**Ação:**
```bash
docker build --no-cache --progress=plain \
    -t shaka-api:latest .
```

**Resultado:**
- ✅ Build bem-sucedido
- ✅ Imagem criada: 267MB
- ❌ Pod ainda usava imagem antiga!

**Descoberta:** K3s estava usando cache mesmo com imagem nova.

---

### **FASE 5: Forçar Imagem Nova no K8s (15 min)**

**Script:** `force-new-image-fixed.sh`

**Estratégia:**
1. Remover TODAS imagens antigas do K3s
2. Importar imagem fresh do Docker
3. Patch no deployment: `imagePullPolicy: Never`
4. Deletar pod e forçar recriação

**Resultado PARCIAL:**
```
Data do UserService.js NO POD: 2025-12-10 01:48:17 ✅ CORRETO!
Código: UserRepository_1.UserRepository.findByEmail ✅ CORRETO!
```

**MAS:**
```json
{
  "success": false,
  "error": "Cannot read properties of undefined (reading 'findOne')"
}
```

**Conclusão:** Código estava correto, mas problema era em runtime!

---

## 🚨 **ROOT CAUSE DEFINITIVO**

### **FASE 6: Investigação de Runtime (20 min)**

**Script:** `investigate-repository-runtime.sh`

**Teste Executado Dentro do Pod:**
```javascript
const { UserRepository } = require('/app/dist/infrastructure/database/repositories/UserRepository');

console.log('UserRepository.repository:', typeof UserRepository.repository);
// Resultado: undefined ❌
```

**Código do UserRepository.js:**
```javascript
class UserRepository {
    static initialize() {  // ← Método existe
        this.repository = config_1.AppDataSource.getRepository(UserEntity_1.UserEntity);
    }
    
    static async findByEmail(email) {
        return this.repository.findOne({ where: { email } });  // ← repository é undefined!
    }
}
```

**PROBLEMA IDENTIFICADO:**
- O método `initialize()` existe, mas **NUNCA FOI CHAMADO**
- `UserRepository.repository` permanece `undefined`
- Toda chamada a `findByEmail()` falha porque tenta acessar `undefined.findOne()`

---

### **FASE 7: Investigação do AppDataSource**

**Script:** `investigate-appdatasource.sh`

**Teste de Runtime:**
```javascript
const { AppDataSource } = require('/app/dist/infrastructure/database/config');

console.log('AppDataSource.isInitialized:', AppDataSource.isInitialized);
// Resultado: false ❌
```

**Descoberta Adicional:**
```
ERRO: No metadata for "UserEntity" was found.
```

**Configuração do AppDataSource:**
```javascript
exports.AppDataSource = new typeorm_1.DataSource({
    type: 'postgres',
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '5432'),
    username: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD || 'postgres',
    database: process.env.DB_NAME || 'shaka_dev',
    synchronize: false,
    logging: !isProduction,
    entities: [UserEntity_1.UserEntity, SubscriptionEntity_1.SubscriptionEntity, ApiKeyEntity_1.ApiKeyEntity],
    // ...
});
```

**Análise do server.js:**
```javascript
async function startServer() {
    try {
        await DatabaseService_1.DatabaseService.initialize();  // ✅ Chama inicialização
        
        // MAS DatabaseService.initialize() usa this.dataSource
        // E NÃO chama AppDataSource.initialize() nem UserRepository.initialize()
```

---

## 🎯 **ARQUITETURA DO PROBLEMA**

### **Fluxo Correto Esperado:**
```
1. server.js inicia
2. DatabaseService.initialize() 
   → AppDataSource.initialize() ✅
   → UserRepository.initialize() ❌ NUNCA ACONTECE!
3. UserRepository.repository fica undefined
4. findByEmail() tenta acessar undefined.findOne()
5. ERRO!
```

### **Por Que DatabaseService.initialize() Não Funciona:**

**Código do DatabaseService.js:**
```javascript
class DatabaseService {
    static dataSource = AppDataSource;  // ← Referência ao AppDataSource
    
    static async initialize() {
        if (this.dataSource.isInitialized) {
            return;
        }
        await this.dataSource.initialize();  // ← Inicializa AppDataSource
        logger.info('✅ Database connected successfully');
    }
}
```

**Problema:**
- `DatabaseService.initialize()` chama `AppDataSource.initialize()` ✅
- MAS `UserRepository.initialize()` nunca é chamado ❌
- Logo, `UserRepository.repository` fica `undefined`

---

## 🔧 **SOLUÇÕES IDENTIFICADAS**

### **Solução 1: Inicialização Automática via Getter (RECOMENDADA)**

**Implementação:**
```javascript
class UserRepository {
    static get repository() {
        if (!this._repository) {
            this._repository = AppDataSource.getRepository(UserEntity);
        }
        return this._repository;
    }
    
    // Resto dos métodos permanece igual
}
```

**Vantagens:**
- ✅ Inicialização lazy (só quando necessário)
- ✅ Não requer mudanças no startup
- ✅ Zero dependências externas
- ✅ Thread-safe (JavaScript é single-threaded)

**Desvantagens:**
- ⚠️ Requer que AppDataSource já esteja inicializado
- ⚠️ Não funciona se AppDataSource.isInitialized = false

---

### **Solução 2: Chamar initialize() no Startup**

**Implementação no server.js:**
```javascript
async function startServer() {
    await DatabaseService.initialize();
    
    // ADICIONAR AQUI:
    const { UserRepository } = require('./infrastructure/database/repositories/UserRepository');
    UserRepository.initialize();
    
    // Mesmo para outros repositories
    const { ApiKeyRepository } = require('./infrastructure/database/repositories/ApiKeyRepository');
    ApiKeyRepository.initialize();
    
    await CacheService.initialize();
    // ...
}
```

**Vantagens:**
- ✅ Controle explícito da inicialização
- ✅ Fácil de debugar
- ✅ Garante ordem de inicialização

**Desvantagens:**
- ❌ Requer mudança em server.js
- ❌ Precisa adicionar cada repository manualmente
- ❌ Esquecimento de um repository causa bugs

---

### **Solução 3: Factory Pattern (IDEAL PARA LONGO PRAZO)**

**Implementação:**
```javascript
// RepositoryFactory.js
class RepositoryFactory {
    static repositories = new Map();
    
    static register(name, entity) {
        this.repositories.set(name, {
            entity,
            instance: null
        });
    }
    
    static get(name) {
        const config = this.repositories.get(name);
        if (!config.instance) {
            config.instance = AppDataSource.getRepository(config.entity);
        }
        return config.instance;
    }
    
    static initialize() {
        // Pré-inicializar todos os repositories
        for (const [name, config] of this.repositories) {
            this.get(name);
        }
    }
}

// UserRepository.js
class UserRepository {
    static get repository() {
        return RepositoryFactory.get('User');
    }
}

// server.js
RepositoryFactory.register('User', UserEntity);
RepositoryFactory.register('ApiKey', ApiKeyEntity);
await RepositoryFactory.initialize();
```

**Vantagens:**
- ✅ Centralizado
- ✅ Type-safe
- ✅ Fácil manutenção
- ✅ Testável

**Desvantagens:**
- ❌ Requer refactoring significativo
- ❌ Mais complexo

---

## 📊 **ESTADO ATUAL DO SISTEMA**

### **Infraestrutura:**
```
NAMESPACE        POD                         STATUS    RAM     
shaka-staging    shaka-api-c69884b7-qj68k    Running   ~150MB  
shaka-staging    postgres-0                  Running   ~512MB  
shaka-shared     redis-0                     Running   ~128MB  

ENDPOINTS:
  Health: http://staging.shaka.local/health ✅ 200 OK
  Auth:   http://staging.shaka.local/api/v1/auth/* ❌ 500 Error
```

### **Database:**
```sql
Tabelas: 5 ✅
  • users (7 colunas)
  • subscriptions (11 colunas)  
  • api_keys (12 colunas)
  • usage_records (10 colunas)
  • migrations (4 colunas)

Indexes: 21 ✅
Foreign Keys: 4 ✅
Conexão: OK ✅
```

### **Código:**
```
UserService.ts:     2025-12-05 18:07 ✅ Fonte atualizada
UserService.js:     2025-12-10 01:48 ✅ Compilado fresh
Pod UserService.js: 2025-12-10 01:48 ✅ Imagem correta

AppDataSource: Configurado ✅ Mas não inicializado no contexto certo ❌
UserRepository: Código correto ✅ Mas repository = undefined ❌
```

---

## 🎓 **LIÇÕES APRENDADAS**

### **1. Docker Image Cache é Persistente**
Mesmo com `docker build --no-cache`, o K3s pode usar cache interno.

**Solução:**
```bash
# Remover TODAS imagens antigas do K3s
sudo k3s ctr images rm <image>

# Importar fresh
sudo k3s ctr images import <tarball>

# Forçar imagePullPolicy
kubectl patch deployment <name> --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/imagePullPolicy", "value": "Never"}
]'
```

---

### **2. TypeORM Repository Pattern Requer Inicialização**

**Problema:**
```javascript
class MyRepository {
    static repository;  // ❌ undefined por padrão
}
```

**Soluções:**
- Getter automático (lazy initialization)
- Método initialize() chamado no startup
- Factory pattern centralizado

---

### **3. Debugging em Runtime é Essencial**

**Ferramentas usadas:**
```bash
# Executar código dentro do pod
kubectl exec -n <ns> <pod> -- node /tmp/test.js

# Copiar arquivo para pod
kubectl cp /tmp/script.js <ns>/<pod>:/tmp/script.js

# Ver logs em tempo real
kubectl logs -f -n <ns> <pod> | grep -v "kube-probe"
```

---

### **4. Separação de Concerns: DatabaseService vs Repositories**

**Arquitetura Atual:**
```
DatabaseService.initialize()
  └─> AppDataSource.initialize() ✅
  
UserRepository.initialize()  ❌ Nunca chamado!
  └─> this.repository = AppDataSource.getRepository(...)
```

**Problema:** Falta de coupling entre DatabaseService e Repositories.

**Solução Ideal:** Factory pattern ou registro centralizado.

---

## 🚀 **PRÓXIMOS PASSOS RECOMENDADOS**

### **PRIORIDADE 1: Corrigir UserRepository (30 min)**

**Opção A - Quick Fix (5 min):**
```bash
# Aplicar getter automático
~/shaka-validation/fix-repository-initialization.sh
```

**Opção B - Proper Fix (15 min):**
1. Editar `src/infrastructure/database/repositories/UserRepository.ts`
2. Adicionar getter estático
3. Rebuild + Deploy

**Opção C - Ideal Fix (30 min):**
1. Criar `RepositoryFactory.ts`
2. Refatorar todos repositories
3. Atualizar `server.ts` startup

---

### **PRIORIDADE 2: Validar Sistema Completo (15 min)**

Após correção, executar:
```bash
~/shaka-validation/test-api-keys-portforward.sh
```

**Checklist:**
- [ ] Registro de usuário (POST /auth/register)
- [ ] Login (POST /auth/login)
- [ ] Criar API Key (POST /keys)
- [ ] Listar API Keys (GET /keys)
- [ ] Rotacionar Key (POST /keys/:id/rotate)
- [ ] Ver uso (GET /keys/:id/usage)
- [ ] Revogar Key (DELETE /keys/:id)

---

### **PRIORIDADE 3: Completar Sprint 1 (60 min)**

Implementar endpoints faltantes:
- `POST /api/v1/keys/:id/rotate` - Rotacionar chave
- `GET /api/v1/keys/:id/usage` - Estatísticas de uso
- `DELETE /api/v1/keys/:id` - Soft delete
- `DELETE /api/v1/keys/:id/permanent` - Hard delete

---

## 📚 **SCRIPTS CRIADOS**

### **Diagnóstico:**
1. `validate-api-keys-sprint1.sh` - Validação inicial completa
2. `investigate-api-structure.sh` - Estrutura de arquivos
3. `investigate-repository-runtime.sh` - Teste em runtime
4. `investigate-appdatasource.sh` - Análise do TypeORM

### **Correção:**
1. `hotfix-user-repository.sh` - Hotfix (não recomendado)
2. `rebuild-and-redeploy-correct.sh` - Rebuild completo
3. `rebuild-no-cache.sh` - Rebuild sem cache
4. `force-new-image-fixed.sh` - Forçar imagem nova no K8s
5. `fix-repository-initialization.sh` - Corrigir inicialização

### **Teste:**
1. `test-api-keys-portforward.sh` - Teste completo via port-forward
2. `check-git-status.sh` - Verificar estado do Git
3. `compare-source-vs-compiled.sh` - Comparar fonte vs compilado

---

## 🔍 **TROUBLESHOOTING PLAYBOOK**

### **Problema: "Cannot read properties of undefined"**

**Diagnóstico:**
```bash
kubectl exec -n shaka-staging <pod> -- node -e "
const { UserRepository } = require('/app/dist/infrastructure/database/repositories/UserRepository');
console.log('repository:', UserRepository.repository);
"
```

**Se resultado for `undefined`:**
- Repository não foi inicializado
- Aplicar getter automático ou chamar initialize()

---

### **Problema: "No metadata for UserEntity"**

**Diagnóstico:**
```bash
kubectl exec -n shaka-staging <pod> -- node -e "
const { AppDataSource } = require('/app/dist/infrastructure/database/config');
console.log('isInitialized:', AppDataSource.isInitialized);
console.log('entities:', AppDataSource.options.entities);
"
```

**Se isInitialized = false:**
- AppDataSource não foi inicializado no startup
- Verificar `DatabaseService.initialize()` no server.js

---

### **Problema: Pod usando imagem antiga**

**Diagnóstico:**
```bash
kubectl exec -n shaka-staging <pod> -- stat -c %y /app/dist/core/services/user/UserService.js
```

**Se data for antiga:**
1. Remover todas imagens do K3s
2. Rebuild sem cache
3. Importar fresh
4. Patch imagePullPolicy: Never
5. Deletar pod e recriar

---

## 📈 **MÉTRICAS DA SESSÃO**

### **Tempo Investido:**
- Diagnóstico inicial: 15 min
- Investigação de estrutura: 20 min
- Tentativas de hotfix: 30 min
- Rebuild e deploy: 25 min
- Investigação de runtime: 20 min
- Total: ~90 min

### **Scripts Criados:** 13
### **Rebuilds Executados:** 3
### **Deploys Realizados:** 4

### **Progresso:**
```
Diagnóstico:    ████████████████████ 100%
Identificação:  ████████████████████ 100%
Correção:       ████████████░░░░░░░░  65%  ← Em andamento
Validação:      ░░░░░░░░░░░░░░░░░░░░   0%  ← Próximo passo
```

---

## 🎯 **ESTADO FINAL DA SESSÃO**

### **✅ SUCESSO:**
- Identificação completa do root cause
- Arquitetura do problema mapeada
- Soluções propostas e documentadas
- Scripts de diagnóstico criados
- Sistema em estado conhecido e previsível

### **⚠️ PENDENTE:**
- Aplicação da correção definitiva
- Validação completa do sistema
- Completar Sprint 1 endpoints

### **📋 PRÓXIMA SESSÃO:**
1. Aplicar correção (Solução 1 ou 2)
2. Validar autenticação funcionando
3. Testar todos endpoints de API Keys
4. Implementar endpoints faltantes
5. Deploy final e validação

---

## 👥 **RESPONSABILIDADES**

### **Backend Team:**
- Decidir qual solução aplicar (1, 2 ou 3)
- Implementar correção
- Validar testes

### **DevOps:**
- Monitorar deploy
- Garantir imagem correta no K8s
- Manter scripts de diagnóstico

### **QA:**
- Validar fluxo completo após correção
- Testar todos endpoints
- Reportar regressões

---

**ASSINADO:**  
CTO Integrador - Equipe Técnica SHAKA API  
**DATA:** 10/12/2025  
**STATUS:** 🔍 **DIAGNÓSTICO COMPLETO - AGUARDANDO CORREÇÃO**

---

> *"A excelência técnica não está em evitar bugs, mas em diagnosticá-los com precisão cirúrgica e documentar o caminho para que outros aprendam."*

---

## 📎 **ANEXOS**

### **A. Comando para Aplicar Correção Rápida**
```bash
cd ~/shaka-validation
./fix-repository-initialization.sh
```

### **B. Comando para Validação Completa**
```bash
cd ~/shaka-validation
./test-api-keys-portforward.sh
```

### **C. Logs Relevantes**
```
/tmp/sprint1-validation-*.log
/tmp/shaka-migration-*.log
```

### **D. Arquivos-Chave**
```
~/shaka-api/src/infrastructure/database/repositories/UserRepository.ts
~/shaka-api/src/infrastructure/database/DatabaseService.ts
~/shaka-api/src/infrastructure/database/config.ts
~/shaka-api/src/server.ts
```
