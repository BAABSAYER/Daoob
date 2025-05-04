#!/bin/bash
echo "Setting up app icons for DAOOB..."

# Clean the project first
flutter clean
echo "Project cleaned."

# Get dependencies
flutter pub get
echo "Dependencies installed."

# Generate icons
echo "Generating app icons..."
flutter pub run flutter_launcher_icons

echo "App icons generated. Please check the following locations:"
echo "- Android: android/app/src/main/res/mipmap-*"
echo "- iOS: ios/Runner/Assets.xcassets/AppIcon.appiconset/"

echo ""
echo "If you don't see the icons in these locations, please refer to ICON_SETUP.md for troubleshooting."
echo ""
echo "You can now run your app with: flutter run"
