# DAOOB Platform - Comprehensive Deployment Guide

## Overview
DAOOB is a full-stack event management platform with React.js web admin dashboard, Flutter mobile app, Node.js/Express backend, and PostgreSQL database.

## System Architecture

### Backend (Node.js/Express)
- **Framework**: Express.js with TypeScript
- **Database**: PostgreSQL with Drizzle ORM
- **Authentication**: Session-based with Passport.js
- **Real-time**: WebSocket messaging
- **API**: RESTful endpoints with proper validation

### Frontend (React.js Web Dashboard)
- **Framework**: React 18 with TypeScript
- **Routing**: Wouter
- **State Management**: TanStack Query
- **UI**: Shadcn/ui + Tailwind CSS
- **Build Tool**: Vite

### Mobile App (Flutter)
- **Framework**: Flutter/Dart
- **State Management**: Provider
- **HTTP Client**: Custom session-based API service
- **Localization**: Arabic/English support

## Deployment Options

### 1. Production-Ready Deployment (Recommended)

#### Prerequisites
```bash
# System requirements
- Node.js 20+
- PostgreSQL 14+
- Flutter 3.0+ (for mobile builds)
- 2GB+ RAM
- 20GB+ storage
```

#### Environment Variables
```env
# Database
DATABASE_URL=postgresql://username:password@host:port/database
PGHOST=your-db-host
PGPORT=5432
PGUSER=your-username
PGPASSWORD=your-password
PGDATABASE=daoob_production

# Security
SESSION_SECRET=your-super-secure-session-secret-min-32-chars
NODE_ENV=production

# Server
PORT=5000
HOST=0.0.0.0
```

#### Build and Deploy Steps

##### Backend Deployment
```bash
# 1. Clone and install dependencies
git clone <your-repo>
cd daoob-platform
npm install

# 2. Database setup
npm run db:push

# 3. Create admin user
node -e "
const { storage } = require('./server/storage.ts');
const { scrypt, randomBytes } = require('crypto');
const { promisify } = require('util');
const scryptAsync = promisify(scrypt);

async function createAdmin() {
  const salt = randomBytes(16).toString('hex');
  const buf = await scryptAsync('your-admin-password', salt, 64);
  const hashedPassword = buf.toString('hex') + '.' + salt;
  
  const admin = await storage.createUser({
    username: 'admin',
    email: 'admin@yourdomain.com',
    password: hashedPassword,
    userType: 'admin',
    fullName: 'System Administrator'
  });
  
  await storage.addAdminPermission({
    userId: admin.id,
    permission: 'manage_event_requests'
  });
  await storage.addAdminPermission({
    userId: admin.id,
    permission: 'manage_quotations'
  });
  await storage.addAdminPermission({
    userId: admin.id,
    permission: 'view_quotations'
  });
  
  console.log('Admin user created successfully');
}
createAdmin();
"

# 4. Build application
npm run build

# 5. Start production server
npm start
```

##### Frontend Build
```bash
# Frontend is included in the main build process
# Vite builds the React app to dist/ directory
# Express serves it as static files
```

##### Mobile App Build
```bash
cd daoob_mobile

# Android build
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk

# iOS build (requires macOS and Xcode)
flutter build ios --release
```

### 2. Cloud Deployment Options

#### A. Traditional VPS/Server
```bash
# Ubuntu/Debian setup
sudo apt update
sudo apt install nodejs npm postgresql nginx certbot

# Install PM2 for process management
npm install -g pm2

# Create PM2 ecosystem file
cat > ecosystem.config.js << EOF
module.exports = {
  apps: [{
    name: 'daoob-api',
    script: 'dist/index.js',
    instances: 'max',
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production',
      PORT: 5000
    }
  }]
};
EOF

# Start with PM2
pm2 start ecosystem.config.js
pm2 save
pm2 startup
```

#### B. Docker Deployment
```dockerfile
# Dockerfile
FROM node:20-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./
RUN npm ci --only=production

# Copy built application
COPY dist/ ./dist/
COPY client/dist/ ./client/dist/

EXPOSE 5000

CMD ["node", "dist/index.js"]
```

```yaml
# docker-compose.yml
version: '3.8'
services:
  app:
    build: .
    ports:
      - "5000:5000"
    environment:
      - NODE_ENV=production
      - DATABASE_URL=postgresql://postgres:password@db:5432/daoob
      - SESSION_SECRET=your-secret-key
    depends_on:
      - db

  db:
    image: postgres:14
    environment:
      - POSTGRES_DB=daoob
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

volumes:
  postgres_data:
```

#### C. Platform-as-a-Service (PaaS)

##### Heroku
```bash
# Install Heroku CLI and login
heroku create your-app-name

# Add PostgreSQL addon
heroku addons:create heroku-postgresql:mini

# Set environment variables
heroku config:set SESSION_SECRET=your-secret-key
heroku config:set NODE_ENV=production

# Deploy
git push heroku main
```

##### Railway
```bash
# Install Railway CLI
npm install -g @railway/cli

# Login and deploy
railway login
railway init
railway up
```

##### DigitalOcean App Platform
- Connect GitHub repository
- Set environment variables in dashboard
- Configure build and run commands
- Deploy automatically

### 3. Database Setup

#### PostgreSQL Configuration
```sql
-- Create database
CREATE DATABASE daoob_production;

-- Create user with appropriate permissions
CREATE USER daoob_user WITH PASSWORD 'secure_password';
GRANT ALL PRIVILEGES ON DATABASE daoob_production TO daoob_user;

-- Connect to database and grant schema permissions
\c daoob_production
GRANT ALL ON SCHEMA public TO daoob_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO daoob_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO daoob_user;
```

#### Database Migration
```bash
# Run migrations
npm run db:push

# Verify tables are created
psql $DATABASE_URL -c "\dt"
```

### 4. Mobile App Distribution

#### Android
```bash
# Build signed APK
flutter build apk --release

# Or build App Bundle for Google Play
flutter build appbundle --release

# Upload to Google Play Console
# - Create app listing
# - Upload APK/AAB
- Configure store listing
# - Submit for review
```

#### iOS
```bash
# Build for iOS (requires macOS)
flutter build ios --release

# Archive in Xcode
# - Open ios/Runner.xcworkspace
# - Product > Archive
# - Upload to App Store Connect
```

## Security Considerations

### 1. Environment Security
```bash
# Use strong session secrets (32+ characters)
SESSION_SECRET=$(openssl rand -base64 32)

# Secure database connections
DATABASE_URL=postgresql://user:pass@host:5432/db?sslmode=require

# Restrict CORS origins in production
CORS_ORIGIN=https://yourdomain.com
```

### 2. Rate Limiting
```javascript
// Add to server/index.ts
import rateLimit from 'express-rate-limit';

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});

app.use('/api', limiter);
```

### 3. HTTPS Configuration
```nginx
# Nginx configuration
server {
    listen 80;
    server_name yourdomain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl;
    server_name yourdomain.com;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/private.key;
    
    location / {
        proxy_pass http://localhost:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## Monitoring and Maintenance

### 1. Health Checks
```javascript
// Add to server/routes.ts
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});
```

### 2. Logging
```javascript
// Production logging
import winston from 'winston';

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({ filename: 'error.log', level: 'error' }),
    new winston.transports.File({ filename: 'combined.log' })
  ]
});
```

### 3. Database Backups
```bash
# Daily backup script
#!/bin/bash
BACKUP_DIR="/backups"
DATE=$(date +%Y%m%d_%H%M%S)
pg_dump $DATABASE_URL > $BACKUP_DIR/daoob_backup_$DATE.sql

# Keep only last 7 days
find $BACKUP_DIR -name "daoob_backup_*.sql" -mtime +7 -delete
```

## Performance Optimization

### 1. Database Indexing
```sql
-- Add indexes for common queries
CREATE INDEX idx_event_requests_client_id ON event_requests(client_id);
CREATE INDEX idx_event_requests_status ON event_requests(status);
CREATE INDEX idx_quotations_event_request_id ON quotations(event_request_id);
CREATE INDEX idx_messages_participants ON messages(sender_id, receiver_id);
```

### 2. Caching
```javascript
// Redis caching for session store
import Redis from 'ioredis';
import connectRedis from 'connect-redis';

const redis = new Redis(process.env.REDIS_URL);
const RedisStore = connectRedis(session);

app.use(session({
  store: new RedisStore({ client: redis }),
  // ... other session options
}));
```

### 3. Static Asset Optimization
```javascript
// Compression middleware
import compression from 'compression';
app.use(compression());

// Static file caching
app.use(express.static('client/dist', {
  maxAge: '1y',
  etag: false
}));
```

## Troubleshooting Common Issues

### 1. Database Connection Issues
```bash
# Test database connection
psql $DATABASE_URL -c "SELECT 1;"

# Check connection limits
psql $DATABASE_URL -c "SHOW max_connections;"
```

### 2. Memory Issues
```bash
# Monitor memory usage
ps aux | grep node
free -h

# Increase Node.js memory limit
node --max-old-space-size=4096 dist/index.js
```

### 3. WebSocket Issues
```javascript
// Add WebSocket error handling
wss.on('error', (error) => {
  console.error('WebSocket server error:', error);
});
```

## Platform-Agnostic Considerations

This application is designed to work on any hosting service that supports:
- Node.js 20+
- PostgreSQL database
- WebSocket connections
- Static file serving

The codebase avoids platform-specific dependencies and uses standard technologies, making it deployable on:
- Traditional VPS (DigitalOcean, Linode, AWS EC2)
- PaaS platforms (Heroku, Railway, Vercel, Netlify)
- Container platforms (Docker, Kubernetes)
- Serverless platforms (with minor modifications)

For specific platform deployment guides, refer to the platform's documentation and adapt the environment variables and build commands accordingly.