#!/bin/bash

echo "=== Rebranding Existing App from Eventora to DAOOB ==="

# Check if eventora_mobile directory exists
if [ ! -d "eventora_mobile" ]; then
    echo "Error: eventora_mobile directory not found."
    exit 1
fi

# Make a backup first
echo "Creating backup of eventora_mobile..."
cp -r eventora_mobile eventora_mobile_backup

# Update package names in Dart files
echo "Updating import statements..."
find eventora_mobile -type f -name "*.dart" -exec sed -i 's/package:eventora_mobile/package:daoob_mobile/g' {} \;
find eventora_mobile -type f -name "*.dart" -exec sed -i 's/package:eventora_app/package:daoob_app/g' {} \;

# Update app name in pubspec.yaml
echo "Updating pubspec.yaml..."
if [ -f "eventora_mobile/pubspec.yaml" ]; then
    sed -i 's/name: eventora_mobile/name: daoob_mobile/g' eventora_mobile/pubspec.yaml
    sed -i 's/name: eventora_app/name: daoob_app/g' eventora_mobile/pubspec.yaml
fi

# Update Android package name if necessary
if [ -f "eventora_mobile/android/app/build.gradle" ]; then
    echo "Updating Android package name..."
    sed -i 's/applicationId "com.eventora/applicationId "com.daoob/g' eventora_mobile/android/app/build.gradle
fi

# Update iOS bundle identifier if necessary
if [ -f "eventora_mobile/ios/Runner/Info.plist" ]; then
    echo "Updating iOS bundle identifier..."
    sed -i 's/com.eventora/com.daoob/g' eventora_mobile/ios/Runner/Info.plist
fi

# Rename the directory
echo "Renaming eventora_mobile directory to daoob_mobile..."
mv eventora_mobile daoob_mobile

echo "=== Rebranding Complete ==="
echo "The app has been rebranded from Eventora to DAOOB"
echo "A backup of the original files is in eventora_mobile_backup"
echo ""
echo "You may need to run 'flutter pub get' in the new daoob_mobile directory"
echo "to update dependencies after the rename."