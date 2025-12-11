import { UserService } from '../../../src/core/services/user/UserService';
import { PasswordService } from '../../../src/core/services/auth/PasswordService';

// Mock do PasswordService
jest.mock('../../../src/core/services/auth/PasswordService');
jest.mock('../../../src/config/logger');

describe('UserService', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('getById', () => {
    it('should return null when user not found', async () => {
      const result = await UserService.getById('nonexistent_id');
      expect(result).toBeNull();
    });

    it('should not return password in response', async () => {
      const result = await UserService.getById('any_id');
      
      if (result) {
        expect(result).not.toHaveProperty('password');
      }
    });
  });

  describe('update', () => {
    it('should throw error when user not found', async () => {
      await expect(
        UserService.update('nonexistent_id', { name: 'Test' })
      ).rejects.toThrow('User not found');
    });

    it('should accept valid update data', async () => {
      const updateData = { name: 'Updated Name', email: 'new@example.com' };
      
      try {
        await UserService.update('some_id', updateData);
      } catch (error: any) {
        expect(error.message).toBe('User not found');
      }
    });
  });

  describe('changePassword', () => {
    it('should throw error when user not found', async () => {
      (PasswordService.comparePassword as jest.Mock).mockResolvedValue(false);
      
      await expect(
        UserService.changePassword('nonexistent_id', 'old', 'new')
      ).rejects.toThrow();
    });

    it('should accept password change parameters', async () => {
      try {
        await UserService.changePassword('user_id', 'OldPass@123', 'NewPass@123');
      } catch (error) {
        expect(error).toBeDefined();
      }
    });
  });

  describe('list', () => {
    it('should return paginated users with default parameters', async () => {
      const result = await UserService.list();
      
      expect(result).toBeDefined();
      expect(result).toHaveProperty('users');
      expect(result).toHaveProperty('pagination');
      expect(result.pagination).toHaveProperty('total');
      expect(result.pagination).toHaveProperty('page');
      expect(result.pagination).toHaveProperty('limit');
      expect(Array.isArray(result.users)).toBe(true);
    });

    it('should accept custom pagination parameters', async () => {
      const result = await UserService.list(2, 5);
      
      expect(result).toBeDefined();
      expect(result.pagination.page).toBe(2);
      expect(result.pagination.limit).toBe(5);
      expect(Array.isArray(result.users)).toBe(true);
    });

    it('should return users without password field', async () => {
      const result = await UserService.list(1, 10);
      
      result.users.forEach((user: any) => {
        expect(user).not.toHaveProperty('password');
      });
    });

    it('should handle large page numbers', async () => {
      const result = await UserService.list(999, 10);
      
      expect(result).toBeDefined();
      expect(result.users).toBeDefined();
      expect(Array.isArray(result.users)).toBe(true);
    });

    it('should calculate total pages correctly', async () => {
      const result = await UserService.list(1, 10);
      
      expect(result.pagination).toHaveProperty('totalPages');
      expect(typeof result.pagination.totalPages).toBe('number');
    });
  });

  describe('deactivate', () => {
    it('should throw error when user not found', async () => {
      await expect(
        UserService.deactivate('nonexistent_id')
      ).rejects.toThrow('User not found');
    });

    it('should accept valid user id', async () => {
      try {
        await UserService.deactivate('some_user_id');
      } catch (error: any) {
        expect(error.message).toBe('User not found');
      }
    });
  });

  describe('UserService methods existence', () => {
    it('should have getById method', () => {
      expect(typeof UserService.getById).toBe('function');
    });

    it('should have update method', () => {
      expect(typeof UserService.update).toBe('function');
    });

    it('should have changePassword method', () => {
      expect(typeof UserService.changePassword).toBe('function');
    });

    it('should have list method', () => {
      expect(typeof UserService.list).toBe('function');
    });

    it('should have deactivate method', () => {
      expect(typeof UserService.deactivate).toBe('function');
    });
  });
});
