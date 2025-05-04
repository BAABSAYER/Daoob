# App Icon Setup

This document explains how to properly set up the app icon for your DAOOB application.

## Requirements

1. Flutter installed and configured
2. Image file for the app icon (already included in assets/images/full_logo.jpg)

## Steps

### 1. Install Packages

First, get the necessary dependencies:

```bash
flutter pub get
```

### 2. Generate Icons

Run the flutter_launcher_icons package to generate all the app icons:

```bash
flutter pub run flutter_launcher_icons
```

This will:
- Create Android adaptive icons with proper resolutions
- Create iOS icons with proper resolutions
- Place them in the correct locations in the project

### 3. Verify Icons

After running the generator, check:
- Android: Look in `android/app/src/main/res/` for various mipmap folders
- iOS: Look in `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

### 4. Rebuild App

After generating the icons, rebuild your app:

```bash
flutter clean
flutter pub get
flutter run
```

## Common Issues

If the app icon doesn't appear:
1. Make sure the image file is a high-quality JPG or PNG (at least 1024x1024 pixels)
2. Try cleaning the project with `flutter clean`
3. If using a PNG, make sure it has the correct transparency settings

## Manual Configuration

If automatic generation doesn't work:

### Android:
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<application
    android:icon="@mipmap/ic_launcher"
    android:roundIcon="@mipmap/ic_launcher_round"
    ...
>
```

### iOS:
Xcode -> Runner -> General -> App Icons and Launch Images -> App Icons Source -> AppIcon
