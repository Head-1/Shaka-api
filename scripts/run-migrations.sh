#!/bin/bash

echo "🚀 Running Database Migrations..."

# Compilar TypeScript
npm run build

# Rodar migrations
npx typeorm migration:run -d dist/infrastructure/database/config.js

echo "✅ Migrations completed!"
