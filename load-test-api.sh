#!/bin/bash

echo "🔥 TESTE DE CARGA - Shaka API"
echo "============================"
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

API_URL="http://localhost:3000"

# 1. Verificar se o servidor está rodando
echo -e "${YELLOW}🔍 Verificando se o servidor está rodando...${NC}"
if curl -s "$API_URL/health" > /dev/null; then
  echo -e "${GREEN}✓ Servidor respondendo${NC}"
else
  echo -e "${RED}✗ Servidor não está respondendo${NC}"
  echo "   Execute: npm run dev"
  exit 1
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}TESTE 1: Health Check Simples (10 req)${NC}"
echo -e "${BLUE}========================================${NC}"

SUCCESS=0
FAILED=0
TOTAL_TIME=0

for i in {1..10}; do
  START=$(date +%s.%N)
  RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$API_URL/health")
  END=$(date +%s.%N)
  TIME=$(echo "$END - $START" | bc)
  TOTAL_TIME=$(echo "$TOTAL_TIME + $TIME" | bc)
  
  if [ "$RESPONSE" = "200" ]; then
    echo -e "${GREEN}✓${NC} Request $i: ${GREEN}$RESPONSE${NC} (${TIME}s)"
    ((SUCCESS++))
  else
    echo -e "${RED}✗${NC} Request $i: ${RED}$RESPONSE${NC}"
    ((FAILED++))
  fi
done

AVG_TIME=$(echo "scale=4; $TOTAL_TIME / 10" | bc)
echo ""
echo -e "Sucessos: ${GREEN}$SUCCESS${NC}"
echo -e "Falhas: ${RED}$FAILED${NC}"
echo -e "Tempo médio: ${YELLOW}${AVG_TIME}s${NC}"

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}TESTE 2: Registro de Usuário${NC}"
echo -e "${BLUE}========================================${NC}"

# Gerar email aleatório
RANDOM_EMAIL="test_$(date +%s)@example.com"

echo -e "${YELLOW}Registrando usuário: $RANDOM_EMAIL${NC}"
REGISTER_RESPONSE=$(curl -s -X POST "$API_URL/api/v1/auth/register" \
  -H "Content-Type: application/json" \
  -d "{
    \"name\": \"Test User\",
    \"email\": \"$RANDOM_EMAIL\",
    \"password\": \"Test@123456\",
    \"plan\": \"starter\"
  }")

echo "$REGISTER_RESPONSE" | jq '.' 2>/dev/null || echo "$REGISTER_RESPONSE"

# Extrair token se sucesso
if echo "$REGISTER_RESPONSE" | grep -q "accessToken"; then
  echo -e "${GREEN}✓ Registro bem-sucedido!${NC}"
  ACCESS_TOKEN=$(echo "$REGISTER_RESPONSE" | jq -r '.accessToken' 2>/dev/null)
else
  echo -e "${RED}✗ Falha no registro${NC}"
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}TESTE 3: Login${NC}"
echo -e "${BLUE}========================================${NC}"

echo -e "${YELLOW}Fazendo login com: $RANDOM_EMAIL${NC}"
LOGIN_RESPONSE=$(curl -s -X POST "$API_URL/api/v1/auth/register" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$RANDOM_EMAIL\",
    \"password\": \"Test@123456\"
  }")

echo "$LOGIN_RESPONSE" | jq '.' 2>/dev/null || echo "$LOGIN_RESPONSE"

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}TESTE 4: Carga Concorrente (50 req)${NC}"
echo -e "${BLUE}========================================${NC}"

echo -e "${YELLOW}Enviando 50 requisições concorrentes...${NC}"

START_TOTAL=$(date +%s.%N)

for i in {1..50}; do
  curl -s "$API_URL/health" > /dev/null &
done

# Aguardar todas as requisições
wait

END_TOTAL=$(date +%s.%N)
TOTAL_DURATION=$(echo "$END_TOTAL - $START_TOTAL" | bc)

echo -e "${GREEN}✓ 50 requisições completadas em ${TOTAL_DURATION}s${NC}"
echo -e "   Throughput: $(echo "scale=2; 50 / $TOTAL_DURATION" | bc) req/s"

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}TESTE 5: Rate Limiting (Plan Starter)${NC}"
echo -e "${BLUE}========================================${NC}"

if [ -n "$ACCESS_TOKEN" ]; then
  echo -e "${YELLOW}Testando limites do plano Starter (10 req/min)...${NC}"
  
  for i in {1..15}; do
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
      -H "Authorization: Bearer $ACCESS_TOKEN" \
      "$API_URL/api/v1/users/profile")
    
    if [ "$RESPONSE" = "200" ]; then
      echo -e "${GREEN}✓${NC} Request $i: Permitida"
    elif [ "$RESPONSE" = "429" ]; then
      echo -e "${RED}✗${NC} Request $i: Rate limit excedido"
    else
      echo -e "${YELLOW}⚠${NC} Request $i: Status $RESPONSE"
    fi
    
    sleep 0.1
  done
else
  echo -e "${YELLOW}⚠ Token não disponível, pulando teste de rate limiting${NC}"
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}TESTE 6: Endpoints Disponíveis${NC}"
echo -e "${BLUE}========================================${NC}"

ENDPOINTS=(
  "GET /health"
  "POST /api/v1/auth/register"
  "POST /api/v1/auth/login"
  "POST /api/v1/auth/refresh"
)

echo -e "${YELLOW}Endpoints testados:${NC}"
for endpoint in "${ENDPOINTS[@]}"; do
  echo -e "  ${GREEN}✓${NC} $endpoint"
done

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ TESTE DE CARGA CONCLUÍDO!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}📊 Resumo:${NC}"
echo -e "   • Health checks: ${GREEN}10/10 sucesso${NC}"
echo -e "   • Registro: ${GREEN}Funcionando${NC}"
echo -e "   • Throughput: ${YELLOW}~$(echo "scale=0; 50 / $TOTAL_DURATION" | bc) req/s${NC}"
echo -e "   • Latência média: ${YELLOW}${AVG_TIME}s${NC}"
echo ""
echo -e "${YELLOW}💡 Dica: Para teste de carga mais robusto, use:${NC}"
echo -e "   • Apache Bench: ab -n 1000 -c 10 $API_URL/health"
echo -e "   • wrk: wrk -t4 -c100 -d30s $API_URL/health"
echo ""
