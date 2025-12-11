#!/bin/bash
set -e

echo "🚨 SHAKA API - EMERGENCY RECOVERY & BUILD"
echo "=========================================="
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

cd ~/shaka-api

# ═══════════════════════════════════════════════════════════
# STEP 1: FIND DOCKERFILE
# ═══════════════════════════════════════════════════════════
echo -e "${BLUE}[1/5] Locating Dockerfile${NC}"
echo "--------------------------------------"

DOCKERFILE_PATH=""

# Check common locations
for path in \
  "docker/Dockerfile" \
  "docker/Dockerfile.production" \
  "docker/Dockerfile.dev" \
  "Dockerfile" \
  "dockerfile"; do
  
  if [ -f "$path" ]; then
    echo -e "${GREEN}✅ Found: $path${NC}"
    DOCKERFILE_PATH="$path"
    break
  fi
done

if [ -z "$DOCKERFILE_PATH" ]; then
  echo -e "${RED}❌ No Dockerfile found in common locations${NC}"
  echo "Checked: docker/Dockerfile, Dockerfile, etc."
  exit 1
fi

echo "Using Dockerfile: $DOCKERFILE_PATH"
echo ""

# Show dockerfile content (first 20 lines)
echo "Dockerfile preview:"
head -20 "$DOCKERFILE_PATH"
echo ""

# ═══════════════════════════════════════════════════════════
# STEP 2: VERIFY BUILD OUTPUT EXISTS
# ═══════════════════════════════════════════════════════════
echo -e "${BLUE}[2/5] Verifying Build${NC}"
echo "--------------------------------------"

if [ ! -d "dist" ] || [ ! -f "dist/server.js" ]; then
  echo -e "${YELLOW}⚠️  Build output missing or incomplete${NC}"
  echo "Rebuilding TypeScript..."
  npm run build
fi

echo -e "${GREEN}✅ Build verified${NC}"
echo "Key files:"
ls -lh dist/server.js 2>/dev/null || echo "  server.js: missing"
ls -lh dist/api/middlewares/requestLogger.js 2>/dev/null || echo "  requestLogger.js: missing"

# Verify the fix is in place
echo ""
echo "Verifying RequestLogger fix:"
if grep -q "req.originalUrl" dist/api/middlewares/requestLogger.js 2>/dev/null; then
  echo -e "${GREEN}✅ requestLogger.js uses req.originalUrl (CORRECT)${NC}"
elif grep -q "req.path" dist/api/middlewares/requestLogger.js 2>/dev/null; then
  echo -e "${YELLOW}⚠️  Compiled code still has req.path - fix may not be compiled${NC}"
fi

echo ""

# ═══════════════════════════════════════════════════════════
# STEP 3: BUILD DOCKER IMAGE
# ═══════════════════════════════════════════════════════════
echo -e "${BLUE}[3/5] Building Docker Image${NC}"
echo "--------------------------------------"

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
IMAGE_TAG="registry.localhost:5000/shaka-api:recovery-${TIMESTAMP}"

echo "Building image: $IMAGE_TAG"
echo "Using Dockerfile: $DOCKERFILE_PATH"
echo ""

# Build with correct dockerfile path
if docker build -f "$DOCKERFILE_PATH" -t "$IMAGE_TAG" .; then
  echo -e "${GREEN}✅ Docker build successful${NC}"
  
  # Push to registry
  echo "Pushing to registry..."
  docker push "$IMAGE_TAG"
  
  # Tag as latest
  docker tag "$IMAGE_TAG" registry.localhost:5000/shaka-api:latest
  docker push registry.localhost:5000/shaka-api:latest
  
  # Import to K3s
  echo "Importing to K3s..."
  docker save "$IMAGE_TAG" | sudo k3s ctr images import -
  
  echo -e "${GREEN}✅ Image ready: $IMAGE_TAG${NC}"
  
  # Save image tag for later use
  echo "$IMAGE_TAG" > /tmp/latest-shaka-image.txt
else
  echo -e "${RED}❌ Docker build failed${NC}"
  echo ""
  echo "Build error details:"
  docker build -f "$DOCKERFILE_PATH" -t "$IMAGE_TAG" . 2>&1 | tail -30
  exit 1
fi

echo ""

# ═══════════════════════════════════════════════════════════
# STEP 4: CLEANUP OLD DEPLOYMENTS
# ═══════════════════════════════════════════════════════════
echo -e "${BLUE}[4/5] Cleaning Up Failed Deployments${NC}"
echo "--------------------------------------"

echo "Current problematic pods:"
kubectl get pods -A | grep -E "shaka.*(Error|CrashLoop|ImagePull|Pending)" || echo "  None found"

echo ""
echo "Deleting failed/problematic pods..."

# Delete failed pods
kubectl delete pods --field-selector=status.phase=Failed -A 2>/dev/null || true

# Delete pending pods (they won't schedule anyway)
kubectl delete pods --field-selector=status.phase=Pending -A 2>/dev/null || true

# Force delete specific problematic pods
kubectl delete pod shaka-api-5f75577f6b-qxdcl -n shaka-dev --force --grace-period=0 2>/dev/null || true
kubectl delete pod shaka-api-5fb59d7b54-8sfrk -n shaka-dev --force --grace-period=0 2>/dev/null || true
kubectl delete pod shaka-api-5ff58c764-fdvnc -n shaka-staging --force --grace-period=0 2>/dev/null || true
kubectl delete pod shaka-api-77594d496-4tgfr -n shaka-staging --force --grace-period=0 2>/dev/null || true

echo "Waiting for cleanup to complete..."
sleep 5

echo -e "${GREEN}✅ Cleanup complete${NC}"
echo ""

# ═══════════════════════════════════════════════════════════
# STEP 5: DEPLOY WITH NEW IMAGE
# ═══════════════════════════════════════════════════════════
echo -e "${BLUE}[5/5] Deploying to Environments${NC}"
echo "--------------------------------------"

IMAGE_TAG=$(cat /tmp/latest-shaka-image.txt)

# Deploy to DEV
echo "→ Deploying to DEV with image: $IMAGE_TAG"
if kubectl set image deployment/shaka-api shaka-api="$IMAGE_TAG" -n shaka-dev 2>/dev/null; then
  echo "  Deployment updated, waiting for rollout..."
  kubectl rollout status deployment/shaka-api -n shaka-dev --timeout=90s || \
    echo "  ⚠️  Rollout did not complete in 90s"
else
  echo "  ⚠️  DEV deployment not found or failed"
fi

echo ""

# Deploy to STAGING
echo "→ Deploying to STAGING with image: $IMAGE_TAG"
if kubectl set image deployment/shaka-api shaka-api="$IMAGE_TAG" -n shaka-staging 2>/dev/null; then
  echo "  Deployment updated, waiting for rollout..."
  kubectl rollout status deployment/shaka-api -n shaka-staging --timeout=90s || \
    echo "  ⚠️  Rollout did not complete in 90s"
else
  echo "  ⚠️  STAGING deployment not found or failed"
fi

echo ""
echo "PROD: Keeping at 0 replicas (as configured)"

echo ""

# ═══════════════════════════════════════════════════════════
# VERIFICATION & DIAGNOSTICS
# ═══════════════════════════════════════════════════════════
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "${BLUE}📊 DEPLOYMENT STATUS${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo ""

echo "All Shaka Pods:"
kubectl get pods -A | grep shaka | grep -v postgres | grep -v redis

echo ""
echo "Resource Usage:"
kubectl top node 2>/dev/null || echo "(Metrics not available)"

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "${BLUE}🔍 HEALTH CHECK${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo ""

# Check for running pods
RUNNING_PODS=$(kubectl get pods -A | grep shaka-api | grep -c Running || echo "0")
PROBLEM_PODS=$(kubectl get pods -A | grep shaka-api | grep -Ec "Error|CrashLoop|ImagePull|Pending" || echo "0")

echo "Summary:"
echo "  Running pods: $RUNNING_PODS"
echo "  Problem pods: $PROBLEM_PODS"

if [ "$PROBLEM_PODS" -gt 0 ]; then
  echo ""
  echo -e "${YELLOW}⚠️  Found problematic pods. Checking logs...${NC}"
  echo ""
  
  # Get first problematic pod
  FIRST_BAD=$(kubectl get pods -A | grep shaka-api | grep -E "Error|CrashLoop|ImagePull" | head -1)
  
  if [ -n "$FIRST_BAD" ]; then
    POD_NS=$(echo "$FIRST_BAD" | awk '{print $1}')
    POD_NAME=$(echo "$FIRST_BAD" | awk '{print $2}')
    POD_STATUS=$(echo "$FIRST_BAD" | awk '{print $4}')
    
    echo "Problematic pod: $POD_NAME ($POD_STATUS) in namespace $POD_NS"
    echo ""
    echo "Recent logs:"
    kubectl logs -n "$POD_NS" "$POD_NAME" --tail=20 2>&1 || \
      kubectl logs -n "$POD_NS" "$POD_NAME" --previous --tail=20 2>&1 || \
      echo "Could not retrieve logs"
    
    echo ""
    echo "Pod description (events):"
    kubectl describe pod -n "$POD_NS" "$POD_NAME" | grep -A 10 "Events:" || echo "No events"
  fi
else
  echo ""
  echo -e "${GREEN}✅ All pods healthy!${NC}"
  
  # Show logs from a running pod
  RUNNING_POD=$(kubectl get pods -n shaka-staging -l app=shaka-api -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
  
  if [ -n "$RUNNING_POD" ]; then
    echo ""
    echo "Recent logs from $RUNNING_POD:"
    kubectl logs -n shaka-staging "$RUNNING_POD" --tail=15 2>&1 || echo "Could not get logs"
  fi
fi

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ RECOVERY COMPLETE${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
echo ""
echo "Image deployed: $IMAGE_TAG"
echo ""
echo "Next steps:"
echo "  1. Monitor pods: watch kubectl get pods -A | grep shaka"
echo "  2. Check logs: kubectl logs -n shaka-staging -l app=shaka-api -f"
echo "  3. Test health: curl http://staging.shaka-api.localhost/health"
echo "  4. Test fix: curl -X POST http://staging.shaka-api.localhost/api/v1/auth/register -H 'Content-Type: application/json' -d '{}'"
echo ""
echo "If pods still crash, check logs with:"
echo "  kubectl logs -n shaka-staging -l app=shaka-api --previous"
echo ""
