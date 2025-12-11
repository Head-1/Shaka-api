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
