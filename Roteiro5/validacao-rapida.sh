#!/bin/bash
# Script para teste rápido de validação

echo "🧪 Validação Rápida do Sistema"
echo "=============================="

# Verificar se os serviços estão rodando
echo ""
echo "🔍 1. Verificando serviços..."

# Testar API Gateway
echo -n "   API Gateway (3000): "
if curl -f -s http://localhost:3000/health > /dev/null; then
    echo "✅ OK"
else
    echo "❌ FALHA - Certifique-se que todos os serviços estejam rodando"
    exit 1
fi

# Verificar RabbitMQ
echo -n "   RabbitMQ Management: "
if curl -f -s http://admin:admin123@localhost:15672/api/overview > /dev/null; then
    echo "✅ OK"
else
    echo "❌ FALHA - RabbitMQ não está acessível"
    exit 1
fi

echo ""
echo "🧪 2. Executando teste de checkout..."
node test-checkout.js

echo ""
echo "📊 3. Verificando estatísticas RabbitMQ..."

# Pegar estatísticas do RabbitMQ
STATS=$(curl -s http://admin:admin123@localhost:15672/api/overview)
PUBLISHES=$(echo $STATS | grep -o '"publish":[0-9]*' | cut -d':' -f2)
DELIVERS=$(echo $STATS | grep -o '"deliver":[0-9]*' | cut -d':' -f2)

echo "   📤 Mensagens publicadas: $PUBLISHES"
echo "   📥 Mensagens entregues: $DELIVERS"

if [ "$PUBLISHES" -gt 0 ] && [ "$DELIVERS" -gt 0 ]; then
    echo "   ✅ Sistema de mensageria funcionando!"
else
    echo "   ⚠️  Possível problema na mensageria"
fi

echo ""
echo "🏁 Validação concluída!"
echo ""
echo "💡 Para demonstração completa, consulte: ROTEIRO_GUIADO.md"