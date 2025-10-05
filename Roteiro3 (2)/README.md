# Microservices Architecture with Advanced Features

This project implements a comprehensive microservices architecture with JWT authentication, robust error handling, load balancing, and real-time bidirectional streaming chat.

## Features Implemented

### 1. JWT Authentication Interceptors
- **Client-side interceptors**: Automatically add JWT tokens to gRPC calls
- **Server-side interceptors**: Validate JWT tokens and extract user information
- **Express middleware**: JWT validation for REST API endpoints
- **Token utilities**: Generate and validate JWT tokens

### 2. Robust Error Handling
- **gRPC error mapping**: Convert JavaScript errors to proper gRPC status codes
- **Error interceptors**: Log and transform errors for better client handling
- **Circuit breaker pattern**: Prevent cascading failures
- **Retry mechanism**: Automatic retries for transient failures
- **Express error handler**: Centralized error handling for REST endpoints

### 3. Load Balancing
- **Multiple load balancing strategies**: Round-robin, random, least-connections
- **Health checking**: Automatic endpoint health monitoring
- **Service discovery**: Dynamic service registration and discovery
- **Failover support**: Automatic failover to healthy instances

### 4. Bidirectional Streaming Chat
- **Real-time messaging**: gRPC bidirectional streaming for instant chat
- **Room management**: Join/leave chat rooms
- **Message history**: Persistent chat history storage
- **Typing indicators**: Real-time typing status
- **User presence**: Online/offline status tracking
- **WebSocket gateway**: WebSocket-to-gRPC bridge for web clients

## Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Web Client    │    │  Mobile Client  │    │  Other Services │
└─────────┬───────┘    └─────────┬───────┘    └─────────┬───────┘
          │                      │                      │
          │ HTTP/WebSocket       │ gRPC                 │ gRPC
          │                      │                      │
          ▼                      ▼                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                     API Gateway                                 │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐              │
│  │Load Balancer│ │Auth Handler │ │Error Handler│              │
│  └─────────────┘ └─────────────┘ └─────────────┘              │
└─────────────────────┬───────────────────────────────────────────┘
                      │ gRPC with interceptors
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                  Service Mesh                                   │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌───────────┐ │
│  │User Service │ │Product Svc  │ │Order Service│ │Chat Service│ │
│  │(Multi inst.)│ │(Multi inst.)│ │(Multi inst.)│ │           │ │
│  └─────────────┘ └─────────────┘ └─────────────┘ └───────────┘ │
└─────────────────────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│               Infrastructure                                    │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐              │
│  │    Redis    │ │    Kafka    │ │  Database   │              │
│  └─────────────┘ └─────────────┘ └─────────────┘              │
└─────────────────────────────────────────────────────────────────┘
```

## Getting Started

### Prerequisites
- Node.js 18+
- Docker and Docker Compose
- Git

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd Roteiro3
```

2. Install dependencies for all services:
```bash
# API Gateway
cd api-gateway && npm install && cd ..

# Services
cd services/user-service && npm install && cd ../..
cd services/product-service && npm install && cd ../..
cd services/order-service && npm install && cd ../..
cd services/payment-service && npm install && cd ../..
cd services/notification-service && npm install && cd ../..
```

3. Start infrastructure services:
```bash
docker-compose up -d redis kafka zookeeper
```

### Running Services

#### Development Mode (Individual Services)

1. Start User Service:
```bash
cd services/user-service
node server.js
```

2. Start Chat Service:
```bash
cd services/notification-service
node chat-service.js
```

3. Start API Gateway:
```bash
cd api-gateway
node server.js
```

#### Production Mode (Docker)

```bash
docker-compose up --build
```

This will start:
- Multiple instances of each service for load balancing
- API Gateway with WebSocket support
- Infrastructure services (Redis, Kafka, etc.)
- Monitoring tools (Prometheus, Grafana)

## API Endpoints

### Authentication
```bash
# Register user
POST /api/auth/register
{
  "email": "user@example.com",
  "password": "password123",
  "username": "username"
}

# Login
POST /api/auth/login
{
  "email": "user@example.com",
  "password": "password123"
}
```

### Protected Endpoints (Require JWT token)
```bash
# Get user profile
GET /api/protected/users/profile
Headers: Authorization: Bearer <token>

# Update profile
PUT /api/protected/users/profile
Headers: Authorization: Bearer <token>
{
  "username": "newusername",
  "email": "newemail@example.com"
}

# Join chat room
POST /api/protected/chat/rooms/general/join
Headers: Authorization: Bearer <token>

# Get chat history
GET /api/protected/chat/rooms/general/history?limit=50
Headers: Authorization: Bearer <token>
```

## WebSocket Chat Usage

### Connect to WebSocket
```javascript
const ws = new WebSocket('ws://localhost:3000');

// Authenticate
ws.send(JSON.stringify({
  type: 'auth',
  token: 'your-jwt-token'
}));

// Join room
ws.send(JSON.stringify({
  type: 'join_room',
  roomId: 'general'
}));

// Send message
ws.send(JSON.stringify({
  type: 'send_message',
  roomId: 'general',
  content: 'Hello, world!',
  messageType: 'TEXT'
}));

// Handle incoming messages
ws.onmessage = (event) => {
  const data = JSON.parse(event.data);
  console.log('Received:', data);
};
```

## gRPC Client Usage

### Direct gRPC with Authentication
```javascript
const grpc = require('@grpc/grpc-js');
const { createAuthInterceptor } = require('./shared/middleware/auth');

// Create client with auth interceptor
const client = new UserService('localhost:50051', grpc.credentials.createInsecure());

// Add auth interceptor
const authInterceptor = createAuthInterceptor();
client.interceptors.push(authInterceptor);

// Make authenticated call
const metadata = new grpc.Metadata();
metadata.add('authorization', 'Bearer your-jwt-token');

client.getProfile({}, metadata, (error, response) => {
  if (error) {
    console.error('Error:', error);
  } else {
    console.log('Profile:', response.user);
  }
});
```

### Load Balanced gRPC Client
```javascript
const { LoadBalancedGrpcClient } = require('./shared/utils/load-balancer');

// Create load balanced client
const client = new LoadBalancedGrpcClient(
  UserService,
  ['localhost:50051', 'localhost:50061', 'localhost:50071'],
  { strategy: 'round-robin', maxRetries: 3 }
);

// Make call (automatically load balanced)
const response = await client.call('getProfile', {}, {
  authorization: 'Bearer your-jwt-token'
});
```

## Chat Service Usage

### Server-side (gRPC)
```javascript
const { startChatServer } = require('./services/notification-service/chat-service');

// Start chat server
const server = startChatServer(50055);
```

### Client-side
```javascript
const ChatClient = require('./shared/utils/chat-client');

// Create chat client
const chatClient = new ChatClient('localhost:50055', 'your-jwt-token');

// Initialize
await chatClient.initialize('user123', 'username');

// Set message handler
chatClient.setMessageHandler((message) => {
  console.log(`[${message.room_id}] ${message.username}: ${message.content}`);
});

// Join room and send message
await chatClient.joinRoom('general');
chatClient.sendMessage('general', 'Hello, everyone!');
```

## Error Handling Examples

### Circuit Breaker Pattern
```javascript
const { CircuitBreaker } = require('./shared/middleware/error-handling');

const circuitBreaker = new CircuitBreaker({
  failureThreshold: 5,
  resetTimeout: 60000
});

// Use with any async operation
const result = await circuitBreaker.execute(async () => {
  return await someUnreliableService();
});
```

### Retry with Exponential Backoff
```javascript
const { withRetry } = require('./shared/middleware/error-handling');

const result = await withRetry(async () => {
  return await riskyOperation();
}, 3, 1000); // 3 retries, 1 second base delay
```

## Load Balancing Configuration

### Service Registration
```javascript
const { ServiceRegistry } = require('./shared/utils/load-balancer');

const registry = new ServiceRegistry();

// Register service instances
registry.register('user-service', 'localhost:50051', { version: '1.0' });
registry.register('user-service', 'localhost:50061', { version: '1.0' });
registry.register('user-service', 'localhost:50071', { version: '1.0' });

// Get available endpoints
const endpoints = registry.getEndpoints('user-service');
```

## Monitoring and Health Checks

### Health Check Endpoint
```bash
GET /health
```

Response:
```json
{
  "status": "healthy",
  "timestamp": "2023-12-07T10:30:00.000Z",
  "services": {
    "user": { "status": "CLOSED", "failures": 0 },
    "product": { "status": "CLOSED", "failures": 0 },
    "order": { "status": "OPEN", "failures": 5 },
    "payment": { "status": "HALF_OPEN", "failures": 3 }
  }
}
```

### Service Registry Status
```bash
GET /api/registry/user-service
```

## Environment Variables

```bash
# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key

# Service Ports
API_GATEWAY_PORT=3000
USER_SERVICE_PORT=50051
PRODUCT_SERVICE_PORT=50052
ORDER_SERVICE_PORT=50053
PAYMENT_SERVICE_PORT=50054
CHAT_SERVICE_PORT=50055

# Infrastructure
REDIS_URL=redis://localhost:6379
KAFKA_BROKERS=localhost:9092
```

## Testing

Run the feature demonstration:
```bash
node examples/feature-demo.js
```

This will demonstrate:
- JWT token generation and validation
- Load balancer round-robin distribution
- Error handling with retries and circuit breaker
- Chat client functionality (requires chat service running)

## Production Considerations

1. **Security**:
   - Use strong JWT secrets
   - Implement proper CORS policies
   - Add rate limiting per user
   - Use HTTPS/TLS for production

2. **Scalability**:
   - Use proper databases instead of in-memory storage
   - Implement proper service discovery (Consul, etcd)
   - Add horizontal pod autoscaling
   - Use message queues for async processing

3. **Monitoring**:
   - Add metrics collection (Prometheus)
   - Implement distributed tracing (Jaeger)
   - Set up log aggregation (ELK stack)
   - Configure alerting

4. **Deployment**:
   - Use Kubernetes for orchestration
   - Implement blue-green deployments
   - Add health checks and readiness probes
   - Configure resource limits and requests

## Troubleshooting

### Common Issues

1. **Connection Refused**:
   - Check if services are running on correct ports
   - Verify Docker network connectivity
   - Check firewall settings

2. **Authentication Errors**:
   - Verify JWT secret consistency across services
   - Check token expiration
   - Ensure proper token format in requests

3. **Load Balancing Issues**:
   - Check service registration
   - Verify health check endpoints
   - Monitor circuit breaker status

4. **Chat Connection Issues**:
   - Ensure WebSocket support in client
   - Check authentication token validity
   - Verify gRPC streaming connection

For more detailed logs, set environment variable:
```bash
DEBUG=microservices:*
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Implement your changes
4. Add tests
5. Submit a pull request

## License

MIT License - see LICENSE file for details.
