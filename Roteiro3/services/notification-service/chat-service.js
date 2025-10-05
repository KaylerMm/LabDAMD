const grpc = require('@grpc/grpc-js');
const protoLoader = require('@grpc/proto-loader');
const path = require('path');
const { v4: uuidv4 } = require('uuid');
const { serverAuthInterceptor } = require('../../shared/middleware/auth');
const { serverErrorInterceptor } = require('../../shared/middleware/error-handling');

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

// In-memory storage (use Redis/Database in production)
class ChatService {
  constructor() {
    this.rooms = new Map(); // roomId -> Set of userIds
    this.userStreams = new Map(); // userId -> stream
    this.userRooms = new Map(); // userId -> Set of roomIds
    this.messageHistory = new Map(); // roomId -> Array of messages
    this.userPresence = new Map(); // userId -> status
  }

  // Bidirectional streaming for real-time chat
  chatStream(call) {
    let userId = null;
    let currentRooms = new Set();

    call.on('data', (message) => {
      try {
        // Set user ID from first message or auth metadata
        if (!userId) {
          userId = message.user_id || call.metadata.get('user-id')[0];
          if (!userId) {
            call.destroy(new Error('User ID required'));
            return;
          }
          
          // Store user stream for broadcasting
          this.userStreams.set(userId, call);
          
          // Join rooms user was previously in
          const userRoomsSet = this.userRooms.get(userId) || new Set();
          userRoomsSet.forEach(roomId => currentRooms.add(roomId));
        }

        // Process different message types
        switch (message.type) {
          case 'TEXT':
          case 'IMAGE':
          case 'FILE':
            this.handleChatMessage(message, currentRooms);
            break;
          case 'TYPING':
            this.handleTypingIndicator(message, currentRooms);
            break;
          case 'SYSTEM':
            // Handle system messages (join/leave notifications)
            this.handleSystemMessage(message, currentRooms);
            break;
        }
      } catch (error) {
        console.error('Error processing chat message:', error);
        call.destroy(error);
      }
    });

    call.on('end', () => {
      this.handleUserDisconnect(userId, currentRooms);
    });

    call.on('error', (error) => {
      console.error('Chat stream error:', error);
      this.handleUserDisconnect(userId, currentRooms);
    });

    call.on('cancelled', () => {
      this.handleUserDisconnect(userId, currentRooms);
    });
  }

  handleChatMessage(message, userRooms) {
    const roomId = message.room_id;
    
    if (!userRooms.has(roomId)) {
      throw new Error('User not in room');
    }

    // Add timestamp and ID
    message.id = uuidv4();
    message.timestamp = Date.now();

    // Store message in history
    if (!this.messageHistory.has(roomId)) {
      this.messageHistory.set(roomId, []);
    }
    this.messageHistory.get(roomId).push(message);

    // Broadcast to all users in room
    this.broadcastToRoom(roomId, message);
  }

  handleTypingIndicator(message, userRooms) {
    const roomId = message.room_id;
    
    if (!userRooms.has(roomId)) {
      return; // Ignore if user not in room
    }

    // Broadcast typing indicator (don't store in history)
    this.broadcastToRoom(roomId, message, message.user_id);
  }

  handleSystemMessage(message, userRooms) {
    const roomId = message.room_id;
    
    // Store system message
    if (!this.messageHistory.has(roomId)) {
      this.messageHistory.set(roomId, []);
    }
    
    message.id = uuidv4();
    message.timestamp = Date.now();
    this.messageHistory.get(roomId).push(message);

    // Broadcast to room
    this.broadcastToRoom(roomId, message);
  }

  broadcastToRoom(roomId, message, excludeUserId = null) {
    const roomUsers = this.rooms.get(roomId) || new Set();
    
    roomUsers.forEach(userId => {
      if (userId !== excludeUserId) {
        const userStream = this.userStreams.get(userId);
        if (userStream && !userStream.destroyed) {
          try {
            userStream.write(message);
          } catch (error) {
            console.error(`Failed to send message to user ${userId}:`, error);
            this.userStreams.delete(userId);
          }
        }
      }
    });
  }

  handleUserDisconnect(userId, userRooms) {
    if (!userId) return;

    // Remove user from streams
    this.userStreams.delete(userId);
    
    // Update presence
    this.userPresence.set(userId, 'OFFLINE');
    
    // Notify rooms about user leaving
    userRooms.forEach(roomId => {
      const leaveMessage = {
        id: uuidv4(),
        room_id: roomId,
        user_id: userId,
        content: `User left the room`,
        timestamp: Date.now(),
        type: 'SYSTEM'
      };
      
      this.broadcastToRoom(roomId, leaveMessage);
    });
  }

  // Join room
  joinRoom(call, callback) {
    try {
      const { room_id, user_id, username } = call.request;
      
      // Add user to room
      if (!this.rooms.has(room_id)) {
        this.rooms.set(room_id, new Set());
      }
      this.rooms.get(room_id).add(user_id);
      
      // Track user's rooms
      if (!this.userRooms.has(user_id)) {
        this.userRooms.set(user_id, new Set());
      }
      this.userRooms.get(user_id).add(room_id);
      
      // Update presence
      this.userPresence.set(user_id, 'ONLINE');
      
      // Get current participants
      const participants = Array.from(this.rooms.get(room_id));
      
      // Send join notification
      const joinMessage = {
        id: uuidv4(),
        room_id: room_id,
        user_id: user_id,
        username: username,
        content: `${username} joined the room`,
        timestamp: Date.now(),
        type: 'SYSTEM'
      };
      
      this.broadcastToRoom(room_id, joinMessage);
      
      callback(null, {
        success: true,
        message: 'Successfully joined room',
        participants: participants
      });
    } catch (error) {
      callback(error);
    }
  }

  // Leave room
  leaveRoom(call, callback) {
    try {
      const { room_id, user_id } = call.request;
      
      // Remove user from room
      if (this.rooms.has(room_id)) {
        this.rooms.get(room_id).delete(user_id);
        
        // Clean up empty rooms
        if (this.rooms.get(room_id).size === 0) {
          this.rooms.delete(room_id);
        }
      }
      
      // Remove room from user's rooms
      if (this.userRooms.has(user_id)) {
        this.userRooms.get(user_id).delete(room_id);
      }
      
      // Send leave notification
      const leaveMessage = {
        id: uuidv4(),
        room_id: room_id,
        user_id: user_id,
        content: `User left the room`,
        timestamp: Date.now(),
        type: 'SYSTEM'
      };
      
      this.broadcastToRoom(room_id, leaveMessage);
      
      callback(null, {
        success: true,
        message: 'Successfully left room'
      });
    } catch (error) {
      callback(error);
    }
  }

  // Get chat history
  getHistory(call, callback) {
    try {
      const { room_id, limit = 50, before_timestamp } = call.request;
      
      let messages = this.messageHistory.get(room_id) || [];
      
      // Filter by timestamp if provided
      if (before_timestamp) {
        messages = messages.filter(msg => msg.timestamp < before_timestamp);
      }
      
      // Sort by timestamp (newest first) and limit
      messages = messages
        .sort((a, b) => b.timestamp - a.timestamp)
        .slice(0, limit);
      
      const hasMore = messages.length === limit;
      
      callback(null, {
        messages: messages.reverse(), // Return in chronological order
        has_more: hasMore
      });
    } catch (error) {
      callback(error);
    }
  }

  // Update user presence
  updatePresence(call, callback) {
    try {
      const { user_id, status } = call.request;
      
      this.userPresence.set(user_id, status);
      
      // Notify all rooms user is in about presence change
      const userRooms = this.userRooms.get(user_id) || new Set();
      userRooms.forEach(roomId => {
        const presenceMessage = {
          id: uuidv4(),
          room_id: roomId,
          user_id: user_id,
          content: `User is now ${status.toLowerCase()}`,
          timestamp: Date.now(),
          type: 'SYSTEM',
          metadata: { presence: status }
        };
        
        this.broadcastToRoom(roomId, presenceMessage, user_id);
      });
      
      callback(null, { success: true });
    } catch (error) {
      callback(error);
    }
  }
}

// Create and start server
function startChatServer(port = 50053) {
  const server = new grpc.Server();
  const chatService = new ChatService();
  
  // Add interceptors
  server.addService(chatProto.ChatService.service, {
    chatStream: chatService.chatStream.bind(chatService),
    joinRoom: chatService.joinRoom.bind(chatService),
    leaveRoom: chatService.leaveRoom.bind(chatService),
    getHistory: chatService.getHistory.bind(chatService),
    updatePresence: chatService.updatePresence.bind(chatService)
  });
  
  server.bindAsync(
    `0.0.0.0:${port}`,
    grpc.ServerCredentials.createInsecure(),
    (error, port) => {
      if (error) {
        console.error('Failed to start chat server:', error);
        return;
      }
      
      console.log(`Chat server listening on port ${port}`);
      server.start();
    }
  );
  
  return server;
}

if (require.main === module) {
  startChatServer(50055);
}

module.exports = {
  ChatService,
  startChatServer,
  chatProto
};
