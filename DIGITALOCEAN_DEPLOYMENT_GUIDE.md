# Complete DigitalOcean Deployment Guide for DAOOB Platform

## Prerequisites

### 1. DigitalOcean Setup
- Create a DigitalOcean droplet (minimum 2GB RAM, Ubuntu 22.04)
- Add your SSH key to the droplet during creation
- Note your droplet's IP address

### 2. Local Requirements
- Docker installed on your local machine
- SSH access to your droplet
- Git repository with the DAOOB code

## Step-by-Step Deployment

### Step 1: Prepare Your Local Environment

1. **Clone/Download the project** (if not already done):
```bash
git clone <your-repo-url>
cd daoob-platform
```

2. **Make the deployment script executable**:
```bash
chmod +x deploy-to-digitalocean.sh
```

### Step 2: Deploy to DigitalOcean

Run the deployment script with your droplet IP:
```bash
./deploy-to-digitalocean.sh YOUR_DROPLET_IP
```

Replace `YOUR_DROPLET_IP` with your actual DigitalOcean droplet IP address.

The script will automatically:
- Install Docker and Docker Compose on your droplet
- Copy all project files
- Build the Docker containers
- Start the application
- Create an admin user
- Configure the database

### Step 3: Verify Deployment

After deployment completes, test these URLs in your browser:

1. **Health Check**: `http://YOUR_DROPLET_IP/health`
2. **Web Dashboard**: `http://YOUR_DROPLET_IP:8080`
3. **Direct API**: `http://YOUR_DROPLET_IP`

Login credentials:
- Username: `admin`
- Password: `admin123`

### Step 4: Configure Mobile App for DigitalOcean

1. **Update the Flutter app configuration**:
   - Open `daoob_mobile/lib/config/api_config.dart`
   - Replace `YOUR_DROPLET_IP_HERE` with your actual droplet IP
   
   Example:
   ```dart
   static const String productionApiUrl = 'http://157.245.1.234'; // Your actual IP
   ```

2. **Build the mobile app for testing**:
```bash
cd daoob_mobile
flutter clean
flutter pub get
flutter build ios --debug  # For iOS simulator
```

### Step 5: Test Complete Workflow

#### A. Test Web Dashboard
1. Access `http://YOUR_DROPLET_IP:8080`
2. Login with admin/admin123
3. Navigate to Event Management
4. Create a new event type (e.g., "Wedding")
5. Add questionnaire items

#### B. Test Mobile App
1. Start iOS Simulator
2. Run the Flutter app:
```bash
cd daoob_mobile
flutter run
```
3. Register a new user
4. Browse event types
5. Submit an event request

#### C. Test Admin-Client Workflow
1. **In Mobile App**: Submit an event request
2. **In Web Dashboard**: 
   - View the new request in Event Management
   - Create a quotation for the request
   - Set amount, description, expiry date
3. **In Mobile App**: 
   - Check Event Requests tab
   - View the quotation
   - Accept or decline it
4. **In Web Dashboard**: Verify status updated

## Manual Deployment (Alternative Method)

If the automated script doesn't work, follow these manual steps:

### 1. SSH into Your Droplet
```bash
ssh root@YOUR_DROPLET_IP
```

### 2. Install Docker
```bash
# Update system
apt update && apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
```

### 3. Upload Project Files
From your local machine:
```bash
scp -r ./ root@YOUR_DROPLET_IP:/opt/daoob/
```

### 4. Deploy Application
```bash
ssh root@YOUR_DROPLET_IP
cd /opt/daoob
docker-compose up --build -d
```

### 5. Create Admin User
```bash
docker-compose exec daoob_app node -e "
const { storage } = require('./dist/storage.js');
const { scrypt, randomBytes } = require('crypto');
const { promisify } = require('util');

const scryptAsync = promisify(scrypt);

async function createAdmin() {
  try {
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
  } catch (error) {
    console.error('Error:', error);
  }
}

createAdmin().then(() => process.exit(0));
"
```

## iPhone Simulator Testing

### 1. Start iOS Simulator
```bash
open -a Simulator
```

### 2. Run Flutter App
```bash
cd daoob_mobile
flutter run
```

### 3. Test Network Connectivity
If the app can't connect to your DigitalOcean server:

1. **Check iOS Simulator network settings**
2. **Verify your droplet IP is accessible**:
```bash
ping YOUR_DROPLET_IP
curl http://YOUR_DROPLET_IP/health
```

3. **Check DigitalOcean firewall**:
```bash
# On your droplet
ufw status
ufw allow 80
ufw allow 8080
```

## Common Issues and Solutions

### 1. Docker Build Fails
```bash
# Clear Docker cache
docker system prune -a
docker-compose build --no-cache
```

### 2. Database Connection Issues
```bash
# Check database logs
docker-compose logs postgres

# Restart database
docker-compose restart postgres
```

### 3. Mobile App Can't Connect
- Verify API URL in `api_config.dart`
- Check droplet firewall settings
- Test API endpoint directly in browser

### 4. Port Already in Use
```bash
# Kill processes using port 80
sudo lsof -t -i:80 | xargs sudo kill -9

# Or use different ports in docker-compose.yml
```

## Production Hardening

### 1. Change Default Passwords
```bash
# SSH into droplet
ssh root@YOUR_DROPLET_IP

# Update admin password in web dashboard
# Update database password in docker-compose.yml
```

### 2. Enable HTTPS
```bash
# Install Certbot
apt install certbot python3-certbot-nginx

# Get SSL certificate
certbot --nginx -d yourdomain.com
```

### 3. Configure Firewall
```bash
ufw enable
ufw allow ssh
ufw allow http
ufw allow https
ufw deny 5432  # Block direct database access
```

## Monitoring and Maintenance

### 1. View Application Logs
```bash
docker-compose logs -f daoob_app
```

### 2. Monitor System Resources
```bash
docker stats
htop
df -h
```

### 3. Backup Database
```bash
docker-compose exec postgres pg_dump -U daoob_user daoob_production > backup.sql
```

### 4. Update Application
```bash
# Pull latest code
git pull

# Rebuild and restart
docker-compose down
docker-compose up --build -d
```

## Access Information

After successful deployment:

- **Web Dashboard**: `http://YOUR_DROPLET_IP:8080`
- **API Base**: `http://YOUR_DROPLET_IP`
- **Admin Login**: admin / admin123
- **Database**: `postgresql://daoob_user:daoob_secure_password_2024@YOUR_DROPLET_IP:5432/daoob_production`

## Support Commands

```bash
# Restart all services
docker-compose restart

# View service status
docker-compose ps

# Access container shell
docker-compose exec daoob_app sh

# View database
docker-compose exec postgres psql -U daoob_user -d daoob_production
```

Your DAOOB platform is now ready for testing with the complete mobile-to-web workflow!