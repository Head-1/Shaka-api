#!/bin/bash

# ============================================================================
# Verificar Build - Esperando ZERO Erros
# ============================================================================

cd ~/shaka-api

echo "=========================================="
echo "🔍 VERIFICAÇÃO FINAL DO BUILD"
echo "=========================================="
echo ""

# Verificar log do build
if [ -f /tmp/build-ultimate.log ]; then
    echo "[1/3] Analisando resultado do build..."
    echo ""
    
    ERROR_COUNT=$(grep -c "error TS" /tmp/build-ultimate.log 2>/dev/null || echo "0")
    WARNING_COUNT=$(grep -c "warning TS" /tmp/build-ultimate.log 2>/dev/null || echo "0")
    
    echo "   Erros TypeScript: $ERROR_COUNT"
    echo "   Warnings TypeScript: $WARNING_COUNT"
    echo ""
    
    if [ "$ERROR_COUNT" -eq "0" ]; then
        echo "🎉🎉🎉 BUILD PERFEITO! ZERO ERROS! 🎉🎉🎉"
        echo ""
    else
        echo "⚠️  Ainda há $ERROR_COUNT erro(s):"
        echo ""
        grep "error TS" /tmp/build-ultimate.log
        echo ""
    fi
    
    echo "[2/3] Últimas 30 linhas do build:"
    echo ""
    tail -30 /tmp/build-ultimate.log
    echo ""
    
else
    echo "❌ Log /tmp/build-ultimate.log não encontrado"
    echo "   Executando novo build..."
    echo ""
    
    npm run build 2>&1 | tee /tmp/build-check.log
    
    ERROR_COUNT=$(grep -c "error TS" /tmp/build-check.log 2>/dev/null || echo "0")
    
    echo ""
    if [ "$ERROR_COUNT" -eq "0" ]; then
        echo "🎉 BUILD LIMPO!"
    else
        echo "⚠️  $ERROR_COUNT erro(s) encontrado(s)"
    fi
    echo ""
fi

echo "[3/3] Verificando arquivos gerados..."
echo ""

if [ -d "dist" ]; then
    JS_COUNT=$(find dist -name "*.js" 2>/dev/null | wc -l)
    DTS_COUNT=$(find dist -name "*.d.ts" 2>/dev/null | wc -l)
    MAP_COUNT=$(find dist -name "*.map" 2>/dev/null | wc -l)
    
    echo "   📦 Arquivos .js: $JS_COUNT"
    echo "   📦 Arquivos .d.ts: $DTS_COUNT"
    echo "   📦 Arquivos .map: $MAP_COUNT"
    echo ""
    
    # Verificar arquivos críticos
    echo "   Arquivos críticos:"
    CRITICAL_FILES=(
        "dist/server.js"
        "dist/api/routes/index.js"
        "dist/api/routes/auth.routes.js"
        "dist/api/routes/apiKey.routes.js"
        "dist/core/services/auth/AuthService.js"
        "dist/core/services/user/UserService.js"
        "dist/core/services/apiKey/ApiKeyService.js"
        "dist/infrastructure/database/DatabaseService.js"
    )
    
    ALL_CRITICAL_OK=true
    for file in "${CRITICAL_FILES[@]}"; do
        if [ -f "$file" ]; then
            echo "     ✅ ${file##dist/}"
        else
            echo "     ❌ ${file##dist/} (NOT FOUND)"
            ALL_CRITICAL_OK=false
        fi
    done
    echo ""
else
    echo "   ❌ Pasta dist/ não encontrada"
    echo ""
    ALL_CRITICAL_OK=false
fi

echo "=========================================="
echo "📊 RESUMO FINAL"
echo "=========================================="
echo ""

if [ "$ERROR_COUNT" -eq "0" ] && [ "$ALL_CRITICAL_OK" = true ]; then
    echo "✅✅✅ TUDO PERFEITO! ✅✅✅"
    echo ""
    echo "Status do Projeto:"
    echo "  ✅ Build TypeScript: ZERO ERROS"
    echo "  ✅ Arquivos .js gerados: $JS_COUNT"
    echo "  ✅ Arquivos críticos: TODOS PRESENTES"
    echo ""
    echo "══════════════════════════════════════════════"
    echo "🚀 PRONTO PARA DEPLOY - EXECUTAR PARTE 7/8"
    echo "══════════════════════════════════════════════"
    echo ""
    echo "Execute o script de deploy completo:"
    echo ""
    echo "  bash scripts/sprint1/setup-build-deploy-test.sh"
    echo ""
    echo "Este script irá:"
    echo ""
    echo "  [1/6] Aplicar migrations no PostgreSQL"
    echo "        ├─ Criar tabela api_keys"
    echo "        ├─ Criar tabela usage_records"
    echo "        └─ Criar índices de performance"
    echo ""
    echo "  [2/6] Build Docker Image"
    echo "        ├─ Tag timestamped para rastreabilidade"
    echo "        └─ Tag 'latest' para facilidade"
    echo ""
    echo "  [3/6] Deploy Kubernetes"
    echo "        ├─ Backup deployment atual"
    echo "        ├─ Rolling update (zero downtime)"
    echo "        └─ Aguardar rollout completo"
    echo ""
    echo "  [4/6] Health Check"
    echo "        ├─ Verificar pod status"
    echo "        ├─ Testar endpoint /health"
    echo "        └─ Validar logs"
    echo ""
    echo "  [5/6] Criar Scripts de Teste E2E"
    echo "        └─ Suite completa: 7 cenários"
    echo ""
    echo "  [6/6] Executar Testes E2E"
    echo "        ├─ Register User"
    echo "        ├─ Create API Key"
    echo "        ├─ List API Keys"
    echo "        ├─ Get API Key Details"
    echo "        ├─ Use API Key (auth)"
    echo "        ├─ Get Usage Stats"
    echo "        └─ Revoke API Key"
    echo ""
    echo "Tempo estimado: 3-5 minutos"
    echo ""
    
elif [ "$ERROR_COUNT" -eq "0" ]; then
    echo "✅ Zero erros TypeScript"
    echo "⚠️  Alguns arquivos críticos ausentes"
    echo ""
    echo "Tente: npm run build"
    echo ""
    
else
    echo "❌ Build ainda com $ERROR_COUNT erro(s)"
    echo ""
    echo "Erros encontrados:"
    grep "error TS" /tmp/build-ultimate.log 2>/dev/null || \
    grep "error TS" /tmp/build-check.log 2>/dev/null
    echo ""
    echo "Ação necessária: Analisar e corrigir erros acima"
    echo ""
fi
