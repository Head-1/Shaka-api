#!/bin/bash

echo "🔧 SCRIPT 9: Corrigindo BaseRepository (TypeORM Constraints)"
echo "============================================================"
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}📝 Corrigindo BaseRepository.ts...${NC}"

cat > src/infrastructure/database/repositories/BaseRepository.ts << 'EOF'
import { Repository, FindOptionsWhere, ObjectLiteral } from 'typeorm';
import { AppDataSource } from '../config';

// Base repository with proper TypeORM constraints
export abstract class BaseRepository<T extends ObjectLiteral> {
  protected repository: Repository<T>;

  constructor(entity: new () => T) {
    this.repository = AppDataSource.getRepository(entity);
  }

  async findById(id: string): Promise<T | null> {
    return this.repository.findOne({ where: { id } as FindOptionsWhere<T> });
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
      where: { id } as FindOptionsWhere<T> 
    });
    return count > 0;
  }
}
EOF

echo -e "${GREEN}✓ BaseRepository.ts corrigido com ObjectLiteral constraint${NC}"
echo ""
echo -e "${GREEN}✅ SCRIPT 9 CONCLUÍDO!${NC}"
echo ""
echo "📊 BaseRepository corrigido:"
echo "   • Adicionado: extends ObjectLiteral"
echo "   • Corrigido: save() para aceitar T | T[]"
echo "   • Corrigido: TypeScript generics"
echo ""
echo "🧪 Validação FINAL:"
echo "   npm run build"
echo ""
echo "🎯 Resultado esperado: BUILD SUCCESS! ✅"
echo ""
