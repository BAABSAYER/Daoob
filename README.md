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

## Setup Instructions

### Backend and Web App

1. Install dependencies
```bash
npm install
```

2. Set up the database
```bash
npm run db:push
```

3. Start the development server
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