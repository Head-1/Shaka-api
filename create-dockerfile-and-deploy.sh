#!/bin/bash
set -e

echo "🚀 SHAKA API - CREATE DOCKERFILE & DEPLOY"
echo "=========================================="
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

cd ~/shaka-api

# ═══════════════════════════════════════════════════════════
# STEP 1: CREATE OPTIMIZED DOCKERFILE
# ═══════════════════════════════════════════════════════════
echo -e "${BLUE}[1/6] Creating Optimized Dockerfile${NC}"
echo "--------------------------------------"

# Backup if exists
if [ -f "Dockerfile" ]; then
  mv Dockerfile Dockerfile.backup.$(date +%s)
  echo "Backed up existing Dockerfile"
fi

cat > Dockerfile << 'DOCKERFILE_EOF'
# ═══════════════════════════════════════════════════════════
# MULTI-STAGE BUILD - Optimized for production
# ═══════════════════════════════════════════════════════════

# ───────────────────────────────────────────────────────────
# Stage 1: Builder - Install dependencies and build
# ───────────────────────────────────────────────────────────
FROM node:20-alpine AS builder

# Install build dependencies
RUN apk add --no-cache python3 make g++

WORKDIR /app

# Copy package files
COPY package*.json ./
COPY tsconfig.json ./

# Install ALL dependencies (including devDependencies for build)
RUN npm ci

# Copy source code
COPY src ./src

# Build TypeScript
RUN npm run build

# Remove dev dependencies
RUN npm prune --production

# ───────────────────────────────────────────────────────────
# Stage 2: Production - Minimal runtime image
# ───────────────────────────────────────────────────────────
FROM node:20-alpine

# Install dumb-init for proper signal handling
RUN apk add --no-cache dumb-init

WORKDIR /app

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Copy from builder
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist
COPY --from=builder --chown=nodejs:nodejs /app/package*.json ./

# Switch to non-root user
USER nodejs

# Expose port
EXPOSE 3000

# Environment variables (can be overridden)
ENV NODE_ENV=production \
    PORT=3000

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=40s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Use dumb-init to handle signals properly
ENTRYPOINT ["dumb-init", "--"]

# Start application
CMD ["node", "dist/server.js"]
DOCKERFILE_EOF

echo -e "${GREEN}✅ Dockerfile created${NC}"
echo ""

# Show dockerfile
echo "Dockerfile content:"
cat Dockerfile
echo ""

# ═══════════════════════════════════════════════════════════
# STEP 2: CREATE .dockerignore
# ═══════════════════════════════════════════════════════════
echo -e "${BLUE}[2/6] Creating .dockerignore${NC}"
echo "--------------------------------------"

cat > .dockerignore << 'DOCKERIGNORE_EOF'
# Dependencies
node_modules
npm-debug.log
yarn-error.log
package-lock.json

# Testing
coverage
.nyc_output
*.test.ts
*.spec.ts
tests

# Build
dist
*.tsbuildinfo

# Environment
.env
.env.local
.env.*.local

# Git
.git
.gitignore
.github

# Documentation
*.md
docs

# IDE
.vscode
.idea

# CI/CD
.gitlab-ci
.github

# Logs
logs
*.log
server.log
*.pid

# Misc
.DS_Store
*.swp
*.swo
*~
backup
backups
DOCKERIGNORE_EOF

echo -e "${GREEN}✅ .dockerignore created${NC}"
echo ""

# ═══════════════════════════════════════════════════════════
# STEP 3: VERIFY BUILD OUTPUT
# ═══════════════════════════════════════════════════════════
echo -e "${BLUE}[3/6] Verifying TypeScript Build${NC}"
echo "--------------------------------------"

if [ ! -d "dist" ] || [ ! -f "dist/server.js" ]; then
  echo "Building TypeScript..."
  npm run build
else
  echo "Build already exists"
fi

# Verify the RequestLogger fix
echo ""
echo "Verifying RequestLogger fix:"
if grep -q "req.originalUrl" dist/api/middlewares/requestLogger.js 2>/dev/null; then
  echo -e "${GREEN}✅ Uses req.originalUrl (CORRECT)${NC}"
elif grep -q "req.path" dist/api/middlewares/requestLogger.js 2>/dev/null; then
  echo -e "${RED}❌ Still uses req.path - rebuilding...${NC}"
  npm run build
fi

echo ""

# ═══════════════════════════════════════════════════════════
# STEP 4: BUILD DOCKER IMAGE
# ═══════════════════════════════════════════════════════════
echo -e "${BLUE}[4/6] Building Docker Image${NC}"
echo "--------------------------------------"

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
IMAGE_TAG="registry.localhost:5000/shaka-api:v2-${TIMESTAMP}"

echo "Building: $IMAGE_TAG"
echo ""

if docker build -t "$IMAGE_TAG" .; then
  echo ""
  echo -e "${GREEN}✅ Docker build successful${NC}"
  
  # Push to registry
  echo ""
  echo "Pushing to registry..."
  docker push "$IMAGE_TAG"
  
  # Tag as latest
  docker tag "$IMAGE_TAG" registry.localhost:5000/shaka-api:latest
  docker push registry.localhost:5000/shaka-api:latest
  
  # Import to K3s
  echo ""
  echo "Importing to K3s..."
  docker save "$IMAGE_TAG" | sudo k3s ctr images import -
  
  echo ""
  echo -e "${GREEN}✅ Image ready: $IMAGE_TAG${NC}"
  
  # Save for later
  echo "$IMAGE_TAG" > /tmp/latest-shaka-image.txt
else
  echo ""
  echo -e "${RED}❌ Docker build failed${NC}"
  exit 1
fi

echo ""

# ═══════════════════════════════════════════════════════════
# STEP 5: CLEANUP CLUSTER
# ═══════════════════════════════════════════════════════════
echo -e "${BLUE}[5/6] Cleaning Up Cluster${NC}"
echo "--------------------------------------"

echo "Deleting problematic pods..."

# Delete all failed/error/pending pods
kubectl delete pods --all-namespaces --field-selector=status.phase=Failed --force --grace-period=0 2>/dev/null || true
kubectl delete pods --all-namespaces --field-selector=status.phase=Unknown --force --grace-period=0 2>/dev/null || true

# Delete specific problematic pods
kubectl get pods -A | grep -E "shaka-api.*(CrashLoop|Error|ImagePull)" | awk '{print $2, $1}' | \
  while read pod ns; do
    echo "  Deleting $pod in $ns"
    kubectl delete pod "$pod" -n "$ns" --force --grace-period=0 2>/dev/null || true
  done

echo ""
echo "Waiting for cleanup..."
sleep 5

echo -e "${GREEN}✅ Cleanup complete${NC}"
echo ""

# ═══════════════════════════════════════════════════════════
# STEP 6: DEPLOY
# ═══════════════════════════════════════════════════════════
echo -e "${BLUE}[6/6] Deploying to Environments${NC}"
echo "--------------------------------------"

IMAGE_TAG=$(cat /tmp/latest-shaka-image.txt)

echo "Image: $IMAGE_TAG"
echo ""

# Deploy to DEV
echo "→ DEV Environment:"
if kubectl set image deployment/shaka-api shaka-api="$IMAGE_TAG" -n shaka-dev 2>/dev/null; then
  echo "  Deployment updated"
  echo "  Waiting for rollout..."
  kubectl rollout status deployment/shaka-api -n shaka-dev --timeout=120s 2>&1 | sed 's/^/  /' || \
    echo "  ⚠️  Timeout - check manually"
else
  echo "  ⚠️  Deployment not found or failed"
fi

echo ""

# Deploy to STAGING
echo "→ STAGING Environment:"
if kubectl set image deployment/shaka-api shaka-api="$IMAGE_TAG" -n shaka-staging 2>/dev/null; then
  echo "  Deployment updated"
  echo "  Waiting for rollout..."
  kubectl rollout status deployment/shaka-api -n shaka-staging --timeout=120s 2>&1 | sed 's/^/  /' || \
    echo "  ⚠️  Timeout - check manually"
else
  echo "  ⚠️  Deployment not found or failed"
fi

echo ""
echo "→ PROD: Keeping at 0 replicas (as configured)"

echo ""

# ═══════════════════════════════════════════════════════════
# VERIFICATION
# ═══════════════════════════════════════════════════════════
echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
echo -e "${GREEN}📊 FINAL STATUS${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
echo ""

echo "Pod Status:"
kubectl get pods -A | grep shaka | grep -v postgres | grep -v redis

echo ""
echo "Resource Usage:"
kubectl top node 2>/dev/null || echo "(Metrics not available)"

# Check for issues
echo ""
RUNNING=$(kubectl get pods -A | grep shaka-api | grep -c Running || echo "0")
PROBLEMS=$(kubectl get pods -A | grep shaka-api | grep -Ec "Error|CrashLoop|ImagePull|Pending" || echo "0")

echo "Summary:"
echo "  ✅ Running: $RUNNING pods"
echo "  ⚠️  Problems: $PROBLEMS pods"

if [ "$PROBLEMS" -gt 0 ]; then
  echo ""
  echo "Checking problematic pod..."
  FIRST_BAD=$(kubectl get pods -A | grep shaka-api | grep -E "Error|CrashLoop|ImagePull|Pending" | head -1)
  if [ -n "$FIRST_BAD" ]; then
    POD_NS=$(echo "$FIRST_BAD" | awk '{print $1}')
    POD_NAME=$(echo "$FIRST_BAD" | awk '{print $2}')
    
    echo ""
    echo "Pod: $POD_NAME in $POD_NS"
    echo "Logs:"
    kubectl logs -n "$POD_NS" "$POD_NAME" --tail=20 2>&1 | sed 's/^/  /' || \
      kubectl describe pod -n "$POD_NS" "$POD_NAME" | grep -A 5 "Events:" | sed 's/^/  /'
  fi
fi

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ DEPLOYMENT COMPLETE${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
echo ""
echo "Image: $IMAGE_TAG"
echo ""
echo "Next steps:"
echo "  1. Monitor: watch kubectl get pods -A | grep shaka"
echo "  2. Logs: kubectl logs -n shaka-staging -l app=shaka-api -f"
echo "  3. Test health: curl http://staging.shaka-api.localhost/health"
echo "  4. Test API: curl -X POST http://staging.shaka-api.localhost/api/v1/auth/register"
echo ""
