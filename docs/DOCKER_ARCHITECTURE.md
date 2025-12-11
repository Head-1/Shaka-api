# 🏗️ Docker Architecture

## 📋 Visão Geral

O Shaka API usa uma arquitetura containerizada com Docker Compose, separando serviços em containers isolados para melhor escalabilidade e manutenibilidade.

## 🐳 Containers

### 1. API Container (Node.js)

**Imagem:** Custom (Multi-stage build)  
**Base:** node:20-alpine  
**Porta:** 3000  
**Propósito:** Aplicação principal

**Features:**
- Multi-stage build (builder + runtime)
- Non-root user (nodejs:nodejs)
- Health checks automáticos
- Hot reload em desenvolvimento
- Otimizado para produção

**Resources:**
- CPU: 0.5-1 core
- RAM: 256MB-512MB

### 2. PostgreSQL Container

**Imagem:** postgres:15-alpine  
**Porta:** 5432  
**Propósito:** Database principal

**Features:**
- Health checks com pg_isready
- Volume persistente
- Init scripts automáticos
- Backup support

**Resources:**
- CPU: 0.5-1 core
- RAM: 512MB-1GB

### 3. Redis Container

**Imagem:** redis:7-alpine  
**Porta:** 6379  
**Propósito:** Cache e rate limiting

**Features:**
- AOF persistence
- Health checks
- Password protection
- Volume persistente

**Resources:**
- CPU: 0.25-0.5 core
- RAM: 128MB-256MB

## 🌐 Networks

### shaka-network (Bridge)

**Tipo:** Bridge Network  
**Isolamento:** Completo entre host e containers  
**DNS:** Resolução automática entre containers

**Conectividade:**
```
api → postgres (postgres:5432)
api → redis (redis:6379)
host → api (localhost:3000)
host → postgres (localhost:5432)
host → redis (localhost:6379)
```

## 💾 Volumes

### postgres_data

**Tipo:** Named volume  
**Mount:** `/var/lib/postgresql/data`  
**Persistência:** Dados do PostgreSQL  
**Backup:** Recomendado diariamente

### redis_data

**Tipo:** Named volume  
**Mount:** `/data`  
**Persistência:** Cache e AOF logs  
**Backup:** Opcional

## 🔄 Lifecycle

### Startup Sequence

1. **PostgreSQL** inicia primeiro
   - Aguarda health check (pg_isready)
   - Executa init scripts
   
2. **Redis** inicia em paralelo
   - Aguarda health check (ping)
   - Carrega AOF se existir

3. **API** aguarda dependências
   - Espera PostgreSQL healthy
   - Espera Redis healthy
   - Conecta ao database
   - Conecta ao cache
   - Inicia servidor Express

### Shutdown Sequence

1. **API** recebe SIGTERM
   - Fecha conexões ativas
   - Flush logs
   - Exit gracefully

2. **Redis** salva AOF
   - Persiste cache
   - Exit

3. **PostgreSQL** fecha conexões
   - Checkpoint
   - Exit

## 🏗️ Build Process

### Multi-stage Build

```dockerfile
# Stage 1: Builder
FROM node:20-alpine AS builder
- Instala dependências (incluindo devDependencies)
- Compila TypeScript
- Remove devDependencies

# Stage 2: Runtime
FROM node:20-alpine
- Copia node_modules de produção
- Copia dist/ compilado
- Configura non-root user
- Define health check
```

**Benefícios:**
- Imagem final ~300MB (vs ~800MB single-stage)
- Sem devDependencies em produção
- Sem código TypeScript em runtime
- Melhor segurança

## 🔒 Segurança

### Container Isolation

- ✅ Non-root user (nodejs:nodejs)
- ✅ Read-only filesystem (onde possível)
- ✅ Dropped capabilities
- ✅ Resource limits
- ✅ Network isolation

### Secrets Management

```bash
# Development
.env (não commitado)

# Production
- Use Docker Secrets
- Ou variáveis de ambiente do host
- Ou serviço de secrets (Vault, etc)
```

### Best Practices

1. **Nunca** rodar como root
2. **Sempre** usar health checks
3. **Sempre** definir resource limits
4. **Nunca** commitar secrets
5. **Sempre** usar volumes para dados

## 📊 Monitoring

### Health Checks

Todos os containers têm health checks configurados:

```yaml
api:
  healthcheck:
    test: curl -f http://localhost:3000/health
    interval: 30s
    timeout: 10s
    retries: 3
    start_period: 40s
```

### Logs

```bash
# Ver logs
docker-compose logs -f [service]

# Logs com timestamp
docker-compose logs -f --timestamps

# Últimas N linhas
docker-compose logs --tail=100
```

### Metrics

```bash
# CPU e RAM em tempo real
docker stats

# Uso de disco
docker system df
```

## 🔄 Updates e Rollback

### Update

```bash
# Pull nova imagem
docker-compose pull api

# Recreate container
docker-compose up -d api
```

### Rollback

```bash
# Usar imagem anterior
docker tag shaka-api:latest shaka-api:backup
docker-compose up -d api
```

## 🧪 Testing

### Development

```bash
docker-compose up -d
docker-compose exec api npm test
```

### Production

```bash
docker-compose -f docker-compose.prod.yml up -d
# Testes de carga, monitoring, etc
```

## 📈 Scaling

### Horizontal Scaling

```bash
# Escalar API (múltiplas instâncias)
docker-compose up -d --scale api=3

# Adicionar load balancer (nginx)
# Configurar health checks
```

### Vertical Scaling

```yaml
deploy:
  resources:
    limits:
      cpus: '2'
      memory: 1G
```

## 🎯 Comparação Dev vs Prod

| Feature | Development | Production |
|---------|-------------|------------|
| Build stage | builder | runtime |
| Hot reload | ✅ Sim | ❌ Não |
| Volumes | Source mount | Named only |
| Resources | Unlimited | Limited |
| Restart | unless-stopped | always |
| Logs | stdout | JSON file |
| Security | Relaxed | Hardened |
