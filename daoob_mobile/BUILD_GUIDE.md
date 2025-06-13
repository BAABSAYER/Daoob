# Flutter iOS & Android Build Guide

## Prerequisites

### For iOS Development
- macOS computer with Xcode installed
- iOS Simulator or physical iOS device
- Apple Developer account (for App Store deployment)

### For Android Development
- Android Studio installed
- Android SDK configured
- Android emulator or physical Android device

## Building for iOS

### 1. Setup iOS Development Environment
```bash
# Install Xcode Command Line Tools
xcode-select --install

# Install CocoaPods (if not already installed)
sudo gem install cocoapods
```

### 2. Configure iOS Project
```bash
cd daoob_mobile

# Install iOS dependencies
cd ios
pod install
cd ..
```

### 3. Build iOS App
```bash
# Debug build for simulator
flutter build ios --debug --simulator

# Release build for device
flutter build ios --release

# Run on iOS simulator
flutter run -d ios

# Run on connected iOS device
flutter run -d <device-id>
```

### 4. iOS App Store Deployment
```bash
# Build for App Store
flutter build ipa --release

# The .ipa file will be in build/ios/ipa/
# Upload to App Store Connect using Xcode or Transporter
```

## Building for Android

### 1. Configure Android Signing
Create `android/key.properties`:
```
storePassword=<your-store-password>
keyPassword=<your-key-password>
keyAlias=<your-key-alias>
storeFile=<path-to-keystore-file>
```

### 2. Build Android App
```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# Android App Bundle (recommended for Play Store)
flutter build appbundle --release

# Run on Android emulator/device
flutter run -d android
```

### 3. Android Play Store Deployment
```bash
# Build App Bundle for Play Store
flutter build appbundle --release

# The .aab file will be in build/app/outputs/bundle/release/
# Upload to Google Play Console
```

## Testing Builds

### List Available Devices
```bash
flutter devices
```

### Run on Specific Device
```bash
# iOS Simulator
flutter run -d "iPhone 14 Pro Max"

# Android Emulator
flutter run -d "Pixel_7_API_33"

# Physical device
flutter run -d <device-id>
```

## Production Configuration

### Update App Information
Edit `pubspec.yaml`:
```yaml
name: daoob_mobile
description: DAOOB Event Management Platform
version: 1.0.0+1
```

### iOS Configuration (ios/Runner/Info.plist)
```xml
<key>CFBundleDisplayName</key>
<string>DAOOB</string>
<key>CFBundleIdentifier</key>
<string>com.daoob.mobile</string>
```

### Android Configuration (android/app/build.gradle)
```gradle
android {
    defaultConfig {
        applicationId "com.daoob.mobile"
        versionCode 1
        versionName "1.0.0"
    }
}
```

## App Icons & Splash Screens

### Generate App Icons
```bash
# Install flutter_launcher_icons
flutter pub add dev:flutter_launcher_icons

# Configure in pubspec.yaml and run
flutter pub get
flutter pub run flutter_launcher_icons:main
```

### Generate Splash Screens
```bash
# Install flutter_native_splash
flutter pub add dev:flutter_native_splash

# Configure in pubspec.yaml and run
flutter pub get
flutter pub run flutter_native_splash:create
```

## Common Issues & Solutions

### iOS Build Issues
- Clean build: `flutter clean && flutter pub get`
- Update CocoaPods: `cd ios && pod repo update && pod install`
- Check Xcode project settings for deployment target

### Android Build Issues
- Clean build: `flutter clean && flutter pub get`
- Update Android SDK and build tools
- Check ProGuard rules for release builds

## Server Configuration
Your app is configured to connect to: `178.62.41.245:8080`

Make sure your production server is running and accessible before testing the mobile apps.