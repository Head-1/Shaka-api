import { MigrationInterface, QueryRunner, Table, TableForeignKey, TableIndex } from 'typeorm';

export class CreateSubscriptionsTable1700000000002 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.createTable(
      new Table({
        name: 'subscriptions',
        columns: [
          {
            name: 'id',
            type: 'uuid',
            isPrimary: true,
            generationStrategy: 'uuid',
            default: 'uuid_generate_v4()'
          },
          {
            name: 'user_id',
            type: 'uuid'
          },
          {
            name: 'plan',
            type: 'enum',
            enum: ['starter', 'pro', 'business'],
            default: "'starter'"
          },
          {
            name: 'status',
            type: 'enum',
            enum: ['active', 'cancelled', 'expired'],
            default: "'active'"
          },
          {
            name: 'start_date',
            type: 'timestamp',
            default: 'CURRENT_TIMESTAMP'
          },
          {
            name: 'end_date',
            type: 'timestamp'
          },
          {
            name: 'auto_renew',
            type: 'boolean',
            default: true
          },
          {
            name: 'created_at',
            type: 'timestamp',
            default: 'CURRENT_TIMESTAMP'
          },
          {
            name: 'updated_at',
            type: 'timestamp',
            default: 'CURRENT_TIMESTAMP'
          }
        ]
      }),
      true
    );

    // Foreign key para users
    await queryRunner.createForeignKey(
      'subscriptions',
      new TableForeignKey({
        columnNames: ['user_id'],
        referencedColumnNames: ['id'],
        referencedTableName: 'users',
        onDelete: 'CASCADE'
      })
    );

    // Índices
    await queryRunner.createIndex(
      'subscriptions',
      new TableIndex({
        name: 'IDX_SUBSCRIPTIONS_USER_ID',
        columnNames: ['user_id']
      })
    );

    await queryRunner.createIndex(
      'subscriptions',
      new TableIndex({
        name: 'IDX_SUBSCRIPTIONS_STATUS',
        columnNames: ['status']
      })
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    const table = await queryRunner.getTable('subscriptions');
    const foreignKey = table?.foreignKeys.find(fk => fk.columnNames.indexOf('user_id') !== -1);
    
    if (foreignKey) {
      await queryRunner.dropForeignKey('subscriptions', foreignKey);
    }
    
    await queryRunner.dropIndex('subscriptions', 'IDX_SUBSCRIPTIONS_STATUS');
    await queryRunner.dropIndex('subscriptions', 'IDX_SUBSCRIPTIONS_USER_ID');
    await queryRunner.dropTable('subscriptions');
  }
}
