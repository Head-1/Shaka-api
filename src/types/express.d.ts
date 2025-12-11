import { User } from '../core/types/user.types';
import { ApiKey } from '../core/services/api-key/types';

declare global {
  namespace Express {
    interface Request {
      user?: User;
      apiKey?: ApiKey;
    }
  }
}

export {};
