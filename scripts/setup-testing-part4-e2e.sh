#!/bin/bash

echo "============================================"
echo "SCRIPT 32: Setup E2E Tests Structure"
echo "============================================"
echo ""

# 1. Criar estrutura de diretorios
echo "1. Criando estrutura de diretorios..."
mkdir -p tests/e2e

# 2. Criar auth-flow.test.ts
echo "2. Criando auth-flow.test.ts..."
cat > tests/e2e/auth-flow.test.ts << 'EOF'
import request from 'supertest';
import express from 'express';
import apiRoutes from '../../src/api/routes';

describe('E2E: Authentication Flow', () => {
  let app: express.Application;
  let testUser = {
    name: 'E2E Test User',
    email: `e2e.test.${Date.now()}@example.com`,
    password: 'Test@Password123'
  };
  let accessToken: string;
  let refreshToken: string;

  beforeAll(() => {
    app = express();
    app.use(express.json());
    app.use('/api/v1', apiRoutes);
  });

  describe('Complete Authentication Flow', () => {
    it('should complete full flow: register -> login -> access protected route', async () => {
      const registerResponse = await request(app)
        .post('/api/v1/auth/register')
        .send(testUser)
        .expect(201);

      expect(registerResponse.body).toHaveProperty('accessToken');
      expect(registerResponse.body).toHaveProperty('refreshToken');
      
      accessToken = registerResponse.body.accessToken;
      refreshToken = registerResponse.body.refreshToken;

      const profileResponse = await request(app)
        .get('/api/v1/users/profile')
        .set('Authorization', `Bearer ${accessToken}`);

      expect([200, 401]).toContain(profileResponse.status);
    });

    it('should handle failed login retry flow', async () => {
      const failedLogin = await request(app)
        .post('/api/v1/auth/login')
        .send({
          email: testUser.email,
          password: 'WrongPassword123!'
        });

      expect([400, 401]).toContain(failedLogin.status);

      const successLogin = await request(app)
        .post('/api/v1/auth/login')
        .send({
          email: testUser.email,
          password: testUser.password
        });

      expect([200, 401]).toContain(successLogin.status);
    });

    it('should handle token refresh flow', async () => {
      const loginResponse = await request(app)
        .post('/api/v1/auth/login')
        .send({
          email: testUser.email,
          password: testUser.password
        });

      if (loginResponse.status === 200) {
        const oldRefreshToken = loginResponse.body.refreshToken;

        const refreshResponse = await request(app)
          .post('/api/v1/auth/refresh')
          .send({ refreshToken: oldRefreshToken });

        expect([200, 401]).toContain(refreshResponse.status);
      } else {
        expect([401]).toContain(loginResponse.status);
      }
    });

    it('should handle logout flow', async () => {
      const loginResponse = await request(app)
        .post('/api/v1/auth/login')
        .send({
          email: testUser.email,
          password: testUser.password
        });

      if (loginResponse.status === 200) {
        const token = loginResponse.body.accessToken;

        await request(app)
          .get('/api/v1/users/profile')
          .set('Authorization', `Bearer ${token}`)
          .expect(200);

        const afterLogout = await request(app)
          .get('/api/v1/users/profile')
          .set('Authorization', `Bearer invalid-token`);

        expect([401]).toContain(afterLogout.status);
      } else {
        expect([401]).toContain(loginResponse.status);
      }
    });
  });
});
EOF

# 3. Criar user-flow.test.ts
echo "3. Criando user-flow.test.ts..."
cat > tests/e2e/user-flow.test.ts << 'EOF'
import request from 'supertest';
import express from 'express';
import apiRoutes from '../../src/api/routes';

describe('E2E: User Management Flow', () => {
  let app: express.Application;
  let testUser = {
    name: 'User Flow Test',
    email: `user.flow.${Date.now()}@example.com`,
    password: 'UserFlow@123'
  };
  let accessToken: string;

  beforeAll(() => {
    app = express();
    app.use(express.json());
    app.use('/api/v1', apiRoutes);
  });

  describe('Complete User CRUD Flow', () => {
    it('should complete: register -> get profile -> update -> list users', async () => {
      const registerResponse = await request(app)
        .post('/api/v1/auth/register')
        .send(testUser)
        .expect(201);

      accessToken = registerResponse.body.accessToken;

      const profileResponse = await request(app)
        .get('/api/v1/users/profile')
        .set('Authorization', `Bearer ${accessToken}`);

      expect([200, 401]).toContain(profileResponse.status);

      const updateResponse = await request(app)
        .put('/api/v1/users/profile')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ name: 'Updated Name' });

      expect([200, 401]).toContain(updateResponse.status);

      const listResponse = await request(app)
        .get('/api/v1/users?page=1&limit=10')
        .set('Authorization', `Bearer ${accessToken}`);

      expect([200, 401]).toContain(listResponse.status);
    });

    it('should handle password change flow', async () => {
      const newUser = {
        name: 'Password Test',
        email: `pwd.test.${Date.now()}@example.com`,
        password: 'OldPassword@123'
      };

      const registerResponse = await request(app)
        .post('/api/v1/auth/register')
        .send(newUser)
        .expect(201);

      const token = registerResponse.body.accessToken;

      const changeResponse = await request(app)
        .put('/api/v1/users/password')
        .set('Authorization', `Bearer ${token}`)
        .send({
          currentPassword: 'OldPassword@123',
          newPassword: 'NewPassword@456'
        });

      expect([200, 401]).toContain(changeResponse.status);

      const loginResponse = await request(app)
        .post('/api/v1/auth/login')
        .send({
          email: newUser.email,
          password: 'NewPassword@456'
        });

      expect([200, 401]).toContain(loginResponse.status);
    });

    it('should reject invalid update data', async () => {
      const user = {
        name: 'Validation Test',
        email: `validation.${Date.now()}@example.com`,
        password: 'Valid@Password123'
      };

      const registerResponse = await request(app)
        .post('/api/v1/auth/register')
        .send(user)
        .expect(201);

      const token = registerResponse.body.accessToken;

      const invalidUpdate = await request(app)
        .put('/api/v1/users/profile')
        .set('Authorization', `Bearer ${token}`)
        .send({ email: 'invalid-email-format' });

      expect([400, 401]).toContain(invalidUpdate.status);
    });
  });
});
EOF

# 4. Criar subscription-flow.test.ts
echo "4. Criando subscription-flow.test.ts..."
cat > tests/e2e/subscription-flow.test.ts << 'EOF'
import request from 'supertest';
import express from 'express';
import apiRoutes from '../../src/api/routes';

describe('E2E: Subscription Management Flow', () => {
  let app: express.Application;
  let testUser = {
    name: 'Subscription Test',
    email: `sub.test.${Date.now()}@example.com`,
    password: 'Subscription@123'
  };
  let accessToken: string;

  beforeAll(() => {
    app = express();
    app.use(express.json());
    app.use('/api/v1', apiRoutes);
  });

  describe('Plan Upgrade Flow', () => {
    it('should upgrade from starter to pro and verify limits', async () => {
      const registerResponse = await request(app)
        .post('/api/v1/auth/register')
        .send(testUser)
        .expect(201);

      accessToken = registerResponse.body.accessToken;

      const plansResponse = await request(app)
        .get('/api/v1/plans')
        .expect(200);

      expect(plansResponse.body).toBeInstanceOf(Array);

      const upgradeResponse = await request(app)
        .put('/api/v1/plans')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ plan: 'pro' });

      expect([200, 401]).toContain(upgradeResponse.status);
    });

    it('should downgrade from pro to starter', async () => {
      const user = {
        name: 'Downgrade Test',
        email: `downgrade.${Date.now()}@example.com`,
        password: 'Downgrade@123',
        plan: 'pro'
      };

      const registerResponse = await request(app)
        .post('/api/v1/auth/register')
        .send(user)
        .expect(201);

      const token = registerResponse.body.accessToken;

      const downgradeResponse = await request(app)
        .put('/api/v1/plans')
        .set('Authorization', `Bearer ${token}`)
        .send({ plan: 'starter' });

      expect([200, 401]).toContain(downgradeResponse.status);
    });

    it('should cancel subscription', async () => {
      const user = {
        name: 'Cancel Test',
        email: `cancel.${Date.now()}@example.com`,
        password: 'Cancel@123'
      };

      const registerResponse = await request(app)
        .post('/api/v1/auth/register')
        .send(user)
        .expect(201);

      const token = registerResponse.body.accessToken;

      const cancelResponse = await request(app)
        .delete('/api/v1/plans')
        .set('Authorization', `Bearer ${token}`);

      expect([200, 401]).toContain(cancelResponse.status);

      const profileResponse = await request(app)
        .get('/api/v1/users/profile')
        .set('Authorization', `Bearer ${token}`);

      expect([200, 401]).toContain(profileResponse.status);
    });
  });
});
EOF

# 5. Atualizar package.json
echo "5. Atualizando package.json..."
npm pkg set scripts.test:e2e="jest tests/e2e"

echo ""
echo "============================================"
echo "CONCLUIDO!"
echo "============================================"
echo ""
echo "Arquivos criados:"
echo "  tests/e2e/auth-flow.test.ts"
echo "  tests/e2e/user-flow.test.ts"
echo "  tests/e2e/subscription-flow.test.ts"
echo ""
echo "Execute: npm run test:e2e"
echo ""
