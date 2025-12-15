#!/bin/bash

export AWS_ACCESS_KEY_ID="test"
export AWS_SECRET_ACCESS_KEY="test"
export AWS_DEFAULT_REGION="us-east-1"

echo "=== Starting LocalStack (Community) ==="
echo ""

echo "Stopping any existing LocalStack..."
localstack stop 2>/dev/null || true

echo ""
echo "Starting LocalStack Community Edition..."
LOCALSTACK_AUTH_TOKEN="" DEBUG=1 localstack start -d

echo ""
echo "Waiting for LocalStack..."
for i in {1..30}; do
    if curl -s http://localhost:4566/_localstack/health > /dev/null 2>&1; then
        echo "✓ LocalStack is ready!"
        break
    fi
    echo -n "."
    sleep 2
done

echo ""
echo ""
echo "Initializing AWS services..."

aws s3 mb s3://shopping-images --endpoint-url=http://localhost:4566
echo "✓ S3 bucket created"

aws dynamodb create-table \
  --endpoint-url=http://localhost:4566 \
  --table-name tasks \
  --attribute-definitions \
    AttributeName=id,AttributeType=S \
    AttributeName=userId,AttributeType=S \
  --key-schema AttributeName=id,KeyType=HASH \
  --global-secondary-indexes \
    '[{"IndexName":"userId-index","KeySchema":[{"AttributeName":"userId","KeyType":"HASH"}],"Projection":{"ProjectionType":"ALL"},"ProvisionedThroughput":{"ReadCapacityUnits":5,"WriteCapacityUnits":5}}]' \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  > /dev/null 2>&1
echo "✓ DynamoDB table created"

aws sqs create-queue --endpoint-url=http://localhost:4566 --queue-name task-queue > /dev/null 2>&1
echo "✓ SQS queue created"

aws sns create-topic --endpoint-url=http://localhost:4566 --name task-notifications > /dev/null 2>&1
echo "✓ SNS topic created"

aws sns subscribe \
  --endpoint-url=http://localhost:4566 \
  --topic-arn arn:aws:sns:us-east-1:000000000000:task-notifications \
  --protocol sqs \
  --notification-endpoint arn:aws:sqs:us-east-1:000000000000:task-queue \
  > /dev/null 2>&1
echo "✓ SNS subscribed"

echo ""
echo "✅ LocalStack ready at http://localhost:4566"
echo ""
echo "Next steps:"
echo "  1. Start services: ./start-services.sh"
echo "  2. Or manually start each service in separate terminals"
