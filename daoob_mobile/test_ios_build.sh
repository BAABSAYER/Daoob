#!/bin/bash
echo "Testing iOS build configuration..."

# Make sure iOS platform files exist
flutter create --platforms=ios .

# Try to build iOS without codesigning (just to test configuration)
flutter build ios --no-codesign

if [ $? -eq 0 ]; then
    echo "iOS build configuration is working correctly!"
    echo "You can now run: open ios/Runner.xcworkspace"
    echo "Then use Xcode to sign and deploy to your device."
else
    echo "iOS build is still having issues. Let's create a minimal configuration."
    
    # Create a simple ios/Flutter/Debug.xcconfig
    mkdir -p ios/Flutter
    echo "FLUTTER_TARGET=lib/main.dart" > ios/Flutter/Debug.xcconfig
    echo "FLUTTER_BUILD_DIR=build" >> ios/Flutter/Debug.xcconfig
    echo "FLUTTER_BUILD_NAME=1.0.0" >> ios/Flutter/Debug.xcconfig
    echo "FLUTTER_BUILD_NUMBER=1" >> ios/Flutter/Debug.xcconfig
    
    # Try again
    flutter build ios --no-codesign
    
    if [ $? -eq 0 ]; then
        echo "iOS build working now with minimal configuration!"
    else
        echo "iOS build still has issues. Consider using Xcode directly."
        echo "Run: open ios/Runner.xcworkspace"
    fi
fi
