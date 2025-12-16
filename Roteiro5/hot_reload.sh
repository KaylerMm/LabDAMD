#!/bin/bash

echo "🔄 FAZENDO HOT RELOAD NO FLUTTER..."
echo

# Encontrar o PID do processo flutter
flutter_pid=$(ps aux | grep "flutter run" | grep -v grep | awk '{print $2}' | head -1)

if [ -z "$flutter_pid" ]; then
    echo "❌ Flutter não está rodando"
    echo "   Execute: cd task_manager && flutter run -d fcdb13cf"
    exit 1
fi

echo "Flutter PID: $flutter_pid"
echo "Enviando comando 'r' (hot reload)..."

# Tentar enviar 'r' para o processo do flutter
# Isso funciona se o flutter estiver rodando em um terminal interativo
echo "r" > /proc/$flutter_pid/fd/0 2>/dev/null || echo "⚠️  Não foi possível enviar comando automaticamente"

echo
echo "✅ Comando enviado!"
echo
echo "💡 Se não funcionou automaticamente:"
echo "   1. Vá ao terminal onde o Flutter está rodando"
echo "   2. Pressione a tecla 'r'"
echo
