#!/bin/bash

echo "=== Creating Enhanced DAOOB Flutter App with Full Functionality ==="

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$SCRIPT_DIR"

# Check for Flutter
if ! command -v flutter &> /dev/null; then
    echo "Flutter is not installed or not in your PATH. Please install Flutter first."
    exit 1
fi

# Clean any previous attempts
if [ -d "eventora_mobile" ]; then
    echo "Removing existing eventora_mobile directory..."
    rm -rf eventora_mobile
fi

if [ -d "daoob_mobile" ]; then
    echo "Removing existing daoob_mobile directory..."
    rm -rf daoob_mobile
fi

# Create the Flutter project from scratch
echo "Creating a new Flutter project..."
flutter create --org com.daoob --project-name daoob daoob_mobile

# Navigate to the project
cd daoob_mobile

# Create necessary directories
mkdir -p assets/images lib/models lib/screens lib/services lib/widgets lib/utils lib/l10n
mkdir -p assets/lang
mkdir -p lib/screens/events

# Copy the logo
if [ -f "../WhatsApp Image 2025-04-06 at 21.40.44_8e7cb969.jpg" ]; then
    echo "Setting up app logo..."
    cp "../WhatsApp Image 2025-04-06 at 21.40.44_8e7cb969.jpg" assets/images/daoob-logo.jpg
else
    echo "Logo not found. Skipping logo setup."
fi

# Create all your files here as in your original enhanced_app.sh
# ...

# UPDATE YOUR MAIN.DART FILE
cat > lib/main.dart << 'EOL'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:daoob_mobile/services/auth_service.dart';
import 'package:daoob_mobile/services/event_provider.dart';
import 'package:daoob_mobile/screens/splash_screen.dart';
import 'package:daoob_mobile/screens/login_screen.dart';
import 'package:daoob_mobile/screens/app_wrapper.dart';
import 'package:daoob_mobile/screens/vendor_detail_screen.dart';
import 'package:daoob_mobile/l10n/app_localizations.dart';
import 'package:daoob_mobile/l10n/language_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthService()),
        ChangeNotifierProvider(create: (context) => LanguageProvider()),
        ChangeNotifierProvider(create: (context) => EventProvider()),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'DAOOB',
            theme: ThemeData(
              primaryColor: const Color(0xFF6A3DE8),
              primarySwatch: Colors.deepPurple,
              colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6A3DE8)),
              fontFamily: 'Roboto',
              useMaterial3: true,
            ),
            locale: languageProvider.locale,
            textDirection: languageProvider.isRTL ? TextDirection.rtl : TextDirection.ltr,
            supportedLocales: const [
              Locale('en', ''),
              Locale('ar', ''),
            ],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            initialRoute: '/',
            routes: {
              '/': (context) => const SplashScreen(),
              '/login': (context) => const LoginScreen(),
              '/home': (context) => const AppWrapper(),
              '/vendor-details': (context) => VendorDetailScreen(
                  vendorId: ModalRoute.of(context)!.settings.arguments as int),
            },
          );
        },
      ),
    );
  }
}
EOL

# Update pubspec.yaml
cat > pubspec.yaml << 'EOL'
name: daoob_mobile
description: "DAOOB - Smart Event Management Platform"
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
  provider: ^6.0.5
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

# Add localization files and all your other files here
# ...

# IMPORTANT: Update all import statements in all Dart files
echo "Updating package names from eventora to daoob..."
find lib -type f -name "*.dart" -exec sed -i 's/package:eventora_mobile/package:daoob_mobile/g' {} \;

# Fix Android NDK version in build.gradle files
if [ -f "android/app/build.gradle" ]; then
  if ! grep -q "ndkVersion" android/app/build.gradle; then
    sed -i '/defaultConfig {/a \        ndkVersion "27.0.12077973"' android/app/build.gradle
    echo "Added ndkVersion to android/app/build.gradle"
  fi
fi

if [ -f "android/app/build.gradle.kts" ]; then
  if ! grep -q "ndkVersion" android/app/build.gradle.kts; then
    sed -i '/android {/a \    ndkVersion = "27.0.12077973"' android/app/build.gradle.kts
    echo "Added ndkVersion to android/app/build.gradle.kts"
  fi
fi

# Get dependencies
echo "Getting dependencies..."
flutter pub get

# Setup app icon
echo "Setting up app icon..."
flutter pub run flutter_launcher_icons

echo "=== Building APK ==="
flutter build apk --release

echo "=== Setup complete! ==="
echo "APK has been built and is located at:"
echo "$(pwd)/build/app/outputs/flutter-apk/app-release.apk"