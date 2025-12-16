#!/bin/bash

echo "Aguardando LocalStack inicializar..."
sleep 5

echo "Criando bucket S3 para imagens..."
awslocal s3 mb s3://shopping-images
awslocal s3api put-bucket-cors --bucket shopping-images --cors-configuration '{
  "CORSRules": [{
    "AllowedOrigins": ["*"],
    "AllowedMethods": ["GET", "PUT", "POST", "DELETE"],
    "AllowedHeaders": ["*"],
    "MaxAgeSeconds": 3000
  }]
}'

echo "Criando tabela DynamoDB para metadados de imagens..."
awslocal dynamodb create-table \
    --table-name TaskImages \
    --attribute-definitions \
        AttributeName=imageId,AttributeType=S \
        AttributeName=taskId,AttributeType=S \
    --key-schema \
        AttributeName=imageId,KeyType=HASH \
    --global-secondary-indexes \
        "[{\"IndexName\": \"taskId-index\",\"KeySchema\":[{\"AttributeName\":\"taskId\",\"KeyType\":\"HASH\"}],\"Projection\":{\"ProjectionType\":\"ALL\"},\"ProvisionedThroughput\":{\"ReadCapacityUnits\":5,\"WriteCapacityUnits\":5}}]" \
    --provisioned-throughput \
        ReadCapacityUnits=5,WriteCapacityUnits=5

echo "Criando fila SQS para processamento de imagens..."
awslocal sqs create-queue --queue-name image-upload-queue

echo "Criando tópico SNS para notificações..."
awslocal sns create-topic --name image-upload-notifications

echo "Obtendo ARNs..."
TOPIC_ARN=$(awslocal sns list-topics --query "Topics[?contains(TopicArn, 'image-upload-notifications')].TopicArn" --output text)
QUEUE_URL=$(awslocal sqs get-queue-url --queue-name image-upload-queue --query 'QueueUrl' --output text)

echo "Inscrevendo fila SQS no tópico SNS..."
awslocal sns subscribe \
    --topic-arn $TOPIC_ARN \
    --protocol sqs \
    --notification-endpoint arn:aws:sqs:us-east-1:000000000000:image-upload-queue

echo "✅ Recursos AWS configurados com sucesso!"
echo "📦 S3 Bucket: shopping-images"
echo "💾 DynamoDB Table: TaskImages"
echo "📨 SQS Queue: image-upload-queue"
echo "🔔 SNS Topic: image-upload-notifications"
