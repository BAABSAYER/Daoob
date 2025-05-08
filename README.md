# DAOOB Event Management Platform

A comprehensive mobile and web-based event management platform that simplifies vendor discovery, event planning, and collaborative experiences through an intelligent, user-friendly interface.

## Project Components

### Web Admin Dashboard
- Admin interface for platform oversight
- Vendor management
- Booking and event request handling
- Admin team management with permissions system

### Mobile Application (Flutter)
- Client app for users to browse vendors and book services
- Vendor app for service providers to manage bookings
- Real-time chat functionality
- Offline mode with local caching

## Technology Stack

### Backend
- Node.js with Express
- TypeScript
- PostgreSQL database with Drizzle ORM
- WebSocket for real-time messaging
- Authentication with Passport.js

### Web Frontend
- React.js
- TypeScript
- TanStack Query for data fetching
- Shadcn UI components with Tailwind CSS

### Mobile App
- Flutter/Dart
- Provider for state management
- SQLite for local storage
- WebSocket for real-time chat

## Local Setup

### Prerequisites
- Node.js 18+ and npm
- PostgreSQL
- Flutter SDK

### Getting Started

1. Clone the repository
```bash
git clone https://github.com/yourusername/daoob-event-management.git
cd daoob-event-management
```

2. Install dependencies
```bash
npm install
```

3. Set up the database
```bash
npm run db:push
```

4. Run the server
```bash
./start-local-server.sh
```

5. Build the Flutter app
```bash
cd daoob_mobile
flutter pub get
flutter build apk
```

### Testing Local Connectivity
Run the connectivity test script to verify your setup:
```bash
./test-local-connection.sh
```

## Features

- **Vendor Discovery** - Browse and search vendors by category, location, and ratings
- **Booking Management** - Create, view, and manage event bookings
- **Real-time Messaging** - Chat directly with vendors or clients
- **Admin Dashboard** - Comprehensive platform management
- **Offline Mode** - Use the mobile app even without internet connection
- **Multi-language Support** - Arabic (RTL) and English interfaces

## Project Structure

- `/client` - React web frontend
- `/server` - Node.js backend
- `/shared` - Shared TypeScript schemas and types
- `/daoob_mobile` - Flutter mobile application