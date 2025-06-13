# DAOOB Event Management Platform

## Overview

DAOOB is a comprehensive event management platform that combines a React.js web admin dashboard, Flutter mobile application, and Node.js/Express backend to provide a complete solution for event planning and management. The platform enables clients to submit event requests through mobile apps while administrators manage these requests through a web dashboard.

## System Architecture

### Backend Architecture
- **Framework**: Node.js with Express.js and TypeScript
- **Database**: PostgreSQL with Drizzle ORM for type-safe database operations
- **Authentication**: Session-based authentication using Passport.js with local strategy
- **Session Storage**: PostgreSQL-backed session store using connect-pg-simple
- **Real-time Communication**: WebSocket integration for messaging between clients and admins
- **API Design**: RESTful API endpoints with proper validation and error handling

### Frontend Web Dashboard
- **Framework**: React 18 with TypeScript for type safety
- **Build Tool**: Vite for fast development and optimized builds
- **Routing**: Wouter for lightweight client-side routing
- **State Management**: TanStack Query for server state management
- **UI Components**: Shadcn/ui components with Tailwind CSS for styling
- **Form Handling**: React Hook Form with Zod validation

### Mobile Application
- **Framework**: Flutter with Dart for cross-platform mobile development
- **State Management**: Provider pattern for reactive state management
- **HTTP Client**: Custom API service with session-based authentication
- **Localization**: Multi-language support (English/Arabic) with RTL text support
- **Local Storage**: SharedPreferences for user session persistence

## Key Components

### Authentication System
- Session-based authentication with secure cookie handling
- User roles: admin, client, vendor (extensible for future vendor functionality)
- Password hashing using scrypt with salt for security
- Admin permission system for granular access control

### Event Management Workflow
1. **Event Types**: Admin-defined event categories with associated questionnaires
2. **Questionnaire System**: Dynamic forms based on event type selection
3. **Event Requests**: Client submissions through mobile app with detailed requirements
4. **Quotation System**: Admin-generated quotes with pricing and service details
5. **Status Tracking**: Complete workflow from request to confirmation

### Database Schema
- **Users**: Core user management with role-based access
- **Event Types**: Categorized event templates
- **Questionnaire Items**: Dynamic form fields per event type
- **Event Requests**: Client submissions with answers and metadata
- **Quotations**: Admin responses with pricing and terms
- **Messages**: Real-time communication between users
- **Admin Permissions**: Granular permission management

### Real-time Messaging
- WebSocket-based chat system between clients and administrators
- Message persistence in PostgreSQL
- Real-time notifications for new messages
- User presence tracking

## Data Flow

### Client Journey (Mobile App)
1. User registration/login with session establishment
2. Event type selection from admin-configured categories
3. Dynamic questionnaire completion based on selected event type
4. Event request submission with all gathered information
5. Real-time status updates and messaging with administrators
6. Quotation review and acceptance/rejection

### Admin Journey (Web Dashboard)
1. Secure admin login with permission verification
2. Event request management and review
3. Quotation creation with detailed pricing
4. Real-time communication with clients
5. Status tracking and workflow management

### API Communication
- All mobile-web communication through RESTful APIs
- Session cookies for authentication state management
- JSON data exchange with proper validation
- Error handling with meaningful status codes

## External Dependencies

### Core Dependencies
- **Database**: PostgreSQL 14+ required for full feature support
- **Node.js**: Version 20+ for optimal performance
- **Flutter**: Version 3.0+ for mobile app compilation

### Third-party Services
- **Session Storage**: connect-pg-simple for PostgreSQL session management
- **Password Security**: Node.js crypto module for password hashing
- **HTTP Communication**: Axios/fetch for API requests
- **WebSocket**: ws library for real-time messaging

### Development Tools
- **TypeScript**: Type safety across the entire stack
- **Drizzle Kit**: Database schema management and migrations
- **ESBuild**: Fast JavaScript bundling for production
- **Tailwind CSS**: Utility-first styling framework

## Deployment Strategy

### Development Environment
- Local PostgreSQL instance with development credentials
- Vite dev server for hot-reload frontend development
- tsx for TypeScript execution in development
- Environment variables via .env files

### Production Deployment
- Docker containerization with multi-stage builds
- Nginx reverse proxy for static file serving and API routing
- PostgreSQL as managed database service
- PM2 process management for Node.js application
- Health check endpoints for monitoring

### Container Strategy
- Single application container with built React frontend
- Separate PostgreSQL container with persistent volumes
- Nginx container for reverse proxy and static file serving
- Docker Compose for orchestration

## Changelog
- June 13, 2025. Initial setup

## User Preferences

Preferred communication style: Simple, everyday language.