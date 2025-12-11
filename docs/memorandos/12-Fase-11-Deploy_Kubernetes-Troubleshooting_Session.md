# 📋 MEMORANDO DE HANDOFF/ONBOARDING - SHAKA API

## 🎯 INFORMAÇÕES DA SESSÃO

**Data:** 28 de Novembro de 2025  
**Hora:** 20:00 - 21:35 UTC (1h35min)  
**CTO Responsável:** Headmaster Integrador  
**Projeto:** Shaka API - Sistema Enterprise de API Management  
**Fase:** Deploy Kubernetes - Troubleshooting Session  
**Status:** ⚠️ **PARCIALMENTE COMPLETO** - Investigação em andamento  

---

## 📊 RESUMO EXECUTIVO

### Objetivo da Sessão
Realizar o primeiro deploy da API Shaka no cluster Kubernetes K3s, validando a stack completa (PostgreSQL + Redis + API Node.js).

### Problemas Encontrados e Resolvidos
1. ✅ **Logger Permission Issue** - EACCES na criação do diretório `logs/`
2. ✅ **Module Resolution** - Path aliases TypeScript não resolvidos em runtime
3. ⚠️ **CrashLoopBackOff Persistente** - Investigação em andamento

### Status Atual
- **Build TypeScript:** ✅ Sucesso
- **Docker Image:** ✅ Criada (205MB)
- **K3s Import:** ✅ Sucesso
- **Pods Running:** ❌ 0/3 (CrashLoopBackOff)

---

## 🔍 CRONOLOGIA DETALHADA

### 20:06 - Deploy Inicial (Script 44)
**Ação:** Primeiro deploy dos manifestos Kubernetes
```bash
bash ~/shaka-api/scripts/deployment/deploy-api-k8s.sh
```

**Resultado:**
- ✅ Manifestos aplicados com sucesso
- ✅ 3 deployments criados (dev, staging, prod)
- ✅ 3 services criados
- ❌ Pods em CrashLoopBackOff

**Erro Identificado:**
```
Error: EACCES: permission denied, mkdir 'logs'
```

**Root Cause:** Container rodando como `nodejs` user (non-root) sem permissão para criar diretório.

---

### 20:12 - Primeira Tentativa de Correção
**Script:** `fix-logger-permissions.sh`

**Mudanças Aplicadas:**
```dockerfile
# Adicionado no Dockerfile antes de USER nodejs
RUN mkdir -p /app/logs && chown -R nodejs:nodejs /app/logs
```

**Execução:**
- ✅ Dockerfile atualizado
- ✅ Image rebuilded
- ✅ Reimportado para K3s
- ✅ HPA removido (otimização de recursos)
- ✅ Replicas reduzidas para 1 por ambiente

**Resultado:**
- ❌ **Novo erro identificado:** `Cannot find module '@core/services/auth/AuthService'`

---

### 20:18 - Investigação Root Cause
**Descoberta Crítica:**
```javascript
// Código compilado (dist/):
require('@core/services/auth/AuthService')

// Node.js em runtime não entende path aliases do TypeScript
// Precisa de: require('../../../core/services/auth/AuthService')
```

**Diagnóstico:**
- TypeScript `paths` no `tsconfig.json` funcionam em dev (ts-node resolve)
- ❌ Não funcionam em prod (node puro não resolve)
- Solução: `tsconfig-paths/register` em runtime

---

### 20:25 - Segunda Correção (Module Resolution)
**Mudanças Aplicadas:**

**1. Dockerfile CMD atualizado:**
```dockerfile
# ANTES
CMD ["node", "dist/server.js"]

# DEPOIS
CMD ["node", "-r", "tsconfig-paths/register", "dist/server.js"]
```

**2. package.json atualizado:**
```json
{
  "scripts": {
    "start": "node -r tsconfig-paths/register dist/server.js"
  }
}
```

**Execução:**
```bash
npm run build
docker build -t shaka-api:latest -f docker/api/Dockerfile .
docker save shaka-api:latest | sudo k3s ctr images import -
kubectl delete pods -l app=shaka-api --all-namespaces
sleep 60
```

**Resultado:**
- ✅ Build sucesso
- ✅ Image criada
- ✅ Reimportada
- ❌ **Pods ainda em CrashLoopBackOff**

---

### 21:35 - Status Final da Sessão
**Pods Status:**
```
NAMESPACE     NAME                          STATUS             RESTARTS
shaka-dev     shaka-api-xxx-pmxnq          CrashLoopBackOff   3 (17s ago)
shaka-prod    shaka-api-xxx-t8rqb          CrashLoopBackOff   3 (15s ago)
shaka-staging shaka-api-xxx-qcs6l          Pending            0
```

**Ações Pendentes:**
1. Verificar logs atuais do pod
2. Identificar novo erro (se houver)
3. Aplicar correção definitiva

---

## 🛠️ ARQUIVOS MODIFICADOS

### 1. Dockerfile
**Arquivo:** `docker/api/Dockerfile`

**Mudanças:**
```dockerfile
# Linha adicionada antes de USER nodejs
RUN mkdir -p /app/logs && chown -R nodejs:nodejs /app/logs

# CMD atualizado
CMD ["node", "-r", "tsconfig-paths/register", "dist/server.js"]
```

**Versões:**
- `Dockerfile.backup` - Original
- `Dockerfile.backup2` - Após primeira correção
- `Dockerfile` - Atual (com ambas correções)

---

### 2. package.json
**Arquivo:** `package.json`

**Mudanças:**
```json
{
  "scripts": {
    "start": "node -r tsconfig-paths/register dist/server.js",
    "start:prod": "NODE_ENV=production node -r tsconfig-paths/register dist/server.js"
  }
}
```

**Versão:**
- `package.json.backup` - Original
- `package.json` - Atual

---

### 3. Scripts Criados

**Diretório:** `~/shaka-api/scripts/deployment/`

```
create-api-deployment-manifest.sh    # Cria 05-api-deployment.yaml
deploy-api-k8s.sh                    # Deploy completo (Script 44)
fix-logger-permissions.sh            # Correção 1 (logger)
fix-module-resolution.sh             # Correção 2 (paths) - NÃO USADO
```

---

## 📊 MÉTRICAS DA SESSÃO

### Tempo Investido
```
Diagnóstico inicial:      15 min
Primeira correção:        20 min
Segunda correção:         25 min
Troubleshooting:          35 min
─────────────────────────────────
TOTAL:                    1h35min
```

### Tentativas de Deploy
```
Deploy 1: 20:06 - EACCES error
Deploy 2: 20:12 - Module not found
Deploy 3: 20:25 - CrashLoopBackOff (atual)
```

### Recursos Utilizados
```
Docker builds:      3
K3s imports:        3
Pod recreations:    3
Scripts criados:    4
```

---

## 🎓 LIÇÕES APRENDIDAS

### 1. **Non-root Containers Require Planning**

**Problema:** User `nodejs` não tem permissão para criar diretórios em `/app`.

**Solução:** Criar diretórios **antes** de trocar para non-root:
```dockerfile
RUN mkdir -p /app/logs /app/uploads /app/temp && \
    chown -R nodejs:nodejs /app
USER nodejs
```

**Best Practice:** Mapear volumes externos (emptyDir, PVC) para writes.

---

### 2. **TypeScript Paths em Produção**

**Problema:** `tsconfig.json paths` não funcionam em runtime Node.js puro.

**Soluções avaliadas:**

| Opção | Prós | Contras | Escolhida |
|-------|------|---------|-----------|
| `tsconfig-paths/register` | Simples, sem build changes | Overhead runtime mínimo | ✅ Sim |
| `tsc-alias` | Resolve em build time | Dependência extra | ❌ |
| Webpack/esbuild | Bundle único | Complexidade alta | ❌ |

**Implementação:**
```bash
node -r tsconfig-paths/register dist/server.js
```

---

### 3. **Kubernetes CrashLoopBackOff Debugging**

**Workflow estabelecido:**
```bash
# 1. Verificar status
kubectl get pods -A | grep shaka-api

# 2. Ver logs (erro atual)
kubectl logs -l app=shaka-api -n shaka-dev --tail=30

# 3. Eventos (histórico)
kubectl get events -n shaka-dev --sort-by='.lastTimestamp' | tail -20

# 4. Describe pod (detalhes)
POD=$(kubectl get pods -n shaka-dev -l app=shaka-api -o jsonpath='{.items[0].metadata.name}')
kubectl describe pod $POD -n shaka-dev

# 5. Exec no pod (se possível)
kubectl exec -it $POD -n shaka-dev -- sh
```

---

### 4. **Docker Multi-stage Build Benefits**

**Arquitetura implementada:**
```
Stage 1 (builder): node:20-alpine
  ├─ Instala devDependencies
  ├─ Compila TypeScript
  └─ Remove devDependencies (npm prune)

Stage 2 (runtime): node:20-alpine
  ├─ Copia node_modules produção
  ├─ Copia dist/ compilado
  └─ User nodejs (non-root)
```

**Resultado:**
- Imagem final: ~205MB (vs ~800MB com devDeps)
- Mais segura (sem ferramentas de build)
- Startup mais rápido

---

### 5. **Resource Constraints em Servidor Limitado**

**Servidor atual:**
```
CPU:  2 cores
RAM:  ~2GB
```

**Pods planejados:**
```
PostgreSQL: 3 × 256MB = 768MB
Redis:      1 × 128MB = 128MB
API:        3 × 128MB = 384MB
─────────────────────────────────
TOTAL:      1280MB (~1.3GB)
```

**Otimizações aplicadas:**
- ✅ Removido HPA (reduzia disponibilidade)
- ✅ 1 replica por ambiente (ao invés de 2 em staging/prod)
- ✅ Redis shared (economia de 256MB vs 3 separados)

**Conclusão:** Servidor viável para dev/staging/prod com 1 replica cada.

---

## 🔧 PRÓXIMOS PASSOS (SESSÃO FUTURA)

### IMEDIATO (Próxima Sessão - 15 min)

**1. Verificar erro atual:**
```bash
kubectl logs -l app=shaka-api -n shaka-dev --tail=50
```

**2. Hipóteses possíveis:**
- ❓ Novo erro TypeScript/JavaScript não identificado
- ❓ Database connection failed (postgres-dev não conecta)
- ❓ Redis connection failed (redis shared não conecta)
- ❓ Secrets faltando/incorretos
- ❓ ConfigMap com valores errados

**3. Diagnóstico completo:**
```bash
# Ver se DB/Redis estão rodando
kubectl get pods -n shaka-dev | grep postgres
kubectl get pods -n shaka-shared | grep redis

# Testar conectividade
kubectl exec postgres-0 -n shaka-dev -- pg_isready
kubectl exec redis-0 -n shaka-shared -- redis-cli ping

# Verificar secrets
kubectl get secret shaka-api-secrets -n shaka-dev -o jsonpath='{.data}' | jq 'keys'

# Verificar configmap
kubectl describe configmap shaka-api-config -n shaka-dev
```

---

### CURTO PRAZO (Esta Semana)

**1. Completar Deploy API** (1-2 horas)
- Resolver CrashLoopBackOff atual
- Validar 3/3 ambientes rodando
- Testar health endpoints
- Verificar logs de inicialização

**2. Ingress & TLS** (1 hora)
- Instalar Traefik ou NGINX Ingress Controller
- Configurar Cert-Manager
- Setup Let's Encrypt
- DNS apontando para cluster

**3. Metrics Server** (30 min)
```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

**4. Testes E2E** (1 hora)
- Registro de usuário
- Login
- CRUD operações
- Rate limiting
- JWT refresh

---

### MÉDIO PRAZO (Este Mês)

**1. Observability Stack** (2-3 horas)
- Prometheus + Grafana
- Loki (log aggregation)
- Dashboards customizados
- Alertas críticos

**2. CI/CD Pipeline** (2-3 horas)
- GitHub Actions workflow
- Automated testing
- Docker registry push
- K8s deployment automation

**3. Backup & Disaster Recovery** (1-2 horas)
- PostgreSQL backups automáticos (CronJob)
- S3/GCS backup storage
- Restore procedures testadas
- Retention policies

**4. Documentation** (1 hora)
- README atualizado
- Deployment guide
- Troubleshooting guide
- Architecture diagrams

---

## 📋 CHECKLIST DE VALIDAÇÃO FINAL

### Build & Image
- [x] TypeScript build sem erros
- [x] Dockerfile multi-stage otimizado
- [x] Image size < 300MB
- [x] Image importada no K3s
- [x] Non-root user (nodejs)
- [x] Health check configurado

### Kubernetes Resources
- [x] Namespaces criados (3)
- [x] ConfigMaps aplicados (3)
- [x] Secrets aplicados (3)
- [x] PostgreSQL rodando (3/3)
- [x] Redis rodando (1/1)
- [ ] API rodando (0/3) ⚠️ **PENDENTE**

### Code Fixes
- [x] Logger permissions corrigidos
- [x] TypeScript paths runtime resolver
- [ ] Startup bem-sucedido ⚠️ **PENDENTE**

---

## 🚨 PROBLEMAS CONHECIDOS

### 1. CrashLoopBackOff Não Resolvido
**Status:** ⚠️ Investigação necessária  
**Prioridade:** 🔴 CRÍTICA  
**Próxima Ação:** Verificar logs atuais do pod  

**Comando de diagnóstico:**
```bash
kubectl logs -l app=shaka-api -n shaka-dev --tail=50
```

---

### 2. HPA Sem Metrics Server
**Status:** ⚠️ Conhecido mas não crítico  
**Prioridade:** 🟡 MÉDIA  
**Próxima Ação:** Instalar Metrics Server  

**Solução:**
```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Depois recriar HPA
kubectl apply -f ~/shaka-api/infrastructure/kubernetes/05-api-deployment.yaml
```

---

### 3. Recursos Limitados do Servidor
**Status:** ⚠️ Mitigado (1 replica/ambiente)  
**Prioridade:** 🟢 BAIXA  
**Próxima Ação:** Monitorar uso (kubectl top)  

**Solução de longo prazo:**
- Upgrade servidor (4 CPU / 4GB RAM)
- Ou mover para cloud (GKE, EKS, AKS)

---

## 📚 DOCUMENTAÇÃO GERADA

### Memorandos Anteriores
```
Fase-9-Kubernetes_Production-Grade_Infrastructure.md
Fase-10-Correção_TypeScript_Build+Preparação_Docker.md
```

### Novos Documentos (Esta Sessão)
```
Memorando-Deploy-K8s-Session-1.md (este documento)
```

### Scripts Criados
```
~/shaka-api/scripts/deployment/
├── create-api-deployment-manifest.sh    (Script 44A)
├── deploy-api-k8s.sh                    (Script 44)
├── fix-logger-permissions.sh            (Script 45)
└── fix-module-resolution.sh             (Script 46 - não usado)
```

### Manifests Kubernetes
```
~/shaka-api/infrastructure/kubernetes/
├── 01-namespace.yaml
├── 02-configmaps-secrets.yaml
├── 03-postgres-prod-fixed.yaml
├── 04-redis-simple-scalable.yaml
└── 05-api-deployment.yaml               (NOVO - 483 linhas)
```

---

## 🎯 COMANDOS ÚTEIS PARA PRÓXIMA SESSÃO

### Diagnóstico Rápido
```bash
# Status geral
kubectl get pods -A | grep -E "shaka|postgres|redis"

# Logs do erro atual
kubectl logs -l app=shaka-api -n shaka-dev --tail=50

# Eventos recentes
kubectl get events -A --sort-by='.lastTimestamp' | grep shaka | tail -20

# Describe pod problemático
POD=$(kubectl get pods -n shaka-dev -l app=shaka-api -o jsonpath='{.items[0].metadata.name}')
kubectl describe pod $POD -n shaka-dev
```

### Testes de Conectividade
```bash
# PostgreSQL
kubectl exec postgres-0 -n shaka-dev -- \
  psql -U shaka_dev -d shaka_dev -c "SELECT version();"

# Redis
kubectl exec redis-0 -n shaka-shared -- redis-cli ping

# DNS resolution (de dentro de um pod)
kubectl run -it --rm debug --image=busybox --restart=Never -- \
  nslookup postgres-dev.shaka-dev.svc.cluster.local
```

### Force Recreate
```bash
# Se precisar forçar recreação
kubectl delete pods -l app=shaka-api --all-namespaces
kubectl rollout restart deployment shaka-api -n shaka-dev
```

---

## 📊 DASHBOARD DE STATUS

```
┌─────────────────────────────────────────────────────┐
│  SHAKA API - KUBERNETES DEPLOY STATUS               │
├─────────────────────────────────────────────────────┤
│  Fase 9:  Infrastructure         ✅ 100%           │
│  Fase 10: TypeScript Build       ✅ 100%           │
│  Fase 11: Docker Containerization ✅ 100%           │
│  Fase 12: K8s Deploy             ⚠️  80%            │
├─────────────────────────────────────────────────────┤
│  PostgreSQL (3 ambientes)        ✅ 3/3 Running    │
│  Redis (shared)                  ✅ 1/1 Running    │
│  API (3 ambientes)               ❌ 0/3 Running    │
├─────────────────────────────────────────────────────┤
│  BLOQUEADOR:                                        │
│  API pods em CrashLoopBackOff                       │
│  Investigação de logs necessária                    │
└─────────────────────────────────────────────────────┘
```

---

## ✅ CONCLUSÃO

### Conquistas da Sessão
1. ✅ Primeiro deploy completo executado
2. ✅ 2 problemas críticos identificados e corrigidos
3. ✅ Infraestrutura (DB + Redis) 100% operacional
4. ✅ Docker image otimizada (<205MB)
5. ✅ Metodologia de troubleshooting estabelecida

### Pendências Críticas
1. ⚠️ Resolver CrashLoopBackOff atual
2. ⚠️ Validar API initialization completa
3. ⚠️ Testar health endpoints

### Estimativa de Conclusão
- **Próxima sessão:** 15-30 minutos (diagnóstico + fix)
- **Deploy completo:** 1-2 horas adicionais
- **MVP production-ready:** 3-4 horas totais

---

## 📞 INFORMAÇÕES DE HANDOFF

### Para o Próximo CTO/Desenvolvedor

**Estado atual:**
- Código TypeScript: ✅ Build limpo
- Docker image: ✅ Criada e otimizada
- K3s cluster: ✅ Operacional
- Database: ✅ 3 ambientes rodando
- Cache: ✅ Redis shared rodando
- API: ❌ CrashLoopBackOff (logs pending)

**Primeiro comando a executar:**
```bash
kubectl logs -l app=shaka-api -n shaka-dev --tail=50
```

**Documentação relevante:**
- Este memorando (troubleshooting steps)
- Fase 9 (K8s infrastructure)
- Fase 10 (TypeScript build fixes)

**Contato:**
- Scripts em: `~/shaka-api/scripts/deployment/`
- Manifests em: `~/shaka-api/infrastructure/kubernetes/`
- Logs em: `/tmp/rebuild*.log`

---

**Assinatura Digital:**  
🔧 **Headmaster CTO Integrador**  
📅 **28/11/2025 - 21:35 UTC**  
🚀 **Projeto:** Shaka API v1.0  
⚠️ **Status:** Deploy 80% - Troubleshooting Pendente  

---

**Fim do Memorando**

_Este documento serve como registro completo da sessão de deploy e guia 
para continuação do troubleshooting na próxima sessão._
