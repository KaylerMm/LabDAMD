#!/bin/bash

echo "📊 MONITORAMENTO EM TEMPO REAL - UPLOAD DE FOTOS"
echo "=================================================="
echo ""

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Limpar tela
clear

while true; do
    # Data/hora
    echo -e "${BLUE}$(date '+%Y-%m-%d %H:%M:%S')${NC}"
    echo "=================================================="
    
    # Status do servidor
    echo -e "${YELLOW}📡 STATUS DO SERVIDOR:${NC}"
    if curl -s http://localhost:3000/api/health > /dev/null 2>&1; then
        echo -e "   ${GREEN}✅ Servidor de upload: ONLINE${NC}"
    else
        echo -e "   ❌ Servidor de upload: OFFLINE"
    fi
    
    # Status do LocalStack
    if curl -s http://localhost:4566/_localstack/health > /dev/null 2>&1; then
        echo -e "   ${GREEN}✅ LocalStack: ONLINE${NC}"
    else
        echo -e "   ❌ LocalStack: OFFLINE"
    fi
    
    echo ""
    
    # Contar imagens no S3
    echo -e "${YELLOW}📦 BUCKET S3 (shopping-images):${NC}"
    S3_COUNT=$(docker exec localstack awslocal s3 ls s3://shopping-images/ 2>/dev/null | grep -v "PRE" | wc -l)
    echo -e "   Total de imagens: ${GREEN}$S3_COUNT${NC}"
    
    # Últimas 3 imagens
    if [ "$S3_COUNT" -gt 0 ]; then
        echo -e "   ${BLUE}Últimas imagens:${NC}"
        docker exec localstack awslocal s3 ls s3://shopping-images/ 2>/dev/null | grep -v "PRE" | tail -3 | while read -r line; do
            echo "      $line"
        done
    fi
    
    echo ""
    
    # Contar registros no DynamoDB
    echo -e "${YELLOW}💾 DYNAMODB (TaskImages):${NC}"
    DYNAMO_COUNT=$(docker exec localstack awslocal dynamodb scan --table-name TaskImages --select "COUNT" 2>/dev/null | jq -r '.Count // 0')
    echo -e "   Total de registros: ${GREEN}$DYNAMO_COUNT${NC}"
    
    # Último registro
    if [ "$DYNAMO_COUNT" -gt 0 ]; then
        echo -e "   ${BLUE}Último upload:${NC}"
        LAST_UPLOAD=$(docker exec localstack awslocal dynamodb scan --table-name TaskImages 2>/dev/null | jq -r '.Items[-1] | "      ID: \(.imageId.S)\n      Task: \(.taskId.S)\n      Data: \(.uploadedAt.S)"')
        echo "$LAST_UPLOAD"
    fi
    
    echo ""
    
    # Mensagens na fila SQS
    echo -e "${YELLOW}📨 FILA SQS:${NC}"
    SQS_ATTRS=$(docker exec localstack awslocal sqs get-queue-attributes \
        --queue-url http://localhost:4566/000000000000/image-upload-queue \
        --attribute-names ApproximateNumberOfMessages 2>/dev/null | jq -r '.Attributes.ApproximateNumberOfMessages // 0')
    echo -e "   Mensagens na fila: ${GREEN}$SQS_ATTRS${NC}"
    
    echo ""
    
    # Logs recentes do servidor
    echo -e "${YELLOW}📝 LOGS RECENTES (últimas 3 linhas):${NC}"
    tail -3 /home/kayler/Puc/Lab\ App\ Mov/Roteiro5/server_simples/upload_server.log 2>/dev/null | while read -r line; do
        echo "   $line"
    done
    
    echo ""
    echo "=================================================="
    echo -e "${BLUE}Pressione Ctrl+C para sair${NC}"
    echo ""
    
    # Aguardar 3 segundos
    sleep 3
    
    # Limpar tela para próxima atualização
    clear
done
