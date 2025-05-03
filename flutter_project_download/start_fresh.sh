#!/bin/bash

echo "=== Starting a fresh build of the DAOOB Flutter app ==="

# Make sure we're in the right directory
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
cd "$SCRIPT_DIR"

# Check for Flutter
if ! command -v flutter &> /dev/null; then
    echo "Flutter is not installed or not in your PATH. Please install Flutter first."
    exit 1
fi

# Clean any previous attempts
if [ -d "eventora_app" ]; then
    echo "Removing existing eventora_app directory..."
    rm -rf eventora_app
fi

# Create the Flutter project from scratch
echo "Creating a new Flutter project..."
flutter create --project-name eventora_app --org com.daoob eventora_app

# Navigate to the project
cd eventora_app

# Create necessary directories
mkdir -p assets/images assets/lang lib/models lib/screens lib/services

# Copy the logo
echo "Setting up app logo..."
cp "../WhatsApp Image 2025-04-06 at 21.40.44_8e7cb969.jpg" assets/images/daoob-logo.jpg

# Create pubspec.yaml with all required dependencies
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

# Create a basic main.dart file
cat > lib/main.dart << 'EOL'
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DAOOB',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6A3DE8)),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DAOOB Event Management'),
        backgroundColor: const Color(0xFF6A3DE8),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/daoob-logo.jpg',
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 20),
            const Text(
              'Welcome to DAOOB!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Your Event Management Solution',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
EOL

# Fix Android NDK version
if [ -f "android/app/build.gradle" ]; then
  if ! grep -q "ndkVersion" android/app/build.gradle; then
    sed -i '/defaultConfig {/a \        ndkVersion "27.0.12077973"' android/app/build.gradle
    echo "Added ndkVersion to android/app/build.gradle"
  fi
fi

# Get dependencies
echo "Getting dependencies..."
flutter pub get

echo "Setting up app icon..."
flutter pub run flutter_launcher_icons

echo "=== Setup complete! ==="
echo "You can now build the APK with: flutter build apk --release"
echo "Current directory: $(pwd)"