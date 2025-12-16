#!/bin/bash

echo "🛑 Parando sistema de upload..."

# Parar servidor Node.js
pkill -f "node server_upload.js"

# Parar LocalStack
docker-compose down

echo "✅ Sistema parado com sucesso!"
