# Simple production Dockerfile that works
FROM node:20-alpine

# Install build dependencies for native modules
RUN apk add --no-cache python3 make g++

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy all source code
COPY . .

# Build the application using the existing scripts
RUN npm run build

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S daoob -u 1001

# Set permissions
RUN chown -R daoob:nodejs /app

# Switch to non-root user
USER daoob

# Expose port
EXPOSE 3001

# Start the application directly with tsx in production mode
CMD ["npm", "start"]