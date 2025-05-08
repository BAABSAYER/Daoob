#!/bin/bash

# DAOOB Local Connection Test Script
# This script helps verify that your local server setup is working correctly

echo "🔍 DAOOB Local Connection Test"
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

# Check if the server is running
echo "🔍 Testing server availability..."
SERVER_URL="http://$LOCAL_IP:5000"
TEST_ENDPOINT="$SERVER_URL/api/test"

# Use curl with a timeout to test connection
if curl --silent --max-time 5 "$TEST_ENDPOINT" > /dev/null; then
  echo "✅ Server is reachable at $SERVER_URL"
else
  echo "❌ Server is not reachable at $SERVER_URL"
  echo "Please ensure the server is running using './start-local-server.sh'"
  echo "Also check that port 5000 is not blocked by your firewall."
  exit 1
fi

# Check server API
echo ""
echo "🔍 Testing API functionality..."
API_RESPONSE=$(curl --silent --max-time 5 "$TEST_ENDPOINT")
if [[ "$API_RESPONSE" == *"API is working"* ]]; then
  echo "✅ API is functioning correctly"
else
  echo "⚠️ API response doesn't match expected format"
  echo "Raw response: $API_RESPONSE"
fi

# Test WebSocket connection
echo ""
echo "🔍 Testing WebSocket connection..."
WS_URL="ws://$LOCAL_IP:5000/ws"
if command -v websocat > /dev/null; then
  if echo '{"type":"ping"}' | websocat --no-close --ping-interval 1 --ping-timeout 5 "$WS_URL" &> /dev/null; then
    echo "✅ WebSocket connection successful at $WS_URL"
  else
    echo "⚠️ WebSocket connection failed at $WS_URL"
    echo "This might affect real-time messaging functionality."
  fi
else
  echo "⚠️ 'websocat' tool not installed, skipping WebSocket test"
  echo "To test WebSockets, install websocat: https://github.com/vi/websocat"
fi

# Network traffic permissions check for Android
echo ""
echo "🔍 Checking Android network security configuration..."
if [ -f "daoob_mobile/android/app/src/main/res/xml/network_security_config.xml" ]; then
  echo "✅ Android network security configuration file exists"
  if grep -q "cleartextTrafficPermitted=\"true\"" "daoob_mobile/android/app/src/main/res/xml/network_security_config.xml"; then
    echo "✅ Cleartext traffic is permitted in network security config"
  else
    echo "⚠️ Cleartext traffic may not be permitted in network security config"
    echo "Check daoob_mobile/android/app/src/main/res/xml/network_security_config.xml"
  fi
else
  echo "⚠️ Android network security configuration file not found"
  echo "This might cause connection issues on Android 9+ devices"
fi

if [ -f "daoob_mobile/android/app/src/main/AndroidManifest.xml" ]; then
  if grep -q "android:usesCleartextTraffic=\"true\"" "daoob_mobile/android/app/src/main/AndroidManifest.xml"; then
    echo "✅ usesCleartextTraffic is enabled in AndroidManifest.xml"
  else
    echo "⚠️ usesCleartextTraffic may not be enabled in AndroidManifest.xml"
    echo "Check daoob_mobile/android/app/src/main/AndroidManifest.xml"
  fi
else
  echo "⚠️ AndroidManifest.xml not found"
fi

# Check Flutter dependencies
echo ""
echo "🔍 Checking Flutter dependencies..."
if [ -f "daoob_mobile/pubspec.yaml" ]; then
  echo "✅ Flutter pubspec.yaml file exists"
  
  # Check required dependencies
  echo "Checking required packages:"
  for pkg in "http" "web_socket_channel" "shared_preferences" "sqflite" "path"; do
    if grep -q "^  $pkg:" "daoob_mobile/pubspec.yaml"; then
      echo "✅ $pkg package found in pubspec.yaml"
    else
      echo "⚠️ $pkg package may be missing in pubspec.yaml"
    fi
  done
else
  echo "⚠️ Flutter pubspec.yaml not found"
  echo "Make sure the Flutter project is properly set up"
fi

echo ""
echo "🎉 Connection test completed!"
echo "If all checks passed, your local server setup should be working correctly."