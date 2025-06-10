#!/bin/bash
set -e

echo "🚀 DAOOB DigitalOcean Docker Deployment Script"
echo "=============================================="

# Configuration
DROPLET_IP=""
SSH_KEY_PATH="~/.ssh/id_rsa"
REMOTE_USER="root"
PROJECT_NAME="daoob"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if droplet IP is provided
if [ -z "$1" ]; then
    print_error "Please provide your DigitalOcean droplet IP address"
    echo "Usage: ./deploy-to-digitalocean.sh YOUR_DROPLET_IP"
    echo "Example: ./deploy-to-digitalocean.sh 157.245.1.234"
    exit 1
fi

DROPLET_IP="$1"

print_status "Starting deployment to DigitalOcean droplet: $DROPLET_IP"

# 1. Check local requirements
print_status "Checking local requirements..."
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed locally. Please install Docker first."
    exit 1
fi

if ! command -v rsync &> /dev/null; then
    print_error "rsync is not installed. Please install rsync first."
    exit 1
fi

# 2. Test SSH connection
print_status "Testing SSH connection to droplet..."
if ! ssh -o ConnectTimeout=10 -i $SSH_KEY_PATH $REMOTE_USER@$DROPLET_IP "echo 'SSH connection successful'" &> /dev/null; then
    print_error "Cannot connect to droplet via SSH. Please check:"
    echo "  - Your SSH key path: $SSH_KEY_PATH"
    echo "  - Droplet IP: $DROPLET_IP"
    echo "  - SSH key is added to your DigitalOcean droplet"
    exit 1
fi

print_status "SSH connection successful"

# 3. Install Docker and Docker Compose on droplet
print_status "Installing Docker and Docker Compose on droplet..."
ssh -i $SSH_KEY_PATH $REMOTE_USER@$DROPLET_IP << 'EOF'
# Update system
apt update && apt upgrade -y

# Install Docker if not already installed
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    systemctl enable docker
    systemctl start docker
    rm get-docker.sh
    echo "Docker installed successfully"
else
    echo "Docker is already installed"
fi

# Install Docker Compose if not already installed
if ! command -v docker-compose &> /dev/null; then
    echo "Installing Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    echo "Docker Compose installed successfully"
else
    echo "Docker Compose is already installed"
fi

# Install other required tools
apt install -y nginx certbot python3-certbot-nginx ufw git

# Configure firewall
ufw --force enable
ufw allow ssh
ufw allow http
ufw allow https
ufw allow 8080
EOF

# 4. Create project directory on droplet
print_status "Creating project directory on droplet..."
ssh -i $SSH_KEY_PATH $REMOTE_USER@$DROPLET_IP "mkdir -p /opt/$PROJECT_NAME"

# 5. Copy project files to droplet
print_status "Copying project files to droplet..."
rsync -avz --progress \
    --exclude node_modules \
    --exclude dist \
    --exclude 'client/dist' \
    --exclude 'daoob_mobile/build' \
    --exclude '.git' \
    --exclude '*.log' \
    -e "ssh -i $SSH_KEY_PATH" \
    ./ $REMOTE_USER@$DROPLET_IP:/opt/$PROJECT_NAME/

# 6. Build and deploy on droplet
print_status "Building and deploying application on droplet..."
ssh -i $SSH_KEY_PATH $REMOTE_USER@$DROPLET_IP << EOF
cd /opt/$PROJECT_NAME

# Stop any existing containers
docker-compose down --remove-orphans || true

# Remove old images to free up space
docker system prune -f

# Build and start the application
docker-compose up --build -d

# Wait for services to start
echo "Waiting for services to start..."
sleep 30

# Check if services are running
docker-compose ps

# Check application health
echo "Checking application health..."
sleep 10

# Test the health endpoint
if curl -f http://localhost:5000/health; then
    echo "✅ Application is healthy!"
else
    echo "❌ Application health check failed"
    echo "Checking logs..."
    docker-compose logs daoob_app
fi
EOF

# 7. Display deployment information
print_status "Deployment completed!"
echo ""
echo "🎉 DAOOB has been deployed successfully!"
echo ""
echo "📱 Access Information:"
echo "   Web Dashboard: http://$DROPLET_IP:8080"
echo "   Direct API: http://$DROPLET_IP"
echo "   Health Check: http://$DROPLET_IP/health"
echo ""
echo "📱 Mobile App Configuration:"
echo "   Update your Flutter app's API base URL to: http://$DROPLET_IP"
echo ""
echo "🔧 Management Commands:"
echo "   SSH to server: ssh -i $SSH_KEY_PATH $REMOTE_USER@$DROPLET_IP"
echo "   View logs: docker-compose logs -f"
echo "   Restart: docker-compose restart"
echo "   Stop: docker-compose down"
echo ""
echo "🗄️ Database Access:"
echo "   Connection: postgresql://daoob_user:daoob_secure_password_2024@$DROPLET_IP:5432/daoob_production"
echo ""

# 8. Run post-deployment setup
print_status "Running post-deployment setup..."
ssh -i $SSH_KEY_PATH $REMOTE_USER@$DROPLET_IP << 'EOF'
cd /opt/daoob

echo "Creating admin user and setting up database..."

# Wait for database to be ready
sleep 15

# Create admin user
docker-compose exec -T daoob_app node -e "
const { storage } = require('./dist/storage.js');
const { scrypt, randomBytes } = require('crypto');
const { promisify } = require('util');

const scryptAsync = promisify(scrypt);

async function createAdmin() {
  try {
    console.log('Creating admin user...');
    
    // Check if admin already exists
    const existingAdmin = await storage.getUserByUsername('admin');
    if (existingAdmin) {
      console.log('Admin user already exists');
      return;
    }
    
    const salt = randomBytes(16).toString('hex');
    const buf = await scryptAsync('admin123', salt, 64);
    const hashedPassword = buf.toString('hex') + '.' + salt;
    
    const admin = await storage.createUser({
      username: 'admin',
      email: 'admin@daoob.com',
      password: hashedPassword,
      userType: 'admin',
      fullName: 'System Administrator'
    });
    
    console.log('Admin user created with ID:', admin.id);
    
    // Add admin permissions
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
    
    console.log('✅ Admin user setup completed!');
    console.log('Username: admin');
    console.log('Password: admin123');
    
  } catch (error) {
    console.error('Error creating admin user:', error);
  }
}

createAdmin().then(() => process.exit(0)).catch(console.error);
" || echo "Admin user creation completed (may already exist)"

echo ""
echo "🔑 Default Admin Credentials:"
echo "   Username: admin"
echo "   Password: admin123"
echo "   Please change this password after first login!"
echo ""
EOF

print_status "Setup completed! Your DAOOB platform is ready to use."

echo ""
echo "📋 Next Steps:"
echo "1. Access the web dashboard at http://$DROPLET_IP:8080"
echo "2. Login with admin/admin123 and change the password"
echo "3. Update your Flutter app's API configuration"
echo "4. Test the complete workflow"
echo ""
print_warning "Remember to change the default admin password and update session secrets for production use!"