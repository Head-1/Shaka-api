export interface User {
  id: string;
  email: string;
  name: string;
  plan: 'starter' | 'pro' | 'business' | 'enterprise';
  createdAt: Date;
  updatedAt: Date;
}

export interface CreateUserData {
  email: string;
  password: string;
  name: string;
  plan?: 'starter' | 'pro' | 'business' | 'enterprise';
}

export interface UpdateUserData {
  email?: string;
  name?: string;
  plan?: 'starter' | 'pro' | 'business' | 'enterprise';
}

export interface UserResponse {
  id: string;
  email: string;
  name: string;
  plan: string;
  createdAt: Date;
  updatedAt: Date;
}
