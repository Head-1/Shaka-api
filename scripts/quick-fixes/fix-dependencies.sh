#!/bin/bash
# Install missing type definitions

cd ~/shaka-api

echo "📦 Installing missing types..."

npm install --save-dev @types/bcryptjs

echo "✅ Dependencies installed"

