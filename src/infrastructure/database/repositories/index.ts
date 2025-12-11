import { UserRepository } from './UserRepository';
import { SubscriptionRepository } from './SubscriptionRepository';

export class RepositoryFactory {
  private static userRepository: UserRepository;
  private static subscriptionRepository: SubscriptionRepository;

  static getUserRepository(): UserRepository {
    if (!this.userRepository) {
      this.userRepository = new UserRepository();
    }
    return this.userRepository;
  }

  static getSubscriptionRepository(): SubscriptionRepository {
    if (!this.subscriptionRepository) {
      this.subscriptionRepository = new SubscriptionRepository();
    }
    return this.subscriptionRepository;
  }
}

export { UserRepository, SubscriptionRepository };
