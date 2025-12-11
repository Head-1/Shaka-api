import { MigrationInterface, QueryRunner, Table, TableForeignKey, TableIndex } from 'typeorm';

export class CreateApiKeysTable1234567890123 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    // Create api_keys table
    await queryRunner.createTable(
      new Table({
        name: 'api_keys',
        columns: [
          {
            name: 'id',
            type: 'uuid',
            isPrimary: true,
            default: 'uuid_generate_v4()'
          },
          {
            name: 'userId',
            type: 'uuid',
            isNullable: false
          },
          {
            name: 'name',
            type: 'varchar',
            length: '100',
            isNullable: false
          },
          {
            name: 'keyHash',
            type: 'varchar',
            length: '64',
            isNullable: false,
            isUnique: true
          },
          {
            name: 'keyPreview',
            type: 'varchar',
            length: '16',
            isNullable: false
          },
          {
            name: 'permissions',
            type: 'text',
            isNullable: false,
            default: "'read,write'"
          },
          {
            name: 'rateLimit',
            type: 'jsonb',
            isNullable: false
          },
          {
            name: 'isActive',
            type: 'boolean',
            default: true
          },
          {
            name: 'lastUsedAt',
            type: 'timestamp',
            isNullable: true
          },
          {
            name: 'expiresAt',
            type: 'timestamp',
            isNullable: true
          },
          {
            name: 'createdAt',
            type: 'timestamp',
            default: 'CURRENT_TIMESTAMP'
          },
          {
            name: 'updatedAt',
            type: 'timestamp',
            default: 'CURRENT_TIMESTAMP'
          }
        ]
      }),
      true
    );

    // Create foreign key to users table
    await queryRunner.createForeignKey(
      'api_keys',
      new TableForeignKey({
        columnNames: ['userId'],
        referencedColumnNames: ['id'],
        referencedTableName: 'users',
        onDelete: 'CASCADE'
      })
    );

    // Create indexes
    await queryRunner.createIndex(
      'api_keys',
      new TableIndex({
        name: 'IDX_api_keys_userId',
        columnNames: ['userId']
      })
    );

    await queryRunner.createIndex(
      'api_keys',
      new TableIndex({
        name: 'IDX_api_keys_keyHash',
        columnNames: ['keyHash'],
        isUnique: true
      })
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.dropTable('api_keys');
  }
}
