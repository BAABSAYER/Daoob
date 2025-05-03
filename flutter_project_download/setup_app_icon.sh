#!/bin/bash

echo "Setting up the app icon from the provided logo..."

# Make sure we're in the Flutter project directory
cd eventora_app

# Create the necessary directories for Android launcher icons
mkdir -p android/app/src/main/res/mipmap-hdpi
mkdir -p android/app/src/main/res/mipmap-mdpi
mkdir -p android/app/src/main/res/mipmap-xhdpi
mkdir -p android/app/src/main/res/mipmap-xxhdpi
mkdir -p android/app/src/main/res/mipmap-xxxhdpi

# Copy the logo file into assets
cp ../../attached_assets/WhatsApp\ Image\ 2025-04-06\ at\ 21.40.44_8e7cb969.jpg assets/images/daoob-logo.jpg

# Update pubspec.yaml to include the assets and flutter_launcher_icons dependency
cat >> pubspec.yaml << 'EOL'

# Add assets
assets:
  - assets/images/

# For app icon generation
flutter_icons:
  android: true
  ios: true
  image_path: "assets/images/daoob-logo.jpg"
  adaptive_icon_background: "#6A3DE8"
EOL

# Add flutter_launcher_icons dependency
flutter pub add flutter_launcher_icons

# Run flutter_launcher_icons to generate app icons
flutter pub run flutter_launcher_icons

echo "App icon setup complete. The DAOOB logo is now set as the app icon."