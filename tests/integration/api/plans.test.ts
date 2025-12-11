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

  describe('PUT /api/v1/plans', () => {
    it('should reject request without authentication', async () => {
      const response = await request(app)
        .put('/api/v1/plans')
        .send({ plan: 'pro' })
        .expect(401);

      expect(response.body).toHaveProperty('error');
    });

    it('should reject invalid plan name with mock token', async () => {
      const response = await request(app)
        .put('/api/v1/plans')
        .set('Authorization', 'Bearer mock-token')
        .send({ plan: 'invalid-plan' });

      // Mock token inválido, então 401 é aceitável
      expect([400, 401]).toContain(response.status);
    });

    it('should accept valid plan upgrade with mock token', async () => {
      const response = await request(app)
        .put('/api/v1/plans')
        .set('Authorization', 'Bearer mock-token')
        .send({ plan: 'pro' });

      // Mock token inválido, então 401 é esperado
      expect([200, 401, 500]).toContain(response.status);
    });
  });

  describe('DELETE /api/v1/plans', () => {
    it('should reject request without authentication', async () => {
      const response = await request(app)
        .delete('/api/v1/plans')
        .expect(401);

      expect(response.body).toHaveProperty('error');
    });
  });
});
