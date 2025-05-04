# DAOOB App Build Instructions

## To fix the Gradle/Java compatibility error:

```
./fix_gradle_java_error.sh
```

Then try building:

```
flutter build apk --debug
```

If successful, build the release version:

```
flutter build apk --release
```

## Android Testing Script

To run a more comprehensive Android build test:

```
./test_android_build.sh
```

## iOS Build

To test iOS build configuration:

```
./test_ios_build.sh
```

Then to open in Xcode:

```
open ios/Runner.xcworkspace
```

## Common Solutions for Gradle/Java Errors

1. **Incompatible Java version**: The error indicates your Java version (21) is too new for the default Gradle version. Our fix script updates the Gradle wrapper to version 8.6 which is compatible with Java 21.

2. **If still experiencing issues**:
   - Try setting `JAVA_HOME` to point to a Java 17 or 11 installation
   - Consider creating a Flutter project from scratch and copying your code over

## For iOS Development

1. Make sure you have Xcode installed
2. Connect your iPhone to your Mac
3. Open the project in Xcode: `open ios/Runner.xcworkspace`
4. Sign the app with your Apple ID in Xcode
5. Build and run directly to your device

## Credentials

Use the following test accounts:
- **Client**: Username: "demouser", Password: "password"
- **Vendor**: Username: "demovendor", Password: "password"

## Offline Mode

Toggle "Offline Mode" on the login screen to use the app without a backend connection.
