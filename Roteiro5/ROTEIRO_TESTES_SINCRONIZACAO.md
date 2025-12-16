# Roteiro de Testes - Sincronização de Tarefas

Este roteiro permite testar completamente o fluxo de sincronização entre o aplicativo Flutter no celular e o servidor REST no computador.

## 📋 Pré-requisitos

- Android Studio ou VS Code com Flutter
- Dispositivo Android conectado via USB (com depuração USB ativada)
- Node.js instalado
- SQLite3 instalado (`sudo apt install sqlite3` no Ubuntu/Debian)

## 🔧 Passo 0: Configurar IP do Servidor

### 0.1. Descobrir o IP da máquina
```bash
ip route get 1.1.1.1 | grep -oP 'src \K\S+' | head -1
```

### 0.2. Atualizar IP no código do Flutter
Edite o arquivo `task_manager/lib/services/api_service.dart`:
```dart
class ApiService {
  static const String baseUrl = 'http://SEU_IP_AQUI:3000/api';
```

### 0.3. Testar conectividade
```bash
curl http://SEU_IP_AQUI:3000/health
```

## 🚀 Passo 1: Inicializar o Servidor REST (Roteiro1)

### 1.1. Navegar para o diretório do servidor
```bash
cd "/home/kayler/Puc/Lab App Mov/Roteiro1"
```

### 1.2. Instalar dependências (se necessário)
```bash
npm install
```

### 1.3. Verificar se o banco de dados existe
```bash
sqlite3 database/tasks.db ".tables"
```
**Resultado esperado:** `tasks  users`

### 1.4. Limpar tarefas existentes (opcional - para teste limpo)
```bash
sqlite3 database/tasks.db "DELETE FROM tasks;"
```

### 1.5. Iniciar o servidor REST
```bash
node server.js
```
**Resultado esperado:** 
```
🚀 Servidor iniciado na porta 3000
📊 Endpoints disponíveis:
  - Health: GET /health
  - Auth: POST /api/auth/login, POST /api/auth/register
  - Tasks: GET /api/tasks, POST /api/tasks, PUT /api/tasks/:id, DELETE /api/tasks/:id
```

### 1.6. Testar conectividade do servidor (em outro terminal)
```bash
curl http://localhost:3000/health
```
**Resultado esperado:** `{"status":"ok","service":"Task Management API"}`

## 📱 Passo 2: Inicializar o Aplicativo Flutter

### 2.1. Navegar para o diretório do app (em novo terminal)
```bash
cd "/home/kayler/Puc/Lab App Mov/Roteiro5/task_manager"
```

### 2.2. Verificar dispositivos conectados
```bash
flutter devices
```

### 2.3. Executar o aplicativo
```bash
flutter run
```

### 2.4. Verificar conectividade no app
- Observe os logs do Flutter para confirmar:
  - `🌐 Conectado - servidor acessível`
  - `📱 Inicializando database em: /data/user/0/com.example.task_manager/databases/task_manager_v2.db`

## 🧪 Passo 3: Testes de Sincronização

### 3.1. Verificar Estado Inicial

#### No computador (banco do servidor):
```bash
sqlite3 "/home/kayler/Puc/Lab App Mov/Roteiro1/database/tasks.db" -header -column "
SELECT 
  COUNT(*) as total_servidor,
  SUM(CASE WHEN completed = 1 THEN 1 ELSE 0 END) as completas_servidor,
  SUM(CASE WHEN completed = 0 THEN 1 ELSE 0 END) as pendentes_servidor
FROM tasks;"
```

#### No celular (banco local):
```bash
# Extrair banco do celular
adb shell "run-as com.example.task_manager cat /data/data/com.example.task_manager/databases/task_manager_v2.db" > /tmp/task_manager_celular.db

# Verificar contadores
sqlite3 /tmp/task_manager_celular.db -header "
SELECT 
  COUNT(*) as total_celular,
  SUM(CASE WHEN completed = 1 THEN 1 ELSE 0 END) as completas_celular,
  SUM(CASE WHEN completed = 0 THEN 1 ELSE 0 END) as pendentes_celular,
  SUM(CASE WHEN needsSync = 1 THEN 1 ELSE 0 END) as nao_sincronizadas
FROM tasks;"
```

### 3.2. Teste 1 - Criar Nova Tarefa

#### No aplicativo Flutter:
1. Toque no botão **+** (FloatingActionButton)
2. Digite o título: `"Teste Sync 1"`
3. Digite a descrição: `"Primeira tarefa de teste"`
4. Toque em **Salvar**

#### Verificar nos logs do Flutter:
```
✅ Task inserida: Teste Sync 1 (ID: [timestamp])
✅ Task adicionada: Teste Sync 1 (ID: [timestamp])
📋 X tasks carregadas
🔄 Iniciando sincronização...
📤 Sincronizando 1 tasks locais...
✅ Task marcada como sincronizada: [localId] -> [serverId]
✅ Task criada no servidor: Teste Sync 1 -> [serverId]
```

#### Verificar no banco do servidor:
```bash
sqlite3 "/home/kayler/Puc/Lab App Mov/Roteiro1/database/tasks.db" -header -column "
SELECT id, title, description, completed, createdAt 
FROM tasks 
ORDER BY createdAt DESC 
LIMIT 3;"
```

#### Verificar no banco do celular:
```bash
adb shell "run-as com.example.task_manager cat /data/data/com.example.task_manager/databases/task_manager_v2.db" > /tmp/task_manager_celular.db
sqlite3 /tmp/task_manager_celular.db -header -column "
SELECT id, title, needsSync, serverId 
FROM tasks 
ORDER BY createdAt DESC 
LIMIT 3;"
```

**Resultado esperado:** 
- ✅ Tarefa aparece em ambos os bancos
- ✅ `needsSync = 0` no celular (sincronizada)
- ✅ `serverId` preenchido no celular

### 3.3. Teste 2 - Marcar Tarefa como Completa

#### No aplicativo Flutter:
1. Toque no **checkbox** da tarefa "Teste Sync 1"
2. Observe que a tarefa fica riscada

#### Verificar nos logs do Flutter:
```
✅ Task atualizada: Teste Sync 1
📋 X tasks carregadas
🔄 Iniciando sincronização...
📤 Sincronizando 1 tasks locais...
✅ Task atualizada no servidor: Teste Sync 1
```

#### Verificar no banco do servidor:
```bash
sqlite3 "/home/kayler/Puc/Lab App Mov/Roteiro1/database/tasks.db" -header -column "
SELECT title, completed, createdAt 
FROM tasks 
WHERE title LIKE '%Teste Sync%' 
ORDER BY createdAt DESC;"
```

#### Verificar no banco do celular:
```bash
adb shell "run-as com.example.task_manager cat /data/data/com.example.task_manager/databases/task_manager_v2.db" > /tmp/task_manager_celular.db
sqlite3 /tmp/task_manager_celular.db -header -column "
SELECT title, completed, needsSync 
FROM tasks 
WHERE title LIKE '%Teste Sync%' 
ORDER BY createdAt DESC;"
```

**Resultado esperado:** 
- ✅ `completed = 1` em ambos os bancos
- ✅ `needsSync = 0` no celular (sincronizada)

### 3.4. Teste 3 - Criar Tarefa Offline (Simulado)

#### Simular offline (desconectar WiFi/dados ou usar modo avião):
1. Ative o modo avião no celular
2. No app, crie nova tarefa: `"Teste Offline"`
3. Observe o indicador mostrando "Offline"

#### Verificar nos logs do Flutter:
```
📱 Offline - não é possível sincronizar agora
```

#### Verificar no banco do celular:
```bash
adb shell "run-as com.example.task_manager cat /data/data/com.example.task_manager/databases/task_manager_v2.db" > /tmp/task_manager_celular.db
sqlite3 /tmp/task_manager_celular.db -header -column "
SELECT title, needsSync, serverId 
FROM tasks 
WHERE title = 'Teste Offline';"
```

**Resultado esperado:** 
- ✅ `needsSync = 1` (não sincronizada)
- ✅ `serverId = null` (não tem ID do servidor)

#### Reativar conexão:
1. Desative o modo avião
2. Toque no botão de sincronização no app
3. Observe a sincronização automática

#### Verificar sincronização:
```bash
# No servidor
sqlite3 "/home/kayler/Puc/Lab App Mov/Roteiro1/database/tasks.db" -header -column "
SELECT title, completed 
FROM tasks 
WHERE title = 'Teste Offline';"

# No celular
adb shell "run-as com.example.task_manager cat /data/data/com.example.task_manager/databases/task_manager_v2.db" > /tmp/task_manager_celular.db
sqlite3 /tmp/task_manager_celular.db -header -column "
SELECT title, needsSync, serverId 
FROM tasks 
WHERE title = 'Teste Offline';"
```

### 3.5. Teste 4 - Editar Tarefa

#### No aplicativo Flutter:
1. Toque no menu ⋮ de uma tarefa
2. Selecione **Editar**
3. Altere o título para: `"Teste Editado"`
4. Toque em **Salvar**

#### Verificar sincronização nos bancos (usar comandos dos testes anteriores)

### 3.6. Teste 5 - Deletar Tarefa

#### No aplicativo Flutter:
1. Toque no menu ⋮ de uma tarefa
2. Selecione **Excluir**
3. Confirme a exclusão

#### Verificar nos logs do Flutter:
```
✅ Task removida: [título]
📤 Task deletada do servidor: [serverId]
```

#### Verificar remoção nos bancos:
```bash
# Contar tarefas no servidor
sqlite3 "/home/kayler/Puc/Lab App Mov/Roteiro1/database/tasks.db" "SELECT COUNT(*) FROM tasks;"

# Contar tarefas no celular
adb shell "run-as com.example.task_manager cat /data/data/com.example.task_manager/databases/task_manager_v2.db" > /tmp/task_manager_celular.db
sqlite3 /tmp/task_manager_celular.db "SELECT COUNT(*) FROM tasks;"
```

## 📊 Passo 4: Verificação Final dos Contadores

### 4.1. Contadores no Aplicativo
Observe na tela principal do app:
- **Total**: X tarefas
- **Pendentes**: Y tarefas (não completas)
- **Completas**: Z tarefas (marcadas como completas)
- **Não Sync**: W tarefas (pendentes que precisam sincronizar)

### 4.2. Contadores no Banco do Servidor
```bash
sqlite3 "/home/kayler/Puc/Lab App Mov/Roteiro1/database/tasks.db" -header "
SELECT 
  COUNT(*) as total_servidor,
  SUM(CASE WHEN completed = 1 THEN 1 ELSE 0 END) as completas_servidor,
  SUM(CASE WHEN completed = 0 THEN 1 ELSE 0 END) as pendentes_servidor
FROM tasks;"
```

### 4.3. Contadores no Banco do Celular
```bash
adb shell "run-as com.example.task_manager cat /data/data/com.example.task_manager/databases/task_manager_v2.db" > /tmp/task_manager_celular.db
sqlite3 /tmp/task_manager_celular.db -header "
SELECT 
  COUNT(*) as total_celular,
  SUM(CASE WHEN completed = 1 THEN 1 ELSE 0 END) as completas_celular,
  SUM(CASE WHEN completed = 0 THEN 1 ELSE 0 END) as pendentes_celular,
  SUM(CASE WHEN needsSync = 1 THEN 1 ELSE 0 END) as nao_sincronizadas,
  SUM(CASE WHEN completed = 0 AND needsSync = 1 THEN 1 ELSE 0 END) as pendentes_nao_sync
FROM tasks;"
```

## ✅ Critérios de Sucesso

Para que o teste seja considerado bem-sucedido:

1. **✅ Conectividade**: App mostra "Online" quando conectado
2. **✅ Criação**: Tarefas criadas no app aparecem no banco do servidor
3. **✅ Sincronização**: `needsSync = 0` após sincronização bem-sucedida
4. **✅ Atualização**: Mudanças (completed, edição) refletem em ambos os bancos
5. **✅ Exclusão**: Tarefas deletadas somem de ambos os bancos
6. **✅ Offline**: App funciona offline e sincroniza quando volta online
7. **✅ Contadores**: Números do app coincidem com os bancos

## 🐛 Solução de Problemas

### Problema: App mostra "Offline" ou "TimeoutException"
```bash
# 1. Verificar se servidor está rodando
curl http://localhost:3000/health

# 2. Descobrir IP atual da máquina
IP_ATUAL=$(ip route get 1.1.1.1 | grep -oP 'src \K\S+' | head -1)
echo "IP atual: $IP_ATUAL"

# 3. Testar servidor no IP da rede local
curl http://$IP_ATUAL:3000/health

# 4. Atualizar IP no código Flutter
# Arquivo: task_manager/lib/services/api_service.dart
# Linha: static const String baseUrl = 'http://SEU_IP_ATUAL:3000/api';

# 5. Fazer hot reload no Flutter após alterar o IP
# No terminal do Flutter, digite: r
```

### Problema: Erro de sincronização
```bash
# Verificar logs do servidor no terminal onde rodou 'node server.js'
# Verificar logs do Flutter no terminal onde rodou 'flutter run'
```

### Problema: Banco não encontrado
```bash
# Verificar se dispositivo está conectado
adb devices

# Verificar se app está instalado
adb shell pm list packages | grep task_manager
```

## 📝 Relatório de Teste

Ao final dos testes, documente:

- ✅/❌ Criação de tarefas
- ✅/❌ Sincronização automática
- ✅/❌ Marcação como completa
- ✅/❌ Edição de tarefas
- ✅/❌ Exclusão de tarefas
- ✅/❌ Funcionamento offline
- ✅/❌ Consistência de contadores
- ✅/❌ Integridade dos dados nos bancos

---

**Nota**: Este roteiro assume que o servidor REST (Roteiro1) está sendo usado como backend. Se estiver usando outro backend, ajuste os comandos de verificação de banco correspondentemente.