#!/bin/bash
echo "Preparing DAOOB app for iOS..."

# Update the Gradle wrapper to be compatible with Java 21
echo "Updating Gradle wrapper for compatibility with Java 21..."
mkdir -p android/gradle/wrapper
cat > android/gradle/wrapper/gradle-wrapper.properties << 'GWEOF'
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.4-all.zip
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
GWEOF

# Update build.gradle to be compatible with Java 21
echo "Updating build.gradle for Java 21 compatibility..."
cat > android/build.gradle << 'BGEOF'
buildscript {
    ext.kotlin_version = '1.9.22'
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath 'com.android.tools.build:gradle:8.2.0'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.buildDir = '../build'
subprojects {
    project.buildDir = "${rootProject.buildDir}/${project.name}"
}
subprojects {
    project.evaluationDependsOn(':app')
}

tasks.register("clean", Delete) {
    delete rootProject.buildDir
}
BGEOF

cat > android/app/build.gradle << 'AGEOF'
plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
}

def localProperties = new Properties()
def localPropertiesFile = rootProject.file('local.properties')
if (localPropertiesFile.exists()) {
    localPropertiesFile.withReader('UTF-8') { reader ->
        localProperties.load(reader)
    }
}

def flutterVersionCode = localProperties.getProperty('flutter.versionCode')
if (flutterVersionCode == null) {
    flutterVersionCode = '1'
}

def flutterVersionName = localProperties.getProperty('flutter.versionName')
if (flutterVersionName == null) {
    flutterVersionName = '1.0'
}

android {
    namespace "com.example.daoob_mobile"
    compileSdk 34
    ndkVersion flutter.ndkVersion

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId "com.example.daoob_mobile"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
    }

    buildTypes {
        release {
            signingConfig signingConfigs.debug
        }
    }
}

flutter {
    source '../..'
}

dependencies {}
AGEOF

# Clean any previous builds and get dependencies
echo "Cleaning and getting dependencies..."
flutter clean
flutter pub get

# Make sure iOS platform files exist
echo "Setting up iOS platform files..."
flutter create --platforms=ios .

# Specific iOS setup - Create a script to run the iOS build and open Xcode
echo "Preparing for iOS development..."
cat > run_ios.sh << 'RUNIOS'
#!/bin/bash
# Run this script to build the iOS app and open it in Xcode

# Clean up any previous builds first
flutter clean ios
flutter pub get

# Build iOS files first
flutter build ios --no-codesign

# Open the project in Xcode
open ios/Runner.xcworkspace
RUNIOS
chmod +x run_ios.sh

echo ""
echo "iOS setup complete! Follow these steps to run on your iPhone X Max:"
echo ""
echo "1. Run this command to open in Xcode:"
echo "   ./run_ios.sh"
echo ""
echo "2. In Xcode:"
echo "   - Click on 'Runner' in the left sidebar"
echo "   - Go to 'Signing & Capabilities' tab"
echo "   - Check 'Automatically manage signing'"
echo "   - Select your personal Apple ID from the Team dropdown"
echo ""
echo "3. Connect your iPhone to your Mac with a USB cable"
echo ""
echo "4. In Xcode:"
echo "   - Select your iPhone from the device dropdown at the top"
echo "   - Click the Play (▶) button to build and install"
echo ""
echo "5. On your iPhone:"
echo "   - If prompted, go to Settings → General → Device Management"
echo "   - Find your Apple ID and tap 'Trust'"
echo ""
echo "The app should now install and run on your iPhone!"
