#!/bin/bash

echo "============================================"
echo "SCRIPT 37: Comprehensive Test Validation"
echo "============================================"
echo ""

# 1. Rodar todos os testes
echo "1. Executando todos os testes..."
npm test

echo ""
echo "2. Gerando coverage report atualizado..."
npm run test:coverage -- --silent

echo ""
echo "============================================"
echo "RESULTADO FINAL"
echo "============================================"
echo ""

# Extrair metricas
COVERAGE_FILE="coverage/coverage-summary.json"
if [ -f "$COVERAGE_FILE" ]; then
  echo "Coverage Summary:"
  cat $COVERAGE_FILE | grep -A 4 "total"
else
  echo "⚠️  Coverage file nao encontrado"
fi

echo ""
echo "Para ver relatorio completo:"
echo "  open coverage/index.html"
echo ""
