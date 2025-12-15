#!/bin/bash

export AWS_ACCESS_KEY_ID="test"
export AWS_SECRET_ACCESS_KEY="test"
export AWS_DEFAULT_REGION="us-east-1"

echo "=== LocalStack CLI Validation ==="
echo ""

echo "1. Checking LocalStack status..."
if localstack status 2>/dev/null | grep -q "running"; then
    echo "✓ LocalStack is running"
else
    echo "✗ LocalStack is not running"
    echo "Start with: ./start-localstack.sh"
    exit 1
fi

echo ""
echo "2. Checking S3 bucket..."
if aws s3 ls --endpoint-url=http://localhost:4566 2>/dev/null | grep -q shopping-images; then
    echo "✓ Bucket 'shopping-images' exists"
else
    echo "✗ Bucket not found"
    exit 1
fi

echo ""
echo "3. Listing S3 contents..."
aws s3 ls s3://shopping-images --endpoint-url=http://localhost:4566 --recursive 2>/dev/null || echo "(empty)"

echo ""
echo "4. Checking DynamoDB table..."
if aws dynamodb list-tables --endpoint-url=http://localhost:4566 2>/dev/null | grep -q tasks; then
    echo "✓ DynamoDB table 'tasks' exists"
else
    echo "✗ DynamoDB table not found"
    exit 1
fi

echo ""
echo "5. Counting DynamoDB items..."
aws dynamodb scan --table-name tasks --endpoint-url=http://localhost:4566 --output json 2>/dev/null | grep -o '"Count": [0-9]*' || echo "(empty)"

echo ""
echo "6. Checking SQS queue..."
if aws sqs list-queues --endpoint-url=http://localhost:4566 2>/dev/null | grep -q task-queue; then
    echo "✓ SQS queue exists"
else
    echo "✗ SQS queue not found"
    exit 1
fi

echo ""
echo "7. Checking SNS topic..."
if aws sns list-topics --endpoint-url=http://localhost:4566 2>/dev/null | grep -q task-notifications; then
    echo "✓ SNS topic exists"
else
    echo "✗ SNS topic not found"
    exit 1
fi

echo ""
echo "8. Checking API Gateway..."
if curl -s http://localhost:3000/health > /dev/null 2>&1; then
    echo "✓ API Gateway is healthy"
else
    echo "✗ API Gateway not responding"
    exit 1
fi

echo ""
echo "=== All validations passed! ==="
echo ""
echo "📋 Quick commands:"
echo "  aws s3 ls s3://shopping-images --endpoint-url=http://localhost:4566 --recursive"
echo "  aws dynamodb scan --table-name tasks --endpoint-url=http://localhost:4566"
echo "  curl http://localhost:3000/health"
