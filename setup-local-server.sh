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
echo "1. Install required Flutter packages with 'cd daoob_mobile && flutter pub get'"
echo "   Required packages: web_socket_channel, sqflite, path, shared_preferences, http"
echo "2. Run './start-local-server.sh' to start the local server"
echo "3. Build the Flutter app with 'cd daoob_mobile && flutter build apk'"
echo "4. Install the APK on your Android device or run on an emulator"
echo ""
echo "🎉 Setup completed successfully!"
echo ""
echo "📡 NETWORK CONFIGURATION NOTES"
echo "==============================="
echo "1. The server listens on all network interfaces (0.0.0.0) on port 5000"
echo "2. Ensure port 5000 is not blocked by your firewall"
echo "3. All devices must be on the same WiFi/network to connect to the server"
echo "4. The address $LOCAL_IP:5000 should be accessible from all devices on your network"
echo "5. For Android physical devices, ensure 'Use cleartext traffic' is enabled in your app's configuration"
echo ""
echo "📝 TROUBLESHOOTING"
echo "==================="
echo "- If devices can't connect, check the LAN connection using ping $LOCAL_IP"
echo "- For Android devices, try running: 'adb reverse tcp:5000 tcp:5000'"
echo "- For direct debugging, use: curl http://$LOCAL_IP:5000/api/test"
echo "- Check that the server is running and listening on 0.0.0.0:5000"