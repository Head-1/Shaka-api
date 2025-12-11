#!/bin/bash
echo "═══════════════════════════════════════════════════════════════"
echo "🔍 SHAKA API - DIAGNÓSTICO COMPLETO DO SISTEMA"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# ═══════════════════════════════════════════════════════════════
# LAYER 1: KUBERNETES STATE
# ═══════════════════════════════════════════════════════════════
echo "📦 LAYER 1: KUBERNETES STATE"
echo "─────────────────────────────────────────────────────────────"
echo ""

echo "1.1 Pods Status (All Namespaces):"
kubectl get pods -A | grep shaka
echo ""

echo "1.2 Deployment Configuration (Staging):"
kubectl get deployment shaka-api -n shaka-staging -o yaml | grep -A 10 "containers:"
echo ""

echo "1.3 Pod Events (Last 20):"
kubectl get events -n shaka-staging --sort-by='.lastTimestamp' | tail -20
echo ""

echo "1.4 Describe Failed Pod:"
FAILED_POD=$(kubectl get pods -n shaka-staging -l app=shaka-api --sort-by='.status.startTime' | grep -E "CrashLoop|Pending|Error" | tail -1 | awk '{print $1}')
if [ -n "$FAILED_POD" ]; then
  echo "Pod: $FAILED_POD"
  kubectl describe pod "$FAILED_POD" -n shaka-staging | tail -50
else
  echo "No failed pods found"
fi
echo ""

# ═══════════════════════════════════════════════════════════════
# LAYER 2: DOCKER IMAGES
# ═══════════════════════════════════════════════════════════════
echo "═══════════════════════════════════════════════════════════════"
echo "🐳 LAYER 2: DOCKER IMAGES STATE"
echo "─────────────────────────────────────────────────────────────"
echo ""

echo "2.1 Images in K3s CRI:"
sudo k3s ctr images ls | grep shaka-api
echo ""

echo "2.2 Images in Docker:"
docker images | grep shaka-api
echo ""

echo "2.3 Inspect Latest Image (K3s):"
LATEST_IMAGE=$(sudo k3s ctr images ls | grep "shaka-api:final-fix" | head -1 | awk '{print $1}')
if [ -n "$LATEST_IMAGE" ]; then
  echo "Image: $LATEST_IMAGE"
  sudo k3s ctr images inspect "$LATEST_IMAGE" | grep -A 5 "config"
else
  echo "No final-fix image found"
fi
echo ""

# ═══════════════════════════════════════════════════════════════
# LAYER 3: APPLICATION CODE STATE
# ═══════════════════════════════════════════════════════════════
echo "═══════════════════════════════════════════════════════════════"
echo "💻 LAYER 3: APPLICATION CODE STATE"
echo "─────────────────────────────────────────────────────────────"
echo ""

cd ~/shaka-api

echo "3.1 RequestLogger Fix Status (Source):"
if [ -f "src/api/middlewares/requestLogger.ts" ]; then
  echo "✅ File exists"
  grep -n "path:" src/api/middlewares/requestLogger.ts
  echo ""
  if grep -q "req\.originalUrl" src/api/middlewares/requestLogger.ts; then
    echo "✅ Uses req.originalUrl (CORRECT)"
  elif grep -q "req\.path" src/api/middlewares/requestLogger.ts; then
    echo "❌ Uses req.path (INCORRECT)"
  fi
else
  echo "❌ File not found"
fi
echo ""

echo "3.2 RequestLogger Fix Status (Compiled):"
if [ -f "dist/api/middlewares/requestLogger.js" ]; then
  echo "✅ File exists"
  grep -n "path:" dist/api/middlewares/requestLogger.js | head -5
  echo ""
  if grep -q "req\.originalUrl" dist/api/middlewares/requestLogger.js; then
    echo "✅ Compiled uses req.originalUrl (CORRECT)"
  elif grep -q "req\.path" dist/api/middlewares/requestLogger.js; then
    echo "❌ Compiled uses req.path (INCORRECT)"
  fi
else
  echo "❌ Dist not found - needs rebuild"
fi
echo ""

echo "3.3 Logger Config (Source):"
if [ -f "src/config/logger.ts" ]; then
  grep -n "LOG_DIR\|filename:" src/config/logger.ts | head -10
  echo ""
  if grep -q "path\.join.*logs" src/config/logger.ts; then
    echo "✅ Uses path.join (CORRECT)"
  elif grep -q "filename: 'logs/" src/config/logger.ts; then
    echo "❌ Uses relative path (INCORRECT)"
  fi
else
  echo "❌ Logger config not found"
fi
echo ""

echo "3.4 Dockerfile Status:"
if [ -f "Dockerfile" ]; then
  echo "✅ Dockerfile exists in root"
  echo ""
  echo "Key sections:"
  grep -n "mkdir.*logs\|USER nodejs\|RUN npm install" Dockerfile
  echo ""
  if grep -q "mkdir -p /app/logs" Dockerfile; then
    echo "✅ Creates logs directory (CORRECT)"
  else
    echo "❌ Missing logs directory creation"
  fi
else
  echo "❌ No Dockerfile in root"
fi
echo ""

# ═══════════════════════════════════════════════════════════════
# LAYER 4: RUNNING CONTAINERS STATE
# ═══════════════════════════════════════════════════════════════
echo "═══════════════════════════════════════════════════════════════"
echo "🏃 LAYER 4: RUNNING CONTAINERS STATE"
echo "─────────────────────────────────────────────────────────────"
echo ""

RUNNING_POD=$(kubectl get pods -n shaka-staging -l app=shaka-api -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}' 2>/dev/null | awk '{print $1}')

if [ -n "$RUNNING_POD" ]; then
  echo "4.1 Found Running Pod: $RUNNING_POD"
  echo ""
  
  echo "4.2 Container Names:"
  kubectl get pod "$RUNNING_POD" -n shaka-staging -o jsonpath='{.spec.containers[*].name}'
  echo ""
  echo ""
  
  echo "4.3 Container Images:"
  kubectl get pod "$RUNNING_POD" -n shaka-staging -o jsonpath='{.spec.containers[*].image}'
  echo ""
  echo ""
  
  echo "4.4 Last 30 lines of logs (container: api):"
  kubectl logs -n shaka-staging "$RUNNING_POD" -c api --tail=30 2>&1 || echo "Container 'api' not ready or not found"
  echo ""
  
  echo "4.5 Code inside running pod (requestLogger):"
  kubectl exec -n shaka-staging "$RUNNING_POD" -c api -- cat /app/dist/api/middlewares/requestLogger.js 2>&1 | grep -A 3 "path:" | head -10 || echo "Cannot access pod filesystem"
  echo ""
  
else
  echo "❌ No running pods found in shaka-staging"
  echo ""
  echo "Checking crashed pod logs..."
  CRASHED_POD=$(kubectl get pods -n shaka-staging -l app=shaka-api --sort-by='.status.startTime' | tail -1 | awk '{print $1}')
  if [ -n "$CRASHED_POD" ]; then
    echo "Last pod: $CRASHED_POD"
    echo ""
    echo "Previous container logs:"
    kubectl logs -n shaka-staging "$CRASHED_POD" -c api --previous --tail=50 2>&1 || echo "No previous logs"
  fi
fi
echo ""

# ═══════════════════════════════════════════════════════════════
# LAYER 5: RESOURCES & LIMITS
# ═══════════════════════════════════════════════════════════════
echo "═══════════════════════════════════════════════════════════════"
echo "⚙️ LAYER 5: RESOURCES & SYSTEM STATE"
echo "─────────────────────────────────────────────────────────────"
echo ""

echo "5.1 Node Resources:"
kubectl top node 2>/dev/null || echo "Metrics not available"
echo ""

echo "5.2 Pod Resources (shaka-api):"
kubectl top pods -n shaka-staging -l app=shaka-api 2>/dev/null || echo "Metrics not available"
echo ""

echo "5.3 Resource Requests/Limits:"
kubectl get deployment shaka-api -n shaka-staging -o yaml | grep -A 8 "resources:"
echo ""

echo "5.4 System Memory:"
free -h
echo ""

# ═══════════════════════════════════════════════════════════════
# LAYER 6: DEPLOYMENT CONFIGURATION
# ═══════════════════════════════════════════════════════════════
echo "═══════════════════════════════════════════════════════════════"
echo "🎯 LAYER 6: DEPLOYMENT CONFIGURATION"
echo "─────────────────────────────────────────────────────────────"
echo ""

echo "6.1 Deployment Spec (containers):"
kubectl get deployment shaka-api -n shaka-staging -o jsonpath='{.spec.template.spec.containers[*]}' | jq . 2>/dev/null || kubectl get deployment shaka-api -n shaka-staging -o yaml | grep -A 30 "containers:"
echo ""

echo "6.2 ImagePullPolicy:"
kubectl get deployment shaka-api -n shaka-staging -o jsonpath='{.spec.template.spec.containers[*].imagePullPolicy}'
echo ""
echo ""

echo "6.3 Environment Variables:"
kubectl get deployment shaka-api -n shaka-staging -o yaml | grep -A 20 "env:"
echo ""

# ═══════════════════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════════════════
echo "═══════════════════════════════════════════════════════════════"
echo "📋 DIAGNOSTIC SUMMARY"
echo "═══════════════════════════════════════════════════════════════"
echo ""

echo "Critical Checks:"
echo "────────────────"
echo ""

# Check 1: Source code
if grep -q "req\.originalUrl" src/api/middlewares/requestLogger.ts 2>/dev/null; then
  echo "✅ Source code: RequestLogger uses req.originalUrl"
else
  echo "❌ Source code: RequestLogger NOT fixed"
fi

# Check 2: Compiled code
if grep -q "req\.originalUrl" dist/api/middlewares/requestLogger.js 2>/dev/null; then
  echo "✅ Compiled code: Fix present in dist/"
else
  echo "❌ Compiled code: Needs rebuild"
fi

# Check 3: Dockerfile
if grep -q "mkdir -p /app/logs" Dockerfile 2>/dev/null; then
  echo "✅ Dockerfile: Creates logs directory"
else
  echo "❌ Dockerfile: Missing logs directory creation"
fi

# Check 4: Pods
RUNNING_COUNT=$(kubectl get pods -n shaka-staging -l app=shaka-api -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}' 2>/dev/null | wc -w)
CRASH_COUNT=$(kubectl get pods -n shaka-staging -l app=shaka-api -o jsonpath='{.items[?(@.status.containerStatuses[0].state.waiting.reason=="CrashLoopBackOff")].metadata.name}' 2>/dev/null | wc -w)

echo "✅ Running pods: $RUNNING_COUNT"
echo "❌ Crashed pods: $CRASH_COUNT"

# Check 5: Images
IMAGE_COUNT=$(sudo k3s ctr images ls | grep -c "shaka-api")
echo "✅ Images in K3s: $IMAGE_COUNT"

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "✅ DIAGNOSTIC COMPLETE"
echo "═══════════════════════════════════════════════════════════════"
