FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY services/user-service/package.json ./
COPY shared/ ./shared/

# Install dependencies
RUN npm install

# Copy source code
COPY services/user-service/ ./

# Expose port
EXPOSE 50051

# Start the application
CMD ["node", "server.js"]
