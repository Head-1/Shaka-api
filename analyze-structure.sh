#!/bin/bash

echo "📊 ANÁLISE DA ESTRUTURA DO SHAKA API"
echo "===================================="

echo ""
echo "📁 ESTRUTURA PRINCIPAL:"
ls -la

echo ""
echo "📦 TAMANHO DAS PASTAS:"
du -sh * | sort -hr

echo ""
echo "🔧 SCRIPTS DISPONÍVEIS:"
find scripts/ -name "*.sh" -type f | wc -l
find scripts/ -name "*.sh" -type f | head -10

echo ""
echo "🧪 TESTES:"
find tests/ -name "*.test.ts" -type f | wc -l
find tests/ -name "*.spec.ts" -type f | wc -l

echo ""
echo "💻 CÓDIGO FONTE:"
find src/ -name "*.ts" -type f | wc -l

echo ""
echo "📚 DOCUMENTAÇÃO:"
find docs/ -name "*.md" -type f | wc -l

echo ""
echo "🎯 ESTATÍSTICAS GERAIS:"
echo "Arquivos TypeScript: $(find . -name "*.ts" -not -path "*/node_modules/*" | wc -l)"
echo "Arquivos de Teste: $(find . -name "*.test.ts" -not -path "*/node_modules/*" | wc -l)"
echo "Scripts Shell: $(find . -name "*.sh" -not -path "*/node_modules/*" | wc -l)"
echo "Arquivos Markdown: $(find . -name "*.md" -not -path "*/node_modules/*" | wc -l)"
