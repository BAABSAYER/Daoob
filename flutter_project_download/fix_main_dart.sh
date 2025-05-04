#!/bin/bash

# Check if daoob_mobile directory exists
if [ ! -d "daoob_mobile" ]; then
    echo "Error: daoob_mobile directory not found."
    exit 1
fi

echo "Fixing import statements in main.dart..."
# Replace all eventora_mobile import statements with daoob_mobile
sed -i 's/package:eventora_mobile/package:daoob_mobile/g' daoob_mobile/lib/main.dart

echo "Checking main.dart for syntax errors..."
cd daoob_mobile
flutter analyze lib/main.dart

echo "Done fixing main.dart"
echo "Now try building the APK again with:"
echo "cd daoob_mobile && flutter build apk --release"