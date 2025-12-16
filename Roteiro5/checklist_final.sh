#!/bin/bash

echo "✅ CHECKLIST FINAL ANTES DA APRESENTAÇÃO"
echo "========================================"
echo

# Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

checks_passed=0
checks_total=0

# Função para checar
check() {
    checks_total=$((checks_total + 1))
    if eval "$2"; then
        echo -e "${GREEN}✅${NC} $1"
        checks_passed=$((checks_passed + 1))
        return 0
    else
        echo -e "${RED}❌${NC} $1"
        echo "   💡 $3"
        return 1
    fi
}

echo "🖥️  SERVIDOR"
check "Servidor rodando" \
      "curl -s http://localhost:3000/health > /dev/null 2>&1" \
      "Execute: cd Roteiro1 && node server.js &"

check "Endpoint tasks acessível" \
      "curl -s http://localhost:3000/api/tasks > /dev/null 2>&1" \
      "Verifique se o servidor está funcionando"

echo
echo "📱 DISPOSITIVO ANDROID"
check "Dispositivo conectado" \
      "adb devices | grep -q 'device$'" \
      "Conecte o dispositivo via USB e ative debug USB"

check "Port forwarding configurado" \
      "adb reverse --list 2>/dev/null | grep -q 'tcp:3000'" \
      "Execute: adb reverse tcp:3000 tcp:3000"

echo
echo "💾 BANCO DE DADOS"
check "Banco do servidor existe" \
      "[ -f '/home/kayler/Puc/Lab App Mov/Roteiro1/database/tasks.db' ]" \
      "O banco será criado automaticamente ao iniciar servidor"

tasks_count=$(sqlite3 "/home/kayler/Puc/Lab App Mov/Roteiro1/database/tasks.db" "SELECT COUNT(*) FROM tasks;" 2>/dev/null || echo "0")
echo "   📊 Tasks no servidor: $tasks_count"

echo
echo "🔧 FERRAMENTAS"
check "Flutter disponível" \
      "command -v flutter > /dev/null 2>&1" \
      "Instale Flutter SDK"

check "ADB disponível" \
      "command -v adb > /dev/null 2>&1" \
      "Instale: sudo apt install android-tools-adb"

check "Node.js disponível" \
      "command -v node > /dev/null 2>&1" \
      "Instale Node.js"

check "SQLite3 disponível" \
      "command -v sqlite3 > /dev/null 2>&1" \
      "Instale: sudo apt install sqlite3"

echo
echo "📱 APLICATIVO FLUTTER"
flutter_running=$(ps aux | grep -c "flutter run" || echo "0")
if [ "$flutter_running" -gt 1 ]; then
    echo -e "${GREEN}✅${NC} Flutter app rodando"
    checks_passed=$((checks_passed + 1))
else
    echo -e "${YELLOW}⚠️${NC}  Flutter app não iniciado"
    echo "   💡 Execute: flutter run -d fcdb13cf"
fi
checks_total=$((checks_total + 1))

echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "RESULTADO: ${GREEN}$checks_passed${NC}/$checks_total checks passaram"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

if [ "$checks_passed" -eq "$checks_total" ]; then
    echo -e "${GREEN}🎉 TUDO PRONTO PARA APRESENTAÇÃO!${NC}"
    echo
    echo "📖 Veja o roteiro: cat GUIA_DEMONSTRACAO.md"
else
    echo -e "${YELLOW}⚠️  Alguns itens precisam de atenção${NC}"
    echo
    echo "🔧 Para reiniciar tudo: ./DEMO_APRESENTACAO.sh"
fi
echo
