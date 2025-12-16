#!/bin/bash

echo "🔍 VERIFICAÇÃO PRÉ-DEMO"
echo "======================"
echo ""

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

ERRORS=0

# 1. Docker
echo -n "1. Docker instalado... "
if command -v docker &> /dev/null; then
    echo -e "${GREEN}✅${NC}"
else
    echo -e "${RED}❌ Docker não encontrado${NC}"
    ((ERRORS++))
fi

# 2. Docker rodando
echo -n "2. Docker rodando... "
if docker ps &> /dev/null; then
    echo -e "${GREEN}✅${NC}"
else
    echo -e "${RED}❌ Docker não está rodando${NC}"
    ((ERRORS++))
fi

# 3. Node.js
echo -n "3. Node.js instalado... "
if command -v node &> /dev/null; then
    VERSION=$(node --version)
    echo -e "${GREEN}✅ ($VERSION)${NC}"
else
    echo -e "${RED}❌ Node.js não encontrado${NC}"
    ((ERRORS++))
fi

# 4. NPM
echo -n "4. npm instalado... "
if command -v npm &> /dev/null; then
    VERSION=$(npm --version)
    echo -e "${GREEN}✅ ($VERSION)${NC}"
else
    echo -e "${RED}❌ npm não encontrado${NC}"
    ((ERRORS++))
fi

# 5. ADB
echo -n "5. ADB instalado... "
if command -v adb &> /dev/null; then
    echo -e "${GREEN}✅${NC}"
else
    echo -e "${YELLOW}⚠️  ADB não encontrado (opcional)${NC}"
fi

# 6. Dispositivo Android
echo -n "6. Dispositivo Android conectado... "
DEVICES=$(adb devices | grep -v "List" | grep "device" | wc -l)
if [ "$DEVICES" -gt 0 ]; then
    echo -e "${GREEN}✅ ($DEVICES dispositivo(s))${NC}"
else
    echo -e "${YELLOW}⚠️  Nenhum dispositivo conectado${NC}"
fi

# 7. Dependências do servidor
echo -n "7. Dependências do servidor... "
if [ -d "server_simples/node_modules" ]; then
    echo -e "${GREEN}✅${NC}"
else
    echo -e "${RED}❌ Execute: cd server_simples && npm install${NC}"
    ((ERRORS++))
fi

# 8. Scripts executáveis
echo -n "8. Scripts executáveis... "
if [ -x "START_UPLOAD.sh" ] && [ -x "STOP_UPLOAD.sh" ] && [ -x "TEST_UPLOAD.sh" ]; then
    echo -e "${GREEN}✅${NC}"
else
    echo -e "${RED}❌ Execute: chmod +x *.sh${NC}"
    ((ERRORS++))
fi

# 9. docker-compose.yml
echo -n "9. docker-compose.yml... "
if [ -f "docker-compose.yml" ]; then
    echo -e "${GREEN}✅${NC}"
else
    echo -e "${RED}❌ Arquivo não encontrado${NC}"
    ((ERRORS++))
fi

# 10. init-aws.sh
echo -n "10. init-aws.sh... "
if [ -f "init-aws.sh" ]; then
    echo -e "${GREEN}✅${NC}"
else
    echo -e "${RED}❌ Arquivo não encontrado${NC}"
    ((ERRORS++))
fi

# 11. server_upload.js
echo -n "11. server_upload.js... "
if [ -f "server_simples/server_upload.js" ]; then
    echo -e "${GREEN}✅${NC}"
else
    echo -e "${RED}❌ Arquivo não encontrado${NC}"
    ((ERRORS++))
fi

# 12. Documentação
echo -n "12. Documentação completa... "
if [ -f "README_UPLOAD.md" ] && [ -f "ROTEIRO_APRESENTACAO.md" ]; then
    echo -e "${GREEN}✅${NC}"
else
    echo -e "${RED}❌ Arquivos de documentação faltando${NC}"
    ((ERRORS++))
fi

echo ""
echo "======================"

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✅ TUDO PRONTO PARA A DEMO!${NC}"
    echo ""
    echo "Próximos passos:"
    echo "1. ./START_UPLOAD.sh    # Iniciar sistema"
    echo "2. ./TEST_UPLOAD.sh     # Testar"
    echo "3. Abrir app Flutter    # Testar upload"
    echo ""
    echo -e "${GREEN}BOA SORTE! 🍀${NC}"
    exit 0
else
    echo -e "${RED}❌ $ERRORS ERRO(S) ENCONTRADO(S)${NC}"
    echo ""
    echo "Corrija os erros acima antes de prosseguir."
    exit 1
fi
