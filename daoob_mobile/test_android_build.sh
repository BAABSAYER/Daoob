#!/bin/bash
echo "Testing Android build with minimal configuration..."

# Run the fix first
./fix_gradle_java_error.sh

# Try a debug build
flutter build apk --debug

if [ $? -eq 0 ]; then
    echo "Debug build succeeded! You can try a release build: flutter build apk --release"
else
    echo "Build still failing. Let's try to be even more minimal."
    
    # Create a very simple build.gradle
    cat > android/build.gradle << 'BGEOF'
buildscript {
    ext.kotlin_version = '1.9.0'
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath 'com.android.tools.build:gradle:8.1.0'
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
BGEOF
    
    # Try the build again
    flutter build apk --debug
    
    if [ $? -eq 0 ]; then
        echo "Debug build succeeded with minimal configuration!"
    else
        echo "Still failing. Let's create a local.properties file with a direct path to the Android SDK"
        
        # Get Flutter SDK path
        FLUTTER_SDK=$(flutter --version --machine | grep flutterRoot | cut -d '"' -f 4)
        
        # Create local.properties with SDK path
        echo "flutter.sdk=$FLUTTER_SDK" > android/local.properties
        echo "sdk.dir=$HOME/Library/Android/sdk" >> android/local.properties
        
        # Try again
        flutter build apk --debug
        
        if [ $? -eq 0 ]; then
            echo "Success with SDK path specification!"
        else
            echo "All normal fixes failed. This might require manual setup."
        fi
    fi
fi
