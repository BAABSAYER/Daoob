# Android Build Fixes

## New Error: Task 'assembleDebug' not found / AndroidX missing

These errors indicate that:
1. The Android project structure is incorrect or corrupted
2. The app is not set up to use AndroidX (modern Android library support)

## Option 1: Fix existing project structure

Run this command to fix the project structure issues:
```
./fix_android_project.sh
```

This will:
- Set up the correct Gradle version for Java 21
- Fix the Android project structure
- Enable AndroidX support
- Create proper build configuration files

Then try building:
```
flutter clean
flutter pub get
flutter build apk --debug
```

## Option 2: Recreate Android folder completely

If Option 1 doesn't work, try recreating the Android folder from scratch:
```
./recreate_android.sh
```

This will:
- Delete the entire android directory
- Create a fresh Android project structure
- Update Gradle configuration for Java 21
- Try to build a debug APK

## Common Android Project Issues:

1. **Project Structure**: Flutter expects a specific Android project structure. When this is corrupted, you get "Task not found" errors.

2. **AndroidX**: Modern Android projects need to use AndroidX libraries. When this is missing, compatibility issues occur.

3. **Gradle Version**: Your Java version (21) requires a newer Gradle version (8.6+).

4. **Local Properties**: The SDK paths need to be correctly specified in local.properties.

## After Fixes:

Once the build succeeds, you can build a release APK:
```
flutter build apk --release
```

The APK will be available at:
`build/app/outputs/flutter-apk/app-release.apk`

A copy will also be placed at:
`./daoob.apk`
