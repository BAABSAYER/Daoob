# DAOOB Flutter App with Arabic Support

This project contains scripts to build the DAOOB event management mobile app with bilingual support (English and Arabic).

## Prerequisites

Before building the app, you need to have the following installed on your computer:

- Flutter SDK (latest stable version recommended)
- Android Studio or Xcode (for building to respective platforms)
- Git

## How to Build the App

Follow these steps to build the DAOOB app:

1. **Download all files** from this folder to your local machine
2. **Place the logo file** in the correct location:
   - Make sure the file `WhatsApp Image 2025-04-06 at 21.40.44_8e7cb969.jpg` is in a folder named `attached_assets` in the same directory as these scripts
3. **Make all scripts executable**:
   ```bash
   chmod +x *.sh
   ```
4. **Update the master script** first:
   ```bash
   ./update_master_script.sh
   ```
5. **Build the app** by running:
   ```bash
   ./create_and_build_app.sh
   ```
6. **Wait for the build process** to complete (this may take several minutes)
7. **Find the APK** at:
   ```
   eventora_app/build/app/outputs/flutter-apk/app-release.apk
   ```

## Features

- **Bilingual Support**: The app supports both English and Arabic languages
- **Offline Mode**: Toggle between online and offline functionality
- **Real-time API Connection**: Connects to your server when online
- **DAOOB App Icon**: Uses your custom logo as the app icon
- **Demo Accounts**: Pre-configured demo accounts for testing

## Demo Credentials

- **Client**: Username: `demouser`, Password: `password`
- **Vendor**: Username: `demovendor`, Password: `password`

## App Structure

The Flutter app follows a clean architecture with:

- **Models**: Data models for users, bookings, services, etc.
- **Services**: API service, authentication service
- **Screens**: UI screens for different app functionalities
- **Localization**: Support for English and Arabic
- **Themes**: Consistent Purple theme (Color: #6A3DE8)

## Troubleshooting

If you encounter issues:

1. **Flutter errors**: Make sure Flutter is properly installed and on your PATH
2. **Build errors**: Check Android SDK or iOS development setup
3. **Script errors**: Ensure all scripts have execute permissions

## Contact

For any questions or issues, please contact the development team.