export const mockCacheService = {
  initialize: jest.fn().mockResolvedValue(undefined),
  get: jest.fn(),
  set: jest.fn().mockResolvedValue('OK'),
  delete: jest.fn().mockResolvedValue(1),
  exists: jest.fn().mockResolvedValue(false),
  disconnect: jest.fn().mockResolvedValue(undefined)
};
