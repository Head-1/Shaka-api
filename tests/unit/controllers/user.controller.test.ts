import { Request, Response } from 'express';
import { UserController } from '../../../src/api/controllers/user/UserController';
import { UserService } from '../../../src/core/services/user/UserService';

jest.mock('../../../src/core/services/user/UserService');
jest.mock('../../../src/config/logger');

describe('UserController', () => {
  let mockRequest: Partial<Request>;
  let mockResponse: Partial<Response>;
  let jsonMock: jest.Mock;
  let statusMock: jest.Mock;

  beforeEach(() => {
    jest.clearAllMocks();
    
    jsonMock = jest.fn();
    statusMock = jest.fn().mockReturnValue({ json: jsonMock });
    
    mockResponse = {
      status: statusMock,
      json: jsonMock
    };
  });

  describe('getProfile', () => {
    it('should return user profile successfully', async () => {
      const mockUser = {
        id: 'user_123',
        name: 'Test User',
        email: 'test@example.com',
        plan: 'pro'
      };

      mockRequest = {
        user: { id: 'user_123' }
      } as any;

      (UserService.getById as jest.Mock).mockResolvedValue(mockUser);

      await UserController.getProfile(mockRequest as Request, mockResponse as Response);

      expect(UserService.getById).toHaveBeenCalledWith('user_123');
      expect(statusMock).toHaveBeenCalledWith(200);
      expect(jsonMock).toHaveBeenCalledWith({ user: mockUser });
    });

    it('should return 401 when user not authenticated', async () => {
      mockRequest = {} as any;

      await UserController.getProfile(mockRequest as Request, mockResponse as Response);

      expect(statusMock).toHaveBeenCalledWith(401);
      expect(jsonMock).toHaveBeenCalledWith({ error: 'Unauthorized' });
    });

    it('should return 404 when user not found', async () => {
      mockRequest = {
        user: { id: 'user_123' }
      } as any;

      (UserService.getById as jest.Mock).mockResolvedValue(null);

      await UserController.getProfile(mockRequest as Request, mockResponse as Response);

      expect(statusMock).toHaveBeenCalledWith(404);
      expect(jsonMock).toHaveBeenCalledWith({ error: 'User not found' });
    });

    it('should handle errors gracefully', async () => {
      mockRequest = {
        user: { id: 'user_123' }
      } as any;

      (UserService.getById as jest.Mock).mockRejectedValue(new Error('Database error'));

      await UserController.getProfile(mockRequest as Request, mockResponse as Response);

      expect(statusMock).toHaveBeenCalledWith(500);
      expect(jsonMock).toHaveBeenCalledWith({ error: 'Internal server error' });
    });
  });

  describe('getById', () => {
    it('should return user by id successfully', async () => {
      const mockUser = {
        id: 'user_456',
        name: 'Another User',
        email: 'another@example.com'
      };

      mockRequest = {
        params: { id: 'user_456' }
      };

      (UserService.getById as jest.Mock).mockResolvedValue(mockUser);

      await UserController.getById(mockRequest as Request, mockResponse as Response);

      expect(UserService.getById).toHaveBeenCalledWith('user_456');
      expect(statusMock).toHaveBeenCalledWith(200);
      expect(jsonMock).toHaveBeenCalledWith({ user: mockUser });
    });

    it('should return 404 when user not found', async () => {
      mockRequest = {
        params: { id: 'nonexistent' }
      };

      (UserService.getById as jest.Mock).mockResolvedValue(null);

      await UserController.getById(mockRequest as Request, mockResponse as Response);

      expect(statusMock).toHaveBeenCalledWith(404);
      expect(jsonMock).toHaveBeenCalledWith({ error: 'User not found' });
    });

    it('should handle errors gracefully', async () => {
      mockRequest = {
        params: { id: 'user_123' }
      };

      (UserService.getById as jest.Mock).mockRejectedValue(new Error('Database error'));

      await UserController.getById(mockRequest as Request, mockResponse as Response);

      expect(statusMock).toHaveBeenCalledWith(500);
      expect(jsonMock).toHaveBeenCalledWith({ error: 'Internal server error' });
    });
  });

  describe('updateProfile', () => {
    it('should update user profile successfully', async () => {
      const updateData = { name: 'Updated Name' };
      const updatedUser = {
        id: 'user_123',
        name: 'Updated Name',
        email: 'test@example.com'
      };

      mockRequest = {
        user: { id: 'user_123' },
        body: updateData
      } as any;

      (UserService.update as jest.Mock).mockResolvedValue(updatedUser);

      await UserController.updateProfile(mockRequest as Request, mockResponse as Response);

      expect(UserService.update).toHaveBeenCalledWith('user_123', updateData);
      expect(statusMock).toHaveBeenCalledWith(200);
      expect(jsonMock).toHaveBeenCalledWith({ user: updatedUser });
    });

    it('should return 401 when user not authenticated', async () => {
      mockRequest = {
        body: { name: 'Test' }
      } as any;

      await UserController.updateProfile(mockRequest as Request, mockResponse as Response);

      expect(statusMock).toHaveBeenCalledWith(401);
      expect(jsonMock).toHaveBeenCalledWith({ error: 'Unauthorized' });
    });

    it('should handle errors gracefully', async () => {
      mockRequest = {
        user: { id: 'user_123' },
        body: { name: 'Test' }
      } as any;

      (UserService.update as jest.Mock).mockRejectedValue(new Error('Update failed'));

      await UserController.updateProfile(mockRequest as Request, mockResponse as Response);

      expect(statusMock).toHaveBeenCalledWith(500);
      expect(jsonMock).toHaveBeenCalledWith({ error: 'Internal server error' });
    });
  });

  describe('changePassword', () => {
    it('should change password successfully', async () => {
      mockRequest = {
        user: { id: 'user_123' },
        body: {
          currentPassword: 'OldPass@123',
          newPassword: 'NewPass@123'
        }
      } as any;

      (UserService.changePassword as jest.Mock).mockResolvedValue(undefined);

      await UserController.changePassword(mockRequest as Request, mockResponse as Response);

      expect(UserService.changePassword).toHaveBeenCalledWith(
        'user_123',
        'OldPass@123',
        'NewPass@123'
      );
      expect(statusMock).toHaveBeenCalledWith(200);
      expect(jsonMock).toHaveBeenCalledWith({ message: 'Password changed successfully' });
    });

    it('should return 401 when user not authenticated', async () => {
      mockRequest = {
        body: {
          currentPassword: 'old',
          newPassword: 'new'
        }
      } as any;

      await UserController.changePassword(mockRequest as Request, mockResponse as Response);

      expect(statusMock).toHaveBeenCalledWith(401);
      expect(jsonMock).toHaveBeenCalledWith({ error: 'Unauthorized' });
    });

    it('should return 400 for invalid current password', async () => {
      mockRequest = {
        user: { id: 'user_123' },
        body: {
          currentPassword: 'WrongPass',
          newPassword: 'NewPass@123'
        }
      } as any;

      const error = new Error('Invalid current password');
      (UserService.changePassword as jest.Mock).mockRejectedValue(error);

      await UserController.changePassword(mockRequest as Request, mockResponse as Response);

      expect(statusMock).toHaveBeenCalledWith(400);
      expect(jsonMock).toHaveBeenCalledWith({ error: 'Invalid current password' });
    });

    it('should handle generic errors gracefully', async () => {
      mockRequest = {
        user: { id: 'user_123' },
        body: {
          currentPassword: 'Old@123',
          newPassword: 'New@123'
        }
      } as any;

      (UserService.changePassword as jest.Mock).mockRejectedValue(new Error('Database error'));

      await UserController.changePassword(mockRequest as Request, mockResponse as Response);

      expect(statusMock).toHaveBeenCalledWith(500);
      expect(jsonMock).toHaveBeenCalledWith({ error: 'Internal server error' });
    });
  });

  describe('list', () => {
    it('should list users with default pagination', async () => {
      const mockResult = {
        users: [
          { id: 'user_1', name: 'User 1' },
          { id: 'user_2', name: 'User 2' }
        ],
        pagination: {
          page: 1,
          limit: 10,
          total: 2,
          totalPages: 1
        }
      };

      mockRequest = {
        query: {}
      };

      (UserService.list as jest.Mock).mockResolvedValue(mockResult);

      await UserController.list(mockRequest as Request, mockResponse as Response);

      expect(UserService.list).toHaveBeenCalledWith(1, 10);
      expect(statusMock).toHaveBeenCalledWith(200);
      expect(jsonMock).toHaveBeenCalledWith(mockResult);
    });

    it('should list users with custom pagination', async () => {
      const mockResult = {
        users: [{ id: 'user_1', name: 'User 1' }],
        pagination: {
          page: 2,
          limit: 5,
          total: 10,
          totalPages: 2
        }
      };

      mockRequest = {
        query: { page: '2', limit: '5' }
      };

      (UserService.list as jest.Mock).mockResolvedValue(mockResult);

      await UserController.list(mockRequest as Request, mockResponse as Response);

      expect(UserService.list).toHaveBeenCalledWith(2, 5);
      expect(statusMock).toHaveBeenCalledWith(200);
    });

    it('should handle errors gracefully', async () => {
      mockRequest = {
        query: {}
      };

      (UserService.list as jest.Mock).mockRejectedValue(new Error('Database error'));

      await UserController.list(mockRequest as Request, mockResponse as Response);

      expect(statusMock).toHaveBeenCalledWith(500);
      expect(jsonMock).toHaveBeenCalledWith({ error: 'Internal server error' });
    });
  });
});
