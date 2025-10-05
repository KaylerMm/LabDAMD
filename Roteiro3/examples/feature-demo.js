const ChatClient = require('../shared/utils/chat-client');
const { generateToken } = require('../shared/middleware/auth');

// Example usage of the chat client
async function chatExample() {
  try {
    // Generate a test token
    const token = generateToken({
      userId: 'user1',
      email: 'user1@example.com',
      role: 'user'
    });
    
    // Create chat client
    const chatClient = new ChatClient('localhost:50055', token);
    
    // Initialize client
    await chatClient.initialize('user1', 'User1');
    
    // Set message handler
    chatClient.setMessageHandler((message) => {
      console.log(`[${message.room_id}] ${message.username}: ${message.content}`);
    });
    
    // Join a room
    await chatClient.joinRoom('general');
    
    // Send some messages
    chatClient.sendMessage('general', 'Hello, everyone!');
    chatClient.sendMessage('general', 'How is everyone doing?');
    
    // Update presence
    await chatClient.updatePresence('ONLINE');
    
    // Get chat history
    const history = await chatClient.getHistory('general', 10);
    console.log('Chat history:', history);
    
    // Keep the connection alive for a while to receive messages
    setTimeout(() => {
      chatClient.close();
      console.log('Chat example completed');
    }, 10000);
    
  } catch (error) {
    console.error('Chat example error:', error);
  }
}

// Example of load balancer usage
async function loadBalancerExample() {
  const { LoadBalancer, ServiceRegistry } = require('../shared/utils/load-balancer');
  
  // Create service registry
  const registry = new ServiceRegistry();
  
  // Register multiple instances of a service
  registry.register('user-service', 'localhost:50051');
  registry.register('user-service', 'localhost:50061');
  registry.register('user-service', 'localhost:50071');
  
  // Create load balancer
  const endpoints = registry.getEndpoints('user-service');
  const loadBalancer = new LoadBalancer(endpoints, 'round-robin');
  
  // Test load balancing
  console.log('Load Balancer Example:');
  for (let i = 0; i < 6; i++) {
    const endpoint = loadBalancer.getEndpoint();
    console.log(`Request ${i + 1}: ${endpoint}`);
  }
  
  // Check health status
  const healthStatus = loadBalancer.getHealthStatus();
  console.log('Health Status:', healthStatus);
}

// Example of error handling
async function errorHandlingExample() {
  const { withRetry, CircuitBreaker, GrpcError, ErrorCodes } = require('../shared/middleware/error-handling');
  
  console.log('Error Handling Example:');
  
  // Example with retry
  try {
    await withRetry(async () => {
      console.log('Attempting operation...');
      // Simulate a failing operation
      throw new GrpcError(ErrorCodes.UNAVAILABLE, 'Service temporarily unavailable');
    }, 3, 1000);
  } catch (error) {
    console.log('Operation failed after retries:', error.message);
  }
  
  // Example with circuit breaker
  const circuitBreaker = new CircuitBreaker({
    failureThreshold: 2,
    resetTimeout: 5000
  });
  
  for (let i = 0; i < 5; i++) {
    try {
      await circuitBreaker.execute(async () => {
        console.log(`Circuit breaker attempt ${i + 1}`);
        if (i < 3) {
          throw new Error('Service error');
        }
        return 'Success!';
      });
    } catch (error) {
      console.log(`Attempt ${i + 1} failed:`, error.message);
    }
  }
}

// Example of authentication
function authExample() {
  const { generateToken, validateToken } = require('../shared/middleware/auth');
  
  console.log('Authentication Example:');
  
  // Generate token
  const payload = {
    userId: 'user123',
    email: 'user@example.com',
    role: 'user'
  };
  
  const token = generateToken(payload);
  console.log('Generated token:', token);
  
  // Validate token
  try {
    const decoded = validateToken(token);
    console.log('Token validation successful:', decoded);
  } catch (error) {
    console.log('Token validation failed:', error.message);
  }
}

// Run examples
async function runExamples() {
  console.log('=== Microservices Features Demo ===\n');
  
  console.log('1. Authentication Example:');
  authExample();
  console.log('\n');
  
  console.log('2. Load Balancer Example:');
  await loadBalancerExample();
  console.log('\n');
  
  console.log('3. Error Handling Example:');
  await errorHandlingExample();
  console.log('\n');
  
  console.log('4. Chat Example (requires chat service running):');
  // Uncomment to test with running chat service
  // await chatExample();
  
  console.log('=== Demo completed ===');
}

if (require.main === module) {
  runExamples().catch(console.error);
}

module.exports = {
  chatExample,
  loadBalancerExample,
  errorHandlingExample,
  authExample
};
