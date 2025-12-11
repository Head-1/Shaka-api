import { Repository, FindOptionsWhere, ObjectLiteral } from 'typeorm';
import { AppDataSource } from '../config';

export abstract class BaseRepository<T extends ObjectLiteral> {
  protected repository: Repository<T>;

  constructor(entity: new () => T) {
    this.repository = AppDataSource.getRepository(entity);
  }

  async findById(id: string): Promise<T | null> {
    return this.repository.findOne({ 
      where: { id } as unknown as FindOptionsWhere<T> 
    });
  }

  async findAll(skip = 0, take = 10): Promise<T[]> {
    return this.repository.find({ skip, take });
  }

  async save(entity: T | T[]): Promise<T | T[]> {
    if (Array.isArray(entity)) {
      return this.repository.save(entity);
    }
    return this.repository.save(entity);
  }

  async delete(id: string): Promise<boolean> {
    const result = await this.repository.delete(id);
    return (result.affected ?? 0) > 0;
  }

  async count(): Promise<number> {
    return this.repository.count();
  }

  async exists(id: string): Promise<boolean> {
    const count = await this.repository.count({ 
      where: { id } as unknown as FindOptionsWhere<T> 
    });
    return count > 0;
  }
}
