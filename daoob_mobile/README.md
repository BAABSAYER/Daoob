# DAOOB Mobile App

Smart Event Management Platform

## Features

- User authentication with client and vendor roles
- Event category selection
- Custom event planning
- Booking management
- Real-time messaging system
- Offline mode support
- Multi-language support (English/Arabic)

## Getting Started

1. Run `flutter pub get` to install dependencies
2. Set up app icons with `./setup_app_icon.sh`
3. Run `flutter create --platforms=ios .` to add iOS platform files if needed
4. Run `flutter run` to start the app

## Offline Mode

The app supports an offline mode that can be enabled from the login screen.
In offline mode, the app will use local storage for data persistence.

## App Icons

The app uses a custom icon system. To set up app icons:

```bash
./setup_app_icon.sh
```

This script will generate all the necessary app icon files for both Android and iOS.
See ICON_SETUP.md for more details on icon configuration.

## Arabic Support

The app fully supports Arabic language with proper RTL layout.
