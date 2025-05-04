#!/bin/bash
echo "Fixing Gradle/Java compatibility issue..."

# Create gradle directory if it doesn't exist
mkdir -p android/gradle/wrapper

# Fix Gradle wrapper properties - use Gradle 8.6 which is compatible with Java 21
echo "Setting up Gradle 8.6 (compatible with Java 21)..."
cat > android/gradle/wrapper/gradle-wrapper.properties << 'GWEOF'
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.6-bin.zip
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
GWEOF

echo "Done! Now run: flutter build apk --debug"
echo "If that works, then run: flutter build apk --release"
