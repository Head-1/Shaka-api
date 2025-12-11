#!/bin/bash

echo "============================================"
echo "SCRIPT 38: UserService Unit Tests"
echo "============================================"
echo ""
echo "Criando testes unitários para UserService..."
echo "Target: Elevar coverage de 6.55% para 80%+"
echo ""

# Criar diretório se não existir
mkdir -p tests/unit/services

# Criar arquivo de teste
cat > tests/unit/services/user.service.test.ts << 'EOF'
import { UserService } from '@core/services/user/UserService';
import { db } from '@config/database';
import { cache } from '@config/cache';
import { PasswordService } from '@core/services/auth/PasswordService';

// Mocks
jest.mock('@config/database');
jest.mock('@config/cache');
jest.mock('@core/services/auth/PasswordService');

describe('UserService', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('createUser', () => {
    it('should create user successfully', async () => {
      const userData = {
        name: 'Test User',
        email: 'test@example.com',
        passwordHash: 'hashed_password',
        plan: 'starter' as const
      };

      const mockUser = {
        id: 'user_123',
        ...userData,
        created_at: new Date(),
        updated_at: new Date()
      };

      (db.query as jest.Mock).mockResolvedValue([mockUser]);

      const result = await UserService.createUser(userData);

      expect(result).toEqual(mockUser);
      expect(db.query).toHaveBeenCalledWith(
        expect.stringContaining('INSERT INTO users'),
        expect.arrayContaining([userData.name, userData.email, userData.passwordHash, userData.plan])
      );
    });

    it('should handle database errors', async () => {
      const userData = {
        name: 'Test User',
        email: 'test@example.com',
        passwordHash: 'hashed_password',
        plan: 'starter' as const
      };

      (db.query as jest.Mock).mockRejectedValue(new Error('Database error'));

      await expect(UserService.createUser(userData)).rejects.toThrow('Database error');
    });

    it('should handle duplicate email error', async () => {
      const userData = {
        name: 'Test User',
        email: 'existing@example.com',
        passwordHash: 'hashed_password',
        plan: 'starter' as const
      };

      const duplicateError = new Error('duplicate key value');
      (duplicateError as any).code = '23505';
      (db.query as jest.Mock).mockRejectedValue(duplicateError);

      await expect(UserService.createUser(userData)).rejects.toThrow();
    });
  });

  describe('getUserById', () => {
    it('should return user when found', async () => {
      const userId = 'user_123';
      const mockUser = {
        id: userId,
        name: 'Test User',
        email: 'test@example.com',
        plan: 'starter',
        created_at: new Date(),
        updated_at: new Date()
      };

      (db.query as jest.Mock).mockResolvedValue([mockUser]);

      const result = await UserService.getUserById(userId);

      expect(result).toEqual(mockUser);
      expect(db.query).toHaveBeenCalledWith(
        expect.stringContaining('SELECT * FROM users'),
        [userId]
      );
    });

    it('should return null when user not found', async () => {
      (db.query as jest.Mock).mockResolvedValue([]);

      const result = await UserService.getUserById('nonexistent');

      expect(result).toBeNull();
    });

    it('should handle database errors', async () => {
      (db.query as jest.Mock).mockRejectedValue(new Error('Database error'));

      await expect(UserService.getUserById('user_123')).rejects.toThrow('Database error');
    });
  });

  describe('getUserByEmail', () => {
    it('should return user when found', async () => {
      const email = 'test@example.com';
      const mockUser = {
        id: 'user_123',
        name: 'Test User',
        email: email,
        plan: 'starter',
        created_at: new Date(),
        updated_at: new Date()
      };

      (db.query as jest.Mock).mockResolvedValue([mockUser]);

      const result = await UserService.getUserByEmail(email);

      expect(result).toEqual(mockUser);
      expect(db.query).toHaveBeenCalledWith(
        expect.stringContaining('SELECT * FROM users'),
        [email]
      );
    });

    it('should return null when user not found', async () => {
      (db.query as jest.Mock).mockResolvedValue([]);

      const result = await UserService.getUserByEmail('nonexistent@example.com');

      expect(result).toBeNull();
    });

    it('should handle database errors', async () => {
      (db.query as jest.Mock).mockRejectedValue(new Error('Database error'));

      await expect(UserService.getUserByEmail('test@example.com')).rejects.toThrow();
    });
  });

  describe('updateUser', () => {
    it('should update user successfully', async () => {
      const userId = 'user_123';
      const updates = {
        name: 'Updated Name',
        email: 'updated@example.com'
      };

      const mockUpdatedUser = {
        id: userId,
        ...updates,
        plan: 'starter',
        created_at: new Date(),
        updated_at: new Date()
      };

      (db.query as jest.Mock).mockResolvedValue([mockUpdatedUser]);

      const result = await UserService.updateUser(userId, updates);

      expect(result).toEqual(mockUpdatedUser);
      expect(db.query).toHaveBeenCalledWith(
        expect.stringContaining('UPDATE users'),
        expect.arrayContaining([userId])
      );
    });

    it('should return null when user not found', async () => {
      (db.query as jest.Mock).mockResolvedValue([]);

      const result = await UserService.updateUser('nonexistent', { name: 'Test' });

      expect(result).toBeNull();
    });

    it('should invalidate cache after update', async () => {
      const userId = 'user_123';
      const mockUser = { id: userId, name: 'Updated' };

      (db.query as jest.Mock).mockResolvedValue([mockUser]);
      (cache.del as jest.Mock).mockResolvedValue(1);

      await UserService.updateUser(userId, { name: 'Updated' });

      expect(cache.del).toHaveBeenCalledWith(`user:${userId}`);
    });
  });

  describe('deleteUser', () => {
    it('should delete user successfully', async () => {
      const userId = 'user_123';

      (db.query as jest.Mock).mockResolvedValue([{ id: userId }]);

      const result = await UserService.deleteUser(userId);

      expect(result).toBe(true);
      expect(db.query).toHaveBeenCalledWith(
        expect.stringContaining('DELETE FROM users'),
        [userId]
      );
    });

    it('should return false when user not found', async () => {
      (db.query as jest.Mock).mockResolvedValue([]);

      const result = await UserService.deleteUser('nonexistent');

      expect(result).toBe(false);
    });

    it('should invalidate cache after deletion', async () => {
      const userId = 'user_123';

      (db.query as jest.Mock).mockResolvedValue([{ id: userId }]);
      (cache.del as jest.Mock).mockResolvedValue(1);

      await UserService.deleteUser(userId);

      expect(cache.del).toHaveBeenCalledWith(`user:${userId}`);
    });
  });

  describe('validatePassword', () => {
    it('should return true for correct password', async () => {
      const userId = 'user_123';
      const password = 'Test@123';
      const passwordHash = 'hashed_password';

      const mockUser = {
        id: userId,
        password_hash: passwordHash
      };

      (db.query as jest.Mock).mockResolvedValue([mockUser]);
      (PasswordService.comparePassword as jest.Mock).mockResolvedValue(true);

      const result = await UserService.validatePassword(userId, password);

      expect(result).toBe(true);
      expect(PasswordService.comparePassword).toHaveBeenCalledWith(password, passwordHash);
    });

    it('should return false for incorrect password', async () => {
      const userId = 'user_123';
      const mockUser = { id: userId, password_hash: 'hashed_password' };

      (db.query as jest.Mock).mockResolvedValue([mockUser]);
      (PasswordService.comparePassword as jest.Mock).mockResolvedValue(false);

      const result = await UserService.validatePassword(userId, 'WrongPassword');

      expect(result).toBe(false);
    });

    it('should return false when user not found', async () => {
      (db.query as jest.Mock).mockResolvedValue([]);

      const result = await UserService.validatePassword('nonexistent', 'password');

      expect(result).toBe(false);
    });
  });

  describe('listUsers', () => {
    it('should return paginated users', async () => {
      const mockUsers = [
        { id: 'user_1', name: 'User 1', email: 'user1@example.com' },
        { id: 'user_2', name: 'User 2', email: 'user2@example.com' }
      ];

      (db.query as jest.Mock)
        .mockResolvedValueOnce(mockUsers)
        .mockResolvedValueOnce([{ count: '10' }]);

      const result = await UserService.listUsers({ page: 1, limit: 10 });

      expect(result.users).toEqual(mockUsers);
      expect(result.total).toBe(10);
      expect(result.page).toBe(1);
      expect(result.limit).toBe(10);
    });

    it('should handle empty results', async () => {
      (db.query as jest.Mock)
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([{ count: '0' }]);

      const result = await UserService.listUsers({ page: 1, limit: 10 });

      expect(result.users).toEqual([]);
      expect(result.total).toBe(0);
    });

    it('should apply correct pagination', async () => {
      const page = 2;
      const limit = 5;

      (db.query as jest.Mock)
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([{ count: '0' }]);

      await UserService.listUsers({ page, limit });

      expect(db.query).toHaveBeenCalledWith(
        expect.stringContaining('LIMIT'),
        expect.arrayContaining([limit, (page - 1) * limit])
      );
    });
  });
});
EOF

echo "✓ Arquivo tests/unit/services/user.service.test.ts criado"
echo ""

# Rodar testes do UserService
echo "Executando testes do UserService..."
npm run test:unit -- --testPathPattern=user.service.test.ts

echo ""
echo "============================================"
echo "SCRIPT 38 CONCLUÍDO!"
echo "============================================"
echo ""
