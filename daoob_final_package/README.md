# DAOOB Mobile App Build Package

This package contains everything you need to build the DAOOB mobile app with:

1. Arabic localization (default) with "دؤوب" as the Arabic name
2. Offline mode toggle on login screen
3. Event category functionality
4. Booking system with SQLite caching for offline use
5. Complete mock data implementation

## Build Instructions

1. Make sure Flutter is installed
2. Run: `chmod +x build_daoob_app.sh` 
3. Run: `./build_daoob_app.sh`
4. The APK will be built at: `daoob_mobile/build/app/outputs/flutter-apk/app-release.apk`

## Features

- Event categories (Wedding, Corporate, Birthday, Graduation, Custom)
- Offline mode toggle on splash screen
- Complete booking system with mock data
- Local database caching for offline use
- RTL support with Arabic as default language
