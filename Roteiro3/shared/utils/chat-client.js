const grpc = require('@grpc/grpc-js');
const protoLoader = require('@grpc/proto-loader');
const path = require('path');
const { createAuthInterceptor, createErrorInterceptor } = require('../../shared/middleware/auth');

// Load proto definition
const PROTO_PATH = path.join(__dirname, '../../shared/proto/chat.proto');
const packageDefinition = protoLoader.loadSync(PROTO_PATH, {
  keepCase: true,
  longs: String,
  enums: String,
  defaults: true,
  oneofs: true
});

const chatProto = grpc.loadPackageDefinition(packageDefinition).chat;

class ChatClient {
  constructor(serverAddress, authToken) {
    this.serverAddress = serverAddress;
    this.authToken = authToken;
    this.client = new chatProto.ChatService(
      serverAddress,
      grpc.credentials.createInsecure()
    );
    this.chatStream = null;
    this.userId = null;
    this.username = null;
    this.currentRooms = new Set();
  }

  // Initialize chat client
  async initialize(userId, username) {
    this.userId = userId;
    this.username = username;
    
    // Create metadata with auth token
    const metadata = new grpc.Metadata();
    if (this.authToken) {
      metadata.add('authorization', `Bearer ${this.authToken}`);
    }
    metadata.add('user-id', userId);
    
    // Create bidirectional stream
    this.chatStream = this.client.chatStream(metadata);
    
    // Handle incoming messages
    this.chatStream.on('data', (message) => {
      this.handleIncomingMessage(message);
    });
    
    this.chatStream.on('error', (error) => {
      console.error('Chat stream error:', error);
      this.handleError(error);
    });
    
    this.chatStream.on('end', () => {
      console.log('Chat stream ended');
      this.chatStream = null;
    });
    
    console.log(`Chat client initialized for user: ${username}`);
  }

  // Join a chat room
  async joinRoom(roomId) {
    return new Promise((resolve, reject) => {
      const metadata = new grpc.Metadata();
      if (this.authToken) {
        metadata.add('authorization', `Bearer ${this.authToken}`);
      }
      
      this.client.joinRoom({
        room_id: roomId,
        user_id: this.userId,
        username: this.username
      }, metadata, (error, response) => {
        if (error) {
          reject(error);
        } else {
          this.currentRooms.add(roomId);
          console.log(`Joined room: ${roomId}`);
          resolve(response);
        }
      });
    });
  }

  // Leave a chat room
  async leaveRoom(roomId) {
    return new Promise((resolve, reject) => {
      const metadata = new grpc.Metadata();
      if (this.authToken) {
        metadata.add('authorization', `Bearer ${this.authToken}`);
      }
      
      this.client.leaveRoom({
        room_id: roomId,
        user_id: this.userId
      }, metadata, (error, response) => {
        if (error) {
          reject(error);
        } else {
          this.currentRooms.delete(roomId);
          console.log(`Left room: ${roomId}`);
          resolve(response);
        }
      });
    });
  }

  // Send a text message
  sendMessage(roomId, content, type = 'TEXT') {
    if (!this.chatStream || this.chatStream.destroyed) {
      throw new Error('Chat stream not available');
    }
    
    if (!this.currentRooms.has(roomId)) {
      throw new Error('Not in room');
    }
    
    const message = {
      room_id: roomId,
      user_id: this.userId,
      username: this.username,
      content: content,
      type: type,
      metadata: {}
    };
    
    this.chatStream.write(message);
    console.log(`Sent message to room ${roomId}: ${content}`);
  }

  // Send typing indicator
  sendTyping(roomId) {
    if (!this.chatStream || this.chatStream.destroyed) {
      return;
    }
    
    if (!this.currentRooms.has(roomId)) {
      return;
    }
    
    const message = {
      room_id: roomId,
      user_id: this.userId,
      username: this.username,
      content: 'typing...',
      type: 'TYPING'
    };
    
    this.chatStream.write(message);
  }

  // Get chat history
  async getHistory(roomId, limit = 50, beforeTimestamp = null) {
    return new Promise((resolve, reject) => {
      const metadata = new grpc.Metadata();
      if (this.authToken) {
        metadata.add('authorization', `Bearer ${this.authToken}`);
      }
      
      const request = {
        room_id: roomId,
        limit: limit
      };
      
      if (beforeTimestamp) {
        request.before_timestamp = beforeTimestamp;
      }
      
      this.client.getHistory(request, metadata, (error, response) => {
        if (error) {
          reject(error);
        } else {
          resolve(response);
        }
      });
    });
  }

  // Update presence
  async updatePresence(status) {
    return new Promise((resolve, reject) => {
      const metadata = new grpc.Metadata();
      if (this.authToken) {
        metadata.add('authorization', `Bearer ${this.authToken}`);
      }
      
      this.client.updatePresence({
        user_id: this.userId,
        status: status
      }, metadata, (error, response) => {
        if (error) {
          reject(error);
        } else {
          resolve(response);
        }
      });
    });
  }

  // Handle incoming messages (override in subclass or set callback)
  handleIncomingMessage(message) {
    console.log(`[${message.room_id}] ${message.username}: ${message.content}`);
    
    // Call custom message handler if set
    if (this.onMessage) {
      this.onMessage(message);
    }
  }

  // Handle errors
  handleError(error) {
    console.error('Chat client error:', error);
    
    // Attempt to reconnect
    setTimeout(() => {
      this.reconnect();
    }, 5000);
    
    // Call custom error handler if set
    if (this.onError) {
      this.onError(error);
    }
  }

  // Reconnect to chat
  async reconnect() {
    try {
      console.log('Attempting to reconnect...');
      await this.initialize(this.userId, this.username);
      
      // Rejoin rooms
      for (const roomId of this.currentRooms) {
        await this.joinRoom(roomId);
      }
      
      console.log('Reconnected successfully');
      
      if (this.onReconnect) {
        this.onReconnect();
      }
    } catch (error) {
      console.error('Reconnection failed:', error);
      
      // Try again after delay
      setTimeout(() => {
        this.reconnect();
      }, 10000);
    }
  }

  // Set event handlers
  setMessageHandler(handler) {
    this.onMessage = handler;
  }

  setErrorHandler(handler) {
    this.onError = handler;
  }

  setReconnectHandler(handler) {
    this.onReconnect = handler;
  }

  // Close connection
  close() {
    if (this.chatStream && !this.chatStream.destroyed) {
      this.chatStream.end();
    }
    console.log('Chat client closed');
  }
}

module.exports = ChatClient;
