import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  Index
} from 'typeorm';

@Entity('usage_records')
@Index(['apiKeyId', 'timestamp'])
@Index(['userId', 'timestamp'])
@Index(['timestamp'])
export class UsageRecordEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'api_key_id', type: 'uuid' })  // ← CORRIGIDO
  apiKeyId!: string;

  @Column({ name: 'user_id', type: 'uuid' })  // ← CORRIGIDO
  userId!: string;

  @Column({ type: 'varchar', length: 200 })
  endpoint!: string;

  @Column({ type: 'varchar', length: 10 })
  method!: string;

  @Column({ name: 'status_code', type: 'int' })  // ← CORRIGIDO
  statusCode!: number;

  @Column({ name: 'response_time_ms', type: 'int' })  // ✅ CORRETO
  responseTime!: number;

  @Column({ name: 'ip_address', type: 'varchar', length: 45, nullable: true })  // ← CORRIGIDO
  ipAddress?: string;

  @Column({ name: 'user_agent', type: 'text', nullable: true })  // ← CORRIGIDO
  userAgent?: string;

  @CreateDateColumn()
  timestamp!: Date;
}
