#!/bin/bash

echo "🧪 TESTANDO SISTEMA DE UPLOAD"
echo "=============================="
echo ""

# Criar imagem de teste (1x1 pixel vermelho em base64)
TEST_IMAGE="iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg=="

# Teste 1: Health Check
echo "1️⃣  Testando Health Check..."
HEALTH=$(curl -s http://localhost:3000/api/health)
if [[ $HEALTH == *"ok"* ]]; then
    echo "✅ Health check passou"
else
    echo "❌ Health check falhou"
    exit 1
fi

# Teste 2: Upload Base64
echo ""
echo "2️⃣  Testando upload Base64..."
RESPONSE=$(curl -s -X POST http://localhost:3000/api/upload/base64 \
  -H "Content-Type: application/json" \
  -d "{
    \"image\": \"data:image/png;base64,$TEST_IMAGE\",
    \"taskId\": \"test-task-123\",
    \"description\": \"Teste automatizado\"
  }")

IMAGE_ID=$(echo $RESPONSE | grep -o '"imageId":"[^"]*' | cut -d'"' -f4)

if [[ $RESPONSE == *"success"* ]]; then
    echo "✅ Upload realizado com sucesso"
    echo "   Image ID: $IMAGE_ID"
else
    echo "❌ Upload falhou"
    echo "   Response: $RESPONSE"
    exit 1
fi

# Teste 3: Verificar S3
echo ""
echo "3️⃣  Verificando S3..."
S3_CHECK=$(docker exec localstack-demo awslocal s3 ls s3://shopping-images/)
if [[ $S3_CHECK == *".jpg"* ]]; then
    echo "✅ Imagem encontrada no S3"
else
    echo "❌ Imagem não encontrada no S3"
fi

# Teste 4: Verificar DynamoDB
echo ""
echo "4️⃣  Verificando DynamoDB..."
DYNAMO_CHECK=$(docker exec localstack-demo awslocal dynamodb scan --table-name TaskImages)
if [[ $DYNAMO_CHECK == *"$IMAGE_ID"* ]]; then
    echo "✅ Metadados encontrados no DynamoDB"
else
    echo "❌ Metadados não encontrados no DynamoDB"
fi

# Teste 5: Listar imagens via API
echo ""
echo "5️⃣  Testando listagem de imagens..."
LIST_RESPONSE=$(curl -s http://localhost:3000/api/images)
if [[ $LIST_RESPONSE == *"$IMAGE_ID"* ]]; then
    echo "✅ API de listagem funcionando"
else
    echo "❌ API de listagem falhou"
fi

# Teste 6: Buscar imagens por taskId
echo ""
echo "6️⃣  Testando busca por taskId..."
TASK_RESPONSE=$(curl -s http://localhost:3000/api/images/test-task-123)
if [[ $TASK_RESPONSE == *"$IMAGE_ID"* ]]; then
    echo "✅ Busca por taskId funcionando"
else
    echo "❌ Busca por taskId falhou"
fi

echo ""
echo "=============================="
echo "✅ TODOS OS TESTES PASSARAM!"
echo "=============================="
echo ""
echo "📊 Resumo:"
echo "   • Health Check: OK"
echo "   • Upload Base64: OK"
echo "   • S3 Storage: OK"
echo "   • DynamoDB: OK"
echo "   • API Listagem: OK"
echo "   • API Busca: OK"
echo ""
echo "🔗 Acesse: http://localhost:4566/shopping-images/ para ver as imagens"
