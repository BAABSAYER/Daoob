# Local Development Setup Guide for DAOOB

## Server Setup (Complete ✅)
You have successfully set up the backend server! It's running on http://localhost:5000

## Database Setup (Next Steps)

1. **Create initial data**

   Run these commands in a new terminal window (keep your server running):

   ```bash
   # Create demo users (admin, clients, vendors)
   npx tsx create-demo-data.ts

   # Create event types and questionnaires
   npx tsx create-event-types.ts
   ```

2. **Verify database setup**

   You can check if data was created successfully by running:
   ```bash
   psql -d daoob -c "SELECT COUNT(*) FROM users"
   psql -d daoob -c "SELECT COUNT(*) FROM event_types"
   ```

## Flutter Mobile App Setup

1. **Build and run the Flutter app**:
   ```bash
   cd daoob_mobile
   flutter pub get
   flutter run
   ```

2. **For physical devices**:
   
   Update the API configuration to point to your computer's IP address. Edit `daoob_mobile/lib/config/api_config.dart`:

   ```dart
   static String get baseUrl {
     // For real device on the same network, use your computer's IP address
     if (Platform.isAndroid && !isEmulator()) {
       return 'http://YOUR_IP_ADDRESS:5000'; // Replace with your computer's IP
     }
     ...
   }
   ```

   You can find your IP address by running:
   - macOS: `ifconfig | grep inet`
   - Linux: `ip addr`
   - Windows: `ipconfig`

## Testing the Application

1. **Log in to the web app**:
   - Open http://localhost:5000 in your browser
   - Use these credentials:
     - Admin: Username: `admin`, Password: `password`
     - Client: Username: `demouser`, Password: `password`
     - Vendor: Username: `demovendor`, Password: `password`

2. **Test the mobile app**:
   - Launch the app on your emulator or device
   - Log in using the same credentials
   - Navigate to "Events" to see if event types load correctly

## Troubleshooting

- **Database Connection Issues**: Check your `.env` file DATABASE_URL setting
- **Event Types Not Loading**: Make sure you've run `npx tsx create-event-types.ts` and the server is running
- **Flutter App Connection Issues**: Make sure the API URL in the Flutter app points to your server

## Restarting the Server

If you need to restart the server, press Ctrl+C to stop it, then run:
```bash
npm run dev
```