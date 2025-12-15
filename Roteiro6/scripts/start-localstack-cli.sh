#!/bin/bash

echo "=== Starting LocalStack with CLI ==="
echo ""

if ! command -v localstack &> /dev/null; then
    echo "❌ LocalStack CLI not found. Install with: pip install localstack"
    exit 1
fi

echo "Starting LocalStack..."
localstack start -d

echo ""
echo "Waiting for LocalStack to be ready..."
sleep 10

echo ""
echo "Initializing AWS services..."

awslocal s3 mb s3://shopping-images
echo "✓ S3 bucket 'shopping-images' created"

awslocal s3api put-bucket-cors --bucket shopping-images --cors-configuration '{
  "CORSRules": [
    {
      "AllowedOrigins": ["*"],
      "AllowedMethods": ["GET", "PUT", "POST", "DELETE"],
      "AllowedHeaders": ["*"],
      "MaxAgeSeconds": 3000
    }
  ]
}'
echo "✓ CORS configured for S3 bucket"

awslocal dynamodb create-table \
  --table-name tasks \
  --attribute-definitions \
    AttributeName=id,AttributeType=S \
    AttributeName=userId,AttributeType=S \
  --key-schema \
    AttributeName=id,KeyType=HASH \
  --global-secondary-indexes \
    "[{\"IndexName\":\"userId-index\",\"KeySchema\":[{\"AttributeName\":\"userId\",\"KeyType\":\"HASH\"}],\"Projection\":{\"ProjectionType\":\"ALL\"},\"ProvisionedThroughput\":{\"ReadCapacityUnits\":5,\"WriteCapacityUnits\":5}}]" \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
echo "✓ DynamoDB table 'tasks' created"

awslocal sqs create-queue --queue-name task-queue
echo "✓ SQS queue 'task-queue' created"

awslocal sns create-topic --name task-notifications
echo "✓ SNS topic 'task-notifications' created"

awslocal sns subscribe \
  --topic-arn arn:aws:sns:us-east-1:000000000000:task-notifications \
  --protocol sqs \
  --notification-endpoint arn:aws:sqs:us-east-1:000000000000:task-queue
echo "✓ SNS topic subscribed to SQS queue"

echo ""
echo "✅ LocalStack started and configured!"
echo ""
echo "LocalStack running at: http://localhost:4566"
echo ""
echo "To stop: localstack stop"
