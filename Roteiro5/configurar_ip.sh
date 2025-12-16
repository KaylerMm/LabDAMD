#!/bin/bash

# Script para configurar automaticamente o IP correto no aplicativo Flutter
# Resolve o problema comum de IP desatualizado no código

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 Configurador de IP - Task Manager${NC}"
echo "======================================"

# Descobrir IP atual da máquina
IP_ATUAL=$(ip route get 1.1.1.1 | grep -oP 'src \K\S+' | head -1)
echo -e "${YELLOW}📍 IP atual da máquina: ${BLUE}$IP_ATUAL${NC}"

# Arquivo do API Service
API_FILE="task_manager/lib/services/api_service.dart"

# Verificar se arquivo existe
if [ ! -f "$API_FILE" ]; then
    echo -e "${RED}❌ Arquivo não encontrado: $API_FILE${NC}"
    echo "   Execute este script do diretório Roteiro5"
    exit 1
fi

# Obter IP atual no código
IP_CODIGO=$(grep -oP "http://\K[^:]*" "$API_FILE" | head -1)
echo -e "${YELLOW}📱 IP no código Flutter: ${BLUE}$IP_CODIGO${NC}"

# Verificar se precisa atualizar
if [ "$IP_ATUAL" == "$IP_CODIGO" ]; then
    echo -e "${GREEN}✅ IP já está correto no código!${NC}"
else
    echo -e "${YELLOW}🔄 Atualizando IP no código...${NC}"
    
    # Fazer backup do arquivo
    cp "$API_FILE" "$API_FILE.bak"
    echo -e "${GREEN}📦 Backup criado: $API_FILE.bak${NC}"
    
    # Atualizar IP
    sed -i "s|http://$IP_CODIGO:3000/api|http://$IP_ATUAL:3000/api|g" "$API_FILE"
    
    echo -e "${GREEN}✅ IP atualizado de $IP_CODIGO para $IP_ATUAL${NC}"
fi

echo
echo -e "${YELLOW}🧪 Testando conectividade...${NC}"

# Testar servidor local
if curl -s http://localhost:3000/health > /dev/null; then
    echo -e "${GREEN}✅ Servidor respondendo em localhost:3000${NC}"
else
    echo -e "${RED}❌ Servidor não está rodando em localhost:3000${NC}"
    echo "   Inicie com: cd ../Roteiro1 && node server.js"
fi

# Testar servidor no IP da rede
if curl -s "http://$IP_ATUAL:3000/health" > /dev/null; then
    echo -e "${GREEN}✅ Servidor acessível no IP da rede: $IP_ATUAL:3000${NC}"
else
    echo -e "${RED}❌ Servidor não acessível no IP da rede: $IP_ATUAL:3000${NC}"
    echo "   Verifique firewall ou configuração de rede"
fi

echo
echo -e "${YELLOW}📋 Próximos passos:${NC}"

if [ "$IP_ATUAL" != "$IP_CODIGO" ]; then
    echo -e "${BLUE}1.${NC} Fazer hot reload no Flutter (digite 'r' no terminal do Flutter)"
    echo -e "${BLUE}2.${NC} Ou reiniciar o aplicativo com: flutter run"
fi

echo -e "${BLUE}3.${NC} Verificar se o app mostra 'Online' no canto superior direito"
echo -e "${BLUE}4.${NC} Testar criação de tarefas para confirmar sincronização"

echo
echo -e "${GREEN}🎉 Configuração concluída!${NC}"