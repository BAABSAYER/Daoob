# DAOOB Mobile App

DAOOB (دؤوب) is a comprehensive event management platform that connects clients with vendors for various event types.

## Features

- User authentication with offline mode support
- Event category browsing and selection
- Vendor discovery and booking
- Real-time chat between clients and vendors
- Booking management for both clients and vendors
- Multi-language support (English and Arabic)

## Getting Started

1. Make sure you have Flutter installed and set up on your machine
2. Clone this repository
3. Run `flutter pub get` to install dependencies
4. Run `flutter run` to start the app on your device or emulator

## Key Files

- **lib/main.dart**: Entry point of the application
- **lib/screens/**: UI screens for the app
- **lib/services/**: Service classes for authentication, booking, etc.
- **lib/providers/**: State management using Provider
- **lib/l10n/**: Localization support for multiple languages
- **lib/models/**: Data models
- **lib/widgets/**: Reusable UI components

## Offline Mode

The app supports an offline mode that allows users to:
- Log in without an internet connection
- View cached bookings
- Create bookings that will be synced when online

To toggle offline mode, use the switch on the login screen.

## Arabic Support

The app fully supports Arabic language and right-to-left (RTL) layout:
- Arabic translations are in `assets/lang/ar.json`
- The app name "دؤوب" displays correctly using the Almarai font

## Important Fixes Applied

1. **Fixed circular dependencies**: User and Booking classes now defined inline to avoid circular imports

2. **Moved offline mode toggle**: The toggle has been moved from the splash screen to the login screen

3. **Added Arabic font support**: Using Almarai font for properly displaying "دؤوب"

4. **Fixed splash screen freezing**: The app now properly advances past the splash screen 

## Development Notes

- Built with Flutter and Provider for state management
- Uses SQLite for local caching of data
- HTTP for API communication
- Shared Preferences for user preferences storage
