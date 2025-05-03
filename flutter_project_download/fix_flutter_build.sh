#!/bin/bash

echo "===== FIXING FLUTTER BUILD ISSUES ====="

# Check if eventora_app directory exists
if [ ! -d "eventora_app" ]; then
  echo "Error: eventora_app directory not found. You need to run create_and_build_app.sh first."
  echo "Running create_and_build_app.sh for you..."
  ./create_and_build_app.sh
fi

# Navigate to the Flutter project
cd eventora_app

# 1. Fix pubspec.yaml - update dependencies with compatible versions
cat > pubspec.yaml << 'EOL'
name: eventora_app
description: "DAOOB Event Management Platform"
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  cupertino_icons: ^1.0.2
  shared_preferences: ^2.2.0
  http: ^1.1.0
  intl: ^0.19.0
  flutter_localization: ^0.3.2
  flutter_launcher_icons: ^0.13.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/lang/

flutter_icons:
  android: true
  ios: true
  image_path: "assets/images/daoob-logo.jpg"
  adaptive_icon_background: "#6A3DE8"
EOL

echo "Updated pubspec.yaml with compatible dependencies"

# 2. Fix the NDK version issue in build.gradle
if [ -f "android/app/build.gradle" ]; then
  # For regular build.gradle
  if ! grep -q "ndkVersion" android/app/build.gradle; then
    sed -i '/defaultConfig {/a \        ndkVersion "27.0.12077973"' android/app/build.gradle
    echo "Added ndkVersion to android/app/build.gradle"
  fi
elif [ -f "android/app/build.gradle.kts" ]; then
  # For Kotlin DSL build.gradle.kts
  if ! grep -q "ndkVersion" android/app/build.gradle.kts; then
    sed -i '/defaultConfig {/a \        ndkVersion = "27.0.12077973"' android/app/build.gradle.kts
    echo "Added ndkVersion to android/app/build.gradle.kts"
  fi
fi

# 3. Fix the app_wrapper.dart file errors
if [ -f "lib/screens/app_wrapper.dart" ]; then
  # Fix the Set<IconButton> error - replace with a single IconButton
  sed -i 's/actions: {/actions: [/g' lib/screens/app_wrapper.dart
  sed -i 's/},/],/g' lib/screens/app_wrapper.dart
  
  # Fix the isOfflineMode issue
  sed -i 's/authService.isOfflineMode/authService.offlineMode/g' lib/screens/app_wrapper.dart
  
  echo "Fixed errors in app_wrapper.dart"
fi

# Ensure the auth_service.dart has an offlineMode getter
if [ -f "lib/services/auth_service.dart" ]; then
  if ! grep -q "bool get offlineMode" lib/services/auth_service.dart; then
    # Add the offlineMode getter at the appropriate location
    awk '/class AuthService/ {print; print "  bool get offlineMode => _offlineMode;"; next}1' lib/services/auth_service.dart > auth_service.temp
    mv auth_service.temp lib/services/auth_service.dart
    echo "Added offlineMode getter to auth_service.dart"
  fi
fi

# Clean and get packages
flutter clean
flutter pub get

echo "===== FIXES APPLIED ====="
echo "Now try building the APK again with:"
echo "flutter build apk --release"