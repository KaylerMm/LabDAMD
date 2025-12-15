#!/bin/bash

echo "=== Roteiro 6 - LocalStack Validation ==="
echo ""

echo "1. Checking LocalStack container..."
if docker ps | grep -q localstack; then
    echo "✓ LocalStack is running"
else
    echo "✗ LocalStack is not running"
    exit 1
fi

echo ""
echo "2. Checking S3 bucket..."
awslocal s3 ls | grep -q shopping-images
if [ $? -eq 0 ]; then
    echo "✓ Bucket 'shopping-images' exists"
else
    echo "✗ Bucket 'shopping-images' not found"
    exit 1
fi

echo ""
echo "3. Listing S3 bucket contents..."
awslocal s3 ls s3://shopping-images --recursive

echo ""
echo "4. Checking DynamoDB table..."
awslocal dynamodb describe-table --table-name tasks > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✓ DynamoDB table 'tasks' exists"
else
    echo "✗ DynamoDB table 'tasks' not found"
    exit 1
fi

echo ""
echo "5. Listing DynamoDB items..."
awslocal dynamodb scan --table-name tasks --output json | jq '.Items'

echo ""
echo "6. Checking SQS queue..."
awslocal sqs list-queues | grep -q task-queue
if [ $? -eq 0 ]; then
    echo "✓ SQS queue 'task-queue' exists"
else
    echo "✗ SQS queue 'task-queue' not found"
    exit 1
fi

echo ""
echo "7. Checking SNS topic..."
awslocal sns list-topics | grep -q task-notifications
if [ $? -eq 0 ]; then
    echo "✓ SNS topic 'task-notifications' exists"
else
    echo "✗ SNS topic 'task-notifications' not found"
    exit 1
fi

echo ""
echo "8. Checking API Gateway..."
curl -s http://localhost:3000/health > /dev/null
if [ $? -eq 0 ]; then
    echo "✓ API Gateway is healthy"
else
    echo "✗ API Gateway is not responding"
    exit 1
fi

echo ""
echo "=== All validations passed! ==="
