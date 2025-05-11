#!/bin/bash
# DAOOB Complete Setup Guide
# This script will guide you through setting up and running the entire DAOOB platform

echo "🚀 DAOOB Complete Setup Guide"
echo "============================="
echo ""
echo "This script will walk you through the entire setup process."
echo ""

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Check for required tools
echo "🔍 Checking for required tools..."

# Check for Node.js and npm
if ! command_exists node; then
  echo "❌ Node.js is not installed. Please install Node.js from https://nodejs.org/"
  echo "   After installing, run this script again."
  exit 1
else
  NODE_VERSION=$(node -v)
  echo "✅ Node.js is installed (version: $NODE_VERSION)"
fi

if ! command_exists npm; then
  echo "❌ npm is not installed. Please install Node.js from https://nodejs.org/"
  echo "   npm should be included with Node.js."
  exit 1
else
  NPM_VERSION=$(npm -v)
  echo "✅ npm is installed (version: $NPM_VERSION)"
fi

# Check for PostgreSQL
if ! command_exists psql; then
  echo "⚠️ PostgreSQL is not installed or not in your PATH."
  echo "   Please install PostgreSQL from https://www.postgresql.org/download/"
  echo ""
  echo "Would you like to continue anyway? (y/n)"
  read -r continue_without_psql
  
  if [[ $continue_without_psql != "y" && $continue_without_psql != "Y" ]]; then
    echo "Exiting setup. Please install PostgreSQL and try again."
    exit 1
  fi
else
  PSQL_VERSION=$(psql --version)
  echo "✅ PostgreSQL is installed ($PSQL_VERSION)"
fi

# Check for Flutter
if ! command_exists flutter; then
  echo "⚠️ Flutter is not installed or not in your PATH."
  echo "   To install Flutter, follow instructions at https://flutter.dev/docs/get-started/install"
  echo ""
  echo "Would you like to continue anyway? (For server-side only setup) (y/n)"
  read -r continue_without_flutter
  
  if [[ $continue_without_flutter != "y" && $continue_without_flutter != "Y" ]]; then
    echo "Exiting setup. Please install Flutter and try again."
    exit 1
  fi
else
  FLUTTER_VERSION=$(flutter --version | head -1)
  echo "✅ Flutter is installed ($FLUTTER_VERSION)"
fi

echo ""
echo "🔧 Starting setup process..."

# Setup .env file for database connection
echo ""
echo "📝 Setting up environment variables"
echo "--------------------------------"

if [ -f .env ]; then
  echo "⚠️ .env file already exists. Do you want to overwrite it? (y/n)"
  read -r overwrite_env
  
  if [[ $overwrite_env != "y" && $overwrite_env != "Y" ]]; then
    echo "Keeping existing .env file."
  else
    # Create new .env file
    cat > .env << EOF
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/daoob
SESSION_SECRET=super_secret_session_key_please_change_in_production
EOF
    echo "✅ Created new .env file"
  fi
else
  # Create .env file
  cat > .env << EOF
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/daoob
SESSION_SECRET=super_secret_session_key_please_change_in_production
EOF
  echo "✅ Created .env file"
fi

echo ""
echo "🗄️ Database setup"
echo "----------------"
echo "Now we'll set up the PostgreSQL database."
echo ""

if command_exists psql; then
  echo "Would you like to create the 'daoob' database in PostgreSQL? (y/n)"
  read -r create_db
  
  if [[ $create_db == "y" || $create_db == "Y" ]]; then
    echo "Please enter your PostgreSQL username (default: postgres):"
    read -r pg_user
    pg_user=${pg_user:-postgres}
    
    echo "Please enter your PostgreSQL password:"
    read -rs pg_password
    
    # Update .env file with the provided credentials
    sed -i.bak "s|postgresql://postgres:postgres@localhost:5432/daoob|postgresql://${pg_user}:${pg_password}@localhost:5432/daoob|g" .env
    rm -f .env.bak
    
    echo "Creating database 'daoob'..."
    PGPASSWORD=$pg_password psql -U $pg_user -c "CREATE DATABASE daoob;" postgres
    
    if [ $? -eq 0 ]; then
      echo "✅ Database 'daoob' created successfully"
    else
      echo "❌ Failed to create database. You may need to create it manually."
    fi
  else
    echo "Skipping database creation. Please ensure you have a database configured in your .env file."
  fi
else
  echo "PostgreSQL not found. Please set up your database manually and update the .env file."
fi

echo ""
echo "📦 Installing dependencies"
echo "------------------------"
echo "Installing Node.js dependencies..."

npm install

if [ $? -eq 0 ]; then
  echo "✅ Node.js dependencies installed successfully"
else
  echo "❌ Failed to install Node.js dependencies"
  exit 1
fi

echo ""
echo "🏗️ Setting up database schema"
echo "---------------------------"
echo "Running database migrations..."

npm run db:push

if [ $? -eq 0 ]; then
  echo "✅ Database schema created successfully"
else
  echo "❌ Failed to create database schema. Check your database connection."
  exit 1
fi

echo ""
echo "🧪 Creating demo data"
echo "-------------------"
echo "Would you like to create demo data (users, vendors, event types)? (y/n)"
read -r create_demo_data

if [[ $create_demo_data == "y" || $create_demo_data == "Y" ]]; then
  echo "Creating demo data..."
  npx tsx create-demo-data.ts
  
  if [ $? -eq 0 ]; then
    echo "✅ Demo data created successfully"
    echo ""
    echo "🔑 Demo login credentials:"
    echo "  - Admin: username='admin', password='password'"
    echo "  - Client: username='demouser', password='password'"
    echo "  - Vendor: username='demovendor', password='password'"
  else
    echo "❌ Failed to create demo data"
  fi
else
  echo "Skipping demo data creation."
fi

echo ""
echo "🌐 Setting up mobile app"
echo "----------------------"

if command_exists flutter; then
  echo "Setting up Flutter app configuration..."
  
  # Get local IP address for mobile app configuration
  LOCAL_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || ipconfig getifaddr en0 2>/dev/null || echo "127.0.0.1")
  
  # Create config directory if it doesn't exist
  mkdir -p daoob_mobile/lib/config
  
  # Create the API config file
  cat > daoob_mobile/lib/config/api_config.dart << EOF
import 'dart:io';

class ApiConfig {
  // Determine the base URL based on the environment
  static String get baseUrl {
    // For real device on the same network, use the local IP address
    if (Platform.isAndroid && !isEmulator()) {
      return 'http://$LOCAL_IP:5000'; // Local network IP
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000'; // Special IP for Android emulator to reach host
    } else if (Platform.isIOS) {
      return 'http://localhost:5000'; // Works for iOS simulator
    } else {
      return 'http://localhost:5000'; // Default for other platforms
    }
  }

  // Check if running in an emulator
  static bool isEmulator() {
    try {
      return Platform.environment.containsKey('ANDROID_EMULATOR') || 
             Platform.environment.containsKey('ANDROID_SDK_ROOT');
    } catch (e) {
      return false;
    }
  }

  // API endpoints
  static String get apiUrl => '\$baseUrl/api';
  static String get wsUrl => baseUrl.replaceFirst('http', 'ws') + '/ws';
  
  // Auth endpoints
  static String get loginEndpoint => '\$apiUrl/login';
  static String get registerEndpoint => '\$apiUrl/register';
  static String get userEndpoint => '\$apiUrl/user';
  static String get logoutEndpoint => '\$apiUrl/logout';
  
  // Vendor endpoints
  static String get vendorsEndpoint => '\$apiUrl/vendors';
  
  // Booking endpoints
  static String get bookingsEndpoint => '\$apiUrl/bookings';
  
  // Review endpoints
  static String get reviewsEndpoint => '\$apiUrl/reviews';
  
  // Message endpoints
  static String get messagesEndpoint => '\$apiUrl/messages';
  
  // Event Management endpoints
  static String get eventTypesEndpoint => '\$apiUrl/event-types';
  static String get eventRequestsEndpoint => '\$apiUrl/event-requests';
  static String get quotationsEndpoint => '\$apiUrl/quotations';
  
  // Offline mode settings
  static const bool defaultOfflineMode = false;
  static const int cacheExpirationHours = 24;
  
  // Headers
  static Map<String, String> get jsonHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  static Map<String, String> authHeaders(String token) => {
    ...jsonHeaders,
    'Authorization': 'Bearer \$token',
  };
}
EOF

  echo "✅ Flutter API configuration created with local IP: $LOCAL_IP"
  
  echo "Installing Flutter dependencies..."
  cd daoob_mobile && flutter pub get
  
  if [ $? -eq 0 ]; then
    echo "✅ Flutter dependencies installed successfully"
    cd ..
  else
    echo "❌ Failed to install Flutter dependencies"
    cd ..
  fi
else
  echo "Flutter not found. Skipping mobile app setup."
  echo "If you want to set up the mobile app later, you'll need to install Flutter first."
fi

echo ""
echo "🚀 Creating startup scripts"
echo "-------------------------"

# Create start script for the server
cat > start-server.sh << EOF
#!/bin/bash
echo "🚀 Starting DAOOB Server"
echo "======================="
echo ""
echo "Server will be available at: http://localhost:5000"
echo ""
echo "Press Ctrl+C to stop the server."

npm run dev
EOF

chmod +x start-server.sh
echo "✅ Created start-server.sh script"

# Create Flutter run script
if command_exists flutter; then
  cat > run-flutter-app.sh << EOF
#!/bin/bash
echo "🚀 Running DAOOB Mobile App"
echo "========================="
echo ""
echo "Make sure the server is running in another terminal window."
echo "Use ./start-server.sh to start the server."
echo ""

cd daoob_mobile
flutter run
EOF

  chmod +x run-flutter-app.sh
  echo "✅ Created run-flutter-app.sh script"
fi

echo ""
echo "🎉 Setup completed successfully!"
echo ""
echo "📱 Next steps:"
echo "1. Start the server with: ./start-server.sh"

if command_exists flutter; then
  echo "2. In a separate terminal, run the mobile app with: ./run-flutter-app.sh"
  echo "3. Log in with the demo credentials shown above"
fi

echo ""
echo "🛠️ Troubleshooting tips:"
echo "- If the mobile app can't connect to the server, check your firewall settings"
echo "- Make sure your devices are on the same network"
echo "- For physical devices, you may need to update the IP address in daoob_mobile/lib/config/api_config.dart"
echo ""
echo "Happy testing! 🚀"