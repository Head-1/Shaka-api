#!/bin/bash

# ============================================================================
# Verificar Status do Build Final
# ============================================================================

cd ~/shaka-api

echo "=========================================="
echo "🔍 VERIFICANDO STATUS DO BUILD"
echo "=========================================="
echo ""

# Verificar se o log de build existe
if [ -f /tmp/build-fix.log ]; then
    echo "[1/3] Contando erros no último build..."
    ERROR_COUNT=$(grep -c "error TS" /tmp/build-fix.log || echo "0")
    
    echo "   Total de erros TypeScript: $ERROR_COUNT"
    echo ""
    
    if [ "$ERROR_COUNT" -eq "0" ]; then
        echo "✅ BUILD LIMPO! Zero erros TypeScript!"
        echo ""
    else
        echo "⚠️  Ainda há $ERROR_COUNT erro(s). Detalhes:"
        echo ""
        grep "error TS" /tmp/build-fix.log
        echo ""
    fi
    
    echo "[2/3] Últimas 30 linhas do build:"
    echo ""
    tail -30 /tmp/build-fix.log
    echo ""
else
    echo "[1/3] Rodando novo build para verificar..."
    npm run build > /tmp/build-verify.log 2>&1
    
    ERROR_COUNT=$(grep -c "error TS" /tmp/build-verify.log || echo "0")
    
    echo "   Total de erros TypeScript: $ERROR_COUNT"
    echo ""
    
    if [ "$ERROR_COUNT" -eq "0" ]; then
        echo "✅ BUILD LIMPO! Zero erros TypeScript!"
        echo ""
    else
        echo "⚠️  Ainda há $ERROR_COUNT erro(s). Detalhes:"
        echo ""
        grep "error TS" /tmp/build-verify.log
        echo ""
    fi
    
    echo "[2/3] Últimas 30 linhas do build:"
    echo ""
    tail -30 /tmp/build-verify.log
    echo ""
fi

echo "[3/3] Verificando arquivos gerados no dist/..."
echo ""

if [ -d "dist" ]; then
    echo "📦 Estrutura do dist/:"
    ls -la dist/ 2>/dev/null || echo "   Pasta dist vazia ou erro ao listar"
    echo ""
    
    # Contar arquivos .js gerados
    JS_COUNT=$(find dist -name "*.js" 2>/dev/null | wc -l)
    echo "   Total de arquivos .js gerados: $JS_COUNT"
    echo ""
else
    echo "❌ Pasta dist/ não existe"
    echo ""
fi

echo "=========================================="
echo "📊 RESUMO"
echo "=========================================="
echo ""

if [ "$ERROR_COUNT" -eq "0" ] && [ -d "dist" ]; then
    echo "✅ Build compilado com sucesso"
    echo "✅ Arquivos .js gerados: $JS_COUNT"
    echo ""
    echo "🚀 PRÓXIMO PASSO:"
    echo "   bash scripts/sprint1/setup-build-deploy-test.sh"
    echo ""
elif [ "$ERROR_COUNT" -eq "0" ]; then
    echo "✅ Zero erros TypeScript"
    echo "⚠️  Pasta dist/ não encontrada - pode precisar rodar 'npm run build' novamente"
    echo ""
else
    echo "❌ Build com erros: $ERROR_COUNT"
    echo ""
    echo "Para ver detalhes completos:"
    echo "   cat /tmp/build-fix.log | grep 'error TS'"
    echo ""
    echo "Para ver log completo:"
    echo "   cat /tmp/build-fix.log"
    echo ""
fi
