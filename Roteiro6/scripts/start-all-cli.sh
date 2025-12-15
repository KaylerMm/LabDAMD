#!/bin/bash

echo "=== Starting Services (LocalStack CLI Mode) ==="
echo ""

echo "Step 1: Starting LocalStack..."
./scripts/start-localstack-cli.sh

echo ""
echo "Step 2: Starting backend services..."

echo "Starting Storage Service..."
cd services/storage-service
npm install
AWS_ENDPOINT=http://localhost:4566 \
AWS_REGION=us-east-1 \
AWS_ACCESS_KEY_ID=test \
AWS_SECRET_ACCESS_KEY=test \
S3_BUCKET=shopping-images \
PORT=50051 \
node index.js &

STORAGE_PID=$!
echo "Storage Service started (PID: $STORAGE_PID)"

cd ../..

echo "Starting Task Service..."
cd services/task-service
npm install
AWS_ENDPOINT=http://localhost:4566 \
AWS_REGION=us-east-1 \
AWS_ACCESS_KEY_ID=test \
AWS_SECRET_ACCESS_KEY=test \
DYNAMODB_TABLE=tasks \
SQS_QUEUE_URL=http://localhost:4566/000000000000/task-queue \
SNS_TOPIC_ARN=arn:aws:sns:us-east-1:000000000000:task-notifications \
PORT=50052 \
node index.js &

TASK_PID=$!
echo "Task Service started (PID: $TASK_PID)"

cd ../..

sleep 3

echo "Starting API Gateway..."
cd api-gateway
npm install
STORAGE_SERVICE_URL=localhost:50051 \
TASK_SERVICE_URL=localhost:50052 \
PORT=3000 \
node index.js &

API_PID=$!
echo "API Gateway started (PID: $API_PID)"

cd ..

echo ""
echo "✅ All services started!"
echo ""
echo "Service PIDs:"
echo "  Storage Service: $STORAGE_PID"
echo "  Task Service: $TASK_PID"
echo "  API Gateway: $API_PID"
echo ""
echo "Endpoints:"
echo "  LocalStack: http://localhost:4566"
echo "  API Gateway: http://localhost:3000"
echo ""
echo "To stop all services:"
echo "  kill $STORAGE_PID $TASK_PID $API_PID"
echo "  localstack stop"
