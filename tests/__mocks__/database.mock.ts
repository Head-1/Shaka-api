export const mockDatabaseService = {
  initialize: jest.fn().mockResolvedValue(undefined),
  getDataSource: jest.fn().mockReturnValue({
    isInitialized: true,
    manager: {
      save: jest.fn(),
      find: jest.fn(),
      findOne: jest.fn(),
      update: jest.fn(),
      delete: jest.fn()
    }
  }),
  disconnect: jest.fn().mockResolvedValue(undefined)
};
