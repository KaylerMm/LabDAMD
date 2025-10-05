const grpc = require('@grpc/grpc-js');
const protoLoader = require('@grpc/proto-loader');
const path = require('path');

// Simple gRPC client for API Gateway
class SimpleGrpcClient {
  constructor(serviceName, endpoints) {
    this.serviceName = serviceName;
    this.endpoints = endpoints;
    this.currentIndex = 0;
    this.client = null;
    this.protoDefinition = null;
    
    this.initializeClient();
  }
  
  async initializeClient() {
    if (this.serviceName === 'user') {
      const userProtoPath = path.join(__dirname, '../shared/proto/user.proto');
      const packageDefinition = protoLoader.loadSync(userProtoPath, {
        keepCase: true,
        longs: String,
        enums: String,
        defaults: true,
        oneofs: true
      });
      
      const userProto = grpc.loadPackageDefinition(packageDefinition).user;
      this.client = new userProto.UserService(
        this.getEndpoint(),
        grpc.credentials.createInsecure()
      );
    }
  }
  
  getEndpoint() {
    const endpoint = this.endpoints[this.currentIndex % this.endpoints.length];
    this.currentIndex++;
    return endpoint;
  }
  
  async call(method, params, metadata = {}) {
    return new Promise((resolve, reject) => {
      if (!this.client) {
        return reject(new Error('Client not initialized'));
      }
      
      const grpcMetadata = new grpc.Metadata();
      Object.entries(metadata).forEach(([key, value]) => {
        grpcMetadata.add(key, value);
      });
      
      // Map method names to client methods
      const methodMap = {
        'login': 'login',
        'register': 'register',
        'getProfile': 'getProfile',
        'updateProfile': 'updateProfile'
      };
      
      const clientMethod = methodMap[method];
      if (!clientMethod || typeof this.client[clientMethod] !== 'function') {
        return reject(new Error(`Method ${method} not found on client`));
      }
      
      this.client[clientMethod](params, grpcMetadata, (error, response) => {
        if (error) {
          reject(error);
        } else {
          resolve(response);
        }
      });
    });
  }
}

module.exports = SimpleGrpcClient;
