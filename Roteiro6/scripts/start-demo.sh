#!/bin/bash

echo "=== Starting Roteiro 6 Demo ==="
echo ""

echo "Step 1: Starting containers..."
docker-compose up -d

echo ""
echo "Waiting for services to be ready..."
sleep 10

echo ""
echo "Step 2: Checking LocalStack services..."
docker exec localstack awslocal s3 ls

echo ""
echo "Step 3: Services are ready!"
echo ""
echo "LocalStack Dashboard: http://localhost:4566"
echo "API Gateway: http://localhost:3000"
echo ""
echo "Available endpoints:"
echo "- POST   /api/upload              - Upload image"
echo "- GET    /api/images              - List images"
echo "- POST   /api/tasks               - Create task"
echo "- GET    /api/tasks?userId=       - List tasks"
echo "- POST   /api/tasks-with-image    - Create task with image"
echo ""
echo "To run validation:"
echo "  ./scripts/validate.sh"
echo ""
echo "To test upload:"
echo "  ./scripts/test-upload.sh"
echo ""
echo "To view logs:"
echo "  docker-compose logs -f [service-name]"
echo ""
echo "=== Demo started successfully! ==="
