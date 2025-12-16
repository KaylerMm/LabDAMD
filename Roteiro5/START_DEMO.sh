#!/bin/bash

echo "🚀 INICIANDO SISTEMA PARA APRESENTAÇÃO"
echo "======================================"
echo

# 1. Parar processos anteriores
echo "1️⃣ Limpando processos anteriores..."
pkill -f "node.*server" 2>/dev/null || true
pkill -f "flutter run" 2>/dev/null || true
sleep 2

# 2. Configurar ADB port forwarding
echo "2️⃣ Configurando ADB port forwarding..."
if command -v adb &> /dev/null; then
    adb reverse tcp:3000 tcp:3000 2>/dev/null || true
fi

# 3. Iniciar servidor simples
echo "3️⃣ Iniciando servidor..."
cd server_simples
nohup node server_simple.js > ../server.log 2>&1 &
SERVER_PID=$!
cd ..
sleep 2

# Verificar se servidor iniciou
if curl -s http://localhost:3000/health > /dev/null; then
    echo "✅ Servidor rodando (PID: $SERVER_PID)"
else
    echo "❌ Servidor não respondeu"
    tail -10 server.log
fi

echo
echo "✅ PRONTO PARA APRESENTAÇÃO!"
echo
echo "📱 Para iniciar o app Flutter:"
echo "   cd task_manager"
echo "   flutter run -d fcdb13cf"
echo
echo "🔄 No Flutter (hot reload): r"
echo "📊 Ver logs servidor: tail -f server.log"
echo "🛑 Parar servidor: kill $SERVER_PID"
echo
echo "PID do servidor: $SERVER_PID" > server.pid
