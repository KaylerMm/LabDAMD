#!/bin/bash

echo "🚀 INICIANDO DEMO DE UPLOAD COM AWS LOCALSTACK"
echo "=============================================="
echo ""

# Cores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Diretório do projeto
PROJECT_DIR="/home/kayler/Puc/Lab App Mov/Roteiro5"
SERVER_DIR="$PROJECT_DIR/server_simples"

cd "$PROJECT_DIR"

# Parar containers anteriores
echo -e "${YELLOW}🛑 Parando containers anteriores...${NC}"
docker-compose down 2>/dev/null

# Limpar dados antigos (opcional)
# rm -rf localstack-data/

# Iniciar LocalStack
echo -e "${BLUE}📦 Iniciando LocalStack...${NC}"
docker-compose up -d localstack

echo -e "${YELLOW}⏳ Aguardando LocalStack inicializar (15 segundos)...${NC}"
sleep 15

# Verificar se LocalStack está rodando
if ! curl -s http://localhost:4566/_localstack/health > /dev/null; then
    echo -e "${RED}❌ Erro: LocalStack não está respondendo${NC}"
    exit 1
fi

echo -e "${GREEN}✅ LocalStack iniciado com sucesso!${NC}"

# Instalar dependências do servidor
cd "$SERVER_DIR"
if [ ! -d "node_modules" ]; then
    echo -e "${BLUE}📥 Instalando dependências do servidor...${NC}"
    npm install
fi

# Parar servidor anterior se estiver rodando
pkill -f "node server_upload.js" 2>/dev/null

# Iniciar servidor de upload
echo -e "${BLUE}🚀 Iniciando servidor de upload...${NC}"
nohup node server_upload.js > upload_server.log 2>&1 &
SERVER_PID=$!

sleep 3

# Verificar se servidor está rodando
if ! curl -s http://localhost:3000/api/health > /dev/null; then
    echo -e "${RED}❌ Erro: Servidor não está respondendo${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Servidor de upload rodando (PID: $SERVER_PID)${NC}"

# Configurar ADB para dispositivo Android
if command -v adb &> /dev/null; then
    echo -e "${BLUE}📱 Configurando conexão ADB...${NC}"
    adb reverse tcp:3000 tcp:3000
    adb reverse tcp:4566 tcp:4566
    echo -e "${GREEN}✅ Port forwarding configurado${NC}"
fi

echo ""
echo -e "${GREEN}=============================================="
echo "✅ SISTEMA PRONTO PARA USO!"
echo "==============================================${NC}"
echo ""
echo -e "${BLUE}📊 Endpoints disponíveis:${NC}"
echo "   • Health Check: http://localhost:3000/api/health"
echo "   • Upload Base64: POST http://localhost:3000/api/upload/base64"
echo "   • Upload Multipart: POST http://localhost:3000/api/upload/multipart"
echo "   • Listar imagens: GET http://localhost:3000/api/images"
echo "   • Imagens por task: GET http://localhost:3000/api/images/:taskId"
echo ""
echo -e "${BLUE}☁️  LocalStack:${NC}"
echo "   • Gateway: http://localhost:4566"
echo "   • S3 Bucket: shopping-images"
echo "   • DynamoDB Table: TaskImages"
echo "   • SQS Queue: image-upload-queue"
echo "   • SNS Topic: image-upload-notifications"
echo ""
echo -e "${YELLOW}📝 Para ver logs do servidor:${NC}"
echo "   tail -f $SERVER_DIR/upload_server.log"
echo ""
echo -e "${YELLOW}🛑 Para parar tudo:${NC}"
echo "   ./STOP_UPLOAD.sh"
echo ""
