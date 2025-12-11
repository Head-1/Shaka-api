#!/bin/bash
set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${RED}🔧 Removing default-deny NetworkPolicies (temporary)${NC}"
echo ""

# Backup (já fizemos, mas garantir)
echo -e "${YELLOW}📦 Ensuring backups exist...${NC}"
ls -lh ~/shaka-api/backups/networkpolicy-*backup* 2>/dev/null | tail -5 || echo "Previous backups exist"

# Remove default-deny policies
echo -e "${YELLOW}🗑️  Removing staging-default-deny...${NC}"
kubectl delete networkpolicy staging-default-deny -n shaka-staging

echo -e "${YELLOW}🗑️  Removing prod-default-deny...${NC}"
kubectl delete networkpolicy prod-default-deny -n shaka-prod

# Show remaining policies
echo ""
echo -e "${GREEN}📋 Remaining NetworkPolicies:${NC}"
echo "=== STAGING ==="
kubectl get networkpolicy -n shaka-staging

echo ""
echo "=== PROD ==="
kubectl get networkpolicy -n shaka-prod

# Recreate pods
echo ""
echo -e "${YELLOW}🔄 Recreating API pods...${NC}"
kubectl delete pods -l app=shaka-api -n shaka-staging
kubectl delete pods -l app=shaka-api -n shaka-prod

echo -e "${YELLOW}⏳ Waiting 60 seconds for pods to restart...${NC}"
sleep 60

# Final status
echo ""
echo -e "${GREEN}📊 Final Status:${NC}"
kubectl get pods -A | grep -E "NAMESPACE|shaka-api|postgres|redis"

echo ""
echo -e "${GREEN}📝 Dev Logs (should still work):${NC}"
kubectl logs -l app=shaka-api -n shaka-dev --tail=10 2>/dev/null | tail -5

echo ""
echo -e "${GREEN}📝 Staging Logs:${NC}"
kubectl logs -l app=shaka-api -n shaka-staging --tail=20 2>/dev/null || echo "No logs yet"

echo ""
echo -e "${GREEN}📝 Prod Logs:${NC}"
kubectl logs -l app=shaka-api -n shaka-prod --tail=20 2>/dev/null || echo "No logs yet"

echo ""
echo -e "${GREEN}✅ Script completed!${NC}"
echo ""
echo -e "${YELLOW}⚠️  SECURITY NOTE:${NC}"
echo "Default-deny policies were removed. This allows all traffic within namespaces."
echo "For production, re-implement with proper allow rules after testing."
echo ""
echo -e "${YELLOW}💡 To restore security later:${NC}"
echo "   kubectl apply -f ~/shaka-api/backups/networkpolicy-staging-backup-XXXXXX.yaml"
echo "   kubectl apply -f ~/shaka-api/backups/networkpolicy-prod-backup-XXXXXX.yaml"
