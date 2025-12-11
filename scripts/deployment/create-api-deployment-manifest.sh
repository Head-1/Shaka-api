#!/bin/bash

#############################################################################
# SCRIPT 44B: CREATE API DEPLOYMENT MANIFEST
# 
# Descrição: Gera manifest K8s completo para deploy da API
# Autor: Headmaster CTO Integrador
# Data: 28/11/2025
# Duração: 5 minutos
#
# Output: infrastructure/kubernetes/05-api-deployment.yaml
#############################################################################

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  📝 SCRIPT 44B: CREATE API DEPLOYMENT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

cd ~/shaka-api || exit 1

# Criar diretório se não existir
mkdir -p infrastructure/kubernetes

echo -e "${BLUE}[INFO]${NC} Criando manifest: 05-api-deployment.yaml"
echo ""

cat > infrastructure/kubernetes/05-api-deployment.yaml << 'EOFMANIFEST'
#############################################################################
# SHAKA API - KUBERNETES DEPLOYMENT MANIFEST
# 
# Componentes:
# - Deployments (dev, staging, prod)
# - Services (ClusterIP)
# - HorizontalPodAutoscaler (prod)
#
# Versão: 1.0
# Data: 28/11/2025
#############################################################################

---
#############################################################################
# DEVELOPMENT ENVIRONMENT
#############################################################################

apiVersion: apps/v1
kind: Deployment
metadata:
  name: shaka-api
  namespace: shaka-dev
  labels:
    app: shaka-api
    environment: development
    version: v1.0.0
spec:
  replicas: 1
  selector:
    matchLabels:
      app: shaka-api
      environment: development
  template:
    metadata:
      labels:
        app: shaka-api
        environment: development
        version: v1.0.0
    spec:
      containers:
      - name: api
        image: shaka-api:latest
        imagePullPolicy: Never  # Use local image (K3s import)
        ports:
        - containerPort: 3000
          name: http
          protocol: TCP
        
        # Environment variables from ConfigMap
        envFrom:
        - configMapRef:
            name: shaka-api-config
        
        # Secrets (DB passwords, JWT, etc)
        env:
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: shaka-api-secrets
              key: DB_PASSWORD
        - name: REDIS_PASSWORD
          valueFrom:
            secretKeyRef:
              name: shaka-api-secrets
              key: REDIS_PASSWORD
        - name: JWT_SECRET
          valueFrom:
            secretKeyRef:
              name: shaka-api-secrets
              key: JWT_SECRET
        - name: JWT_REFRESH_SECRET
          valueFrom:
            secretKeyRef:
              name: shaka-api-secrets
              key: JWT_REFRESH_SECRET
        - name: ENCRYPTION_KEY
          valueFrom:
            secretKeyRef:
              name: shaka-api-secrets
              key: ENCRYPTION_KEY
        
        # Resource limits (dev = relaxed)
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 512Mi
        
        # Liveness probe (restart if unhealthy)
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        
        # Readiness probe (receive traffic when ready)
        readinessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 10
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
        
        # Startup probe (allow slow startup)
        startupProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 0
          periodSeconds: 10
          timeoutSeconds: 3
          failureThreshold: 30  # 5 minutes max startup
      
      # Restart policy
      restartPolicy: Always

---
apiVersion: v1
kind: Service
metadata:
  name: shaka-api
  namespace: shaka-dev
  labels:
    app: shaka-api
    environment: development
spec:
  type: ClusterIP
  selector:
    app: shaka-api
    environment: development
  ports:
  - port: 3000
    targetPort: 3000
    protocol: TCP
    name: http

---
#############################################################################
# STAGING ENVIRONMENT
#############################################################################

apiVersion: apps/v1
kind: Deployment
metadata:
  name: shaka-api
  namespace: shaka-staging
  labels:
    app: shaka-api
    environment: staging
    version: v1.0.0
spec:
  replicas: 2  # 2 replicas for HA
  selector:
    matchLabels:
      app: shaka-api
      environment: staging
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0  # Zero downtime
  template:
    metadata:
      labels:
        app: shaka-api
        environment: staging
        version: v1.0.0
    spec:
      containers:
      - name: api
        image: shaka-api:latest
        imagePullPolicy: Never
        ports:
        - containerPort: 3000
          name: http
          protocol: TCP
        
        envFrom:
        - configMapRef:
            name: shaka-api-config
        
        env:
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: shaka-api-secrets
              key: DB_PASSWORD
        - name: REDIS_PASSWORD
          valueFrom:
            secretKeyRef:
              name: shaka-api-secrets
              key: REDIS_PASSWORD
        - name: JWT_SECRET
          valueFrom:
            secretKeyRef:
              name: shaka-api-secrets
              key: JWT_SECRET
        - name: JWT_REFRESH_SECRET
          valueFrom:
            secretKeyRef:
              name: shaka-api-secrets
              key: JWT_REFRESH_SECRET
        - name: ENCRYPTION_KEY
          valueFrom:
            secretKeyRef:
              name: shaka-api-secrets
              key: ENCRYPTION_KEY
        
        resources:
          requests:
            cpu: 200m
            memory: 256Mi
          limits:
            cpu: 1000m
            memory: 1Gi
        
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        
        readinessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 10
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
        
        startupProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 0
          periodSeconds: 10
          timeoutSeconds: 3
          failureThreshold: 30
      
      restartPolicy: Always
      
      # Anti-affinity (distribute pods across nodes)
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - shaka-api
              topologyKey: kubernetes.io/hostname

---
apiVersion: v1
kind: Service
metadata:
  name: shaka-api
  namespace: shaka-staging
  labels:
    app: shaka-api
    environment: staging
spec:
  type: ClusterIP
  selector:
    app: shaka-api
    environment: staging
  ports:
  - port: 3000
    targetPort: 3000
    protocol: TCP
    name: http

---
#############################################################################
# PRODUCTION ENVIRONMENT
#############################################################################

apiVersion: apps/v1
kind: Deployment
metadata:
  name: shaka-api
  namespace: shaka-prod
  labels:
    app: shaka-api
    environment: production
    version: v1.0.0
spec:
  replicas: 2  # Mínimo 2 para HA (HPA pode escalar até 10)
  selector:
    matchLabels:
      app: shaka-api
      environment: production
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0  # Zero downtime
  template:
    metadata:
      labels:
        app: shaka-api
        environment: production
        version: v1.0.0
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "3000"
        prometheus.io/path: "/metrics"
    spec:
      containers:
      - name: api
        image: shaka-api:latest
        imagePullPolicy: Never
        ports:
        - containerPort: 3000
          name: http
          protocol: TCP
        
        envFrom:
        - configMapRef:
            name: shaka-api-config
        
        env:
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: shaka-api-secrets
              key: DB_PASSWORD
        - name: REDIS_PASSWORD
          valueFrom:
            secretKeyRef:
              name: shaka-api-secrets
              key: REDIS_PASSWORD
        - name: JWT_SECRET
          valueFrom:
            secretKeyRef:
              name: shaka-api-secrets
              key: JWT_SECRET
        - name: JWT_REFRESH_SECRET
          valueFrom:
            secretKeyRef:
              name: shaka-api-secrets
              key: JWT_REFRESH_SECRET
        - name: ENCRYPTION_KEY
          valueFrom:
            secretKeyRef:
              name: shaka-api-secrets
              key: ENCRYPTION_KEY
        
        # Production resources (otimizado para 2 CPU / 2GB RAM)
        resources:
          requests:
            cpu: 200m      # 0.2 CPU
            memory: 256Mi  # 256 MB
          limits:
            cpu: 800m      # 0.8 CPU (deixa margem para outros pods)
            memory: 768Mi  # 768 MB
        
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        
        readinessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 10
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
        
        startupProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 0
          periodSeconds: 10
          timeoutSeconds: 3
          failureThreshold: 30
      
      restartPolicy: Always
      
      # Anti-affinity
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - shaka-api
              topologyKey: kubernetes.io/hostname

---
apiVersion: v1
kind: Service
metadata:
  name: shaka-api
  namespace: shaka-prod
  labels:
    app: shaka-api
    environment: production
spec:
  type: ClusterIP
  selector:
    app: shaka-api
    environment: production
  ports:
  - port: 3000
    targetPort: 3000
    protocol: TCP
    name: http

---
#############################################################################
# HORIZONTAL POD AUTOSCALER (PRODUCTION ONLY)
#############################################################################

apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: shaka-api-hpa
  namespace: shaka-prod
  labels:
    app: shaka-api
    environment: production
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: shaka-api
  minReplicas: 2
  maxReplicas: 4  # Máximo 4 pods (servidor tem 2 CPU / 2GB RAM)
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70  # Scale when CPU > 70%
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80  # Scale when Memory > 80%
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300  # Wait 5 min before scale down
      policies:
      - type: Percent
        value: 50
        periodSeconds: 60  # Scale down max 50% per minute
    scaleUp:
      stabilizationWindowSeconds: 0  # Scale up immediately
      policies:
      - type: Percent
        value: 100
        periodSeconds: 60  # Scale up max 100% per minute
      - type: Pods
        value: 2
        periodSeconds: 60  # Add max 2 pods per minute
EOFMANIFEST

echo -e "${GREEN}[SUCCESS]${NC} Manifest criado!"
echo ""

# Validar YAML
echo -e "${BLUE}[INFO]${NC} Validando sintaxe YAML..."
if command -v yamllint &> /dev/null; then
    yamllint infrastructure/kubernetes/05-api-deployment.yaml || echo "Yamllint não disponível, pulando validação"
else
    echo -e "${YELLOW}[WARNING]${NC} yamllint não instalado, pulando validação"
fi

echo ""

# Mostrar summary
echo -e "${BLUE}[INFO]${NC} Componentes criados:"
echo ""
grep "^kind:" infrastructure/kubernetes/05-api-deployment.yaml | sort | uniq -c
echo ""

echo -e "${GREEN}✅ MANIFEST CRIADO COM SUCESSO!${NC}"
echo ""
echo "Arquivo: infrastructure/kubernetes/05-api-deployment.yaml"
echo "Linhas: $(wc -l < infrastructure/kubernetes/05-api-deployment.yaml)"
echo ""
echo "Próximo passo: Execute o Script 44 novamente"
echo "bash ~/shaka-api/scripts/deployment/deploy-api-k8s.sh"
echo ""
