# 📚 Comandos de Teste Manual

## 🔧 Setup Inicial
```bash
# Navegar para o projeto
cd "/home/kayler/Puc/Lab App Mov/Roteiro5"

# Setup automático
./setup-demo.sh

# OU manual:
docker compose up -d
npm install
```

## 🚀 Iniciar Serviços (6 terminais)

### Terminal 1 - User Service
```bash
cd "/home/kayler/Puc/Lab App Mov/Roteiro5" && node services/user-service/server.js
```

### Terminal 2 - Item Service  
```bash
cd "/home/kayler/Puc/Lab App Mov/Roteiro5" && node services/item-service/server.js
```

### Terminal 3 - List Service (Publisher)
```bash
cd "/home/kayler/Puc/Lab App Mov/Roteiro5" && node services/list-service/server.js
```

### Terminal 4 - API Gateway
```bash
cd "/home/kayler/Puc/Lab App Mov/Roteiro5" && node api-gateway/server.js
```

### Terminal 5 - Notification Consumer
```bash
cd "/home/kayler/Puc/Lab App Mov/Roteiro5" && node consumers/notification-consumer.js
```

### Terminal 6 - Analytics Consumer
```bash
cd "/home/kayler/Puc/Lab App Mov/Roteiro5" && node consumers/analytics-consumer.js
```

## ✅ Validação Rápida
```bash
./validacao-rapida.sh
```

## 🧪 Teste Automático Completo
```bash
node test-checkout.js
```

## 🌐 URLs de Monitoramento
- **RabbitMQ Management**: http://localhost:15672 (admin/admin123)
- **API Gateway Health**: http://localhost:3000/health

## 📊 Verificação RabbitMQ via curl

### Estatísticas gerais
```bash
curl -s http://admin:admin123@localhost:15672/api/overview | grep -E '"publish":[0-9]*|"deliver":[0-9]*'
```

### Listar filas
```bash
curl -s http://admin:admin123@localhost:15672/api/queues | grep -o '"name":"[^"]*"'
```

### Conexões ativas
```bash
curl -s http://admin:admin123@localhost:15672/api/connections | grep -o '"name":"[^"]*"'
```

## 🎯 Teste Manual Passo-a-Passo

### 1. Criar usuário
```bash
curl -X POST http://localhost:3000/users \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Teste User",
    "email": "teste@example.com"
  }'
```

### 2. Criar itens
```bash
curl -X POST http://localhost:3000/items \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Produto Teste",
    "price": 29.99,
    "category": "Teste"
  }'
```

### 3. Criar lista
```bash
curl -X POST http://localhost:3000/lists \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Lista Teste", 
    "userId": "SEU_USER_ID"
  }'
```

### 4. Adicionar item à lista
```bash
curl -X POST http://localhost:3000/lists/SEU_LIST_ID/items \
  -H "Content-Type: application/json" \
  -d '{
    "itemId": "SEU_ITEM_ID",
    "name": "Produto Teste",
    "quantity": 2,
    "price": 29.99
  }'
```

### 5. 🚨 CHECKOUT (Momento da mensageria!)
```bash
curl -X POST http://localhost:3000/lists/SEU_LIST_ID/checkout
```

**Observe:**
- ✅ Resposta 202 Accepted
- 📧 Log no Terminal 5 (Notification)  
- 📊 Log no Terminal 6 (Analytics)

## 🛑 Parar Sistema
```bash
# Parar containers
docker compose down

# OU usar script
./stop-demo.sh
```

## 🔍 Troubleshooting

### Verificar processos nas portas
```bash
lsof -i :3000  # API Gateway
lsof -i :3001  # User Service  
lsof -i :3002  # List Service
lsof -i :3003  # Item Service
lsof -i :5672  # RabbitMQ
lsof -i :15672 # RabbitMQ Management
```

### Logs dos containers
```bash
docker compose logs rabbitmq
docker compose logs mongodb
```

### Reiniciar containers
```bash
docker compose restart
```