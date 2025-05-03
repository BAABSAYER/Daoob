#!/bin/bash

echo "Fixing pubspec.yaml to add SDK constraints..."

# Navigate to the Flutter project
cd eventora_app

# First, check if pubspec.yaml already exists and remove any duplicate flutter_icons
if [ -f pubspec.yaml ]; then
  # Remove any existing flutter_icons section to avoid duplicates
  sed -i '/flutter_icons:/,/adaptive_icon_background:/d' pubspec.yaml
fi

# Update pubspec.yaml to include SDK constraints
cat > pubspec.yaml.new << 'EOL'
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
  intl: ^0.18.0
  flutter_localization: ^0.1.14
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

# Replace the original pubspec.yaml file
mv pubspec.yaml.new pubspec.yaml

echo "Running pub get to update dependencies..."
flutter pub get

echo "Pubspec.yaml has been fixed with proper SDK constraints!"