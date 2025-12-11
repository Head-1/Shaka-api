import { MigrationInterface, QueryRunner, Table, TableIndex } from 'typeorm';

export class CreateUsageRecordsTable1234567890124 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    // Create usage_records table
    await queryRunner.createTable(
      new Table({
        name: 'usage_records',
        columns: [
          {
            name: 'id',
            type: 'uuid',
            isPrimary: true,
            default: 'uuid_generate_v4()'
          },
          {
            name: 'apiKeyId',
            type: 'uuid',
            isNullable: false
          },
          {
            name: 'userId',
            type: 'uuid',
            isNullable: false
          },
          {
            name: 'endpoint',
            type: 'varchar',
            length: '200',
            isNullable: false
          },
          {
            name: 'method',
            type: 'varchar',
            length: '10',
            isNullable: false
          },
          {
            name: 'statusCode',
            type: 'int',
            isNullable: false
          },
          {
            name: 'responseTime',
            type: 'int',
            isNullable: false
          },
          {
            name: 'ipAddress',
            type: 'varchar',
            length: '45',
            isNullable: true
          },
          {
            name: 'userAgent',
            type: 'text',
            isNullable: true
          },
          {
            name: 'errorMessage',
            type: 'text',
            isNullable: true
          },
          {
            name: 'timestamp',
            type: 'timestamp',
            default: 'CURRENT_TIMESTAMP'
          }
        ]
      }),
      true
    );

    // Create composite index for apiKeyId + timestamp (most common query)
    await queryRunner.createIndex(
      'usage_records',
      new TableIndex({
        name: 'IDX_usage_records_apiKeyId_timestamp',
        columnNames: ['apiKeyId', 'timestamp']
      })
    );

    // Create composite index for userId + timestamp
    await queryRunner.createIndex(
      'usage_records',
      new TableIndex({
        name: 'IDX_usage_records_userId_timestamp',
        columnNames: ['userId', 'timestamp']
      })
    );

    // Create index for timestamp only (for cleanup queries)
    await queryRunner.createIndex(
      'usage_records',
      new TableIndex({
        name: 'IDX_usage_records_timestamp',
        columnNames: ['timestamp']
      })
    );

    // Create index for endpoint analysis
    await queryRunner.createIndex(
      'usage_records',
      new TableIndex({
        name: 'IDX_usage_records_endpoint',
        columnNames: ['endpoint', 'method']
      })
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.dropTable('usage_records');
  }
}
