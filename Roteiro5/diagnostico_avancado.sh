#!/bin/bash

echo "📱 DIAGNÓSTICO DE CONECTIVIDADE AVANÇADO"
echo "========================================"
echo

# Verificar tipo de dispositivo Flutter
echo "1️⃣ Verificando dispositivos Flutter conectados:"
cd task_manager
flutter devices

echo
echo "2️⃣ Verificando servidor em diferentes IPs:"

# Testar localhost
echo "   🔍 Localhost (127.0.0.1:3000):"
if curl -s http://127.0.0.1:3000/health > /dev/null; then
    echo "      ✅ Funcionando"
else
    echo "      ❌ Não funciona"
fi

# Testar IP da rede
network_ip=$(ip route get 1.1.1.1 | grep -oP 'src \K\S+' | head -1)
echo "   🔍 IP da rede ($network_ip:3000):"
if curl -s http://$network_ip:3000/health > /dev/null; then
    echo "      ✅ Funcionando"
else
    echo "      ❌ Não funciona"
fi

# Testar todas as interfaces
echo "   🔍 Servidor ouvindo em:"
ss -tuln | grep :3000

echo
echo "3️⃣ SOLUÇÕES RECOMENDADAS:"
echo

echo "📱 PARA EMULADOR ANDROID:"
echo "   • Use: 10.0.2.2:3000"
echo "   • Execute: flutter run"

echo
echo "📲 PARA DISPOSITIVO FÍSICO:"
echo "   • Conecte o telefone via USB"
echo "   • Use: $network_ip:3000"
echo "   • Execute: flutter run -d <device_id>"

echo
echo "🔧 PARA RESOLVER TIMEOUT:"
echo "   1. Pare o Flutter: Ctrl+C"
echo "   2. Execute: flutter clean"
echo "   3. Execute: flutter pub get"
echo "   4. Execute: flutter run"

echo
echo "4️⃣ TESTANDO CONECTIVIDADE DO FLUTTER:"
echo "   Faça hot reload (r) e observe os logs para ver qual URL funcionou"
echo "   Mensagens esperadas:"
echo "   ✅ '🔍 Testando conectividade com servidor...'"
echo "   ✅ '✅ Conectado com sucesso: http://...'"
echo "   ❌ '❌ Nenhuma URL funcionou - servidor offline'"