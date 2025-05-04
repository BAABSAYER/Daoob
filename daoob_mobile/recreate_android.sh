#!/bin/bash
echo "Completely recreating Android folder from scratch..."

# Remove the entire android directory
echo "Removing old android directory..."
rm -rf android

# Clean the project
echo "Cleaning project..."
flutter clean

# Get dependencies
echo "Getting dependencies..."
flutter pub get

# Create new android directory with proper structure
echo "Creating new android project files..."
flutter create --platforms=android .

# Make sure the Android directory was created
if [ ! -d "android" ]; then
    echo "Error: Failed to create android directory."
    exit 1
fi

# Fix the gradle wrapper for Java 21 compatibility
echo "Updating Gradle wrapper for Java 21 compatibility..."
cat > android/gradle/wrapper/gradle-wrapper.properties << 'GWEOF'
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.6-bin.zip
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
GWEOF

# Try to build
echo "Trying to build with the new Android files..."
flutter build apk --debug

if [ $? -eq 0 ]; then
    echo "Build succeeded! You can now build release APK with:"
    echo "flutter build apk --release"
else
    echo "Build still failing. Please check the error messages."
fi
