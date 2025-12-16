#!/bin/bash

echo "🛑 Stopping Shopping List Messaging System"
echo "=========================================="

echo "Stopping Node.js processes..."
pkill -f "node.*user-service"
pkill -f "node.*list-service"
pkill -f "node.*item-service"
pkill -f "node.*gateway"
pkill -f "node.*notification-consumer"
pkill -f "node.*analytics-consumer"

echo "Stopping Docker containers..."
docker-compose down

echo "✅ Demo stopped successfully!"