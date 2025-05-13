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

2. Run the mobile app in development mode
```bash
flutter run
```

3. Build a release version
```bash
flutter build apk --release
```

## Deployment

For production deployment, use the deployment configuration in the `deploy/` directory.

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