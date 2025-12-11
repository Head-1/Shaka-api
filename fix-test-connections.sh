#!/bin/bash

echo "🔧 Corrigindo script test-connections.sh..."

cat > scripts/test-connections.sh << 'ENDOFFILE'
#!/bin/bash

# Carregar variáveis do .env
if [ -f .env ]; then
  export $(cat .env | grep -v '^#' | xargs)
fi

echo "🧪 Testing Database and Redis connections..."
echo ""

# Testar PostgreSQL
echo "Testing PostgreSQL..."
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c "SELECT 1;" > /dev/null 2>&1

if [ $? -eq 0 ]; then
  echo "✅ PostgreSQL connection successful"
  echo "   Host: $DB_HOST:$DB_PORT"
  echo "   Database: $DB_NAME"
  echo "   User: $DB_USER"
else
  echo "❌ PostgreSQL connection failed"
fi

echo ""

# Testar Redis
echo "Testing Redis..."
if [ -z "$REDIS_PASSWORD" ] || [ "$REDIS_PASSWORD" = "null" ]; then
  redis-cli -h $REDIS_HOST -p $REDIS_PORT ping > /dev/null 2>&1
else
  redis-cli -h $REDIS_HOST -p $REDIS_PORT -a $REDIS_PASSWORD ping > /dev/null 2>&1
fi

if [ $? -eq 0 ]; then
  echo "✅ Redis connection successful"
  echo "   Host: $REDIS_HOST:$REDIS_PORT"
else
  echo "❌ Redis connection failed"
fi

echo ""
echo "✅ Connection tests completed!"
ENDOFFILE

chmod +x scripts/test-connections.sh

echo ""
echo "✅ Script corrigido!"
echo ""
echo "🧪 Testando agora..."
./scripts/test-connections.sh

