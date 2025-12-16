#!/bin/bash

echo "🔧 CONFIGURAÇÃO DE PORT FORWARDING VIA ADB"
echo "=========================================="
echo

# Verificar se ADB está disponível
if ! command -v adb &> /dev/null; then
    echo "❌ ADB não encontrado. Instale android-tools-adb"
    exit 1
fi

# Verificar dispositivos conectados
echo "📱 Verificando dispositivos Android conectados..."
device_count=$(adb devices | grep -c "device$")

if [ "$device_count" -eq 0 ]; then
    echo "❌ Nenhum dispositivo Android conectado"
    echo "💡 Conecte o dispositivo via USB e ative debug USB"
    exit 1
fi

echo "✅ Dispositivo Android encontrado"
adb devices

echo
echo "🔗 Configurando port forwarding..."
# Fazer forward da porta 3000 do computador para porta 3000 do dispositivo
adb reverse tcp:3000 tcp:3000

if [ $? -eq 0 ]; then
    echo "✅ Port forwarding configurado: dispositivo:3000 -> computador:3000"
else
    echo "❌ Falha no port forwarding"
    exit 1
fi

echo
echo "📝 Atualizando configuração do Flutter para usar localhost..."
cd task_manager

# Fazer backup
cp lib/services/api_service.dart lib/services/api_service.dart.backup

# Alterar para localhost (que agora será redirecionado via ADB)
sed -i 's|http://[0-9.]*\.[0-9.]*\.[0-9.]*\.[0-9.]*:3000|http://localhost:3000|g' lib/services/api_service.dart
sed -i 's|http://127\.0\.0\.1:3000|http://localhost:3000|g' lib/services/api_service.dart

echo "✅ Flutter configurado para usar localhost:3000"
echo

echo "🧪 Testando conectividade..."
if curl -s http://localhost:3000/health > /dev/null; then
    echo "✅ Servidor acessível em localhost:3000"
    echo "✅ Dispositivo Android poderá acessar via port forwarding"
else
    echo "❌ Servidor não acessível em localhost:3000"
    echo "💡 Certifique-se de que o servidor está rodando: cd ../Roteiro1 && node server.js"
fi

echo
echo "📋 CONFIGURAÇÃO ATUAL:"
grep -n "baseUrl\|_baseUrls\|localhost" lib/services/api_service.dart | head -5

echo
echo "🚀 PRÓXIMOS PASSOS:"
echo "1. Faça hot reload no Flutter: r"
echo "2. O dispositivo usará localhost:3000 via port forwarding"
echo "3. Logs esperados: '✅ Conectado com sucesso: http://localhost:3000'"
echo
echo "💡 Para reverter: adb reverse --remove tcp:3000"