#!/bin/bash
echo "Building DAOOB APK..."

# Make sure we have the latest dependencies
echo "Fetching dependencies..."
flutter pub get

# Generate app icons
echo "Generating app icons..."
flutter pub run flutter_launcher_icons

# Create platforms directory if needed
echo "Ensuring Android platform files are set up..."
flutter create --platforms=android .

# Clean any previous builds
echo "Cleaning previous builds..."
flutter clean

# Build the APK
echo "Building release APK..."
flutter build apk --release

# Check if the build was successful
if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
  echo ""
  echo "✅ APK built successfully!"
  echo ""
  echo "You can find the APK at: build/app/outputs/flutter-apk/app-release.apk"
  echo ""
  echo "To install on an Android device, you can use:"
  echo "flutter install"
  echo ""
  # Copy to a more accessible location
  cp build/app/outputs/flutter-apk/app-release.apk ./daoob.apk
  echo "A copy of the APK has been placed in the current directory as daoob.apk"
else
  echo "❌ APK build failed. Check the logs above for errors."
fi
