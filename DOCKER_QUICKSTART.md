# 🐳 Docker Quick Start Guide

## 📦 Pré-requisitos

- Docker 20.10+
- Docker Compose 2.0+
- 2GB RAM disponível
- 5GB espaço em disco

## 🚀 Início Rápido

### 1. Configurar Environment

```bash
# Copiar template de configuração
cp .env.docker .env

# Editar variáveis (opcional)
nano .env
```

### 2. Iniciar Containers

```bash
# Modo Development
./docker.sh start

# OU usar Make
make start
```

### 3. Aguardar Inicialização (30-60s)

```bash
# Verificar status
./docker.sh ps

# Verificar logs
./docker.sh logs api
```

### 4. Rodar Migrations

```bash
./docker.sh migrate run
```

### 5. Testar API

```bash
curl http://localhost:3000/health
```

## 📋 Comandos Principais

### Gerenciamento Básico

```bash
./docker.sh start          # Iniciar containers
./docker.sh stop           # Parar containers
./docker.sh restart        # Reiniciar containers
./docker.sh ps             # Status dos containers
./docker.sh logs [service] # Ver logs
```

### Health & Debug

```bash
./docker.sh health         # Health check completo
./docker.sh shell api      # Shell no container API
./docker.sh shell postgres # Shell no PostgreSQL
```

### Migrations

```bash
./docker.sh migrate run    # Executar migrations
./docker.sh migrate revert # Reverter última migration
```

### Limpeza

```bash
./docker.sh stop           # Parar containers
./docker.sh reset          # Reset completo (remove dados)
```

## 🔗 Endpoints

- **API:** http://localhost:3000
- **Health:** http://localhost:3000/health
- **PostgreSQL:** localhost:5432
- **Redis:** localhost:6379

## 🐛 Troubleshooting

### Containers não iniciam

```bash
# Ver logs de erro
docker-compose logs

# Reconstruir do zero
./docker.sh reset
./docker.sh start
```

### Porta já em uso

```bash
# Verificar processos
lsof -i :3000
lsof -i :5432
lsof -i :6379

# Matar processos
kill -9 <PID>
```

### Database não conecta

```bash
# Verificar PostgreSQL
./docker.sh shell postgres
psql -U shaka -d shaka_api

# Recriar database
./docker.sh reset
./docker.sh start
./docker.sh migrate run
```

## 📊 Modo Production

```bash
# Configurar .env para produção
cp .env.docker .env
nano .env  # Ajustar senhas e secrets

# Iniciar em modo production
./docker.sh start prod

# Verificar recursos
docker stats
```

## 🧪 Testes

```bash
# Rodar testes no container
docker-compose exec api npm test

# Coverage
docker-compose exec api npm run test:coverage

# Testes específicos
docker-compose exec api npm run test:unit
docker-compose exec api npm run test:integration
docker-compose exec api npm run test:e2e
```

## 📝 Logs

```bash
# Logs em tempo real
./docker.sh logs api

# Últimas 100 linhas
docker-compose logs --tail=100 api

# Todos os serviços
docker-compose logs -f
```

## 💾 Backup e Restore

### Backup PostgreSQL

```bash
docker-compose exec postgres pg_dump -U shaka shaka_api > backup.sql
```

### Restore PostgreSQL

```bash
cat backup.sql | docker-compose exec -T postgres psql -U shaka -d shaka_api
```

## 🔒 Segurança

1. **SEMPRE** alterar senhas padrão em produção
2. Usar `docker-compose.prod.yml` em produção
3. Nunca commitar `.env` no Git
4. Usar secrets management (vault, etc)

## 📚 Mais Informações

- [Docker Compose Docs](https://docs.docker.com/compose/)
- [PostgreSQL Docker](https://hub.docker.com/_/postgres)
- [Redis Docker](https://hub.docker.com/_/redis)
- [Node.js Best Practices](https://github.com/goldbergyoni/nodebestpractices)
