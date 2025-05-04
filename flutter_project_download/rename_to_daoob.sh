#!/bin/bash

# This script completely renames the application from 'eventora' to 'daoob'
# It updates folders, package names, and imports

# Set the execution flag for all scripts
chmod +x *.sh

echo "===== REBRANDING APP FROM EVENTORA TO DAOOB ====="

# 1. Rename references in all script files
echo "Updating script files..."
find . -type f -name "*.sh" -exec sed -i 's/eventora_mobile/daoob_mobile/g' {} \;
find . -type f -name "*.sh" -exec sed -i 's/eventora_app/daoob_app/g' {} \;
find . -type f -name "*.sh" -exec sed -i 's/com\.eventora/com.daoob/g' {} \;
find . -type f -name "*.sh" -exec sed -i 's/package:eventora_mobile/package:daoob_mobile/g' {} \;
find . -type f -name "*.sh" -exec sed -i 's/package:eventora_app/package:daoob_app/g' {} \;
find . -type f -name "*.sh" -exec sed -i 's/name: eventora_mobile/name: daoob_mobile/g' {} \;
find . -type f -name "*.sh" -exec sed -i 's/name: eventora_app/name: daoob_app/g' {} \;

# 2. Update enhanced_app.sh to use the correct package names
echo "Updating enhanced_app.sh..."
sed -i 's/package:eventora_mobile/package:daoob_mobile/g' enhanced_app.sh

# 3. If the application has been created, update the Dart files and pubspec.yaml
if [ -d "../eventora_mobile" ]; then
    echo "Updating existing Flutter project files..."
    
    # Update imports in all Dart files
    find ../eventora_mobile -type f -name "*.dart" -exec sed -i 's/package:eventora_mobile/package:daoob_mobile/g' {} \;
    find ../eventora_mobile -type f -name "*.dart" -exec sed -i 's/package:eventora_app/package:daoob_app/g' {} \;
    
    # Update pubspec.yaml
    sed -i 's/name: eventora_mobile/name: daoob_mobile/g' ../eventora_mobile/pubspec.yaml
    sed -i 's/name: eventora_app/name: daoob_app/g' ../eventora_mobile/pubspec.yaml
    
    # Update Android package name if necessary
    if [ -f "../eventora_mobile/android/app/build.gradle" ]; then
        sed -i 's/applicationId "com.eventora/applicationId "com.daoob/g' ../eventora_mobile/android/app/build.gradle
    fi
    
    # Update iOS bundle identifier if necessary
    if [ -f "../eventora_mobile/ios/Runner/Info.plist" ]; then
        sed -i 's/com.eventora/com.daoob/g' ../eventora_mobile/ios/Runner/Info.plist
    fi
    
    # Rename the directory
    echo "Renaming eventora_mobile directory to daoob_mobile..."
    mv ../eventora_mobile ../daoob_mobile
fi

echo "===== REBRANDING COMPLETE ====="
echo "App has been fully rebranded from EVENTORA to DAOOB"
echo "You may need to update any app assets that contain the old name"