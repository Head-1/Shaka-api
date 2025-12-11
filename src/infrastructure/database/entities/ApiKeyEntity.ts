import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  CreateDateColumn,
  UpdateDateColumn
} from 'typeorm';
import { UserEntity } from './UserEntity';

@Entity('api_keys')
export class ApiKeyEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'uuid', name: 'user_id' })
  userId!: string;

  @Column({ type: 'varchar', length: 255 })
  name!: string;

  @Column({ type: 'varchar', length: 64, name: 'key_hash' })
  keyHash!: string;

  @Column({ type: 'varchar', length: 16, name: 'key_preview' })
  keyPreview!: string;

  @Column({ type: 'text', array: true, default: '{}' })
  permissions!: string[];

  @Column({ type: 'boolean', default: true, name: 'is_active' })
  isActive!: boolean;

  @Column({ type: 'integer', name: 'rate_limit' })
  rateLimit!: number;

  @Column({ type: 'timestamp', nullable: true, name: 'last_used_at' })
  lastUsedAt!: Date | null;

  @Column({ type: 'timestamp', nullable: true, name: 'expires_at' })
  expiresAt!: Date | null;

  @Column({ type: 'timestamp', name: 'created_at' })
  createdAt!: Date;

  @Column({ type: 'timestamp', name: 'updated_at' })
  updatedAt!: Date;

  @ManyToOne(() => UserEntity)
  @JoinColumn({ name: 'user_id' })
  user!: UserEntity;
}
