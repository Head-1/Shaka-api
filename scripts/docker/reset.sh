#!/bin/bash

# ============================================================================
# Docker Reset Script
# ============================================================================
# CUIDADO: Este script remove TODOS os dados (volumes)
# ============================================================================

set -e

echo "⚠️  ATENÇÃO: Este script vai:"
echo "   1. Parar todos os containers"
echo "   2. Remover todos os containers"
echo "   3. Remover todos os volumes (DADOS SERÃO PERDIDOS)"
echo "   4. Remover imagens do projeto"
echo ""
read -p "Tem certeza? Digite 'RESET' para confirmar: " CONFIRM

if [ "$CONFIRM" != "RESET" ]; then
    echo "❌ Operação cancelada"
    exit 1
fi

echo ""
echo "🔄 Iniciando reset completo..."
echo ""

# Parar e remover containers
echo "1️⃣  Parando containers..."
docker-compose down -v

# Remover imagens do projeto
echo "2️⃣  Removendo imagens..."
docker images | grep shaka | awk '{print $3}' | xargs -r docker rmi -f

# Remover volumes órfãos
echo "3️⃣  Limpando volumes órfãos..."
docker volume prune -f

echo ""
echo "✅ Reset completo realizado"
echo ""
echo "🚀 Para reconstruir do zero:"
echo "   bash scripts/docker/start.sh"
