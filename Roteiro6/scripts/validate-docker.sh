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
echo "2. Checking LocalStack health..."
HEALTH=$(curl -s http://localhost:4566/_localstack/health | grep -o '"s3"' | wc -l)
if [ "$HEALTH" -gt 0 ]; then
    echo "✓ LocalStack services are healthy"
else
    echo "✗ LocalStack is not healthy"
    exit 1
fi

echo ""
echo "3. Checking S3 bucket..."
BUCKET_CHECK=$(docker exec localstack awslocal s3 ls 2>/dev/null | grep -c shopping-images)
if [ "$BUCKET_CHECK" -gt 0 ]; then
    echo "✓ Bucket 'shopping-images' exists"
else
    echo "✗ Bucket 'shopping-images' not found"
    exit 1
fi

echo ""
echo "4. Listing S3 bucket contents..."
docker exec localstack awslocal s3 ls s3://shopping-images --recursive 2>/dev/null || echo "(empty)"

echo ""
echo "5. Checking DynamoDB table..."
TABLE_CHECK=$(docker exec localstack awslocal dynamodb list-tables 2>/dev/null | grep -c tasks)
if [ "$TABLE_CHECK" -gt 0 ]; then
    echo "✓ DynamoDB table 'tasks' exists"
else
    echo "✗ DynamoDB table 'tasks' not found"
    exit 1
fi

echo ""
echo "6. Listing DynamoDB items..."
docker exec localstack awslocal dynamodb scan --table-name tasks --output json 2>/dev/null | grep -o '"Count": [0-9]*' || echo "(empty)"

echo ""
echo "7. Checking SQS queue..."
QUEUE_CHECK=$(docker exec localstack awslocal sqs list-queues 2>/dev/null | grep -c task-queue)
if [ "$QUEUE_CHECK" -gt 0 ]; then
    echo "✓ SQS queue 'task-queue' exists"
else
    echo "✗ SQS queue 'task-queue' not found"
    exit 1
fi

echo ""
echo "8. Checking SNS topic..."
TOPIC_CHECK=$(docker exec localstack awslocal sns list-topics 2>/dev/null | grep -c task-notifications)
if [ "$TOPIC_CHECK" -gt 0 ]; then
    echo "✓ SNS topic 'task-notifications' exists"
else
    echo "✗ SNS topic 'task-notifications' not found"
    exit 1
fi

echo ""
echo "9. Checking API Gateway..."
API_HEALTH=$(curl -s http://localhost:3000/health 2>/dev/null)
if [ ! -z "$API_HEALTH" ]; then
    echo "✓ API Gateway is healthy"
else
    echo "✗ API Gateway is not responding"
    exit 1
fi

echo ""
echo "10. Checking Storage Service..."
if docker ps | grep -q storage-service; then
    echo "✓ Storage Service is running"
else
    echo "✗ Storage Service is not running"
fi

echo ""
echo "11. Checking Task Service..."
if docker ps | grep -q task-service; then
    echo "✓ Task Service is running"
else
    echo "✗ Task Service is not running"
fi

echo ""
echo "=== All validations passed! ==="
echo ""
echo "📋 Quick Commands:"
echo "  List S3:       docker exec localstack awslocal s3 ls s3://shopping-images --recursive"
echo "  Scan DynamoDB: docker exec localstack awslocal dynamodb scan --table-name tasks"
echo "  Check SQS:     docker exec localstack awslocal sqs receive-message --queue-url http://localhost:4566/000000000000/task-queue"
echo "  API Health:    curl http://localhost:3000/health"
