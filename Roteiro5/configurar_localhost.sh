#!/bin/bash

echo "🔄 ALTERNATIVA: Configuração com localhost + port forwarding"
echo "========================================================"
echo

# Verificar se o servidor está rodando
if ! curl -s http://localhost:3000/health > /dev/null; then
    echo "❌ Servidor não está rodando em localhost:3000"
    echo "💡 Inicie o servidor primeiro: cd ../Roteiro1 && node server.js"
    exit 1
fi

echo "✅ Servidor encontrado em localhost:3000"
echo

# Configurar Flutter para usar localhost
echo "📱 Configurando Flutter para usar localhost..."
cd task_manager

# Backup do arquivo original
cp lib/services/api_service.dart lib/services/api_service.dart.backup

# Alterar para localhost
sed -i 's|http://[0-9.]*:3000|http://10.0.2.2:3000|g' lib/services/api_service.dart

echo "✅ Flutter configurado para usar 10.0.2.2:3000 (localhost do Android)"
echo

# Mostrar a configuração atual
echo "📋 Configuração atual:"
grep -n "baseUrl" lib/services/api_service.dart

echo
echo "🚀 Para testar:"
echo "1. Execute: flutter run"
echo "2. O Android usará 10.0.2.2:3000 que mapeia para localhost:3000"
echo "3. Isso evita problemas de rede entre máquina host e Android"
echo
echo "💡 Se não funcionar, execute: ./limpar_e_reiniciar_flutter.sh"