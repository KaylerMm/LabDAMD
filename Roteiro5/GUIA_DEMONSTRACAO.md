# 🎓 GUIA DE DEMONSTRAÇÃO - TASK MANAGER

## ✅ Sistema Preparado e Rodando!

### 📱 Iniciar Aplicativo Flutter

```bash
cd "/home/kayler/Puc/Lab App Mov/Roteiro5/task_manager"
flutter run -d fcdb13cf
```

---

## 🎯 ROTEIRO DE DEMONSTRAÇÃO (5-10 minutos)

### 1️⃣ **Introdução (1 min)**
- Aplicativo de gerenciamento de tarefas com sincronização
- Arquitetura cliente-servidor (REST API)
- Suporte offline com sincronização automática

### 2️⃣ **Demonstrar Status de Conectividade (1 min)**
- Mostrar status "Online" no app
- Explicar: app testa conectividade automaticamente
- Mostra quantas tasks estão não sincronizadas

### 3️⃣ **Criar Tasks Online (2 min)**
```
Criar tasks diretamente no app:
• "Tarefa 1 - Estudar Flutter"
• "Tarefa 2 - Desenvolver API"
• "Tarefa 3 - Fazer apresentação"
```

**Mostrar no terminal:**
```bash
curl -s http://localhost:3000/api/tasks | jq '.data | length'
```

### 4️⃣ **Marcar Tasks como Completas (1 min)**
- Marcar algumas tasks como completas
- Mostrar que sincroniza automaticamente
- Verificar contadores (Total, Completas, Pendentes)

### 5️⃣ **Demonstrar Modo Offline (2 min)**

**Simular offline:**
```bash
# Em outro terminal
kill <PID_DO_SERVIDOR>
```

- Mostrar status mudando para "Offline"
- Criar nova task offline
- Marcar task como completa offline
- Contador "Não Sync" aumenta

**Voltar online:**
```bash
cd "/home/kayler/Puc/Lab App Mov/Roteiro1"
node server.js &
```

- Mostrar sincronização automática
- Contador "Não Sync" volta a 0

### 6️⃣ **Comparar Dados (1-2 min)**

**Mostrar dados em ambos os bancos:**
```bash
cd "/home/kayler/Puc/Lab App Mov/Roteiro5"
./comparar_dados_completo.sh
```

Explicar:
- Dispositivo tem BD local (SQLite)
- Servidor tem BD próprio (SQLite)
- Sincronização bidirecional
- Tasks marcadas com `serverId` após sincronização

---

## 🔧 COMANDOS ÚTEIS DURANTE DEMO

### Ver tasks no servidor:
```bash
curl -s http://localhost:3000/api/tasks | jq
```

### Ver logs do servidor:
```bash
tail -f /tmp/server.log
```

### Hot reload no Flutter (após mudanças):
```
r
```

### Restart completo Flutter:
```
R
```

### Parar servidor:
```bash
kill <PID>
# Ou
pkill -f "node.*server.js"
```

---

## 🎨 PONTOS A DESTACAR

### ✅ Arquitetura
- **Cliente-Servidor REST** (HTTP/JSON)
- **Offline-first**: funciona sem conexão
- **Sincronização automática** quando volta online
- **Banco de dados local** (SQLite no dispositivo)

### ✅ Tecnologias
- **Backend**: Node.js + Express
- **Frontend**: Flutter + Dart
- **Database**: SQLite (local e servidor)
- **Comunicação**: REST API via HTTP

### ✅ Funcionalidades
- ✓ Criar, editar, deletar tasks
- ✓ Marcar como completa/incompleta
- ✓ Sincronização automática
- ✓ Trabalho offline
- ✓ Detecção de conectividade
- ✓ Contadores em tempo real

---

## 🐛 TROUBLESHOOTING

### App não conecta:
```bash
# Verificar ADB port forwarding
adb reverse tcp:3000 tcp:3000

# Fazer hot reload
r
```

### Servidor não inicia:
```bash
cd "/home/kayler/Puc/Lab App Mov/Roteiro1"
npm install
node server.js
```

### Resetar tudo para nova demo:
```bash
./DEMO_APRESENTACAO.sh
```

---

## 📊 ARQUIVOS IMPORTANTES

- `server.js` - Servidor REST API
- `lib/services/api_service.dart` - Cliente HTTP
- `lib/services/database_service.dart` - BD local
- `lib/services/task_service.dart` - Lógica de negócio
- `lib/screens/home_screen.dart` - Interface principal

---

**🎉 Boa sorte na apresentação!**
