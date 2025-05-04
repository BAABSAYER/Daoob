#!/bin/bash
echo "Building DAOOB APK with clean environment..."

# Stop any running Gradle daemons
echo "Stopping Gradle daemons..."
cd android && ./gradlew --stop 2>/dev/null || true
cd ..

# Delete Gradle cache directories that could be corrupted
echo "Cleaning Gradle caches..."
rm -rf ~/.gradle/caches/transforms-* 2>/dev/null || true
rm -rf ~/.gradle/caches/*/plugin-resolution/ 2>/dev/null || true
rm -rf ~/.gradle/caches/*/fileHashes/ 2>/dev/null || true
rm -rf android/.gradle 2>/dev/null || true
rm -rf android/app/build 2>/dev/null || true

# Make sure we have the latest dependencies
echo "Fetching dependencies..."
flutter pub get

# Generate app icons
echo "Generating app icons..."
flutter pub run flutter_launcher_icons

# Create platforms directory if needed
echo "Ensuring Android platform files are set up..."
flutter create --platforms=android .

# Clean flutter build
echo "Cleaning previous builds..."
flutter clean

# Create essential directories
mkdir -p android/gradle/wrapper

# Update gradle wrapper to ensure compatibility
echo "Updating Gradle wrapper..."
cat > android/gradle/wrapper/gradle-wrapper.properties << 'GWEOF'
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-7.5-all.zip
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
GWEOF

# Simplify the Kotlin configuration in app/build.gradle
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
    compileSdk 33
    ndkVersion flutter.ndkVersion

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }

    defaultConfig {
        applicationId "com.example.daoob_mobile"
        minSdkVersion 21
        targetSdkVersion 33
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

# Simplify the top-level build.gradle
cat > android/build.gradle << 'BGEOF'
buildscript {
    ext.kotlin_version = '1.7.10'
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath 'com.android.tools.build:gradle:7.3.0'
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

# Create basic local.properties if it doesn't exist
if [ ! -f android/local.properties ]; then
    echo "Creating basic local.properties..."
    echo "flutter.sdk=$(flutter --version --machine | grep flutterRoot | cut -d '"' -f 4)" > android/local.properties
fi

# Try to build a debug APK first
echo "Building debug APK..."
flutter build apk --debug

# If debug build succeeds, try to build the release APK
if [ $? -eq 0 ]; then
    echo "Debug build successful, attempting release build..."
    flutter build apk --release
    
    # Check if the build was successful
    if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
        echo ""
        echo "✅ APK built successfully!"
        echo ""
        echo "You can find the APK at: build/app/outputs/flutter-apk/app-release.apk"
        echo ""
        echo "To install on an Android device, you can use:"
        echo "flutter install"
        echo ""
        # Copy to a more accessible location
        cp build/app/outputs/flutter-apk/app-release.apk ./daoob.apk
        echo "A copy of the APK has been placed in the current directory as daoob.apk"
    else
        echo "❌ Release APK build failed, but debug APK should be available at:"
        echo "build/app/outputs/flutter-apk/app-debug.apk"
        # Copy debug APK to a more accessible location
        cp build/app/outputs/flutter-apk/app-debug.apk ./daoob-debug.apk
        echo "A copy of the debug APK has been placed in the current directory as daoob-debug.apk"
    fi
else
    echo "❌ Debug build failed. Please check the logs above for errors."
fi
