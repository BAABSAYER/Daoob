#!/bin/bash
echo "Preparing project for icon generation..."

# Remove previous platform-specific icon files
if [ -d "ios/Runner/Assets.xcassets/AppIcon.appiconset" ]; then
  rm -rf ios/Runner/Assets.xcassets/AppIcon.appiconset/*
  echo "Cleaned iOS icon assets"
fi

if [ -d "android/app/src/main/res/mipmap" ]; then
  rm -rf android/app/src/main/res/mipmap-*
  echo "Cleaned Android icon assets"
fi

echo "Project is ready for icon generation. Run './generate_app_icons.sh' to create new icons."
