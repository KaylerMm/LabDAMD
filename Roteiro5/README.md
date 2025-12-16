# Shopping List Messaging System with RabbitMQ

Sistema de microsserviços para lista de compras implementando mensageria assíncrona com RabbitMQ.

## Arquitetura

```
API Gateway (3000)
├── User Service (3001)
├── List Service (3002) → RabbitMQ Publisher
└── Item Service (3003)

RabbitMQ Exchange: shopping_events
├── Notification Consumer (Queue: notifications)
└── Analytics Consumer (Queue: analytics)
```

## Pré-requisitos

- Node.js 16+
- Docker & Docker Compose
- MongoDB
- RabbitMQ

## Setup Rápido

### 1. Instalar dependências
```bash
npm install
```

### 2. Iniciar infraestrutura
```bash
docker-compose up -d
```

### 3. Configurar variáveis de ambiente
```bash
cp .env.example .env
```

### 4. Iniciar serviços
```bash
# Terminal 1 - User Service
npm run start:user

# Terminal 2 - Item Service  
npm run start:item

# Terminal 3 - List Service
npm run start:list

# Terminal 4 - API Gateway
npm run start:gateway

# Terminal 5 - Notification Consumer
npm run start:notification-consumer

# Terminal 6 - Analytics Consumer
npm run start:analytics-consumer
```

## Demonstração

### 1. Verificar RabbitMQ Management
Acesse: http://localhost:15672
- User: admin
- Pass: admin123

### 2. Criar usuário
```bash
curl -X POST http://localhost:3000/users \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "john@example.com"
  }'
```

### 3. Criar items
```bash
curl -X POST http://localhost:3000/items \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Apple",
    "price": 1.50,
    "category": "Fruits"
  }'

curl -X POST http://localhost:3000/items \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Milk",
    "price": 2.99,
    "category": "Dairy"
  }'
```

### 4. Criar lista de compras
```bash
curl -X POST http://localhost:3000/lists \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Weekly Shopping",
    "userId": "USER_ID_HERE"
  }'
```

### 5. Adicionar items à lista
```bash
curl -X POST http://localhost:3000/lists/LIST_ID/items \
  -H "Content-Type: application/json" \
  -d '{
    "itemId": "ITEM_ID",
    "name": "Apple",
    "quantity": 5,
    "price": 1.50
  }'
```

### 6. Finalizar compra (Checkout) - EVENTO PRINCIPAL
```bash
curl -X POST http://localhost:3000/lists/LIST_ID/checkout
```

**Resultado esperado:**
- API responde com 202 Accepted imediatamente
- Notification Consumer processa e exibe log de envio de email
- Analytics Consumer atualiza estatísticas
- RabbitMQ Management mostra mensagens sendo processadas

## Endpoints

### API Gateway (Port 3000)

#### Users
- `GET /users` - Listar usuários
- `POST /users` - Criar usuário
- `GET /users/:id` - Buscar usuário
- `PUT /users/:id` - Atualizar usuário
- `DELETE /users/:id` - Remover usuário

#### Items
- `GET /items` - Listar items
- `POST /items` - Criar item
- `GET /items/:id` - Buscar item
- `PUT /items/:id` - Atualizar item
- `DELETE /items/:id` - Remover item

#### Lists
- `GET /lists` - Listar listas
- `POST /lists` - Criar lista
- `GET /lists/:id` - Buscar lista
- `PUT /lists/:id` - Atualizar lista
- `POST /lists/:id/items` - Adicionar item à lista
- `POST /lists/:id/checkout` - **Finalizar compra (Publica evento)**
- `DELETE /lists/:id` - Remover lista

#### Health Check
- `GET /health` - Status de todos os serviços

## Mensageria

### Exchange
- **Nome:** `shopping_events`
- **Tipo:** `topic`

### Routing Key
- `list.checkout.completed` - Publicada quando uma lista é finalizada

### Consumers

#### Notification Consumer
- **Fila:** `notifications`
- **Routing:** `list.checkout.#`
- **Função:** Simula envio de email com comprovante

#### Analytics Consumer
- **Fila:** `analytics`  
- **Routing:** `list.checkout.#`
- **Função:** Calcula estatísticas e atualiza dashboard

## Estrutura do Projeto

```
Roteiro5/
├── api-gateway/
│   └── server.js
├── services/
│   ├── user-service/
│   ├── list-service/     # Publisher RabbitMQ
│   └── item-service/
├── consumers/
│   ├── notification-consumer.js
│   └── analytics-consumer.js
├── shared/
│   └── message-broker.js
├── docker-compose.yml
├── package.json
└── .env
```

## Tecnologias

- **Node.js/Express** - Serviços REST
- **RabbitMQ** - Message Broker
- **MongoDB** - Database
- **Docker** - Containerização
- **amqplib** - RabbitMQ client

## Roteiro de Demonstração

1. **Setup:** Mostrar RabbitMQ Management vazio
2. **Criar dados:** Usuário, items, lista de compras
3. **Checkout:** POST /lists/:id/checkout
4. **Evidências:**
   - Resposta 202 rápida da API
   - Logs instantâneos nos consumers
   - Gráficos do RabbitMQ Management