#!/bin/bash

echo "🔍 DIAGNÓSTICO DE CONECTIVIDADE - Task Manager"
echo "=============================================="
echo

# 1. Verificar IP atual da máquina
echo "📍 1. IP atual da máquina:"
current_ip=$(ip route get 1.1.1.1 | grep -oP 'src \K\S+' | head -1)
echo "   IP detectado: $current_ip"
echo

# 2. Verificar servidor local
echo "🖥️  2. Testando servidor local:"
if curl -s http://localhost:3000/health > /dev/null; then
    echo "   ✅ Servidor rodando em localhost:3000"
    curl -s http://localhost:3000/health | jq -r '"   Status: " + .status + " | Uptime: " + (.uptime | tostring) + "s"'
else
    echo "   ❌ Servidor NÃO está rodando em localhost:3000"
    echo "   💡 Execute: cd ../Roteiro1 && npm start"
fi
echo

# 3. Verificar servidor no IP da rede
echo "🌐 3. Testando servidor no IP da rede:"
if curl -s http://$current_ip:3000/health > /dev/null; then
    echo "   ✅ Servidor acessível em $current_ip:3000"
    curl -s http://$current_ip:3000/health | jq -r '"   Status: " + .status + " | Timestamp: " + .timestamp'
else
    echo "   ❌ Servidor NÃO acessível em $current_ip:3000"
    echo "   💡 Verifique firewall ou configuração de rede"
fi
echo

# 4. Verificar configuração no Flutter
echo "📱 4. Verificando configuração Flutter:"
api_service_file="task_manager/lib/services/api_service.dart"
if [ -f "$api_service_file" ]; then
    configured_ip=$(grep -o "http://[0-9.]*:3000" "$api_service_file" | head -1 | sed 's/http:\/\/\([0-9.]*\):3000/\1/')
    echo "   IP configurado no Flutter: $configured_ip"
    
    if [ "$configured_ip" = "$current_ip" ]; then
        echo "   ✅ IP está correto!"
    else
        echo "   ❌ IP INCORRETO! Deveria ser: $current_ip"
        echo "   💡 Execute: ./configurar_ip.sh"
    fi
else
    echo "   ❌ Arquivo api_service.dart não encontrado!"
fi
echo

# 5. Teste de conectividade do Flutter
echo "🔗 5. Testando endpoint das tasks:"
if curl -s http://$current_ip:3000/api/tasks > /dev/null; then
    echo "   ✅ Endpoint /api/tasks acessível"
    task_count=$(curl -s http://$current_ip:3000/api/tasks | jq '.data | length')
    echo "   📊 Tasks no servidor: $task_count"
else
    echo "   ❌ Endpoint /api/tasks NÃO acessível"
fi
echo

# 6. Instruções para resolver
echo "🔧 PRÓXIMOS PASSOS:"
echo "1. Se o servidor não estiver rodando:"
echo "   cd ../Roteiro1 && npm start"
echo
echo "2. Se o IP estiver incorreto:"
echo "   ./configurar_ip.sh"
echo
echo "3. No terminal do Flutter, faça HOT RELOAD:"
echo "   r"
echo
echo "4. Ou restart completo do Flutter:"
echo "   R"
echo
echo "5. Verificar logs do Flutter:"
echo "   Procure por '🌐 Conectado' ou '🌐 Servidor não acessível'"
echo

# 7. Informações adicionais
echo "ℹ️  INFORMAÇÕES ÚTEIS:"
echo "   • Servidor deve estar em: http://$current_ip:3000"
echo "   • Health check: curl http://$current_ip:3000/health"
echo "   • Tasks endpoint: curl http://$current_ip:3000/api/tasks"
echo "   • Flutter deve mostrar 'Online' após conectar"
echo