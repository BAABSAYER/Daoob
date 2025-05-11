# Running the DAOOB Platform

This document provides instructions for running the DAOOB platform both locally and in a deployment environment.

## Quick Start

We've created a script that automates the entire setup process. To use it:

1. Make the script executable:
   ```bash
   chmod +x daoob-setup-guide.sh
   ```

2. Run the script:
   ```bash
   ./daoob-setup-guide.sh
   ```

3. Follow the on-screen prompts to set up your environment.

## Manual Setup Instructions

If you prefer to set up manually, follow these steps:

### Prerequisites

- Node.js 16+ and npm
- PostgreSQL database
- Flutter (for mobile app)

### Backend Setup

1. **Set up environment variables**:
   Create a `.env` file in the project root with:
   ```
   DATABASE_URL=postgresql://username:password@localhost:5432/daoob
   SESSION_SECRET=some_random_string
   ```
   Replace `username` and `password` with your PostgreSQL credentials.

2. **Install dependencies**:
   ```bash
   npm install
   ```

3. **Create database schema**:
   ```bash
   npm run db:push
   ```

4. **Create demo data**:
   ```bash
   npx tsx create-demo-data.ts
   ```

5. **Create event types** (to fix "failed to load event types" error):
   ```bash
   npx tsx create-event-types.ts
   ```

6. **Start the server**:
   ```bash
   npm run dev
   ```
   The server will be available at http://localhost:5000

### Mobile App Setup

1. **Configure API settings**:
   Update `daoob_mobile/lib/config/api_config.dart` with your local IP address if testing on physical devices.

2. **Install Flutter dependencies**:
   ```bash
   cd daoob_mobile
   flutter pub get
   ```

3. **Run the app**:
   ```bash
   flutter run
   ```

## Demo Login Credentials

After setting up the demo data, you can log in with these credentials:

- **Admin**: Username: `admin`, Password: `password`
- **Client**: Username: `demouser`, Password: `password`
- **Vendor**: Username: `demovendor`, Password: `password`

## Troubleshooting

### "Failed to load event types" Error

If you see this error in the mobile app:

1. Check if the server is running
2. Make sure you've created event types with `npx tsx create-event-types.ts`
3. Verify the API connection by running `curl http://localhost:5000/api/event-types`
4. Check the mobile app's API configuration in `daoob_mobile/lib/config/api_config.dart`

### Connection Issues with Physical Devices

If your physical device cannot connect to the local server:

1. Make sure both your computer and device are on the same WiFi network
2. Update the IP address in `api_config.dart` to your computer's local IP address
3. Verify your firewall isn't blocking connections to port 5000
4. For Android devices, you may need to enable "Use Cleartext Traffic" in the app's manifest

### Database Connection Issues

If you have problems connecting to the database:

1. Verify PostgreSQL is running
2. Check your database credentials in the `.env` file
3. Make sure the database exists with `psql -l`
4. Try connecting manually with `psql -U username -d daoob`

## Deployment

For production deployment:

1. Set up a PostgreSQL database on your hosting service
2. Update the `DATABASE_URL` in your environment variables
3. Generate a secure `SESSION_SECRET` for production
4. Build the Flutter app for production:
   ```bash
   cd daoob_mobile
   flutter build apk --release  # For Android
   flutter build ios --release  # For iOS
   ```
5. Deploy the Node.js server to your preferred hosting service

## Need Help?

If you encounter any issues not covered in this guide, please reach out for support.