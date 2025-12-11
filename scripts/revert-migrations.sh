#!/bin/bash

echo "⏪ Reverting last migration..."

npm run build
npx typeorm migration:revert -d dist/infrastructure/database/config.js

echo "✅ Migration reverted!"
