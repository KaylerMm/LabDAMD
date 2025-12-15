#!/bin/bash

set -e

echo "=== Roteiro 6 - LocalStack Demo Setup ==="
echo ""

echo "📦 Step 1: Installing dependencies..."
echo ""

echo "Installing Storage Service dependencies..."
cd services/storage-service
npm install --silent
cd ../..

echo "Installing Task Service dependencies..."
cd services/task-service
npm install --silent
cd ../..

echo "Installing API Gateway dependencies..."
cd api-gateway
npm install --silent
cd ..

echo ""
echo "🐳 Step 2: Starting Docker containers..."
docker compose down -v 2>/dev/null || true
docker compose up -d

echo ""
echo "⏳ Step 3: Waiting for LocalStack to be ready..."
echo -n "Checking"
for i in {1..30}; do
    if docker ps | grep -q "localstack" && curl -s http://localhost:4566/_localstack/health > /dev/null 2>&1; then
        echo " ✓"
        break
    fi
    echo -n "."
    sleep 1
done

echo "Waiting for other services..."
sleep 5

echo ""
echo "✅ Step 4: Validating setup..."
./scripts/validate.sh

echo ""
echo "🎉 Demo ready!"
echo ""
echo "📱 To run Flutter app:"
echo "   cd flutter_task_manager"
echo "   flutter pub get"
echo "   flutter run"
echo ""
echo "🧪 To test upload:"
echo "   ./scripts/test-upload.sh"
echo ""
echo "📊 To view logs:"
echo "   docker compose logs -f"
echo ""
