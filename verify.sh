#!/bin/bash
echo "🔍 Verificando sincronização..."
LOCAL=$(git rev-parse main)
REMOTE=$(git rev-parse origin/main)

if [ "$LOCAL" = "$REMOTE" ]; then
    echo "✅ GitHub está ATUALIZADO"
    echo "Local:  $LOCAL"
    echo "GitHub: $REMOTE"
else
    echo "⚠️  GitHub NÃO está atualizado"
    echo "Local:  $LOCAL"
    echo "GitHub: $REMOTE"
    echo ""
    echo "Commits locais não pushed:"
    git log origin/main..main --oneline
fi
