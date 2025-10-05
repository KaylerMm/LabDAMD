FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY api-gateway/package.json ./
COPY shared/ ./shared/

# Install dependencies
RUN npm install

# Copy source code
COPY api-gateway/ ./

# Expose port
EXPOSE 3000

# Start the application
CMD ["node", "server.js"]
