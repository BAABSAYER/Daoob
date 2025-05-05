#!/bin/bash

# DAOOB Local Server Setup Script
# This script helps configure all components of the DAOOB platform
# to work together on a local server

echo "🚀 DAOOB Local Server Setup"
echo "============================"
echo ""

# Get the local IP address
LOCAL_IP=$(hostname -I | awk '{print $1}')
if [ -z "$LOCAL_IP" ]; then
  echo "❌ Failed to detect your local IP address."
  echo "Please enter your local IP address manually:"
  read LOCAL_IP
  if [ -z "$LOCAL_IP" ]; then
    echo "❌ No IP address provided. Exiting."
    exit 1
  fi
fi

echo "📡 Your local IP address: $LOCAL_IP"
echo ""
echo "This script will configure your DAOOB platform to run on a local server."
echo "Web and API will be available at: http://$LOCAL_IP:5000"
echo ""

# Create configuration file for Flutter app
echo "📱 Configuring Flutter app..."
mkdir -p daoob_mobile/lib/config
cat > daoob_mobile/lib/config/api_config.dart << EOF
class ApiConfig {
  // Server endpoints
  static const String baseUrl = 'http://$LOCAL_IP:5000';
  static const String apiUrl = '\${baseUrl}/api';
  static const String wsUrl = 'ws://$LOCAL_IP:5000/ws';
  
  // API endpoints
  static const String loginEndpoint = '\${apiUrl}/login';
  static const String registerEndpoint = '\${apiUrl}/register';
  static const String userEndpoint = '\${apiUrl}/user';
  static const String logoutEndpoint = '\${apiUrl}/logout';
  static const String vendorsEndpoint = '\${apiUrl}/vendors';
  static const String bookingsEndpoint = '\${apiUrl}/bookings';
  static const String reviewsEndpoint = '\${apiUrl}/reviews';
  
  // Local cache settings
  static const bool enableOfflineMode = true;
  static const int cacheExpirationHours = 24;
}
EOF
echo "✅ Flutter app configuration created at daoob_mobile/lib/config/api_config.dart"

# Create a utility script for running the local server
cat > start-local-server.sh << EOF
#!/bin/bash

echo "🚀 Starting DAOOB Local Server"
echo "==============================="
echo ""
echo "📡 Server will be available at: http://$LOCAL_IP:5000"
echo ""
echo "📱 Mobile app should connect to: http://$LOCAL_IP:5000/api"
echo ""
echo "Press Ctrl+C to stop the server."
echo ""

# Ensure database is up-to-date
echo "🔄 Updating database schema..."
npm run db:push

# Start the server
echo "🚀 Starting server..."
npm run dev
EOF

# Make the script executable
chmod +x start-local-server.sh

echo "✅ Created start-local-server.sh script for easy server startup"
echo ""
echo "📝 Next steps:"
echo "1. Run './start-local-server.sh' to start the local server"
echo "2. Build the Flutter app with 'cd daoob_mobile && flutter build apk'"
echo "3. Install the APK on your Android device or run on an emulator"
echo ""
echo "🎉 Setup completed successfully!"