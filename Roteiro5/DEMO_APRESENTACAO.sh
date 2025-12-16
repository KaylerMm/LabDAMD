#!/bin/bash

echo "🎓 PREPARAÇÃO PARA DEMONSTRAÇÃO - TASK MANAGER"
echo "=============================================="
echo

# Cores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. Parar processos anteriores
echo -e "${BLUE}1️⃣ Limpando processos anteriores...${NC}"
pkill -f "node.*server.js" 2>/dev/null || true
pkill -f "flutter run" 2>/dev/null || true
sleep 2
echo -e "${GREEN}   ✅ Processos limpos${NC}"
echo

# 2. Verificar servidor
echo -e "${BLUE}2️⃣ Preparando servidor Node.js...${NC}"
cd "/home/kayler/Puc/Lab App Mov/Roteiro1"

if [ ! -d "node_modules" ]; then
    echo "   Instalando dependências..."
    npm install
fi

# Limpar banco de dados para demonstração limpa
rm -f database/tasks.db
echo -e "${GREEN}   ✅ Banco de dados resetado${NC}"
echo

# 3. Iniciar servidor em background
echo -e "${BLUE}3️⃣ Iniciando servidor...${NC}"
node server.js > /tmp/server.log 2>&1 &
SERVER_PID=$!
sleep 3

# Verificar se servidor está rodando
if curl -s http://localhost:3000/health > /dev/null; then
    network_ip=$(ip route get 1.1.1.1 | grep -oP 'src \K\S+' | head -1)
    echo -e "${GREEN}   ✅ Servidor rodando!${NC}"
    echo "      Local: http://localhost:3000"
    echo "      Rede:  http://$network_ip:3000"
else
    echo -e "${YELLOW}   ⚠️  Servidor não respondeu, verificando...${NC}"
    tail -5 /tmp/server.log
fi
echo

# 4. Configurar ADB port forwarding
echo -e "${BLUE}4️⃣ Configurando ADB port forwarding...${NC}"
cd "/home/kayler/Puc/Lab App Mov/Roteiro5"

if command -v adb &> /dev/null; then
    device_count=$(adb devices | grep -c "device$")
    
    if [ "$device_count" -gt 0 ]; then
        adb reverse tcp:3000 tcp:3000
        echo -e "${GREEN}   ✅ Port forwarding configurado${NC}"
    else
        echo -e "${YELLOW}   ⚠️  Nenhum dispositivo Android conectado${NC}"
        echo "      Conecte o dispositivo via USB para a demonstração"
    fi
else
    echo -e "${YELLOW}   ⚠️  ADB não disponível${NC}"
fi
echo

# 5. Verificar Flutter
echo -e "${BLUE}5️⃣ Verificando Flutter...${NC}"
cd task_manager

# Limpar build anterior
flutter clean > /dev/null 2>&1
flutter pub get > /dev/null 2>&1

echo -e "${GREEN}   ✅ Flutter pronto${NC}"
echo

# 6. Listar dispositivos disponíveis
echo -e "${BLUE}6️⃣ Dispositivos disponíveis:${NC}"
flutter devices

echo
echo -e "${GREEN}✅ SISTEMA PRONTO PARA DEMONSTRAÇÃO!${NC}"
echo
echo -e "${BLUE}📋 PRÓXIMOS PASSOS PARA DEMONSTRAÇÃO:${NC}"
echo
echo "1️⃣  Iniciar o app Flutter:"
echo "   ${YELLOW}flutter run -d fcdb13cf${NC}  (ou escolha outro device)"
echo
echo "2️⃣  Demonstrar funcionalidades:"
echo "   • Status Online/Offline"
echo "   • Criar tasks"
echo "   • Marcar como completas"
echo "   • Sincronização automática"
echo
echo "3️⃣  Verificar dados no servidor:"
echo "   ${YELLOW}curl http://localhost:3000/api/tasks${NC}"
echo
echo "4️⃣  Comparar dados (servidor vs dispositivo):"
echo "   ${YELLOW}./comparar_dados_completo.sh${NC}"
echo
echo "5️⃣  Para parar o servidor:"
echo "   ${YELLOW}kill $SERVER_PID${NC}"
echo
echo -e "${BLUE}📊 Logs do servidor:${NC} tail -f /tmp/server.log"
echo
echo "🎉 Boa apresentação!"
