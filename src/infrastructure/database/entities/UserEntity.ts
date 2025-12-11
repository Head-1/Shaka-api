import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, OneToMany } from 'typeorm';
import { ApiKeyEntity } from './ApiKeyEntity';

@Entity('users')
export class UserEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ unique: true })
  email!: string;

  @Column({ name: 'password_hash' })
  passwordHash!: string;

  @Column()
  name!: string;

  @Column({
    type: 'varchar',
    length: 20,
    default: 'starter'
  })
  plan!: 'starter' | 'pro' | 'business' | 'enterprise';

  @CreateDateColumn({ name: 'created_at' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt!: Date;

  @OneToMany(() => ApiKeyEntity, apiKey => apiKey.user)
  apiKeys?: ApiKeyEntity[];
}
