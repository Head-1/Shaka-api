#!/bin/bash
set -e

echo "🔧 SHAKA API - FIX & OPTIMIZE DEPLOYMENT"
echo "========================================"
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

cd ~/shaka-api

# ═══════════════════════════════════════════════════════════
# PART 1: FIX REQUEST LOGGER BUG
# ═══════════════════════════════════════════════════════════
echo -e "${BLUE}[1/5] Fixing RequestLogger Bug${NC}"
echo "--------------------------------------"

# Backup original
cp src/api/middlewares/requestLogger.ts src/api/middlewares/requestLogger.ts.backup

# Apply fix: req.path → req.originalUrl
sed -i 's/path: req\.path,/path: req.originalUrl,/g' src/api/middlewares/requestLogger.ts

echo -e "${GREEN}✅ RequestLogger fixed: req.path → req.originalUrl${NC}"

# Verify fix
echo ""
echo "Verification:"
grep "path: req\." src/api/middlewares/requestLogger.ts

echo ""

# ═══════════════════════════════════════════════════════════
# PART 2: OPTIMIZE RESOURCE CONFIGURATION
# ═══════════════════════════════════════════════════════════
echo -e "${BLUE}[2/5] Optimizing Resource Configuration${NC}"
echo "--------------------------------------"

# Backup deployments
cp k8s/staging/deployment.yaml k8s/staging/deployment.yaml.backup
cp k8s/dev/deployment.yaml k8s/dev/deployment.yaml.backup
cp k8s/prod/deployment.yaml k8s/prod/deployment.yaml.backup

# Update staging: 1 replica, optimized resources
cat > k8s/staging/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shaka-api
  namespace: shaka-staging
  labels:
    app: shaka-api
    environment: staging
spec:
  replicas: 1  # Otimizado: 1 réplica suficiente para staging
  selector:
    matchLabels:
      app: shaka-api
      environment: staging
  template:
    metadata:
      labels:
        app: shaka-api
        environment: staging
    spec:
      containers:
      - name: shaka-api
        image: registry.localhost:5000/shaka-api:latest
        ports:
        - containerPort: 3000
          name: http
        env:
        - name: NODE_ENV
          value: "staging"
        - name: PORT
          value: "3000"
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: shaka-secrets
              key: database-url-staging
        - name: REDIS_URL
          valueFrom:
            secretKeyRef:
              name: shaka-secrets
              key: redis-url
        - name: JWT_SECRET
          valueFrom:
            secretKeyRef:
              name: shaka-secrets
              key: jwt-secret
        resources:
          requests:
            memory: "128Mi"  # Reduzido de 256Mi
            cpu: "50m"       # Reduzido de 100m
          limits:
            memory: "256Mi"  # Reduzido de 512Mi
            cpu: "200m"      # Reduzido de 500m
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
EOF

# Update dev: 1 replica, minimum resources
cat > k8s/dev/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shaka-api
  namespace: shaka-dev
  labels:
    app: shaka-api
    environment: dev
spec:
  replicas: 1  # Otimizado: 1 réplica para dev
  selector:
    matchLabels:
      app: shaka-api
      environment: dev
  template:
    metadata:
      labels:
        app: shaka-api
        environment: dev
    spec:
      containers:
      - name: shaka-api
        image: registry.localhost:5000/shaka-api:latest
        ports:
        - containerPort: 3000
          name: http
        env:
        - name: NODE_ENV
          value: "development"
        - name: PORT
          value: "3000"
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: shaka-secrets
              key: database-url-dev
        - name: REDIS_URL
          valueFrom:
            secretKeyRef:
              name: shaka-secrets
              key: redis-url
        - name: JWT_SECRET
          valueFrom:
            secretKeyRef:
              name: shaka-secrets
              key: jwt-secret
        resources:
          requests:
            memory: "64Mi"   # Mínimo para dev
            cpu: "25m"       # Mínimo para dev
          limits:
            memory: "128Mi"  # Limite baixo para dev
            cpu: "100m"      # Limite baixo para dev
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 10
          periodSeconds: 5
EOF

# Update prod: Keep 0 replicas for now (will scale when needed)
cat > k8s/prod/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shaka-api
  namespace: shaka-prod
  labels:
    app: shaka-api
    environment: production
spec:
  replicas: 0  # Desligado até ter usuários reais
  selector:
    matchLabels:
      app: shaka-api
      environment: production
  template:
    metadata:
      labels:
        app: shaka-api
        environment: production
    spec:
      containers:
      - name: shaka-api
        image: registry.localhost:5000/shaka-api:latest
        ports:
        - containerPort: 3000
          name: http
        env:
        - name: NODE_ENV
          value: "production"
        - name: PORT
          value: "3000"
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: shaka-secrets
              key: database-url-prod
        - name: REDIS_URL
          valueFrom:
            secretKeyRef:
              name: shaka-secrets
              key: redis-url
        - name: JWT_SECRET
          valueFrom:
            secretKeyRef:
              name: shaka-secrets
              key: jwt-secret
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 10
          periodSeconds: 5
EOF

echo -e "${GREEN}✅ Resource configurations optimized${NC}"
echo ""

# ═══════════════════════════════════════════════════════════
# PART 3: BUILD & DEPLOY
# ═══════════════════════════════════════════════════════════
echo -e "${BLUE}[3/5] Building Application${NC}"
echo "--------------------------------------"

npm run build

echo -e "${GREEN}✅ Build successful${NC}"
echo ""

echo -e "${BLUE}[4/5] Building & Pushing Docker Image${NC}"
echo "--------------------------------------"

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
IMAGE_TAG="registry.localhost:5000/shaka-api:fix-logger-${TIMESTAMP}"

docker build -t $IMAGE_TAG .
docker push $IMAGE_TAG

# Also tag as latest
docker tag $IMAGE_TAG registry.localhost:5000/shaka-api:latest
docker push registry.localhost:5000/shaka-api:latest

echo -e "${GREEN}✅ Image built and pushed: $IMAGE_TAG${NC}"
echo ""

# ═══════════════════════════════════════════════════════════
# PART 5: DEPLOY TO ENVIRONMENTS
# ═══════════════════════════════════════════════════════════
echo -e "${BLUE}[5/5] Deploying to Environments${NC}"
echo "--------------------------------------"

# Deploy dev
echo "Deploying to DEV..."
kubectl apply -f k8s/dev/deployment.yaml
kubectl rollout restart deployment/shaka-api -n shaka-dev
kubectl rollout status deployment/shaka-api -n shaka-dev --timeout=120s

echo ""

# Deploy staging
echo "Deploying to STAGING..."
kubectl apply -f k8s/staging/deployment.yaml
kubectl rollout restart deployment/shaka-api -n shaka-staging
kubectl rollout status deployment/shaka-api -n shaka-staging --timeout=120s

echo ""

# Prod stays at 0 replicas
echo "PROD: Keeping at 0 replicas (will scale when needed)"
kubectl apply -f k8s/prod/deployment.yaml

echo ""
echo -e "${GREEN}✅ Deployment complete${NC}"

# ═══════════════════════════════════════════════════════════
# VERIFICATION
# ═══════════════════════════════════════════════════════════
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "${BLUE}📊 DEPLOYMENT SUMMARY${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo ""

echo "Current Pod Status:"
kubectl get pods -n shaka-dev -l app=shaka-api
kubectl get pods -n shaka-staging -l app=shaka-api
kubectl get pods -n shaka-prod -l app=shaka-api

echo ""
echo "Resource Usage:"
kubectl top node

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ FIX & OPTIMIZATION COMPLETE${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
echo ""
echo "Changes applied:"
echo "  1. ✅ RequestLogger now uses req.originalUrl"
echo "  2. ✅ DEV: 64Mi-128Mi, 25m-100m CPU"
echo "  3. ✅ STAGING: 128Mi-256Mi, 50m-200m CPU"
echo "  4. ✅ PROD: 0 replicas (ready to scale)"
echo ""
echo "Expected memory savings: ~600Mi freed"
echo ""
echo "Next steps:"
echo "  - Test API endpoints: curl http://staging.shaka-api.localhost/health"
echo "  - Verify logs show full path: kubectl logs -n shaka-staging -l app=shaka-api --tail=20"
echo "  - Scale prod when needed: kubectl scale deployment/shaka-api --replicas=1 -n shaka-prod"
echo ""
