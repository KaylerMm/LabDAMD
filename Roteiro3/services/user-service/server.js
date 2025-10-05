const grpc = require('@grpc/grpc-js');
const protoLoader = require('@grpc/proto-loader');
const path = require('path');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');

const { serverAuthInterceptor, generateToken, JWT_SECRET } = require('../../shared/middleware/auth');
const { serverErrorInterceptor, GrpcError, ErrorCodes } = require('../../shared/middleware/error-handling');

// Mock database (use real database in production)
const users = new Map();

// Proto definition (create this file)
const userProtoPath = path.join(__dirname, '../../shared/proto/user.proto');

// User service implementation
class UserService {
  async register(call, callback) {
    try {
      const { email, password, username, role = 'user' } = call.request;
      
      // Validation
      if (!email || !password || !username) {
        throw new GrpcError(ErrorCodes.INVALID_ARGUMENT, 'Missing required fields');
      }
      
      if (password.length < 6) {
        throw new GrpcError(ErrorCodes.INVALID_ARGUMENT, 'Password must be at least 6 characters');
      }
      
      // Check if user exists
      for (const user of users.values()) {
        if (user.email === email) {
          throw new GrpcError(ErrorCodes.ALREADY_EXISTS, 'User already exists');
        }
      }
      
      // Hash password
      const hashedPassword = await bcrypt.hash(password, 10);
      
      // Create user
      const userId = uuidv4();
      const user = {
        id: userId,
        email,
        username,
        password: hashedPassword,
        role,
        createdAt: Date.now(),
        updatedAt: Date.now()
      };
      
      users.set(userId, user);
      
      // Return user without password
      const { password: _, ...userResponse } = user;
      
      callback(null, {
        success: true,
        user: userResponse,
        message: 'User created successfully'
      });
    } catch (error) {
      callback(error);
    }
  }
  
  async login(call, callback) {
    try {
      const { email, password } = call.request;
      
      // Find user
      let foundUser = null;
      for (const user of users.values()) {
        if (user.email === email) {
          foundUser = user;
          break;
        }
      }
      
      if (!foundUser) {
        throw new GrpcError(ErrorCodes.NOT_FOUND, 'User not found');
      }
      
      // Verify password
      const isValid = await bcrypt.compare(password, foundUser.password);
      if (!isValid) {
        throw new GrpcError(ErrorCodes.UNAUTHENTICATED, 'Invalid password');
      }
      
      // Return user without password
      const { password: _, ...userResponse } = foundUser;
      
      callback(null, {
        success: true,
        user: userResponse,
        message: 'Login successful'
      });
    } catch (error) {
      callback(error);
    }
  }
  
  async getProfile(call, callback) {
    try {
      // User ID comes from auth interceptor
      const userId = call.user?.userId || call.metadata.get('user-id')[0];
      
      if (!userId) {
        throw new GrpcError(ErrorCodes.UNAUTHENTICATED, 'User ID not found');
      }
      
      const user = users.get(userId);
      if (!user) {
        throw new GrpcError(ErrorCodes.NOT_FOUND, 'User not found');
      }
      
      // Return user without password
      const { password: _, ...userResponse } = user;
      
      callback(null, {
        success: true,
        user: userResponse
      });
    } catch (error) {
      callback(error);
    }
  }
  
  async updateProfile(call, callback) {
    try {
      const userId = call.user?.userId || call.metadata.get('user-id')[0];
      const { username, email } = call.request;
      
      if (!userId) {
        throw new GrpcError(ErrorCodes.UNAUTHENTICATED, 'User ID not found');
      }
      
      const user = users.get(userId);
      if (!user) {
        throw new GrpcError(ErrorCodes.NOT_FOUND, 'User not found');
      }
      
      // Check if email is taken by another user
      if (email && email !== user.email) {
        for (const [id, existingUser] of users.entries()) {
          if (id !== userId && existingUser.email === email) {
            throw new GrpcError(ErrorCodes.ALREADY_EXISTS, 'Email already taken');
          }
        }
      }
      
      // Update user
      if (username) user.username = username;
      if (email) user.email = email;
      user.updatedAt = Date.now();
      
      users.set(userId, user);
      
      // Return user without password
      const { password: _, ...userResponse } = user;
      
      callback(null, {
        success: true,
        user: userResponse,
        message: 'Profile updated successfully'
      });
    } catch (error) {
      callback(error);
    }
  }
  
  async getUserById(call, callback) {
    try {
      const { userId } = call.request;
      
      const user = users.get(userId);
      if (!user) {
        throw new GrpcError(ErrorCodes.NOT_FOUND, 'User not found');
      }
      
      // Return user without password
      const { password: _, ...userResponse } = user;
      
      callback(null, {
        success: true,
        user: userResponse
      });
    } catch (error) {
      callback(error);
    }
  }
  
  async deleteUser(call, callback) {
    try {
      const userId = call.user?.userId || call.metadata.get('user-id')[0];
      
      if (!userId) {
        throw new GrpcError(ErrorCodes.UNAUTHENTICATED, 'User ID not found');
      }
      
      // Check if user has admin role for deleting other users
      const targetUserId = call.request.userId || userId;
      if (targetUserId !== userId && call.user?.role !== 'admin') {
        throw new GrpcError(ErrorCodes.PERMISSION_DENIED, 'Insufficient permissions');
      }
      
      const user = users.get(targetUserId);
      if (!user) {
        throw new GrpcError(ErrorCodes.NOT_FOUND, 'User not found');
      }
      
      users.delete(targetUserId);
      
      callback(null, {
        success: true,
        message: 'User deleted successfully'
      });
    } catch (error) {
      callback(error);
    }
  }
}

// Create proto definition
const userProtoContent = `
syntax = "proto3";

package user;

service UserService {
  rpc Register(RegisterRequest) returns (UserResponse);
  rpc Login(LoginRequest) returns (UserResponse);
  rpc GetProfile(GetProfileRequest) returns (UserResponse);
  rpc UpdateProfile(UpdateProfileRequest) returns (UserResponse);
  rpc GetUserById(GetUserByIdRequest) returns (UserResponse);
  rpc DeleteUser(DeleteUserRequest) returns (DeleteUserResponse);
}

message RegisterRequest {
  string email = 1;
  string password = 2;
  string username = 3;
  string role = 4;
}

message LoginRequest {
  string email = 1;
  string password = 2;
}

message GetProfileRequest {}

message UpdateProfileRequest {
  string username = 1;
  string email = 2;
}

message GetUserByIdRequest {
  string userId = 1;
}

message DeleteUserRequest {
  string userId = 1;
}

message User {
  string id = 1;
  string email = 2;
  string username = 3;
  string role = 4;
  int64 createdAt = 5;
  int64 updatedAt = 6;
}

message UserResponse {
  bool success = 1;
  string message = 2;
  User user = 3;
}

message DeleteUserResponse {
  bool success = 1;
  string message = 2;
}
`;

// Write proto file
const fs = require('fs');
if (!fs.existsSync(userProtoPath)) {
  fs.writeFileSync(userProtoPath, userProtoContent);
}

// Load proto definition
const packageDefinition = protoLoader.loadSync(userProtoPath, {
  keepCase: true,
  longs: String,
  enums: String,
  defaults: true,
  oneofs: true
});

const userProto = grpc.loadPackageDefinition(packageDefinition).user;

// Start server
function startUserServer(port = 50051) {
  const server = new grpc.Server();
  const userService = new UserService();
  
  // Add service with interceptors
  server.addService(userProto.UserService.service, {
    register: (call, callback) => {
      serverErrorInterceptor(call, callback, () => {
        userService.register(call, callback);
      });
    },
    login: (call, callback) => {
      serverErrorInterceptor(call, callback, () => {
        userService.login(call, callback);
      });
    },
    getProfile: (call, callback) => {
      serverAuthInterceptor(call, callback, () => {
        serverErrorInterceptor(call, callback, () => {
          userService.getProfile(call, callback);
        });
      });
    },
    updateProfile: (call, callback) => {
      serverAuthInterceptor(call, callback, () => {
        serverErrorInterceptor(call, callback, () => {
          userService.updateProfile(call, callback);
        });
      });
    },
    getUserById: (call, callback) => {
      serverErrorInterceptor(call, callback, () => {
        userService.getUserById(call, callback);
      });
    },
    deleteUser: (call, callback) => {
      serverAuthInterceptor(call, callback, () => {
        serverErrorInterceptor(call, callback, () => {
          userService.deleteUser(call, callback);
        });
      });
    }
  });
  
  server.bindAsync(
    `0.0.0.0:${port}`,
    grpc.ServerCredentials.createInsecure(),
    (error, port) => {
      if (error) {
        console.error('Failed to start user server:', error);
        return;
      }
      
      console.log(`User service listening on port ${port}`);
      server.start();
      
      // Create default admin user
      const adminId = uuidv4();
      users.set(adminId, {
        id: adminId,
        email: 'admin@example.com',
        username: 'admin',
        password: bcrypt.hashSync('admin123', 10),
        role: 'admin',
        createdAt: Date.now(),
        updatedAt: Date.now()
      });
      
      console.log('Default admin user created: admin@example.com / admin123');
    }
  );
  
  return server;
}

if (require.main === module) {
  startUserServer();
}

module.exports = {
  UserService,
  startUserServer,
  userProto
};
