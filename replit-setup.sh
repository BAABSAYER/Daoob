#!/bin/bash

# DAOOB Replit Setup Script
echo "Setting up DAOOB for Replit deployment..."

# Run database migrations
echo "Setting up database schema..."
npm run db:push

# Initialize database with admin and test users
echo "Initializing database with test users..."
node init-replit-db.js

echo "==================================================="
echo "Replit setup complete!"
echo "==================================================="
echo "Admin credentials:"
echo "Username: admin"
echo "Password: password"
echo "==================================================="
echo "Test user credentials:"
echo "Username: testuser"
echo "Password: password"
echo "==================================================="