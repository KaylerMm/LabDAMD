#!/bin/bash

echo "🔧 LIMPEZA COMPLETA DO FLUTTER - Resolvendo problemas de conectividade"
echo "=================================================================="
echo

# Navegar para o diretório do Flutter
cd task_manager

echo "1️⃣ Parando todos os processos Flutter..."
pkill -f "flutter" 2>/dev/null || true
echo "   ✅ Processos Flutter finalizados"
echo

echo "2️⃣ Limpando cache do Flutter..."
flutter clean
echo "   ✅ Cache limpo"
echo

echo "3️⃣ Removendo arquivos de build..."
rm -rf build/
rm -rf .dart_tool/
echo "   ✅ Arquivos de build removidos"
echo

echo "4️⃣ Reinstalando dependências..."
flutter pub get
echo "   ✅ Dependências reinstaladas"
echo

echo "5️⃣ Verificando configuração de IP..."
current_ip=$(ip route get 1.1.1.1 | grep -oP 'src \K\S+' | head -1)
configured_ip=$(grep -o "http://[0-9.]*:3000" lib/services/api_service.dart | head -1 | sed 's/http:\/\/\([0-9.]*\):3000/\1/')

echo "   IP atual da máquina: $current_ip"
echo "   IP configurado no Flutter: $configured_ip"

if [ "$configured_ip" != "$current_ip" ]; then
    echo "   ❌ IPs diferentes! Corrigindo..."
    sed -i "s|http://[0-9.]*:3000|http://$current_ip:3000|g" lib/services/api_service.dart
    echo "   ✅ IP corrigido para $current_ip"
else
    echo "   ✅ IP está correto"
fi
echo

echo "6️⃣ Testando conectividade do servidor..."
if curl -s http://$current_ip:3000/health > /dev/null; then
    echo "   ✅ Servidor acessível em $current_ip:3000"
else
    echo "   ❌ Servidor NÃO acessível em $current_ip:3000"
    echo "   💡 Verifique se o servidor está rodando"
fi
echo

echo "7️⃣ Iniciando Flutter com restart completo..."
echo "   🚀 Executando: flutter run --debug"
echo
echo "📋 APÓS O FLUTTER INICIAR:"
echo "   • Aguarde a mensagem 'Hot reload enabled'"
echo "   • Verifique se aparece '🌐 Conectado - servidor acessível'"
echo "   • Se ainda mostrar offline, pressione 'R' para restart completo"
echo

flutter run --debug