#!/bin/bash

echo "🚀 FASE 4 - PARTE 3: Database Migrations"
echo "========================================"

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}📝 Criando migrations...${NC}"

# Migration 1: Create Users Table
cat > src/infrastructure/database/migrations/1700000000001-CreateUsersTable.ts << 'EOF'
import { MigrationInterface, QueryRunner, Table, TableIndex } from 'typeorm';

export class CreateUsersTable1700000000001 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.createTable(
      new Table({
        name: 'users',
        columns: [
          {
            name: 'id',
            type: 'uuid',
            isPrimary: true,
            generationStrategy: 'uuid',
            default: 'uuid_generate_v4()'
          },
          {
            name: 'name',
            type: 'varchar',
            length: '100'
          },
          {
            name: 'email',
            type: 'varchar',
            length: '255',
            isUnique: true
          },
          {
            name: 'password_hash',
            type: 'varchar',
            length: '255'
          },
          {
            name: 'plan',
            type: 'enum',
            enum: ['starter', 'pro', 'business'],
            default: "'starter'"
          },
          {
            name: 'is_active',
            type: 'boolean',
            default: true
          },
          {
            name: 'company_name',
            type: 'varchar',
            length: '255',
            isNullable: true
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

    // Criar índice no email
    await queryRunner.createIndex(
      'users',
      new TableIndex({
        name: 'IDX_USERS_EMAIL',
        columnNames: ['email']
      })
    );

    // Criar índice no plan
    await queryRunner.createIndex(
      'users',
      new TableIndex({
        name: 'IDX_USERS_PLAN',
        columnNames: ['plan']
      })
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.dropIndex('users', 'IDX_USERS_PLAN');
    await queryRunner.dropIndex('users', 'IDX_USERS_EMAIL');
    await queryRunner.dropTable('users');
  }
}
EOF

# Migration 2: Create Subscriptions Table
cat > src/infrastructure/database/migrations/1700000000002-CreateSubscriptionsTable.ts << 'EOF'
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
EOF

# Script helper para rodar migrations
cat > scripts/run-migrations.sh << 'EOF'
#!/bin/bash

echo "🚀 Running Database Migrations..."

# Compilar TypeScript
npm run build

# Rodar migrations
npx typeorm migration:run -d dist/infrastructure/database/config.js

echo "✅ Migrations completed!"
EOF

chmod +x scripts/run-migrations.sh

# Script para reverter migrations
cat > scripts/revert-migrations.sh << 'EOF'
#!/bin/bash

echo "⏪ Reverting last migration..."

npm run build
npx typeorm migration:revert -d dist/infrastructure/database/config.js

echo "✅ Migration reverted!"
EOF

chmod +x scripts/revert-migrations.sh

echo -e "${GREEN}✅ PARTE 3 CONCLUÍDA!${NC}"
echo ""
echo "Arquivos criados:"
echo "  ✓ src/infrastructure/database/migrations/1700000000001-CreateUsersTable.ts"
echo "  ✓ src/infrastructure/database/migrations/1700000000002-CreateSubscriptionsTable.ts"
echo "  ✓ scripts/run-migrations.sh"
echo "  ✓ scripts/revert-migrations.sh"
echo ""
echo -e "${YELLOW}⚠️  Para rodar as migrations:${NC}"
echo "  1. Configure o .env com credenciais do PostgreSQL"
echo "  2. Execute: npm run build"
echo "  3. Execute: ./scripts/run-migrations.sh"
echo ""
echo "Execute agora: ./setup-infrastructure-part4-redis.sh"
EOF

chmod +x setup-infrastructure-part3-migrations.sh
