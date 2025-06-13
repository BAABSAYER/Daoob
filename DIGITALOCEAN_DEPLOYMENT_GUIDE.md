# DAOOB DigitalOcean Production Deployment

## Overview
Complete step-by-step guide for deploying the DAOOB event management platform on DigitalOcean using Docker containers.

## Prerequisites

### DigitalOcean Setup
1. **Create DigitalOcean Account** and add payment method
2. **Create Droplet** (recommended: 4GB RAM, 2 vCPU, 80GB SSD)
   - Ubuntu 22.04 LTS
   - Enable monitoring
   - Add SSH key for secure access

### Local Requirements
- Docker installed locally (for testing)
- Git for code management
- SSH client for server access

## Step 1: Server Preparation

### Connect to Your Droplet
```bash
ssh root@your_droplet_ip
```

### Install Docker and Dependencies
```bash
# Update system
apt update && apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install Git and other tools
apt install -y git nano htop
```

### Setup Project Directory
```bash
mkdir -p /var/www/daoob
cd /var/www/daoob
```

## Step 2: Upload Project Files

### Option A: Direct Upload (Recommended)
Upload these files to `/var/www/daoob/`:
- `Dockerfile`
- `docker-compose.yml`
- `nginx.conf`
- `package.json` and `package-lock.json`
- Complete source code (`client/`, `server/`, `shared/`)

### Option B: Git Clone (if using repository)
```bash
git clone https://github.com/yourusername/daoob.git .
```

## Step 3: Environment Configuration

### Create Production Environment File
```bash
nano .env
```

Add production configuration:
```env
NODE_ENV=production
PORT=5000
HOST=0.0.0.0
DOCKER_CONTAINER=true

# Database Configuration
DATABASE_URL=postgresql://daoob_user:your_secure_password_2024@postgres:5432/daoob_production
PGHOST=postgres
PGPORT=5432
PGUSER=daoob_user
PGPASSWORD=your_secure_password_2024
PGDATABASE=daoob_production

# Security
SESSION_SECRET=your_super_secure_session_secret_min_32_characters_long_2024

# Optional: Domain configuration
DOMAIN=yourdomain.com
```

## Step 4: SSL Certificate Setup (Optional but Recommended)

### Install Certbot for Let's Encrypt
```bash
apt install -y certbot python3-certbot-nginx

# Generate certificate (replace yourdomain.com)
certbot certonly --standalone -d yourdomain.com -d www.yourdomain.com
```

### Update Nginx Configuration for SSL
Add to `nginx.conf`:
```nginx
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name yourdomain.com www.yourdomain.com;

    ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;
    
    # SSL Security Settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Rest of configuration same as HTTP version...
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name yourdomain.com www.yourdomain.com;
    return 301 https://$server_name$request_uri;
}
```

## Step 5: Deploy Application

### Build and Start Services
```bash
cd /var/www/daoob

# Build and start all services
docker-compose up --build -d

# Check service status
docker-compose ps
```

Expected output:
```
    Name                   Command               State           Ports
-------------------------------------------------------------------------
daoob_api     npm start                     Up      5000/tcp
nginx         nginx -g daemon off;          Up      0.0.0.0:80->80/tcp
postgres      docker-entrypoint.sh postgres Up      5432/tcp
```

### Initialize Database
```bash
# Access application container
docker exec -it daoob_api sh

# Run database migrations
npm run db:push

# Create admin user
node -e "
const { storage } = require('./dist/storage.js');
storage.createUser({
  username: 'admin',
  password: 'admin123',
  email: 'admin@yourdomain.com',
  fullName: 'System Administrator',
  userType: 'admin'
}).then(() => console.log('Admin user created'));
"

# Exit container
exit
```

## Step 6: Verify Deployment

### Test Health Endpoints
```bash
# Test application health
curl http://localhost/health

# Test from external (replace with your domain/IP)
curl http://your_droplet_ip/health
```

### Check Logs
```bash
# View all service logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f daoob_api
docker-compose logs -f nginx
docker-compose logs -f postgres
```

### Test Web Dashboard
1. Open browser to `http://your_droplet_ip` or `https://yourdomain.com`
2. Login with credentials: `admin` / `admin123`
3. Verify all features work correctly

## Step 7: Production Optimizations

### Setup Firewall
```bash
# Enable UFW firewall
ufw enable

# Allow SSH, HTTP, HTTPS
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp

# Check status
ufw status
```

### Setup Automatic Backups
Create backup script:
```bash
nano /root/backup.sh
```

Add backup script:
```bash
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/root/backups"

mkdir -p $BACKUP_DIR

# Database backup
docker exec postgres pg_dump -U daoob_user daoob_production > "$BACKUP_DIR/db_backup_$DATE.sql"

# Application files backup
docker cp daoob_api:/app/uploads "$BACKUP_DIR/uploads_backup_$DATE"

# Keep only last 7 days of backups
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
find $BACKUP_DIR -name "uploads_backup_*" -mtime +7 -exec rm -rf {} +

echo "Backup completed: $DATE"
```

Make executable and add to crontab:
```bash
chmod +x /root/backup.sh

# Add to crontab (daily backup at 3 AM)
crontab -e
```

Add line:
```
0 3 * * * /root/backup.sh >> /var/log/backup.log 2>&1
```

### Setup Auto-renewal for SSL
```bash
# Add to crontab for certificate renewal
echo "0 12 * * * /usr/bin/certbot renew --quiet && docker-compose restart nginx" | crontab -
```

## Step 8: Monitoring and Maintenance

### Setup Process Monitoring
```bash
# Install and configure htop for monitoring
htop

# Monitor Docker containers
docker stats

# Monitor logs in real-time
docker-compose logs -f --tail=100
```

### Update Deployment
```bash
# Pull latest changes (if using Git)
git pull origin main

# Rebuild and restart
docker-compose up --build -d

# Check status
docker-compose ps
```

## Step 9: Domain Configuration

### DNS Setup
In your domain registrar, add these DNS records:
```
Type: A
Name: @
Value: your_droplet_ip

Type: A  
Name: www
Value: your_droplet_ip
```

### Mobile App Configuration
Update your Flutter app's API base URL to point to your domain:
```dart
// In your Flutter app
static const String baseUrl = 'https://yourdomain.com/api';
```

## Troubleshooting

### Common Issues

**Container won't start:**
```bash
# Check logs
docker-compose logs servicename

# Check disk space
df -h

# Check memory
free -h
```

**Database connection errors:**
```bash
# Check PostgreSQL status
docker-compose logs postgres

# Test database connection
docker exec -it postgres psql -U daoob_user daoob_production
```

**Nginx proxy errors:**
```bash
# Test Nginx configuration
docker exec nginx nginx -t

# Check upstream connectivity
docker-compose logs daoob_api
```

### Performance Optimization

**Enable Redis caching (optional):**
Add to `docker-compose.yml`:
```yaml
redis:
  image: redis:alpine
  restart: unless-stopped
  networks:
    - daoob_network
```

**Database optimization:**
```sql
-- Connect to database and run
VACUUM ANALYZE;
REINDEX DATABASE daoob_production;
```

## Security Checklist

- [ ] Firewall configured (UFW enabled)
- [ ] SSH key authentication (disable password auth)
- [ ] SSL certificate installed and auto-renewal setup
- [ ] Regular backups configured
- [ ] Strong database passwords
- [ ] Security headers configured in Nginx
- [ ] Rate limiting enabled
- [ ] Regular security updates scheduled

## Production URLs

**Web Admin Dashboard:**
- HTTP: `http://your_droplet_ip`
- HTTPS: `https://yourdomain.com`

**Mobile API Endpoints:**
- Base URL: `https://yourdomain.com/api`
- WebSocket: `wss://yourdomain.com/ws`

**Admin Login:**
- Username: `admin`
- Password: `admin123` (change after first login)

Your DAOOB platform is now fully deployed and production-ready on DigitalOcean!