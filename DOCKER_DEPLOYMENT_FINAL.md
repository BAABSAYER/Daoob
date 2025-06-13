# DAOOB Docker Production Deployment Guide

## Overview
This guide provides step-by-step instructions for deploying the DAOOB event management platform using Docker in a production environment.

**Updated: June 13, 2025** - Fixed Docker build dependencies and optimized configurations for production deployment.

## Prerequisites

### System Requirements
- Docker 24.0+ and Docker Compose 2.0+
- 4GB RAM minimum (8GB recommended)
- 20GB disk space minimum
- Ubuntu 20.04+ or CentOS 8+ (for production servers)

### Required Files
Ensure these files are present in your project directory:
- `Dockerfile` (optimized build configuration)
- `docker-compose.yml` (multi-service orchestration)
- `nginx.conf` (reverse proxy configuration)
- `package.json` and `package-lock.json`
- Application source code (`client/`, `server/`, `shared/`)

## Deployment Steps

### 1. Environment Setup

Create production environment file:
```bash
cp .env.example .env
```

Update `.env` with production values:
```env
NODE_ENV=production
DATABASE_URL=postgresql://daoob_user:your_secure_password@postgres:5432/daoob_production
SESSION_SECRET=your_super_secure_session_secret_min_32_characters_long
PGHOST=postgres
PGPORT=5432
PGUSER=daoob_user
PGPASSWORD=your_secure_password
PGDATABASE=daoob_production
```

### 2. Docker Build and Deployment

Start all services:
```bash
docker-compose up --build -d
```

This command will:
- Build the DAOOB application image
- Start PostgreSQL database with persistent storage
- Start Nginx reverse proxy
- Set up networking between services

### 3. Verify Deployment

Check service status:
```bash
docker-compose ps
```

View application logs:
```bash
docker-compose logs -f daoob_api
```

Test health endpoint:
```bash
curl http://localhost/health
```

Expected response:
```json
{
  "status": "healthy",
  "timestamp": "2025-06-13T17:42:00.000Z",
  "uptime": 120,
  "environment": "production"
}
```

### 4. Database Initialization

Access the running container:
```bash
docker exec -it daoob_api sh
```

Run database migrations:
```bash
npm run db:push
```

Create admin user (if needed):
```bash
node -e "
const { storage } = require('./dist/storage.js');
storage.createUser({
  username: 'admin',
  password: 'admin123',
  email: 'admin@daoob.com',
  fullName: 'System Administrator',
  userType: 'admin'
}).then(() => console.log('Admin user created'));
"
```

## Architecture Overview

### Service Configuration

**Application Container (daoob_api)**
- Port: 5000 (internal)
- Health check: `/health` endpoint
- Volume: `app_uploads` for file storage
- Environment: Production mode with PostgreSQL

**Database Container (postgres)**
- Port: 5432 (internal)
- Volume: `postgres_data` for persistence
- Image: PostgreSQL 15 Alpine
- Health check: Connection verification

**Nginx Container (nginx)**
- Port: 80 (external)
- Configuration: Reverse proxy with rate limiting
- Features: WebSocket support, static file caching, security headers

### Network Architecture
```
Internet → Nginx (Port 80) → DAOOB App (Port 5000)
                          ↓
                   PostgreSQL (Port 5432)
```

## Production Optimizations

### Security Features
- Non-root user execution in containers
- Security headers via Nginx
- Rate limiting on API endpoints
- Session-based authentication with secure cookies

### Performance Features
- Multi-stage Docker builds with dependency cleanup
- Nginx static file caching with 1-year expiration
- Gzip compression for text content
- PostgreSQL connection pooling

### Monitoring Features
- Health check endpoints for all services
- Application logs via Docker logging
- Container restart policies
- Resource limits and reservations

## Maintenance Commands

### View Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f daoob_api
docker-compose logs -f postgres
docker-compose logs -f nginx
```

### Database Backup
```bash
docker exec postgres pg_dump -U daoob_user daoob_production > backup.sql
```

### Database Restore
```bash
cat backup.sql | docker exec -i postgres psql -U daoob_user daoob_production
```

### Update Application
```bash
# Pull latest changes
git pull origin main

# Rebuild and restart
docker-compose up --build -d

# View updated logs
docker-compose logs -f daoob_api
```

### Scaling Services
```bash
# Scale application instances
docker-compose up --scale daoob_api=3 -d
```

## Troubleshooting

### Common Issues

**Build fails with module not found:**
- Ensure all dependencies are in package.json
- Verify Dockerfile installs all dependencies before build

**Database connection errors:**
- Check PostgreSQL container status: `docker-compose ps postgres`
- Verify environment variables match container configuration
- Ensure PostgreSQL is fully started before application

**Nginx proxy errors:**
- Check Nginx configuration syntax: `docker exec nginx nginx -t`
- Verify upstream server is responding: `docker-compose logs daoob_api`
- Check port mappings in docker-compose.yml

### Performance Monitoring

Check resource usage:
```bash
docker stats
```

Monitor application metrics:
```bash
curl http://localhost/health
```

Check database performance:
```bash
docker exec postgres psql -U daoob_user daoob_production -c "SELECT * FROM pg_stat_activity;"
```

## SSL/HTTPS Configuration (Optional)

For production deployments with SSL, modify the Nginx configuration:

1. Obtain SSL certificates (Let's Encrypt recommended)
2. Update `nginx.conf` with SSL directives
3. Redirect HTTP to HTTPS
4. Update docker-compose.yml port mappings

Example SSL configuration addition to nginx.conf:
```nginx
server {
    listen 443 ssl http2;
    ssl_certificate /etc/ssl/certs/your_domain.crt;
    ssl_certificate_key /etc/ssl/private/your_domain.key;
    
    # SSL security settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512;
    ssl_prefer_server_ciphers off;
    
    # Rest of configuration...
}
```

## Backup Strategy

### Automated Backup Script
Create a backup script for regular data protection:

```bash
#!/bin/bash
# backup.sh
DATE=$(date +%Y%m%d_%H%M%S)
docker exec postgres pg_dump -U daoob_user daoob_production > "backup_${DATE}.sql"
docker cp daoob_api:/app/uploads ./uploads_backup_${DATE}
echo "Backup completed: ${DATE}"
```

### Restore Procedure
1. Stop application: `docker-compose stop daoob_api`
2. Restore database: `cat backup_file.sql | docker exec -i postgres psql -U daoob_user daoob_production`
3. Restore uploads: `docker cp uploads_backup daoob_api:/app/uploads`
4. Start application: `docker-compose start daoob_api`

This deployment guide ensures a robust, secure, and maintainable Docker-based production environment for the DAOOB platform.