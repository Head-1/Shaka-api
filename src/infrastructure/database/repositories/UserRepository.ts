import { Repository } from 'typeorm';
import { AppDataSource } from '../config';
import { UserEntity } from '../entities/UserEntity';
import { CreateUserData, UpdateUserData, User, UserResponse } from '../../../core/types/user.types';

export class UserRepository {
  private static _repository: Repository<UserEntity> | null = null;

  // ✅ GETTER AUTOMÁTICO - LAZY INITIALIZATION
  static get repository(): Repository<UserEntity> {
    if (!this._repository) {
      if (!AppDataSource.isInitialized) {
        throw new Error('AppDataSource is not initialized. Call DatabaseService.initialize() first.');
      }
      this._repository = AppDataSource.getRepository(UserEntity);
    }
    return this._repository;
  }

  // Método initialize mantido para compatibilidade
  static initialize() {
    if (!AppDataSource.isInitialized) {
      throw new Error('AppDataSource must be initialized before UserRepository');
    }
    this._repository = AppDataSource.getRepository(UserEntity);
  }

  static async create(data: CreateUserData & { passwordHash: string }): Promise<User> {
    const user = this.repository.create({
      email: data.email,
      passwordHash: data.passwordHash,
      name: data.name,
      plan: data.plan || 'starter'
    });

    await this.repository.save(user);

    return this.toUser(user);
  }

  static async findById(id: string): Promise<User | null> {
    const user = await this.repository.findOne({ where: { id } });
    return user ? this.toUser(user) : null;
  }

  static async findByEmail(email: string): Promise<UserEntity | null> {
    return this.repository.findOne({ where: { email } });
  }

  static async update(id: string, data: UpdateUserData): Promise<User | null> {
    const updateData: any = {};

    if (data.email !== undefined) {
      updateData.email = data.email;
    }

    if (data.plan !== undefined) {
      updateData.plan = data.plan;
    }

    if (Object.keys(updateData).length > 0) {
      await this.repository.update(id, updateData);
    }

    return this.findById(id);
  }

  static async updatePassword(id: string, passwordHash: string): Promise<void> {
    await this.repository.update(id, { passwordHash });
  }

  static async delete(id: string): Promise<void> {
    await this.repository.delete(id);
  }

  static async list(limit: number = 100, offset: number = 0): Promise<User[]> {
    const users = await this.repository.find({
      take: limit,
      skip: offset,
      order: { createdAt: 'DESC' }
    });

    return users.map(this.toUser);
  }

  static async count(): Promise<number> {
    return this.repository.count();
  }

  private static toUser(entity: UserEntity): User {
    return {
      id: entity.id,
      email: entity.email,
      name: entity.name,
      plan: entity.plan,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt
    };
  }

  static toUserResponse(user: User): UserResponse {
    return {
      id: user.id,
      email: user.email,
      name: user.name,
      plan: user.plan,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt
    };
  }
}
