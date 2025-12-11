#!/bin/bash

#############################################################################
# SCRIPT 44: DEPLOY SHAKA API TO KUBERNETES
# 
# Descrição: Build Docker image e deploy nos 3 ambientes K8s
# Autor: Headmaster CTO Integrador
# Data: 28/11/2025
# Duração: 1-2 horas
#
# Pré-requisitos:
# - Build TypeScript OK (dist/ existe)
# - K3s rodando
# - PostgreSQL e Redis deployados
# - Secrets configurados
#
# Saída esperada:
# - 3 deployments (dev, staging, prod)
# - 5-7 pods rodando (1 dev, 2 staging, 2-3 prod)
# - Health checks passando
#############################################################################

set -e  # Exit on error

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🚀 SCRIPT 44: DEPLOY API TO K8S"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Função de log
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Função de validação
validate_prerequisite() {
    local check=$1
    local message=$2
    
    if $check; then
        log_success "$message"
        return 0
    else
        log_error "$message"
        return 1
    fi
}

#############################################################################
# FASE 1: VALIDAÇÃO DE PRÉ-REQUISITOS
#############################################################################

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  📋 FASE 1: VALIDAÇÃO DE PRÉ-REQUISITOS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

cd ~/shaka-api || exit 1

# 1.1 - Validar build TypeScript
log_info "Verificando build TypeScript..."
if [ -f "dist/server.js" ]; then
    SIZE=$(du -h dist/server.js | cut -f1)
    log_success "Build TypeScript OK (dist/server.js: $SIZE)"
else
    log_error "Build TypeScript não encontrado. Execute: npm run build"
    exit 1
fi

# 1.2 - Validar Dockerfile
log_info "Verificando Dockerfile..."
if [ -f "docker/api/Dockerfile" ]; then
    log_success "Dockerfile encontrado"
else
    log_error "Dockerfile não encontrado em docker/api/"
    exit 1
fi

# 1.3 - Validar K3s
log_info "Verificando K3s..."
if sudo k3s kubectl get nodes &>/dev/null; then
    log_success "K3s rodando"
else
    log_error "K3s não está rodando. Inicie com: sudo systemctl start k3s"
    exit 1
fi

# 1.4 - Validar PostgreSQL pods
log_info "Verificando PostgreSQL pods..."
PG_PODS=$(sudo k3s kubectl get pods -A | grep postgres | grep Running | wc -l)
if [ "$PG_PODS" -ge 3 ]; then
    log_success "PostgreSQL pods rodando ($PG_PODS/3)"
else
    log_warning "PostgreSQL pods incompletos ($PG_PODS/3). Continuando..."
fi

# 1.5 - Validar Redis pod
log_info "Verificando Redis pod..."
REDIS_PODS=$(sudo k3s kubectl get pods -n shaka-shared | grep redis | grep Running | wc -l)
if [ "$REDIS_PODS" -ge 1 ]; then
    log_success "Redis pod rodando"
else
    log_warning "Redis pod não está rodando. Continuando..."
fi

# 1.6 - Validar deployment manifest
log_info "Verificando deployment manifest..."
if [ -f "infrastructure/kubernetes/05-api-deployment.yaml" ]; then
    log_success "Deployment manifest encontrado"
else
    log_error "Manifest não encontrado: infrastructure/kubernetes/05-api-deployment.yaml"
    exit 1
fi

echo ""
log_success "✅ PRÉ-REQUISITOS VALIDADOS"
echo ""

#############################################################################
# FASE 2: BUILD DOCKER IMAGE
#############################################################################

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🐳 FASE 2: BUILD DOCKER IMAGE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

log_info "Iniciando build Docker..."
log_info "Dockerfile: docker/api/Dockerfile"
log_info "Context: ~/shaka-api"
log_info "Tag: shaka-api:latest"
echo ""

# 2.1 - Build da imagem
log_info "Executando: docker build -t shaka-api:latest -f docker/api/Dockerfile ."
echo ""

if docker build -t shaka-api:latest -f docker/api/Dockerfile . 2>&1 | tee /tmp/docker-build.log; then
    log_success "Docker image buildada com sucesso!"
else
    log_error "Falha no build Docker. Verifique logs em /tmp/docker-build.log"
    exit 1
fi

# 2.2 - Verificar tamanho da imagem
log_info "Verificando tamanho da imagem..."
IMAGE_SIZE=$(docker images shaka-api:latest --format "{{.Size}}")
log_success "Imagem criada: shaka-api:latest ($IMAGE_SIZE)"

# 2.3 - Validar layers
log_info "Validando layers da imagem..."
LAYERS=$(docker history shaka-api:latest --no-trunc | wc -l)
log_info "Layers: $LAYERS"

echo ""
log_success "✅ DOCKER IMAGE BUILDADA"
echo ""

#############################################################################
# FASE 3: IMPORT PARA K3S
#############################################################################

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  📦 FASE 3: IMPORT PARA K3S REGISTRY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

log_info "Importando imagem para K3s internal registry..."
log_info "Comando: docker save shaka-api:latest | sudo k3s ctr images import -"
echo ""

if docker save shaka-api:latest | sudo k3s ctr images import -; then
    log_success "Imagem importada para K3s!"
else
    log_error "Falha ao importar imagem para K3s"
    exit 1
fi

# 3.1 - Verificar import
log_info "Verificando imagem no K3s..."
if sudo k3s ctr images ls | grep -q "shaka-api:latest"; then
    log_success "Imagem disponível no K3s registry"
    sudo k3s ctr images ls | grep shaka-api
else
    log_error "Imagem não encontrada no K3s registry"
    exit 1
fi

echo ""
log_success "✅ IMAGEM IMPORTADA PARA K3S"
echo ""

#############################################################################
# FASE 4: APPLY DEPLOYMENT MANIFESTS
#############################################################################

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ☸️  FASE 4: APPLY DEPLOYMENT MANIFESTS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

log_info "Aplicando deployment manifest..."
log_info "File: infrastructure/kubernetes/05-api-deployment.yaml"
echo ""

if sudo k3s kubectl apply -f infrastructure/kubernetes/05-api-deployment.yaml; then
    log_success "Manifests aplicados!"
else
    log_error "Falha ao aplicar manifests"
    exit 1
fi

echo ""

# 4.1 - Verificar recursos criados
log_info "Verificando recursos criados..."
echo ""

log_info "Deployments:"
sudo k3s kubectl get deployments -A | grep shaka-api

echo ""
log_info "Services:"
sudo k3s kubectl get services -A | grep shaka-api

echo ""
log_info "HPA (se configurado):"
sudo k3s kubectl get hpa -A | grep shaka-api || log_info "HPA não configurado"

echo ""
log_success "✅ MANIFESTS APLICADOS"
echo ""

#############################################################################
# FASE 5: AGUARDAR PODS READY
#############################################################################

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ⏳ FASE 5: AGUARDANDO PODS READY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

log_info "Aguardando pods ficarem prontos (timeout: 5 minutos)..."
echo ""

# 5.1 - Wait for dev
log_info "Ambiente: DEV"
if sudo k3s kubectl wait --for=condition=ready pod -l app=shaka-api -n shaka-dev --timeout=300s 2>/dev/null; then
    log_success "✅ Pods DEV prontos"
else
    log_warning "⚠️  Pods DEV ainda não estão prontos"
fi

echo ""

# 5.2 - Wait for staging
log_info "Ambiente: STAGING"
if sudo k3s kubectl wait --for=condition=ready pod -l app=shaka-api -n shaka-staging --timeout=300s 2>/dev/null; then
    log_success "✅ Pods STAGING prontos"
else
    log_warning "⚠️  Pods STAGING ainda não estão prontos"
fi

echo ""

# 5.3 - Wait for prod
log_info "Ambiente: PRODUCTION"
if sudo k3s kubectl wait --for=condition=ready pod -l app=shaka-api -n shaka-prod --timeout=300s 2>/dev/null; then
    log_success "✅ Pods PROD prontos"
else
    log_warning "⚠️  Pods PROD ainda não estão prontos"
fi

echo ""

# 5.4 - Status geral
log_info "Status geral dos pods:"
echo ""
sudo k3s kubectl get pods -A | grep -E "NAMESPACE|shaka-api"

echo ""

#############################################################################
# FASE 6: HEALTH CHECKS
#############################################################################

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🏥 FASE 6: HEALTH CHECKS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 6.1 - Verificar logs de cada ambiente
log_info "Verificando logs dos pods..."
echo ""

for NS in shaka-dev shaka-staging shaka-prod; do
    log_info "═══════════════════════════════════════"
    log_info "Namespace: $NS"
    log_info "═══════════════════════════════════════"
    echo ""
    
    POD=$(sudo k3s kubectl get pods -n $NS -l app=shaka-api -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [ -n "$POD" ]; then
        log_info "Pod: $POD"
        log_info "Últimas 20 linhas de log:"
        echo ""
        sudo k3s kubectl logs $POD -n $NS --tail=20 2>/dev/null || log_warning "Logs não disponíveis ainda"
        echo ""
    else
        log_warning "Nenhum pod encontrado em $NS"
        echo ""
    fi
done

# 6.2 - Test health endpoint (se acessível)
log_info "Testando health endpoints..."
echo ""

for NS in shaka-dev shaka-staging shaka-prod; do
    POD=$(sudo k3s kubectl get pods -n $NS -l app=shaka-api -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [ -n "$POD" ]; then
        log_info "Testing $NS..."
        if sudo k3s kubectl exec $POD -n $NS -- wget -q -O- http://localhost:3000/health 2>/dev/null; then
            log_success "✅ Health check $NS OK"
        else
            log_warning "⚠️  Health check $NS failed (pod pode estar iniciando)"
        fi
        echo ""
    fi
done

echo ""

#############################################################################
# FASE 7: SUMMARY & VALIDATION
#############################################################################

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  📊 FASE 7: SUMMARY & VALIDATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 7.1 - Contar pods running
TOTAL_PODS=$(sudo k3s kubectl get pods -A | grep shaka-api | grep Running | wc -l)
TOTAL_EXPECTED=5  # 1 dev + 2 staging + 2 prod

log_info "Pods rodando: $TOTAL_PODS/$TOTAL_EXPECTED"

# 7.2 - Deployment status
log_info "Status dos deployments:"
echo ""
sudo k3s kubectl get deployments -A | grep shaka-api

echo ""

# 7.3 - Services
log_info "Services criados:"
echo ""
sudo k3s kubectl get services -A | grep shaka-api

echo ""

# 7.4 - Resource usage
log_info "Uso de recursos (se disponível):"
echo ""
sudo k3s kubectl top pods -A | grep shaka-api 2>/dev/null || log_info "Metrics server não instalado"

echo ""

#############################################################################
# FASE 8: COMANDOS ÚTEIS
#############################################################################

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  📚 COMANDOS ÚTEIS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

cat <<'EOF'
# Ver logs de um pod
sudo k3s kubectl logs -f <POD_NAME> -n shaka-dev

# Ver logs de todos os pods
sudo k3s kubectl logs -l app=shaka-api -n shaka-dev --tail=50

# Entrar em um pod
sudo k3s kubectl exec -it <POD_NAME> -n shaka-dev -- sh

# Testar health check
sudo k3s kubectl exec <POD_NAME> -n shaka-dev -- wget -q -O- http://localhost:3000/health

# Ver eventos
sudo k3s kubectl get events -n shaka-dev --sort-by='.lastTimestamp' | tail -20

# Deletar pods (força recreate)
sudo k3s kubectl delete pods -l app=shaka-api -n shaka-dev

# Ver describe de um pod
sudo k3s kubectl describe pod <POD_NAME> -n shaka-dev

# Ver recursos alocados
sudo k3s kubectl describe node | grep -A 8 "Allocated resources"
EOF

echo ""

#############################################################################
# CONCLUSÃO
#############################################################################

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ SCRIPT 44 COMPLETO!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ "$TOTAL_PODS" -ge 3 ]; then
    log_success "🎉 DEPLOY REALIZADO COM SUCESSO!"
    log_success "Pods rodando: $TOTAL_PODS"
    log_success ""
    log_success "Próximos passos:"
    log_success "1. Verificar logs: sudo k3s kubectl logs -l app=shaka-api -n shaka-dev"
    log_success "2. Testar health: sudo k3s kubectl exec <POD> -n shaka-dev -- wget -O- http://localhost:3000/health"
    log_success "3. Configurar Ingress (Script 45)"
else
    log_warning "⚠️  DEPLOY PARCIALMENTE COMPLETO"
    log_warning "Pods rodando: $TOTAL_PODS/$TOTAL_EXPECTED"
    log_warning ""
    log_warning "Troubleshooting:"
    log_warning "1. Verificar logs: sudo k3s kubectl logs -l app=shaka-api --all-namespaces"
    log_warning "2. Verificar eventos: sudo k3s kubectl get events --all-namespaces | grep shaka-api"
    log_warning "3. Verificar secrets: sudo k3s kubectl get secrets -n shaka-dev"
    log_warning "4. Verificar configmaps: sudo k3s kubectl get configmaps -n shaka-dev"
fi

echo ""
log_info "Log completo salvo em: /tmp/docker-build.log"
echo ""

exit 0
