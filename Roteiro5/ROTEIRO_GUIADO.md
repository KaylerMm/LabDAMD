# 🚀 Roteiro Guiado - Sistema de Mensageria RabbitMQ

## 📋 Pré-requisitos
- [ ] Node.js instalado
- [ ] Docker e Docker Compose instalados
- [ ] Terminal/prompt de comando
- [ ] Navegador web

---

## 🎯 FASE 1: Preparação do Ambiente

### 1.1 Navegar para o projeto
```bash
cd "/home/kayler/Puc/Lab App Mov/Roteiro5"
```

### 1.2 Verificar arquivos
```bash
ls -la
```
**✅ Esperado:** Ver pastas `services/`, `consumers/`, `api-gateway/`, `shared/` e arquivos como `docker-compose.yml`, `package.json`

### 1.3 Instalar dependências
```bash
npm install
```
**✅ Esperado:** Instalação sem erros, criação da pasta `node_modules/`

---

## 🐳 FASE 2: Infraestrutura (RabbitMQ + MongoDB)

### 2.1 Iniciar containers
```bash
docker compose up -d
```
**✅ Esperado:** 
```
✔ Container mongodb   Started
✔ Container rabbitmq  Started
```

### 2.2 Verificar containers
```bash
docker compose ps
```
**✅ Esperado:** Ambos containers com status "Up"
cd "/home/kayler/Puc/Lab App Mov/Roteiro5"
### 2.3 Testar RabbitMQ Management
Abra no navegador: http://localhost:15672
- **Login:** admin
- **Senha:** admin123

**✅ Esperado:** Dashboard do RabbitMQ carregando com 0 filas, 0 exchanges (além dos padrão)

---

## 🏗️ FASE 3: Microsserviços (6 Terminais)

> **📝 Dica:** Abra 6 terminais separados para cada serviço

### Terminal 1 - User Service
```bash
cd "/home/kayler/Puc/Lab App Mov/Roteiro5"
node services/user-service/server.js
```
**✅ Esperado:**
```
Connected to MongoDB
User Service running on port 3001
```

### Terminal 2 - Item Service
```bash
cd "/home/kayler/Puc/Lab App Mov/Roteiro5"
node services/item-service/server.js
```
**✅ Esperado:**
```
Connected to MongoDB
Item Service running on port 3003
```

### Terminal 3 - List Service (Publisher RabbitMQ)
```bash
cd "/home/kayler/Puc/Lab App Mov/Roteiro5"
node services/list-service/server.js
```
**✅ Esperado:**
```
Connected to MongoDB
Connected to RabbitMQ
List Service running on port 3002
```

### Terminal 4 - API Gateway
```bash
cd "/home/kayler/Puc/Lab App Mov/Roteiro5"
node api-gateway/server.js
```
**✅ Esperado:**
```
API Gateway running on port 3000
Service endpoints:
  user: http://localhost:3001
  list: http://localhost:3002
  item: http://localhost:3003
```

### Terminal 5 - Notification Consumer
```bash
cd "/home/kayler/Puc/Lab App Mov/Roteiro5"
node consumers/notification-consumer.js
```
**✅ Esperado:**
```
Connected to RabbitMQ
Notification Consumer started
Listening for checkout events...
```

### Terminal 6 - Analytics Consumer
```bash
cd "/home/kayler/Puc/Lab App Mov/Roteiro5"
node consumers/analytics-consumer.js
```
**✅ Esperado:**
```
Connected to RabbitMQ
Analytics Consumer started
Listening for checkout events for analytics...
```

---

## ✅ FASE 4: Verificação de Saúde

### 4.1 Testar API Gateway
```bash
curl http://localhost:3000/health
```
**✅ Esperado:** JSON com todos os serviços "ok"

### 4.2 Verificar RabbitMQ (Atualizar página)
No navegador, atualize http://localhost:15672
**✅ Esperado:** 
- **Connections:** 3 (List Service + 2 Consumers)
- **Queues:** 2 (notifications, analytics)
- **Exchanges:** 1 (shopping_events) além dos padrão

---

## 🧪 FASE 5: Teste Automatizado

### 5.1 Executar teste completo
Em um novo terminal:
```bash
cd "/home/kayler/Puc/Lab App Mov/Roteiro5"
node test-checkout.js
```

**✅ Esperado:**
```
🧪 Testing Shopping List Checkout Flow
=====================================
1. Creating test user...
✓ User created: [USER_ID]
2. Creating test items...
✓ Items created: Bread, Cheese
3. Creating shopping list...
✓ List created: [LIST_ID]
4. Adding items to list...
✓ Items added to list
5. Performing checkout...
✅ Checkout completed!
   Response time: ~15ms
   Status: 202 Accepted
   Message: Checkout initiated successfully
```

### 5.2 Verificar outputs dos consumers

**Terminal 5 (Notification Consumer):**
```
Processing checkout notification: {...}
📧 Sending receipt for list [LIST_ID] to user [EMAIL]
   - Total amount: $13.47
   - Items count: 2
   - Completed at: [TIMESTAMP]
✅ Receipt sent successfully to [EMAIL]
```

**Terminal 6 (Analytics Consumer):**
```
Processing checkout analytics: {...}
📊 Analytics updated:
   - Order value: $13.47
   - Items purchased: 2
   - Daily revenue: $13.47
   - Orders today: 1
   - Average order: $13.47
✅ Dashboard updated successfully
```

---

## 📊 FASE 6: Verificação RabbitMQ

### 6.1 Verificar estatísticas via API
```bash
curl -s http://admin:admin123@localhost:15672/api/overview | grep -o '"publish":[0-9]*'
```
**✅ Esperado:** `"publish":1` (1 mensagem publicada)

```bash
curl -s http://admin:admin123@localhost:15672/api/overview | grep -o '"deliver":[0-9]*'
```
**✅ Esperado:** `"deliver":2` (2 entregas - uma para cada consumer)

### 6.2 Verificar filas
```bash
curl -s http://admin:admin123@localhost:15672/api/queues | grep -o '"name":"[^"]*"'
```
**✅ Esperado:** 
```
"name":"analytics"
"name":"notifications"
```

---

## 🎬 FASE 7: Demonstração Manual

### 7.1 Criar usuário
```bash
curl -X POST http://localhost:3000/users \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Demo User",
    "email": "demo@example.com"
  }'
```
**✅ Anote o `_id` retornado**

### 7.2 Criar produtos
```bash
curl -X POST http://localhost:3000/items \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Notebook",
    "price": 2499.99,
    "category": "Electronics"
  }'
```
**✅ Anote o `_id` retornado**

```bash
curl -X POST http://localhost:3000/items \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Mouse",
    "price": 89.99,
    "category": "Electronics"
  }'
```
**✅ Anote o `_id` retornado**

### 7.3 Criar lista de compras
```bash
curl -X POST http://localhost:3000/lists \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Compras de Tecnologia",
    "userId": "SEU_USER_ID_AQUI"
  }'
```
**✅ Anote o `_id` retornado**

### 7.4 Adicionar itens à lista
```bash
curl -X POST http://localhost:3000/lists/692503247ec94f171ad506e7/items \
  -H "Content-Type: application/json" \
  -d '{
    "itemId": "692502f1cb0e1ef9dffb741f",
    "name": "Notebook",
    "quantity": 1,
    "price": 2499.99
  }'
```

```bash
curl -X POST http://localhost:3000/lists/SEU_LIST_ID/items \
  -H "Content-Type: application/json" \
  -d '{
    "itemId": "SEU_ITEM_ID_MOUSE", 
    "name": "Mouse",
    "quantity": 2,
    "price": 89.99
  }'
```

### 7.5 🚨 MOMENTO DA VERDADE - CHECKOUT
```bash
curl -X POST http://localhost:3000/lists/692503247ec94f171ad506e7/checkout
```

**✅ Observe:**
1. **Resposta rápida:** 202 Accepted
2. **Terminal 5:** Log de email instantâneo
3. **Terminal 6:** Atualização de analytics
4. **RabbitMQ Management:** Gráficos de mensagens

---

## 🔧 FASE 8: Testes Adicionais

### 8.1 Teste de múltiplos checkouts
Execute o checkout 3 vezes seguidas e observe:
- Analytics acumulando receita
- Notification enviando emails diferentes
- RabbitMQ processando mensagens

### 8.2 Teste de falha de consumer
1. Pare um consumer (Ctrl+C no terminal)
2. Execute checkout
3. Observe mensagens acumulando na fila
4. Reinicie o consumer
5. Veja mensagens sendo processadas

---

## 📈 FASE 9: Monitoramento

### 9.1 RabbitMQ Management Dashboard
- **Overview:** Estatísticas gerais
- **Connections:** Ver conexões ativas
- **Channels:** Canais de comunicação
- **Exchanges:** Exchange `shopping_events`
- **Queues:** Filas `notifications` e `analytics`

### 9.2 Verificar mensagens nas filas
No RabbitMQ Management:
1. Clique em uma fila
2. Vá para "Get messages"
3. Clique "Get Message(s)" para ver conteúdo

---

## 🛑 FASE 10: Limpeza

### 10.1 Parar serviços
Pressione `Ctrl+C` em cada terminal dos serviços

### 10.2 Parar containers
```bash
docker compose down
```

### 10.3 Script automático de limpeza
```bash
./stop-demo.sh
```

---

## 🎯 Checklist de Validação

**Infraestrutura:**
- [ ] RabbitMQ rodando e acessível
- [ ] MongoDB conectado
- [ ] Containers estáveis

**Serviços:**
- [ ] User Service (3001) respondendo
- [ ] Item Service (3003) respondendo  
- [ ] List Service (3002) + RabbitMQ
- [ ] API Gateway (3000) funcionando

**Mensageria:**
- [ ] Exchange `shopping_events` criado
- [ ] Filas `notifications` e `analytics` criadas
- [ ] Consumers conectados e escutando
- [ ] Mensagens sendo publicadas/consumidas

**Funcionalidades:**
- [ ] CRUD de usuários
- [ ] CRUD de itens
- [ ] CRUD de listas
- [ ] Checkout com resposta 202
- [ ] Email simulado enviado
- [ ] Analytics atualizadas

**Performance:**
- [ ] Checkout < 50ms
- [ ] Consumers processando instantaneamente
- [ ] Zero mensagens em fila após processamento

---

## 🚨 Troubleshooting

**Erro de porta ocupada:**
```bash
lsof -i :3000  # Verificar processo na porta
kill -9 PID    # Matar processo se necessário
```

**RabbitMQ não conecta:**
```bash
docker compose logs rabbitmq
```

**MongoDB não conecta:**
```bash
docker compose logs mongodb
```

**Consumer não processa:**
- Verificar se está escutando a fila correta
- Verificar credenciais do RabbitMQ
- Verificar logs de erro

---

## 🎉 Sucesso!

Se todos os checkpoints passaram, você tem um sistema de mensageria completo e funcional seguindo as melhores práticas de microsserviços com RabbitMQ!