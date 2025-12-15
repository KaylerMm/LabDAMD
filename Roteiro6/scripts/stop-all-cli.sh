#!/bin/bash

echo "=== Stopping All Services ==="
echo ""

echo "Stopping Node.js services..."
pkill -f "node.*storage-service"
pkill -f "node.*task-service"
pkill -f "node.*api-gateway"

echo "Stopping LocalStack..."
if command -v localstack &> /dev/null; then
    localstack stop
else
    echo "LocalStack CLI not found, skipping..."
fi

echo ""
echo "✅ All services stopped!"
