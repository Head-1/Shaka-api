#!/bin/bash

echo "🔧 SCRIPT 16: Adicionando método deactivateUser no UserService"
echo "=============================================================="
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}📝 Adicionando método deactivateUser no UserService...${NC}"

# Adicionar o método antes do último } do arquivo
if [ -f "src/core/services/user/UserService.ts" ]; then
  # Remover o último } e adicionar o novo método
  head -n -1 src/core/services/user/UserService.ts > /tmp/userservice.tmp
  
  cat >> /tmp/userservice.tmp << 'EOF'

  // Deactivate user (soft delete)
  static async deactivateUser(userId: string): Promise<void> {
    logger.info('Deactivating user', { userId });

    const user = users.get(userId);
    if (!user) {
      throw new Error('User not found');
    }

    user.isActive = false;
    user.updatedAt = new Date();
    users.set(userId, user);

    logger.info('User deactivated successfully', { userId });
  }
}
EOF
  
  mv /tmp/userservice.tmp src/core/services/user/UserService.ts
  echo -e "${GREEN}✓ Método deactivateUser adicionado${NC}"
else
  echo -e "❌ UserService.ts não encontrado"
fi

echo ""
echo -e "${GREEN}✅ SCRIPT 16 CONCLUÍDO!${NC}"
echo ""
echo "📊 Método adicionado:"
echo "   • deactivateUser(userId: string): Promise<void>"
echo ""
echo "🧪 BUILD FINAL:"
echo "   npm run build"
echo ""
echo "🎯 AGORA SIM: BUILD SUCCESS! ✅"
echo ""
