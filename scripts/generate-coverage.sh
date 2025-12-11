#!/bin/bash

echo "============================================"
echo "SCRIPT 34: Generate Coverage Report"
echo "============================================"
echo ""

# 1. Gerar coverage completo
echo "1. Gerando relatorio de cobertura..."
npm run test:coverage

echo ""
echo "============================================"
echo "SCRIPT 34 CONCLUIDO!"
echo "============================================"
echo ""
echo "Relatorio gerado em: coverage/index.html"
echo ""
echo "Para visualizar:"
echo "  cd coverage"
echo "  python3 -m http.server 8080"
echo "  # Abra: http://localhost:8080"
echo ""
echo "Ou no navegador local:"
echo "  file://$(pwd)/coverage/index.html"
echo ""
