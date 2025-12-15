#!/bin/bash

export AWS_ACCESS_KEY_ID="test"
export AWS_SECRET_ACCESS_KEY="test"
export AWS_DEFAULT_REGION="us-east-1"

echo "=== Roteiro 6 - LocalStack CLI Setup ==="
echo ""

if ! command -v localstack &> /dev/null; then
    echo "❌ LocalStack CLI not found!"
    echo "Install with: pip install localstack"
    exit 1
fi

echo "✓ LocalStack CLI found"
echo ""

echo "🚀 Step 1: Starting LocalStack..."
echo ""
echo "Choose mode:"
echo "  1) Community (free, S3/DynamoDB/SQS/SNS only)"
echo "  2) Pro (requires valid license)"
echo ""
read -p "Select [1]: " mode
mode=${mode:-1}

if [ "$mode" = "1" ]; then
    echo "Starting LocalStack Community..."
    LOCALSTACK_AUTH_TOKEN="" localstack start -d
else
    echo "Starting LocalStack Pro..."
    localstack start -d
fi

echo ""
echo "⏳ Step 2: Waiting for LocalStack to be ready..."
echo -n "Checking"
for i in {1..60}; do
    if curl -s http://localhost:4566/_localstack/health > /dev/null 2>&1; then
        echo " ✓"
        break
    fi
    echo -n "."
    sleep 1
done

echo ""
echo "📦 Step 3: Initializing AWS services..."
echo ""

echo "Creating S3 bucket..."
aws s3 mb s3://shopping-images --endpoint-url=http://localhost:4566
aws s3api put-bucket-cors --bucket shopping-images \
  --endpoint-url=http://localhost:4566 \
  --cors-configuration '{
    "CORSRules": [{
      "AllowedOrigins": ["*"],
      "AllowedMethods": ["GET", "PUT", "POST", "DELETE"],
      "AllowedHeaders": ["*"],
      "MaxAgeSeconds": 3000
    }]
  }'
echo "✓ S3 bucket created"

echo ""
echo "Creating DynamoDB table..."
aws dynamodb create-table \
  --endpoint-url=http://localhost:4566 \
  --table-name tasks \
  --attribute-definitions \
    AttributeName=id,AttributeType=S \
    AttributeName=userId,AttributeType=S \
  --key-schema \
    AttributeName=id,KeyType=HASH \
  --global-secondary-indexes \
    '[{
      "IndexName":"userId-index",
      "KeySchema":[{"AttributeName":"userId","KeyType":"HASH"}],
      "Projection":{"ProjectionType":"ALL"},
      "ProvisionedThroughput":{"ReadCapacityUnits":5,"WriteCapacityUnits":5}
    }]' \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  > /dev/null 2>&1
echo "✓ DynamoDB table created"

echo ""
echo "Creating SQS queue..."
aws sqs create-queue \
  --endpoint-url=http://localhost:4566 \
  --queue-name task-queue \
  > /dev/null 2>&1
echo "✓ SQS queue created"

echo ""
echo "Creating SNS topic..."
aws sns create-topic \
  --endpoint-url=http://localhost:4566 \
  --name task-notifications \
  > /dev/null 2>&1
echo "✓ SNS topic created"

echo ""
echo "Subscribing SNS to SQS..."
aws sns subscribe \
  --endpoint-url=http://localhost:4566 \
  --topic-arn arn:aws:sns:us-east-1:000000000000:task-notifications \
  --protocol sqs \
  --notification-endpoint arn:aws:sqs:us-east-1:000000000000:task-queue \
  > /dev/null 2>&1
echo "✓ SNS subscribed to SQS"

echo ""
echo "📦 Step 4: Installing Node.js dependencies..."
cd services/storage-service && npm install --silent 2>/dev/null
cd ../task-service && npm install --silent 2>/dev/null
cd ../../api-gateway && npm install --silent 2>/dev/null
cd ..
echo "✓ Dependencies installed"

echo ""
echo "🚀 Step 5: Starting backend services..."

cd services/storage-service
AWS_ENDPOINT=http://localhost:4566 \
AWS_REGION=us-east-1 \
AWS_ACCESS_KEY_ID=test \
AWS_SECRET_ACCESS_KEY=test \
S3_BUCKET=shopping-images \
PORT=50051 \
node index.js > /tmp/storage-service.log 2>&1 &
STORAGE_PID=$!
echo "✓ Storage Service started (PID: $STORAGE_PID)"

cd ../task-service
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
echo "✓ Task Service started (PID: $TASK_PID)"

cd ../../api-gateway
STORAGE_SERVICE_URL=localhost:50051 \
TASK_SERVICE_URL=localhost:50052 \
PORT=3000 \
node index.js > /tmp/api-gateway.log 2>&1 &
API_PID=$!
echo "✓ API Gateway started (PID: $API_PID)"

cd ..

echo ""
echo "⏳ Waiting for services to initialize..."
sleep 3

echo ""
echo "✅ Setup complete!"
echo ""
echo "📋 Services running:"
echo "  LocalStack:      http://localhost:4566"
echo "  API Gateway:     http://localhost:3000"
echo "  Storage Service: localhost:50051 (PID: $STORAGE_PID)"
echo "  Task Service:    localhost:50052 (PID: $TASK_PID)"
echo ""
echo "💾 Service PIDs saved to /tmp/roteiro6-pids.txt"
echo "$STORAGE_PID" > /tmp/roteiro6-pids.txt
echo "$TASK_PID" >> /tmp/roteiro6-pids.txt
echo "$API_PID" >> /tmp/roteiro6-pids.txt
echo ""
echo "📱 To run Flutter app:"
echo "   cd flutter_task_manager"
echo "   flutter run"
echo ""
echo "🧪 To test:"
echo "   curl http://localhost:3000/health"
echo "   aws s3 ls s3://shopping-images --endpoint-url=http://localhost:4566"
echo ""
echo "🛑 To stop all services:"
echo "   ./scripts/stop-localstack-cli.sh"
