const grpc = require('@grpc/grpc-js');

// Load balancing strategies
class LoadBalancer {
  constructor(endpoints, strategy = 'round-robin') {
    this.endpoints = endpoints;
    this.strategy = strategy;
    this.currentIndex = 0;
    this.healthyEndpoints = new Set(endpoints);
    this.lastHealthCheck = new Map();
    
    // Start health checking
    this.startHealthChecking();
  }
  
  // Get next endpoint based on strategy
  getEndpoint() {
    const healthy = Array.from(this.healthyEndpoints);
    
    if (healthy.length === 0) {
      throw new Error('No healthy endpoints available');
    }
    
    switch (this.strategy) {
      case 'round-robin':
        return this.roundRobin(healthy);
      case 'random':
        return this.random(healthy);
      case 'least-connections':
        return this.leastConnections(healthy);
      default:
        return this.roundRobin(healthy);
    }
  }
  
  roundRobin(endpoints) {
    const endpoint = endpoints[this.currentIndex % endpoints.length];
    this.currentIndex++;
    return endpoint;
  }
  
  random(endpoints) {
    return endpoints[Math.floor(Math.random() * endpoints.length)];
  }
  
  leastConnections(endpoints) {
    // Simple implementation - in production, track actual connections
    return endpoints.reduce((min, current) => {
      const minConnections = this.getConnectionCount(min);
      const currentConnections = this.getConnectionCount(current);
      return currentConnections < minConnections ? current : min;
    });
  }
  
  getConnectionCount(endpoint) {
    // Mock implementation - in production, track real connections
    return Math.floor(Math.random() * 10);
  }
  
  // Health checking
  async startHealthChecking() {
    setInterval(() => {
      this.endpoints.forEach(endpoint => this.checkHealth(endpoint));
    }, 30000); // Check every 30 seconds
  }
  
  async checkHealth(endpoint) {
    try {
      const client = new grpc.Client(endpoint, grpc.credentials.createInsecure());
      
      // Simple health check - try to connect
      await new Promise((resolve, reject) => {
        client.waitForReady(Date.now() + 5000, (error) => {
          if (error) {
            reject(error);
          } else {
            resolve();
          }
        });
      });
      
      this.healthyEndpoints.add(endpoint);
      this.lastHealthCheck.set(endpoint, { status: 'healthy', timestamp: Date.now() });
      
    } catch (error) {
      this.healthyEndpoints.delete(endpoint);
      this.lastHealthCheck.set(endpoint, { status: 'unhealthy', timestamp: Date.now(), error: error.message });
      console.warn(`Endpoint ${endpoint} is unhealthy:`, error.message);
    }
  }
  
  // Mark endpoint as unhealthy (called on connection errors)
  markUnhealthy(endpoint) {
    this.healthyEndpoints.delete(endpoint);
    console.warn(`Marking endpoint ${endpoint} as unhealthy`);
  }
  
  // Get health status
  getHealthStatus() {
    return {
      total: this.endpoints.length,
      healthy: this.healthyEndpoints.size,
      endpoints: this.endpoints.map(endpoint => ({
        endpoint,
        healthy: this.healthyEndpoints.has(endpoint),
        lastCheck: this.lastHealthCheck.get(endpoint)
      }))
    };
  }
}

// gRPC Client with load balancing
class LoadBalancedGrpcClient {
  constructor(serviceDefinition, endpoints, options = {}) {
    this.serviceDefinition = serviceDefinition;
    this.loadBalancer = new LoadBalancer(endpoints, options.strategy);
    this.clients = new Map();
    this.maxRetries = options.maxRetries || 3;
  }
  
  getClient(endpoint) {
    if (!this.clients.has(endpoint)) {
      const client = new this.serviceDefinition(
        endpoint,
        grpc.credentials.createInsecure()
      );
      this.clients.set(endpoint, client);
    }
    return this.clients.get(endpoint);
  }
  
  async call(method, request, metadata = {}) {
    let lastError;
    
    for (let attempt = 0; attempt < this.maxRetries; attempt++) {
      try {
        const endpoint = this.loadBalancer.getEndpoint();
        const client = this.getClient(endpoint);
        
        return await new Promise((resolve, reject) => {
          client[method](request, metadata, (error, response) => {
            if (error) {
              reject(error);
            } else {
              resolve(response);
            }
          });
        });
        
      } catch (error) {
        lastError = error;
        
        // Mark endpoint as unhealthy on connection errors
        if (error.code === grpc.status.UNAVAILABLE) {
          this.loadBalancer.markUnhealthy(endpoint);
        }
        
        // Don't retry on client errors
        if (error.code === grpc.status.INVALID_ARGUMENT ||
            error.code === grpc.status.UNAUTHENTICATED ||
            error.code === grpc.status.PERMISSION_DENIED) {
          throw error;
        }
      }
    }
    
    throw lastError;
  }
  
  // Streaming methods
  createClientStream(method, metadata = {}) {
    const endpoint = this.loadBalancer.getEndpoint();
    const client = this.getClient(endpoint);
    return client[method](metadata);
  }
  
  createServerStream(method, request, metadata = {}) {
    const endpoint = this.loadBalancer.getEndpoint();
    const client = this.getClient(endpoint);
    return client[method](request, metadata);
  }
  
  createBidirectionalStream(method, metadata = {}) {
    const endpoint = this.loadBalancer.getEndpoint();
    const client = this.getClient(endpoint);
    return client[method](metadata);
  }
}

// Service discovery helper
class ServiceRegistry {
  constructor() {
    this.services = new Map();
  }
  
  register(serviceName, endpoint, metadata = {}) {
    if (!this.services.has(serviceName)) {
      this.services.set(serviceName, []);
    }
    
    const serviceEndpoints = this.services.get(serviceName);
    const existingIndex = serviceEndpoints.findIndex(s => s.endpoint === endpoint);
    
    if (existingIndex >= 0) {
      serviceEndpoints[existingIndex] = { endpoint, metadata, lastSeen: Date.now() };
    } else {
      serviceEndpoints.push({ endpoint, metadata, lastSeen: Date.now() });
    }
    
    console.log(`Registered service ${serviceName} at ${endpoint}`);
  }
  
  unregister(serviceName, endpoint) {
    if (this.services.has(serviceName)) {
      const serviceEndpoints = this.services.get(serviceName);
      const filtered = serviceEndpoints.filter(s => s.endpoint !== endpoint);
      this.services.set(serviceName, filtered);
      console.log(`Unregistered service ${serviceName} from ${endpoint}`);
    }
  }
  
  getEndpoints(serviceName) {
    const services = this.services.get(serviceName) || [];
    return services.map(s => s.endpoint);
  }
  
  getService(serviceName) {
    return this.services.get(serviceName) || [];
  }
  
  // Cleanup stale services
  cleanup(maxAge = 300000) { // 5 minutes
    const now = Date.now();
    
    for (const [serviceName, endpoints] of this.services.entries()) {
      const active = endpoints.filter(s => (now - s.lastSeen) < maxAge);
      this.services.set(serviceName, active);
    }
  }
}

module.exports = {
  LoadBalancer,
  LoadBalancedGrpcClient,
  ServiceRegistry
};
