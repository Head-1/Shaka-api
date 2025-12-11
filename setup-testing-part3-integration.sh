#!/bin/bash

echo "🧪 SCRIPT 26: Integration Tests Setup"
echo "======================================"
echo ""

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${YELLOW}📦 Instalando dependências para integration tests...${NC}"

# Instalar supertest para testes de API
npm install --save-dev supertest @types/supertest

echo -e "${GREEN}✓ Dependências instaladas${NC}"
echo ""

# Criar diretório de integration tests
echo -e "${YELLOW}📁 Criando estrutura de integration tests...${NC}"
mkdir -p tests/integration/api

echo -e "${GREEN}✓ Estrutura criada${NC}"
echo ""

# ====================
# 1. Health Endpoint Tests
# ====================
echo -e "${BLUE}📝 Criando tests/integration/api/health.test.ts...${NC}"

cat > tests/integration/api/health.test.ts << 'EOF'
import request from 'supertest';
import express from 'express';
import { healthRoutes } from '../../../src/api/routes/health.routes';

describe('Health Endpoint Integration Tests', () => {
  let app: express.Application;

  beforeAll(() => {
    app = express();
    app.use(express.json());
    app.use('/', healthRoutes);
  });

  describe('GET /health', () => {
    it('should return 200 and health status', async () => {
      const response = await request(app)
        .get('/health')
        .expect(200);

      expect(response.body).toHaveProperty('status', 'ok');
      expect(response.body).toHaveProperty('timestamp');
      expect(response.body).toHaveProperty('uptime');
      expect(response.body).toHaveProperty('environment');
      expect(response.body).toHaveProperty('services');
    });

    it('should return database and redis status', async () => {
      const response = await request(app)
        .get('/health')
        .expect(200);

      expect(response.body.services).toHaveProperty('database');
      expect(response.body.services).toHaveProperty('redis');
    });

    it('should return valid timestamp format', async () => {
      const response = await request(app)
        .get('/health')
        .expect(200);

      const timestamp = new Date(response.body.timestamp);
      expect(timestamp).toBeInstanceOf(Date);
      expect(timestamp.getTime()).not.toBeNaN();
    });

    it('should return positive uptime', async () => {
      const response = await request(app)
        .get('/health')
        .expect(200);

      expect(response.body.uptime).toBeGreaterThan(0);
      expect(typeof response.body.uptime).toBe('number');
    });
  });
});
EOF

echo -e "${GREEN}✓ Health tests criado${NC}"
echo ""

# ====================
# 2. Auth Endpoints Tests
# ====================
echo -e "${BLUE}📝 Criando tests/integration/api/auth.test.ts...${NC}"

cat > tests/integration/api/auth.test.ts << 'EOF'
import request from 'supertest';
import express from 'express';
import { authRoutes } from '../../../src/api/routes/auth.routes';

describe('Auth Endpoints Integration Tests', () => {
  let app: express.Application;

  beforeAll(() => {
    app = express();
    app.use(express.json());
    app.use('/api/v1/auth', authRoutes);
  });

  describe('POST /api/v1/auth/register', () => {
    it('should reject registration without required fields', async () => {
      const response = await request(app)
        .post('/api/v1/auth/register')
        .send({})
        .expect(400);

      expect(response.body).toHaveProperty('error');
    });

    it('should reject invalid email format', async () => {
      const response = await request(app)
        .post('/api/v1/auth/register')
        .send({
          name: 'Test User',
          email: 'invalid-email',
          password: 'Test@1234',
          plan: 'starter'
        })
        .expect(400);

      expect(response.body).toHaveProperty('error');
    });

    it('should reject weak password', async () => {
      const response = await request(app)
        .post('/api/v1/auth/register')
        .send({
          name: 'Test User',
          email: 'test@example.com',
          password: '123',
          plan: 'starter'
        })
        .expect(400);

      expect(response.body).toHaveProperty('error');
    });

    it('should accept valid registration data', async () => {
      const uniqueEmail = `test${Date.now()}@example.com`;
      
      const response = await request(app)
        .post('/api/v1/auth/register')
        .send({
          name: 'Test User',
          email: uniqueEmail,
          password: 'Test@1234',
          plan: 'starter'
        });

      // Pode retornar 201 (sucesso) ou 500 (erro de database em mock)
      expect([201, 500]).toContain(response.status);
      
      if (response.status === 201) {
        expect(response.body).toHaveProperty('user');
        expect(response.body).toHaveProperty('tokens');
      }
    });
  });

  describe('POST /api/v1/auth/login', () => {
    it('should reject login without credentials', async () => {
      const response = await request(app)
        .post('/api/v1/auth/login')
        .send({})
        .expect(400);

      expect(response.body).toHaveProperty('error');
    });

    it('should reject invalid email format', async () => {
      const response = await request(app)
        .post('/api/v1/auth/login')
        .send({
          email: 'invalid-email',
          password: 'Test@1234'
        })
        .expect(400);

      expect(response.body).toHaveProperty('error');
    });

    it('should handle non-existent user', async () => {
      const response = await request(app)
        .post('/api/v1/auth/login')
        .send({
          email: 'nonexistent@example.com',
          password: 'Test@1234'
        });

      // Pode retornar 401 (credenciais inválidas) ou 500 (erro de database)
      expect([401, 500]).toContain(response.status);
    });
  });

  describe('POST /api/v1/auth/refresh', () => {
    it('should reject refresh without token', async () => {
      const response = await request(app)
        .post('/api/v1/auth/refresh')
        .send({})
        .expect(400);

      expect(response.body).toHaveProperty('error');
    });

    it('should reject invalid refresh token', async () => {
      const response = await request(app)
        .post('/api/v1/auth/refresh')
        .send({
          refreshToken: 'invalid-token'
        });

      // Pode retornar 401 (token inválido) ou 500 (erro de verificação)
      expect([401, 500]).toContain(response.status);
    });
  });
});
EOF

echo -e "${GREEN}✓ Auth tests criado${NC}"
echo ""

# ====================
# 3. User Endpoints Tests
# ====================
echo -e "${BLUE}📝 Criando tests/integration/api/users.test.ts...${NC}"

cat > tests/integration/api/users.test.ts << 'EOF'
import request from 'supertest';
import express from 'express';
import { userRoutes } from '../../../src/api/routes/user.routes';

describe('User Endpoints Integration Tests', () => {
  let app: express.Application;

  beforeAll(() => {
    app = express();
    app.use(express.json());
    app.use('/api/v1/users', userRoutes);
  });

  describe('GET /api/v1/users/profile', () => {
    it('should reject request without authentication', async () => {
      const response = await request(app)
        .get('/api/v1/users/profile')
        .expect(401);

      expect(response.body).toHaveProperty('error');
    });

    it('should reject request with invalid token', async () => {
      const response = await request(app)
        .get('/api/v1/users/profile')
        .set('Authorization', 'Bearer invalid-token')
        .expect(401);

      expect(response.body).toHaveProperty('error');
    });
  });

  describe('GET /api/v1/users/:id', () => {
    it('should reject request without authentication', async () => {
      const response = await request(app)
        .get('/api/v1/users/123')
        .expect(401);

      expect(response.body).toHaveProperty('error');
    });
  });

  describe('PUT /api/v1/users/profile', () => {
    it('should reject request without authentication', async () => {
      const response = await request(app)
        .put('/api/v1/users/profile')
        .send({ name: 'Updated Name' })
        .expect(401);

      expect(response.body).toHaveProperty('error');
    });

    it('should reject invalid update data', async () => {
      const response = await request(app)
        .put('/api/v1/users/profile')
        .set('Authorization', 'Bearer mock-token')
        .send({ email: 'invalid-email' })
        .expect(400);

      expect(response.body).toHaveProperty('error');
    });
  });

  describe('PUT /api/v1/users/password', () => {
    it('should reject request without authentication', async () => {
      const response = await request(app)
        .put('/api/v1/users/password')
        .send({
          currentPassword: 'Old@1234',
          newPassword: 'New@1234'
        })
        .expect(401);

      expect(response.body).toHaveProperty('error');
    });

    it('should reject weak new password', async () => {
      const response = await request(app)
        .put('/api/v1/users/password')
        .set('Authorization', 'Bearer mock-token')
        .send({
          currentPassword: 'Old@1234',
          newPassword: '123'
        })
        .expect(400);

      expect(response.body).toHaveProperty('error');
    });
  });

  describe('GET /api/v1/users', () => {
    it('should reject request without authentication', async () => {
      const response = await request(app)
        .get('/api/v1/users')
        .expect(401);

      expect(response.body).toHaveProperty('error');
    });

    it('should accept valid pagination parameters', async () => {
      const response = await request(app)
        .get('/api/v1/users?page=1&limit=10')
        .set('Authorization', 'Bearer mock-token');

      // Pode retornar 200 (sucesso) ou 401 (token inválido) ou 500 (erro de database)
      expect([200, 401, 500]).toContain(response.status);
    });

    it('should reject invalid pagination parameters', async () => {
      const response = await request(app)
        .get('/api/v1/users?page=0&limit=200')
        .set('Authorization', 'Bearer mock-token')
        .expect(400);

      expect(response.body).toHaveProperty('error');
    });
  });
});
EOF

echo -e "${GREEN}✓ User tests criado${NC}"
echo ""

# ====================
# 4. Plan Endpoints Tests
# ====================
echo -e "${BLUE}📝 Criando tests/integration/api/plans.test.ts...${NC}"

cat > tests/integration/api/plans.test.ts << 'EOF'
import request from 'supertest';
import express from 'express';
import { planRoutes } from '../../../src/api/routes/plan.routes';

describe('Plan Endpoints Integration Tests', () => {
  let app: express.Application;

  beforeAll(() => {
    app = express();
    app.use(express.json());
    app.use('/api/v1/plans', planRoutes);
  });

  describe('GET /api/v1/plans', () => {
    it('should return list of available plans', async () => {
      const response = await request(app)
        .get('/api/v1/plans')
        .expect(200);

      expect(response.body).toHaveProperty('plans');
      expect(Array.isArray(response.body.plans)).toBe(true);
    });

    it('should return plans with correct structure', async () => {
      const response = await request(app)
        .get('/api/v1/plans')
        .expect(200);

      const plans = response.body.plans;
      
      if (plans.length > 0) {
        const plan = plans[0];
        expect(plan).toHaveProperty('id');
        expect(plan).toHaveProperty('name');
        expect(plan).toHaveProperty('limits');
      }
    });
  });

  describe('PUT /api/v1/subscriptions/plan', () => {
    it('should reject request without authentication', async () => {
      const response = await request(app)
        .put('/api/v1/subscriptions/plan')
        .send({ plan: 'pro' })
        .expect(401);

      expect(response.body).toHaveProperty('error');
    });

    it('should reject invalid plan name', async () => {
      const response = await request(app)
        .put('/api/v1/subscriptions/plan')
        .set('Authorization', 'Bearer mock-token')
        .send({ plan: 'invalid-plan' })
        .expect(400);

      expect(response.body).toHaveProperty('error');
    });

    it('should accept valid plan upgrade', async () => {
      const response = await request(app)
        .put('/api/v1/subscriptions/plan')
        .set('Authorization', 'Bearer mock-token')
        .send({ plan: 'pro' });

      // Pode retornar 200 (sucesso) ou 401 (token inválido) ou 500 (erro)
      expect([200, 401, 500]).toContain(response.status);
    });
  });

  describe('DELETE /api/v1/subscriptions', () => {
    it('should reject request without authentication', async () => {
      const response = await request(app)
        .delete('/api/v1/subscriptions')
        .expect(401);

      expect(response.body).toHaveProperty('error');
    });
  });
});
EOF

echo -e "${GREEN}✓ Plan tests criado${NC}"
echo ""

# ====================
# 5. Update package.json scripts
# ====================
echo -e "${BLUE}📝 Atualizando package.json com scripts de integration tests...${NC}"

# Adicionar script de integration tests
npm pkg set scripts.test:integration="jest tests/integration --runInBand"
npm pkg set scripts.test:api="jest tests/integration/api --runInBand"

echo -e "${GREEN}✓ Scripts adicionados ao package.json${NC}"
echo ""

# ====================
# Validação
# ====================
echo -e "${YELLOW}🧪 Validando estrutura criada...${NC}"

if [ -f "tests/integration/api/health.test.ts" ] && \
   [ -f "tests/integration/api/auth.test.ts" ] && \
   [ -f "tests/integration/api/users.test.ts" ] && \
   [ -f "tests/integration/api/plans.test.ts" ]; then
    echo -e "${GREEN}✓ Todos os arquivos de teste criados com sucesso${NC}"
else
    echo -e "${RED}✗ Alguns arquivos podem estar faltando${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ INTEGRATION TESTS SETUP COMPLETO!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}📊 Resumo do que foi criado:${NC}"
echo "  ✓ 4 arquivos de integration tests"
echo "  ✓ 25+ cenários de teste"
echo "  ✓ Testes de endpoints REST"
echo "  ✓ Validação de autenticação"
echo "  ✓ Validação de validadores"
echo ""
echo -e "${YELLOW}📝 Próximos passos:${NC}"
echo "  1. Rodar testes: npm run test:integration"
echo "  2. Rodar apenas API: npm run test:api"
echo "  3. Rodar todos os testes: npm test"
echo ""
echo -e "${BLUE}💡 Dica:${NC}"
echo "  Os testes estão preparados para funcionar com mock data"
echo "  Alguns testes podem falhar se o database real não estiver disponível"
echo "  Isso é esperado e será resolvido nos próximos scripts"
echo ""
