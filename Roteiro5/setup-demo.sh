#!/bin/bash
# Script de demonstração automática

echo "🚀 Iniciando demonstração do sistema de mensageria"
echo "=================================================="

# Verificar se estamos no diretório correto
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Execute este script no diretório Roteiro5"
    exit 1
fi

echo "📋 1. Verificando Docker..."
if ! command -v docker &> /dev/null; then
    echo "❌ Docker não encontrado. Instale o Docker primeiro."
    exit 1
fi

echo "✅ Docker encontrado"

echo ""
echo "📦 2. Iniciando containers (RabbitMQ + MongoDB)..."
docker compose up -d

sleep 5

echo ""
echo "🔍 3. Verificando containers..."
docker compose ps

echo ""
echo "⏳ 4. Aguardando RabbitMQ inicializar (15 segundos)..."
sleep 15

echo ""
echo "🧪 5. Testando conectividade RabbitMQ..."
curl -f -s http://admin:admin123@localhost:15672/api/overview > /dev/null
if [ $? -eq 0 ]; then
    echo "✅ RabbitMQ Management acessível"
else
    echo "❌ RabbitMQ não está acessível"
    exit 1
fi

echo ""
echo "📝 6. Instalando dependências..."
npm install --silent

echo ""
echo "🎬 DEMONSTRAÇÃO PRONTA!"
echo "======================"
echo ""
echo "▶️  Próximos passos:"
echo "   1. Abra 6 terminais"
echo "   2. Execute os serviços conforme ROTEIRO_GUIADO.md"
echo "   3. Ou execute: ./start-demo.sh (se disponível)"
echo ""
echo "🌐 URLs importantes:"
echo "   • RabbitMQ Management: http://localhost:15672 (admin/admin123)"
echo "   • API Gateway: http://localhost:3000"
echo ""
echo "📋 Ver roteiro completo: cat ROTEIRO_GUIADO.md"