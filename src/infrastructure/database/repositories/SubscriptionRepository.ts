import { Repository } from 'typeorm';
import { AppDataSource } from '../config';
import { SubscriptionEntity } from '../entities/SubscriptionEntity';

export interface CreateSubscriptionData {
  userId: string;
  plan: 'starter' | 'pro' | 'business' | 'enterprise';
  stripeCustomerId?: string;
  stripeSubscriptionId?: string;
  currentPeriodStart?: Date;
  currentPeriodEnd?: Date;
}

export interface UpdateSubscriptionData {
  plan?: 'starter' | 'pro' | 'business' | 'enterprise';
  status?: 'active' | 'cancelled' | 'past_due' | 'trialing';
  stripeSubscriptionId?: string;
  currentPeriodStart?: Date;
  currentPeriodEnd?: Date;
  cancelAtPeriodEnd?: boolean;
}

export class SubscriptionRepository {
  private static _repository: Repository<SubscriptionEntity> | null = null;

  static get repository(): Repository<SubscriptionEntity> {
    if (!this._repository) {
      if (!AppDataSource.isInitialized) {
        throw new Error('AppDataSource is not initialized. Call DatabaseService.initialize() first.');
      }
      this._repository = AppDataSource.getRepository(SubscriptionEntity);
    }
    return this._repository;
  }
  static initialize() {
    if (!AppDataSource.isInitialized) {
      throw new Error('AppDataSource must be initialized before SubscriptionRepository');
    }
    this._repository = AppDataSource.getRepository(SubscriptionEntity);
  }

  static async create(data: CreateSubscriptionData): Promise<SubscriptionEntity> {
    const subscription = this.repository.create({
      userId: data.userId,
      plan: data.plan,
      status: 'active',
      stripeCustomerId: data.stripeCustomerId,
      stripeSubscriptionId: data.stripeSubscriptionId,
      currentPeriodStart: data.currentPeriodStart || new Date(),
      currentPeriodEnd: data.currentPeriodEnd,
      cancelAtPeriodEnd: false
    });

    return this.repository.save(subscription);
  }

  static async findByUserId(userId: string): Promise<SubscriptionEntity | null> {
    return this.repository.findOne({
      where: { userId }
    });
  }

  static async findById(id: string): Promise<SubscriptionEntity | null> {
    return this.repository.findOne({
      where: { id }
    });
  }

  static async update(id: string, data: UpdateSubscriptionData): Promise<SubscriptionEntity | null> {
    const updateData: any = {};

    if (data.plan !== undefined) {
      updateData.plan = data.plan;
    }

    if (data.status !== undefined) {
      updateData.status = data.status;
    }

    if (data.stripeSubscriptionId !== undefined) {
      updateData.stripeSubscriptionId = data.stripeSubscriptionId;
    }

    if (data.currentPeriodStart !== undefined) {
      updateData.currentPeriodStart = data.currentPeriodStart;
    }

    if (data.currentPeriodEnd !== undefined) {
      updateData.currentPeriodEnd = data.currentPeriodEnd;
    }

    if (data.cancelAtPeriodEnd !== undefined) {
      updateData.cancelAtPeriodEnd = data.cancelAtPeriodEnd;
    }

    if (Object.keys(updateData).length > 0) {
      await this.repository.update(id, updateData);
    }

    return this.findById(id);
  }

  static async cancel(id: string): Promise<void> {
    await this.repository.update(id, {
      cancelAtPeriodEnd: true
    });
  }

  static async delete(id: string): Promise<void> {
    await this.repository.delete(id);
  }

  static async list(limit: number = 100, offset: number = 0): Promise<SubscriptionEntity[]> {
    return this.repository.find({
      take: limit,
      skip: offset,
      order: { createdAt: 'DESC' }
    });
  }
}
