#!/bin/bash

# ============================================================================
# Apply Database Migrations
# ============================================================================

set -e

NAMESPACE="${1:-shaka-staging}"
POD="${2:-postgres-staging-0}"

echo "=========================================="
echo "🗄️  APPLYING MIGRATIONS"
echo "=========================================="
echo ""
echo "Namespace: $NAMESPACE"
echo "Pod: $POD"
echo ""

# 1. API Keys table
echo "[1/2] Creating api_keys table..."

kubectl exec -n "$NAMESPACE" "$POD" -- psql -U shakauser -d shakadb << 'EOSQL'
-- Create api_keys table if not exists
CREATE TABLE IF NOT EXISTS api_keys (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  "userId" UUID NOT NULL,
  name VARCHAR(100) NOT NULL,
  "keyHash" VARCHAR(64) NOT NULL UNIQUE,
  "keyPreview" VARCHAR(16) NOT NULL,
  permissions TEXT NOT NULL DEFAULT 'read,write',
  "rateLimit" JSONB NOT NULL,
  "isActive" BOOLEAN DEFAULT true,
  "lastUsedAt" TIMESTAMP NULL,
  "expiresAt" TIMESTAMP NULL,
  "createdAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX IF NOT EXISTS "IDX_api_keys_userId" ON api_keys("userId");
CREATE UNIQUE INDEX IF NOT EXISTS "IDX_api_keys_keyHash" ON api_keys("keyHash");

-- Add foreign key
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'FK_api_keys_userId'
  ) THEN
    ALTER TABLE api_keys
    ADD CONSTRAINT "FK_api_keys_userId"
    FOREIGN KEY ("userId") REFERENCES users(id) ON DELETE CASCADE;
  END IF;
END $$;

SELECT 'api_keys table ready' AS status;
EOSQL

echo "✅ api_keys table created"

# 2. Usage Records table
echo "[2/2] Creating usage_records table..."

kubectl exec -n "$NAMESPACE" "$POD" -- psql -U shakauser -d shakadb << 'EOSQL'
-- Create usage_records table if not exists
CREATE TABLE IF NOT EXISTS usage_records (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  "apiKeyId" UUID NOT NULL,
  "userId" UUID NOT NULL,
  endpoint VARCHAR(200) NOT NULL,
  method VARCHAR(10) NOT NULL,
  "statusCode" INT NOT NULL,
  "responseTime" INT NOT NULL,
  "ipAddress" VARCHAR(45) NULL,
  "userAgent" TEXT NULL,
  "errorMessage" TEXT NULL,
  timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS "IDX_usage_records_apiKeyId_timestamp" 
  ON usage_records("apiKeyId", timestamp);

CREATE INDEX IF NOT EXISTS "IDX_usage_records_userId_timestamp" 
  ON usage_records("userId", timestamp);

CREATE INDEX IF NOT EXISTS "IDX_usage_records_timestamp" 
  ON usage_records(timestamp);

CREATE INDEX IF NOT EXISTS "IDX_usage_records_endpoint" 
  ON usage_records(endpoint, method);

SELECT 'usage_records table ready' AS status;
EOSQL

echo "✅ usage_records table created"

echo ""
echo "=========================================="
echo "✅ MIGRATIONS APPLIED SUCCESSFULLY"
echo "=========================================="
echo ""
echo "Verify tables:"
echo "  kubectl exec -n $NAMESPACE $POD -- psql -U shakauser -d shakadb -c '\\dt'"
echo ""
