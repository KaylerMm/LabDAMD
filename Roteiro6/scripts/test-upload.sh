#!/bin/bash

echo "=== Testing Image Upload to LocalStack S3 ==="
echo ""

USER_ID="test-user-123"
TASK_ID="test-task-456"

echo "Creating test image..."
echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==" > /tmp/test_image_base64.txt

IMAGE_DATA=$(cat /tmp/test_image_base64.txt)

echo "Uploading image via API..."
RESPONSE=$(curl -s -X POST http://localhost:3000/api/upload \
  -H "Content-Type: application/json" \
  -d "{
    \"userId\": \"$USER_ID\",
    \"taskId\": \"$TASK_ID\",
    \"imageData\": \"$IMAGE_DATA\",
    \"contentType\": \"image/png\"
  }")

echo "Response: $RESPONSE"
echo ""

IMAGE_KEY=$(echo $RESPONSE | jq -r '.image_key')

if [ "$IMAGE_KEY" != "null" ] && [ -n "$IMAGE_KEY" ]; then
    echo "✓ Image uploaded successfully!"
    echo "Image Key: $IMAGE_KEY"
    
    echo ""
    echo "Verifying image in S3..."
    awslocal s3 ls s3://shopping-images/$IMAGE_KEY
    
    if [ $? -eq 0 ]; then
        echo "✓ Image found in S3 bucket"
    else
        echo "✗ Image not found in S3 bucket"
    fi
else
    echo "✗ Failed to upload image"
    exit 1
fi

echo ""
echo "Creating task with image..."
TASK_RESPONSE=$(curl -s -X POST http://localhost:3000/api/tasks-with-image \
  -H "Content-Type: application/json" \
  -d "{
    \"userId\": \"$USER_ID\",
    \"title\": \"Test Product\",
    \"description\": \"This is a test product with image\",
    \"imageData\": \"$IMAGE_DATA\",
    \"contentType\": \"image/png\"
  }")

echo "Task Response: $TASK_RESPONSE"

TASK_SUCCESS=$(echo $TASK_RESPONSE | jq -r '.success')

if [ "$TASK_SUCCESS" = "true" ]; then
    echo "✓ Task created with image successfully!"
    
    TASK_ID=$(echo $TASK_RESPONSE | jq -r '.task.id')
    echo "Task ID: $TASK_ID"
    
    echo ""
    echo "Checking DynamoDB..."
    awslocal dynamodb get-item \
      --table-name tasks \
      --key "{\"id\": {\"S\": \"$TASK_ID\"}}" \
      --output json | jq '.Item'
else
    echo "✗ Failed to create task with image"
    exit 1
fi

echo ""
echo "=== Test completed successfully! ==="
