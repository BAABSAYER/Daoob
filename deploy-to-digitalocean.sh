#!/bin/bash

# DAOOB DigitalOcean Deployment Script
# Run this script on your DigitalOcean droplet

set -e

echo "=== DAOOB DigitalOcean Deployment Script ==="
echo "This script will set up the complete DAOOB platform on your server"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root (use sudo)${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Running as root${NC}"

# Update system
echo -e "${YELLOW}Updating system packages...${NC}"
apt update && apt upgrade -y

# Install Docker
echo -e "${YELLOW}Installing Docker...${NC}"
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
    echo -e "${GREEN}✓ Docker installed${NC}"
else
    echo -e "${GREEN}✓ Docker already installed${NC}"
fi

# Install Docker Compose
echo -e "${YELLOW}Installing Docker Compose...${NC}"
if ! command -v docker-compose &> /dev/null; then
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    echo -e "${GREEN}✓ Docker Compose installed${NC}"
else
    echo -e "${GREEN}✓ Docker Compose already installed${NC}"
fi

# Install additional tools
echo -e "${YELLOW}Installing additional tools...${NC}"
apt install -y git nano htop ufw curl

# Setup project directory
echo -e "${YELLOW}Setting up project directory...${NC}"
mkdir -p /var/www/daoob
cd /var/www/daoob

# Create production environment file
echo -e "${YELLOW}Creating production environment configuration...${NC}"
cat > .env << EOL
NODE_ENV=production
PORT=5000
HOST=0.0.0.0
DOCKER_CONTAINER=true

# Database Configuration
DATABASE_URL=postgresql://daoob_user:daoob_secure_password_2024@postgres:5432/daoob_production
PGHOST=postgres
PGPORT=5432
PGUSER=daoob_user
PGPASSWORD=daoob_secure_password_2024
PGDATABASE=daoob_production

# Security
SESSION_SECRET=your_super_secure_session_secret_min_32_characters_long_2024
EOL

echo -e "${GREEN}✓ Environment file created${NC}"

# Setup firewall
echo -e "${YELLOW}Configuring firewall...${NC}"
ufw --force enable
ufw allow ssh
ufw allow 8080/tcp
ufw allow 443/tcp
echo -e "${GREEN}✓ Firewall configured (port 8080)${NC}"

# Create backup directory and script
echo -e "${YELLOW}Setting up backup system...${NC}"
mkdir -p /root/backups

cat > /root/backup.sh << 'EOL'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/root/backups"

mkdir -p $BACKUP_DIR

# Database backup
docker exec postgres pg_dump -U daoob_user daoob_production > "$BACKUP_DIR/db_backup_$DATE.sql"

# Application files backup
if docker ps | grep -q daoob_api; then
    docker cp daoob_api:/app/uploads "$BACKUP_DIR/uploads_backup_$DATE" 2>/dev/null || echo "No uploads directory found"
fi

# Keep only last 7 days of backups
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
find $BACKUP_DIR -name "uploads_backup_*" -mtime +7 -exec rm -rf {} + 2>/dev/null || true

echo "Backup completed: $DATE"
EOL

chmod +x /root/backup.sh

# Add backup to crontab
echo -e "${YELLOW}Setting up automated backups...${NC}"
(crontab -l 2>/dev/null; echo "0 3 * * * /root/backup.sh >> /var/log/backup.log 2>&1") | crontab -
echo -e "${GREEN}✓ Daily backups configured${NC}"

# Create deployment verification script
cat > /root/verify-deployment.sh << 'EOL'
#!/bin/bash

echo "=== DAOOB Deployment Verification ==="

# Check Docker services
echo "Checking Docker services..."
docker-compose ps

# Check application health
echo -e "\nChecking application health..."
curl -s http://localhost:8080/health | head -5

# Check logs for errors
echo -e "\nChecking recent logs for errors..."
docker-compose logs --tail=20 | grep -i error || echo "No recent errors found"

# Check disk space
echo -e "\nDisk space usage:"
df -h /

# Check memory usage
echo -e "\nMemory usage:"
free -h

echo -e "\n=== Verification Complete ==="
EOL

chmod +x /root/verify-deployment.sh

echo -e "${GREEN}✓ Backup system configured${NC}"

# Final instructions
echo ""
echo -e "${GREEN}=== SERVER SETUP COMPLETE ===${NC}"
echo ""
echo "Next steps:"
echo "1. Upload your DAOOB project files to /var/www/daoob/"
echo "2. Ensure these files are present:"
echo "   - Dockerfile"
echo "   - docker-compose.yml" 
echo "   - nginx.conf"
echo "   - package.json"
echo "   - client/, server/, shared/ directories"
echo ""
echo "3. Deploy the application:"
echo "   cd /var/www/daoob"
echo "   docker-compose up --build -d"
echo ""
echo "4. Initialize the database:"
echo "   docker exec -it daoob_api npm run db:push"
echo ""
echo "5. Verify deployment:"
echo "   /root/verify-deployment.sh"
echo ""
echo "Your server is ready for DAOOB deployment!"
echo -e "${YELLOW}Server IP: $(curl -s ifconfig.me)${NC}"
echo ""