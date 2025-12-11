# Desenvolvimento
npm run dev              # Iniciar servidor em modo dev
npm run build            # Build de produção
npm run type-check       # Verificar tipos TypeScript

# Testes
npm test                 # Todos os testes
npm run test:unit        # Apenas unit tests
npm run test:integration # Apenas integration tests
npm run test:e2e         # Apenas E2E tests
npm run test:coverage    # Gerar coverage report

# Servidor
./manage-server.sh start    # Iniciar servidor
./manage-server.sh status   # Ver status
./manage-server.sh stop     # Parar servidor
./manage-server.sh logs     # Ver logs
./manage-server.sh test     # Testar endpoints

# Database
npm run migration:run       # Executar migrations
npm run migration:revert    # Reverter última migration

# Utilidades
./scripts/management/test-connections.sh    # Testar DB/Redis
./scripts/management/load-test-api.sh       # Teste de carga
