# DAOOB Event Management Platform

A comprehensive event management platform with web admin dashboard and mobile applications for clients and vendors.

## Core Components

### Web Admin Dashboard
- Admin interface for platform oversight
- Vendor and user management
- Event request and booking management 
- Real-time chat with clients and vendors

### Mobile Application (Flutter)
- Client app for browsing vendors and planning events
- Vendor app for managing services and bookings
- Real-time messaging system
- Multilingual support (English/Arabic with RTL)

## Technology Stack

### Backend (server/)
- Node.js with Express and TypeScript
- PostgreSQL database with Drizzle ORM
- WebSocket for real-time messaging
- RESTful API endpoints

### Web Frontend (client/)
- React with TypeScript 
- TanStack Query for data fetching
- Shadcn UI components and Tailwind CSS
- Responsive design for all devices

### Mobile App (daoob_mobile/)
- Flutter/Dart
- Provider pattern for state management
- API integration with backend server
- Localization support

## Quick Setup for Local Development

### One-Command Setup (Recommended)

Run the setup script to automatically install dependencies, set up the database, and create an admin user:

```bash
# Make the script executable
chmod +x setup.sh

# Run the setup script
./setup.sh
```

The script will:
1. Create necessary environment files
2. Install dependencies
3. Set up the database schema
4. Create an admin user (username: admin, password: password)

After running the setup script, you can start the server:

```bash
npm run dev
```

Then access the application at http://localhost:5000

### Manual Setup

If you prefer to set up manually:

1. Create a `.env` file in the root directory with the following content:
```
DATABASE_URL=postgres://username:password@localhost:5432/database_name
SESSION_SECRET=your_session_secret_here
NODE_ENV=development
PORT=5000
SERVER_HOST=localhost
```

2. Create a `client/.env` file with:
```
VITE_SERVER_HOST=localhost
VITE_SERVER_PORT=5000
```

3. Install dependencies:
```bash
npm install
```

4. Set up the database:
```bash
npm run db:push
```

5. Start the development server:
```bash
npm run dev
```

### Flutter Mobile App

1. Install Flutter dependencies
```bash
cd daoob_mobile
flutter pub get
```

2. Configure the API endpoint
   - To connect to a local server: Make sure `currentEnvironment = ENV_LOCAL` in `lib/config/api_config.dart`
   - To connect to the Replit deployment: Set `currentEnvironment = ENV_REPLIT` in `lib/config/api_config.dart`
   - To connect to production: Set `currentEnvironment = ENV_PRODUCTION` in `lib/config/api_config.dart`

3. Run the mobile app in development mode
```bash
flutter run
```

4. Build a release version
```bash
flutter build apk --release
```

#### Mobile App Connection Notes

- For Android emulator connecting to a local server, the app uses `10.0.2.2:5000` (special Android emulator IP)
- For iOS simulator connecting to a local server, the app uses `localhost:5000`
- For physical devices, you may need to use your computer's actual IP address instead of localhost
- WebSocket connections use the `ws://` or `wss://` protocol with the `/ws` endpoint

## Deployment Options

### Replit Deployment
To deploy the application on Replit:

1. Set up the database and create test users:
   ```bash
   # Make the setup script executable
   chmod +x replit-setup.sh
   
   # Run the setup script
   ./replit-setup.sh
   ```

2. Click the "Deploy" button at the top of the Replit interface
3. Wait for the deployment process to complete
4. Replit will provide a public URL (e.g., https://daoob.replit.app)

5. The mobile app is already configured to connect to the Replit deployment:
   ```dart
   // This is already set in daoob_mobile/lib/config/api_config.dart
   static const int currentEnvironment = ENV_REPLIT;
   ```

#### Test Accounts
The setup script creates two test accounts:

**Admin User:**
- Username: admin
- Password: password

**Test Client:**
- Username: testuser
- Password: password

### Production Deployment
For production deployment on your own server:

1. Use the deployment configuration in the `deploy/` directory
2. Configure your web server (NGINX, Apache, etc.) as a reverse proxy
3. Set up SSL certificates for secure connections
4. Update the mobile app's configuration:
   ```dart
   // In daoob_mobile/lib/config/api_config.dart
   static const String productionApiUrl = 'https://your-production-domain.com';
   static const int currentEnvironment = ENV_PRODUCTION;
   ```

## Key Features

- **Event Planning** - Custom event types with dynamic questionnaires
- **Booking System** - Comprehensive booking management for vendors
- **Real-time Chat** - WebSocket-based messaging between users
- **Admin Dashboard** - Complete platform management interface
- **Multi-language Support** - English and Arabic (RTL) interfaces

## Project Structure

- `client/` - React web frontend
- `server/` - Node.js backend
- `shared/` - Shared TypeScript schemas
- `daoob_mobile/` - Flutter mobile application
- `deploy/` - Deployment configuration