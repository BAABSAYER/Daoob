# Production Dockerfile for DAOOB platform
FROM node:20-alpine

# Install build dependencies for native modules
RUN apk add --no-cache python3 make g++

WORKDIR /app

# Copy package files first for better layer caching
COPY package*.json ./

# Install all dependencies for build
RUN npm ci

# Copy source code
COPY client ./client
COPY server ./server
COPY shared ./shared
COPY vite.config.ts ./
COPY tsconfig.json ./
COPY tailwind.config.ts ./
COPY postcss.config.js ./
COPY components.json ./
COPY drizzle.config.ts ./

# Build the application using existing build script
RUN npm run build

# Keep all node_modules for now since the bundled server imports dev dependencies
# This is a temporary fix - in production the build process should be improved

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S daoob -u 1001

# Set proper permissions
RUN chown -R daoob:nodejs /app

# Switch to non-root user
USER daoob

# Expose port
EXPOSE 5000

# Health check endpoint
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD node -e "require('http').get('http://localhost:5000/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) })"

# Start the application
CMD ["npm", "start"]