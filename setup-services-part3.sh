#!/bin/bash

echo "🚀 FASE 3 - PARTE 3: UserService"
echo "================================="

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

cat > src/core/services/user/UserService.ts << 'EOF'
import { v4 as uuidv4 } from 'uuid';
import { User, UserResponse, CreateUserData, UpdateUserData } from '../../types/user.types';
import { PasswordService } from '../auth/PasswordService';
import { logger } from '../../../config/logger';

export class UserService {
  private static users: Map<string, User> = new Map();

  static async createUser(data: CreateUserData): Promise<UserResponse> {
    const existingUser = Array.from(this.users.values()).find(u => u.email === data.email);
    if (existingUser) throw new Error('Email already exists');

    const passwordHash = await PasswordService.hashPassword(data.password);

    const user: User = {
      id: uuidv4(),
      name: data.name,
      email: data.email,
      passwordHash,
      plan: data.plan || 'starter',
      isActive: true,
      companyName: data.companyName,
      createdAt: new Date(),
      updatedAt: new Date()
    };

    this.users.set(user.id, user);
    logger.info(`User created: ${user.id}`);

    const { passwordHash: _, ...userResponse } = user;
    return userResponse;
  }

  static async getUserById(userId: string): Promise<UserResponse | null> {
    const user = this.users.get(userId);
    if (!user) return null;
    const { passwordHash: _, ...userResponse } = user;
    return userResponse;
  }

  static async getUserByEmail(email: string): Promise<UserResponse | null> {
    const user = Array.from(this.users.values()).find(u => u.email === email);
    if (!user) return null;
    const { passwordHash: _, ...userResponse } = user;
    return userResponse;
  }

  static async listUsers(page: number = 1, limit: number = 10): Promise<{
    users: UserResponse[];
    total: number;
    page: number;
    totalPages: number;
  }> {
    const allUsers = Array.from(this.users.values());
    const total = allUsers.length;
    const totalPages = Math.ceil(total / limit);
    const start = (page - 1) * limit;

    const paginatedUsers = allUsers.slice(start, start + limit).map(user => {
      const { passwordHash: _, ...userResponse } = user;
      return userResponse;
    });

    return { users: paginatedUsers, total, page, totalPages };
  }

  static async updateUser(userId: string, data: UpdateUserData): Promise<UserResponse> {
    const user = this.users.get(userId);
    if (!user) throw new Error('User not found');

    if (data.email) {
      const existing = Array.from(this.users.values())
        .find(u => u.email === data.email && u.id !== userId);
      if (existing) throw new Error('Email already in use');
      user.email = data.email;
    }

    if (data.name) user.name = data.name;
    if (data.companyName !== undefined) user.companyName = data.companyName;
    if (data.isActive !== undefined) user.isActive = data.isActive;

    user.updatedAt = new Date();
    this.users.set(userId, user);

    const { passwordHash: _, ...userResponse } = user;
    return userResponse;
  }

  static async deleteUser(userId: string): Promise<void> {
    const user = this.users.get(userId);
    if (!user) throw new Error('User not found');

    user.isActive = false;
    user.updatedAt = new Date();
    this.users.set(userId, user);
    logger.info(`User deactivated: ${userId}`);
  }

  static async changePassword(userId: string, currentPassword: string, newPassword: string): Promise<void> {
    const user = this.users.get(userId);
    if (!user) throw new Error('User not found');

    const isValid = await PasswordService.comparePassword(currentPassword, user.passwordHash);
    if (!isValid) throw new Error('Current password incorrect');

    user.passwordHash = await PasswordService.hashPassword(newPassword);
    user.updatedAt = new Date();
    this.users.set(userId, user);
    logger.info(`Password changed: ${userId}`);
  }
}
EOF

echo -e "${GREEN}✅ PARTE 3 CONCLUÍDA!${NC}"
echo ""
echo "Arquivos criados:"
echo "  ✓ src/core/services/user/UserService.ts"
echo ""
echo "Execute agora: ./setup-services-part4.sh"
EOF

chmod +x setup-services-part3.sh
