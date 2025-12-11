#!/bin/bash

echo "🔧 SCRIPT 20: Configurando PostgreSQL e Redis"
echo "============================================="
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 1. Verificar se PostgreSQL está instalado
echo -e "${YELLOW}🔍 Verificando PostgreSQL...${NC}"
if command -v psql &> /dev/null; then
  echo -e "${GREEN}✓ PostgreSQL instalado${NC}"
  
  # Verificar se está rodando
  if systemctl is-active --quiet postgresql; then
    echo -e "${GREEN}✓ PostgreSQL rodando${NC}"
  else
    echo -e "${YELLOW}⚠ PostgreSQL parado. Iniciando...${NC}"
    sudo systemctl start postgresql
    sudo systemctl enable postgresql
    echo -e "${GREEN}✓ PostgreSQL iniciado${NC}"
  fi
else
  echo -e "${RED}✗ PostgreSQL NÃO instalado${NC}"
  echo -e "${YELLOW}Instalando PostgreSQL...${NC}"
  sudo apt update
  sudo apt install -y postgresql postgresql-contrib
  sudo systemctl start postgresql
  sudo systemctl enable postgresql
  echo -e "${GREEN}✓ PostgreSQL instalado e iniciado${NC}"
fi

echo ""

# 2. Criar banco de dados
echo -e "${YELLOW}📝 Criando banco de dados 'shaka_api'...${NC}"
sudo -u postgres psql -c "SELECT 1 FROM pg_database WHERE datname = 'shaka_api'" | grep -q 1
if [ $? -eq 0 ]; then
  echo -e "${YELLOW}⚠ Banco 'shaka_api' já existe${NC}"
else
  sudo -u postgres createdb shaka_api
  echo -e "${GREEN}✓ Banco 'shaka_api' criado${NC}"
fi

echo ""

# 3. Criar usuário e definir senha
echo -e "${YELLOW}📝 Configurando usuário PostgreSQL...${NC}"
sudo -u postgres psql << EOF
-- Criar usuário se não existir
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_user WHERE usename = 'shaka_user') THEN
    CREATE USER shaka_user WITH PASSWORD 'shaka_password_2025';
  END IF;
END
\$\$;

-- Dar permissões
GRANT ALL PRIVILEGES ON DATABASE shaka_api TO shaka_user;

-- Conectar ao banco e dar permissões no schema
\c shaka_api
GRANT ALL ON SCHEMA public TO shaka_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO shaka_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO shaka_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO shaka_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO shaka_user;
EOF

echo -e "${GREEN}✓ Usuário PostgreSQL configurado${NC}"
echo ""

# 4. Verificar Redis
echo -e "${YELLOW}🔍 Verificando Redis...${NC}"
if command -v redis-cli &> /dev/null; then
  echo -e "${GREEN}✓ Redis instalado${NC}"
  
  # Verificar se está rodando
  if systemctl is-active --quiet redis || systemctl is-active --quiet redis-server; then
    echo -e "${GREEN}✓ Redis rodando${NC}"
  else
    echo -e "${YELLOW}⚠ Redis parado. Iniciando...${NC}"
    sudo systemctl start redis-server || sudo systemctl start redis
    sudo systemctl enable redis-server || sudo systemctl enable redis
    echo -e "${GREEN}✓ Redis iniciado${NC}"
  fi
else
  echo -e "${RED}✗ Redis NÃO instalado${NC}"
  echo -e "${YELLOW}Instalando Redis...${NC}"
  sudo apt update
  sudo apt install -y redis-server
  sudo systemctl start redis-server
  sudo systemctl enable redis-server
  echo -e "${GREEN}✓ Redis instalado e iniciado${NC}"
fi

echo ""

# 5. Atualizar .env com as credenciais
echo -e "${YELLOW}📝 Atualizando .env...${NC}"

cat > .env << 'EOF'
# Environment
NODE_ENV=development

# Server
PORT=3000

# JWT
JWT_SECRET=your-super-secret-jwt-key-change-in-production-2025
JWT_REFRESH_SECRET=your-super-secret-refresh-key-change-in-production-2025
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=7d

# Database
DB_HOST=localhost
DB_PORT=5432
DB_USER=shaka_user
DB_PASSWORD=shaka_password_2025
DB_NAME=shaka_api

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=
REDIS_DB=0

# Logging
LOG_LEVEL=info
EOF

echo -e "${GREEN}✓ .env atualizado${NC}"
echo ""

# 6. Testar conexões
echo -e "${YELLOW}🧪 Testando conexões...${NC}"
echo ""

# Testar PostgreSQL
echo -n "PostgreSQL: "
if PGPASSWORD=shaka_password_2025 psql -h localhost -U shaka_user -d shaka_api -c "SELECT 1" &> /dev/null; then
  echo -e "${GREEN}✓ Conectado${NC}"
else
  echo -e "${RED}✗ Falha na conexão${NC}"
fi

# Testar Redis
echo -n "Redis: "
if redis-cli ping &> /dev/null; then
  echo -e "${GREEN}✓ Conectado${NC}"
else
  echo -e "${RED}✗ Falha na conexão${NC}"
fi

echo ""
echo -e "${GREEN}✅ SCRIPT 20 CONCLUÍDO!${NC}"
echo ""
echo "📊 Serviços configurados:"
echo "   • PostgreSQL rodando em localhost:5432"
echo "   • Redis rodando em localhost:6379"
echo "   • Banco 'shaka_api' criado"
echo "   • Usuário 'shaka_user' configurado"
echo "   • .env atualizado"
echo ""
echo "🧪 Testar agora:"
echo "   npm run dev"
echo ""
echo "🎯 Próximo passo:"
echo "   Rodar migrations: npm run migration:run"
echo ""
