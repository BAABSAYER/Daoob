# Installing DAOOB on iPhone

## Prerequisites

- A Mac computer
- Xcode installed (get it from the Mac App Store)
- An Apple ID
- Your iPhone connected to your Mac with a USB cable
- iPhone unlocked and trusted with your Mac

## Installation Steps

### 1. Prepare the Project

Run the included setup script which fixes Java/Gradle compatibility issues and prepares the iOS files:

```bash
./build_ios.sh
```

### 2. Open in Xcode and Run

After the setup script completes, run:

```bash
./run_ios.sh
```

This will:
1. Clean the project
2. Prepare iOS build files
3. Open the project in Xcode

### 3. Configure Signing in Xcode

Once Xcode opens:

1. Select "Runner" in the left project navigator
2. Click the "Signing & Capabilities" tab
3. Check "Automatically manage signing"
4. Select your personal Apple ID from the Team dropdown
   - If you don't see your Apple ID, click "Add Account..." and sign in
5. Connect your iPhone to your Mac with a USB cable
6. Select your iPhone from the device dropdown at the top
7. Click the Play (▶) button to build and install

### 4. Trust Developer on Your iPhone

The first time you run the app:

1. If prompted, go to Settings → General → Device Management
2. Find your Apple ID and tap "Trust"

### Troubleshooting

- **App crashes immediately**: Make sure you've enabled Developer Mode on your iPhone
  (Settings → Privacy & Security → Developer Mode)
  
- **"Could not find Developer Disk Image"**: Update Xcode to a version compatible with your iOS version

- **"Unable to install"**: Make sure your iPhone is unlocked and trusted with your Mac

- **Build errors**: Try cleaning the project again with `flutter clean`

- **Expired after 7 days**: Apps installed with a free Apple ID will expire after 7 days.
  You'll need to reinstall the app.

## Features Available on Your iPhone

- Browse event categories and vendors
- Create bookings with multiple vendors
- Manage your bookings (cancel, view details)
- Chat with vendors
- Works completely offline

## Offline Mode

Toggle offline mode on the login screen if you want to use the app without an internet connection.
