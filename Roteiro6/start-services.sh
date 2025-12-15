#!/bin/bash

export AWS_ACCESS_KEY_ID="test"
export AWS_SECRET_ACCESS_KEY="test"
export AWS_DEFAULT_REGION="us-east-1"

echo "=== Starting Backend Services ==="
echo ""

cd services/storage-service
npm install --silent 2>/dev/null
echo "Starting Storage Service..."
AWS_ENDPOINT=http://localhost:4566 \
AWS_REGION=us-east-1 \
AWS_ACCESS_KEY_ID=test \
AWS_SECRET_ACCESS_KEY=test \
S3_BUCKET=shopping-images \
PORT=50051 \
node index.js > /tmp/storage-service.log 2>&1 &
STORAGE_PID=$!
echo "✓ Storage Service (PID: $STORAGE_PID)"

cd ../task-service
npm install --silent 2>/dev/null
echo "Starting Task Service..."
AWS_ENDPOINT=http://localhost:4566 \
AWS_REGION=us-east-1 \
AWS_ACCESS_KEY_ID=test \
AWS_SECRET_ACCESS_KEY=test \
DYNAMODB_TABLE=tasks \
SQS_QUEUE_URL=http://localhost:4566/000000000000/task-queue \
SNS_TOPIC_ARN=arn:aws:sns:us-east-1:000000000000:task-notifications \
PORT=50052 \
node index.js > /tmp/task-service.log 2>&1 &
TASK_PID=$!
echo "✓ Task Service (PID: $TASK_PID)"

cd ../../api-gateway
npm install --silent 2>/dev/null
echo "Starting API Gateway..."
STORAGE_SERVICE_URL=localhost:50051 \
TASK_SERVICE_URL=localhost:50052 \
PORT=3000 \
node index.js > /tmp/api-gateway.log 2>&1 &
API_PID=$!
echo "✓ API Gateway (PID: $API_PID)"

cd ..

echo ""
echo "Saving PIDs..."
echo "$STORAGE_PID" > /tmp/roteiro6-pids.txt
echo "$TASK_PID" >> /tmp/roteiro6-pids.txt
echo "$API_PID" >> /tmp/roteiro6-pids.txt

sleep 2

echo ""
echo "✅ All services running!"
echo ""
echo "Test with: curl http://localhost:3000/health"
echo "Stop with: ./stop-localstack.sh"
echo ""
echo "Service logs:"
echo "  tail -f /tmp/storage-service.log"
echo "  tail -f /tmp/task-service.log"
echo "  tail -f /tmp/api-gateway.log"
