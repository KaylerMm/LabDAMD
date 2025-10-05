const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const grpc = require('@grpc/grpc-js');
const protoLoader = require('@grpc/proto-loader');
const path = require('path');
const WebSocket = require('ws');
const http = require('http');

// Import shared middleware and utilities
const { expressAuthMiddleware, generateToken, validateToken } = require('../shared/middleware/auth');
const { expressErrorHandler, withRetry, CircuitBreaker } = require('../shared/middleware/error-handling');
const { ServiceRegistry } = require('../shared/utils/load-balancer');
const ChatClient = require('../shared/utils/chat-client');
const SimpleGrpcClient = require('./simple-grpc-client');

const app = express();
const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

// Service registry for load balancing
const serviceRegistry = new ServiceRegistry();

// Circuit breakers for each service
const circuitBreakers = {
  user: new CircuitBreaker({ failureThreshold: 3, resetTimeout: 30000 }),
  product: new CircuitBreaker({ failureThreshold: 3, resetTimeout: 30000 }),
  order: new CircuitBreaker({ failureThreshold: 3, resetTimeout: 30000 }),
  payment: new CircuitBreaker({ failureThreshold: 3, resetTimeout: 30000 }),
  chat: new CircuitBreaker({ failureThreshold: 3, resetTimeout: 30000 })
};

// Load balanced gRPC clients
let grpcClients = {};

// Middleware setup
app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP'
});
app.use('/api/', limiter);

// Health check endpoint
app.get('/health', (req, res) => {
  const healthStatus = {
    status: 'healthy',
    timestamp: new Date().toISOString(),
    services: {}
  };
  
  // Check circuit breaker status
  Object.keys(circuitBreakers).forEach(service => {
    const cb = circuitBreakers[service];
    healthStatus.services[service] = {
      status: cb.state,
      failures: cb.failures
    };
  });
  
  res.json(healthStatus);
});

// Service discovery endpoints
app.post('/api/registry/register', (req, res) => {
  const { serviceName, endpoint, metadata } = req.body;
  
  try {
    serviceRegistry.register(serviceName, endpoint, metadata);
    
    // Update load balanced clients
    updateLoadBalancedClients();
    
    res.json({ success: true, message: 'Service registered' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.delete('/api/registry/:serviceName/:endpoint', (req, res) => {
  const { serviceName, endpoint } = req.params;
  
  try {
    serviceRegistry.unregister(serviceName, decodeURIComponent(endpoint));
    
    // Update load balanced clients
    updateLoadBalancedClients();
    
    res.json({ success: true, message: 'Service unregistered' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.get('/api/registry/:serviceName', (req, res) => {
  const { serviceName } = req.params;
  const services = serviceRegistry.getService(serviceName);
  res.json({ services });
});

// Authentication endpoints (public)
app.post('/api/auth/login', async (req, res, next) => {
  try {
    const { email, password } = req.body;
    
    // Call user service with circuit breaker
    const response = await circuitBreakers.user.execute(async () => {
      return await grpcCall('user', 'login', { email, password });
    });
    
    if (response.success) {
      const token = generateToken({
        userId: response.user.id,
        email: response.user.email,
        role: response.user.role
      });
      
      res.json({
        success: true,
        token,
        user: response.user
      });
    } else {
      res.status(401).json({ error: 'Invalid credentials' });
    }
  } catch (error) {
    next(error);
  }
});

app.post('/api/auth/register', async (req, res, next) => {
  try {
    const userData = req.body;
    
    const response = await circuitBreakers.user.execute(async () => {
      return await grpcCall('user', 'register', userData);
    });
    
    if (response.success) {
      const token = generateToken({
        userId: response.user.id,
        email: response.user.email,
        role: response.user.role
      });
      
      res.json({
        success: true,
        token,
        user: response.user
      });
    } else {
      res.status(400).json({ error: response.message });
    }
  } catch (error) {
    next(error);
  }
});

// Protected routes
app.use('/api/protected', expressAuthMiddleware);

// User service routes
app.get('/api/protected/users/profile', async (req, res, next) => {
  try {
    const response = await circuitBreakers.user.execute(async () => {
      return await grpcCall('user', 'getProfile', 
        { userId: req.user.userId }, 
        { authorization: req.headers.authorization }
      );
    });
    
    res.json(response);
  } catch (error) {
    next(error);
  }
});

app.put('/api/protected/users/profile', async (req, res, next) => {
  try {
    const response = await circuitBreakers.user.execute(async () => {
      return await grpcCall('user', 'updateProfile', 
        { userId: req.user.userId, ...req.body }, 
        { authorization: req.headers.authorization }
      );
    });
    
    res.json(response);
  } catch (error) {
    next(error);
  }
});

// Product service routes
app.get('/api/products', async (req, res, next) => {
  try {
    const { page = 1, limit = 10, category, search } = req.query;
    
    const response = await circuitBreakers.product.execute(async () => {
      return await grpcCall('product', 'getProducts', {
        page: parseInt(page),
        limit: parseInt(limit),
        category,
        search
      });
    });
    
    res.json(response);
  } catch (error) {
    next(error);
  }
});

app.get('/api/products/:id', async (req, res, next) => {
  try {
    const response = await circuitBreakers.product.execute(async () => {
      return await grpcCall('product', 'getProduct', { id: req.params.id });
    });
    
    res.json(response);
  } catch (error) {
    next(error);
  }
});

// Order service routes
app.post('/api/protected/orders', async (req, res, next) => {
  try {
    const orderData = {
      userId: req.user.userId,
      ...req.body
    };
    
    const response = await circuitBreakers.order.execute(async () => {
      return await grpcCall('order', 'createOrder', 
        orderData, 
        { authorization: req.headers.authorization }
      );
    });
    
    res.json(response);
  } catch (error) {
    next(error);
  }
});

app.get('/api/protected/orders', async (req, res, next) => {
  try {
    const response = await circuitBreakers.order.execute(async () => {
      return await grpcCall('order', 'getUserOrders', 
        { userId: req.user.userId }, 
        { authorization: req.headers.authorization }
      );
    });
    
    res.json(response);
  } catch (error) {
    next(error);
  }
});

// Payment service routes
app.post('/api/protected/payments/process', async (req, res, next) => {
  try {
    const paymentData = {
      userId: req.user.userId,
      ...req.body
    };
    
    const response = await circuitBreakers.payment.execute(async () => {
      return await grpcCall('payment', 'processPayment', 
        paymentData, 
        { authorization: req.headers.authorization }
      );
    });
    
    res.json(response);
  } catch (error) {
    next(error);
  }
});

// Chat endpoints
app.post('/api/protected/chat/rooms/:roomId/join', async (req, res, next) => {
  try {
    const { roomId } = req.params;
    
    const response = await circuitBreakers.chat.execute(async () => {
      return await grpcCall('chat', 'joinRoom', {
        room_id: roomId,
        user_id: req.user.userId,
        username: req.user.email // or get from user service
      }, { authorization: req.headers.authorization });
    });
    
    res.json(response);
  } catch (error) {
    next(error);
  }
});

app.get('/api/protected/chat/rooms/:roomId/history', async (req, res, next) => {
  try {
    const { roomId } = req.params;
    const { limit = 50, before } = req.query;
    
    const response = await circuitBreakers.chat.execute(async () => {
      return await grpcCall('chat', 'getHistory', {
        room_id: roomId,
        limit: parseInt(limit),
        before_timestamp: before ? parseInt(before) : null
      }, { authorization: req.headers.authorization });
    });
    
    res.json(response);
  } catch (error) {
    next(error);
  }
});

// WebSocket handling for real-time chat
wss.on('connection', (ws, req) => {
  console.log('New WebSocket connection');
  
  let chatClient = null;
  let isAuthenticated = false;
  
  ws.on('message', async (data) => {
    try {
      const message = JSON.parse(data);
      
      if (message.type === 'auth') {
        // Authenticate WebSocket connection
        try {
          const decoded = validateToken(message.token);
          isAuthenticated = true;
          
          // Initialize chat client
          const chatEndpoints = serviceRegistry.getEndpoints('chat');
          if (chatEndpoints.length > 0) {
            chatClient = new ChatClient(chatEndpoints[0], message.token);
            await chatClient.initialize(decoded.userId, decoded.email);
            
            // Set up message handlers
            chatClient.setMessageHandler((chatMessage) => {
              ws.send(JSON.stringify({
                type: 'message',
                data: chatMessage
              }));
            });
            
            chatClient.setErrorHandler((error) => {
              ws.send(JSON.stringify({
                type: 'error',
                error: error.message
              }));
            });
            
            ws.send(JSON.stringify({
              type: 'auth_success',
              message: 'Authenticated successfully'
            }));
          } else {
            throw new Error('Chat service not available');
          }
        } catch (error) {
          ws.send(JSON.stringify({
            type: 'auth_error',
            error: 'Authentication failed'
          }));
        }
      } else if (isAuthenticated && chatClient) {
        // Handle chat messages
        switch (message.type) {
          case 'join_room':
            await chatClient.joinRoom(message.roomId);
            break;
          case 'leave_room':
            await chatClient.leaveRoom(message.roomId);
            break;
          case 'send_message':
            chatClient.sendMessage(message.roomId, message.content, message.messageType || 'TEXT');
            break;
          case 'typing':
            chatClient.sendTyping(message.roomId);
            break;
          case 'presence':
            await chatClient.updatePresence(message.status);
            break;
        }
      } else {
        ws.send(JSON.stringify({
          type: 'error',
          error: 'Not authenticated'
        }));
      }
    } catch (error) {
      console.error('WebSocket message error:', error);
      ws.send(JSON.stringify({
        type: 'error',
        error: error.message
      }));
    }
  });
  
  ws.on('close', () => {
    console.log('WebSocket connection closed');
    if (chatClient) {
      chatClient.close();
    }
  });
  
  ws.on('error', (error) => {
    console.error('WebSocket error:', error);
    if (chatClient) {
      chatClient.close();
    }
  });
});

// Generic gRPC call function
async function grpcCall(serviceName, method, params, metadata = {}) {
  const client = grpcClients[serviceName];
  if (!client) {
    throw new Error(`Service ${serviceName} not available`);
  }
  
  return await withRetry(async () => {
    return await client.call(method, params, metadata);
  });
}

// Update load balanced clients when services change
function updateLoadBalancedClients() {
  const services = ['user', 'product', 'order', 'payment', 'chat'];
  
  services.forEach(serviceName => {
    const endpoints = serviceRegistry.getEndpoints(serviceName);
    if (endpoints.length > 0) {
      grpcClients[serviceName] = new SimpleGrpcClient(serviceName, endpoints);
    }
  });
}

// Error handling middleware (must be last)
app.use(expressErrorHandler);

// Start server
const PORT = process.env.PORT || 3000;

server.listen(PORT, () => {
  console.log(`API Gateway running on port ${PORT}`);
  console.log(`WebSocket server running on port ${PORT}`);
  
  // Register default service endpoints (for development)
  serviceRegistry.register('user', 'localhost:50051');
  serviceRegistry.register('product', 'localhost:50052');
  serviceRegistry.register('order', 'localhost:50053');
  serviceRegistry.register('payment', 'localhost:50054');
  serviceRegistry.register('chat', 'localhost:50055');
  
  updateLoadBalancedClients();
  
  // Start service registry cleanup
  setInterval(() => {
    serviceRegistry.cleanup();
  }, 60000); // Clean up every minute
});

module.exports = app;
