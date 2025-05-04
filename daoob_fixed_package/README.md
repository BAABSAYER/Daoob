# DAOOB Mobile App - Fixed Package

This package contains fixed files for the DAOOB mobile app with:

1. Offline mode toggle on login screen (under "Forgot Password" text)
2. Proper Arabic name "دؤوب" display
3. Fixed import issues that were causing compilation errors

## What's Included

1. `splash_screen.dart` - Updated splash screen without the offline toggle
2. `login_screen.dart` - Login screen with offline toggle below "Forgot Password"
3. `auth_service.dart` - Authentication service with the User class defined inline
4. `booking_service.dart` - Booking service with the Booking class defined inline

## How to Use

1. Replace your existing files with these fixed versions:
   ```
   cp splash_screen.dart [your_app_path]/lib/screens/
   cp login_screen.dart [your_app_path]/lib/screens/
   cp auth_service.dart [your_app_path]/lib/services/
   cp booking_service.dart [your_app_path]/lib/services/
   ```

2. Make sure your fonts are set up correctly in pubspec.yaml for Arabic support:
   ```yaml
   fonts:
     - family: Almarai
       fonts:
         - asset: assets/fonts/Almarai-Regular.ttf
         - asset: assets/fonts/Almarai-Bold.ttf
           weight: 700
   ```

3. Ensure your app has Arabic translations in assets/lang/ar.json

4. Run the app:
   ```
   flutter run
   ```

## Important Notes

- The offline mode toggle is now positioned on the login page under "Forgot Password"
- The Arabic name "دؤوب" should now display correctly with the Almarai font
- We've fixed circular dependency issues by defining classes inline
- SQLite database initialization is now more robust


## Setting up Arabic Support

1. Create or update your Arabic translation file:
   
   ```bash
   # Create directory if it doesn't exist
   mkdir -p daoob_mobile/assets/lang
   
   # Copy the Arabic translations
   cp ar.json daoob_mobile/assets/lang/
   ```

2. Add the Almarai font to your app:
   
   ```bash
   # Create font directory if it doesn't exist
   mkdir -p daoob_mobile/assets/fonts
   
   # Download Almarai font if you don't have it
   curl -o daoob_mobile/assets/fonts/Almarai-Regular.ttf https://github.com/BlackOjonas/Almarai/raw/main/1.%20OTF/Individual%20Weights/Almarai-Regular.otf
   curl -o daoob_mobile/assets/fonts/Almarai-Bold.ttf https://github.com/BlackOjonas/Almarai/raw/main/1.%20OTF/Individual%20Weights/Almarai-Bold.otf
   ```

3. Add font configuration to pubspec.yaml:
   
   ```yaml
   fonts:
     - family: Almarai
       fonts:
         - asset: assets/fonts/Almarai-Regular.ttf
         - asset: assets/fonts/Almarai-Bold.ttf
           weight: 700
   ```

This will ensure that the Arabic text "دؤوب" is displayed correctly with the proper font.
