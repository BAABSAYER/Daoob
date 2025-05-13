#!/bin/bash

# DAOOB Local Setup Script
echo "Setting up DAOOB for local development..."

# Check if .env file exists, if not create it from example
if [ ! -f .env ]; then
  echo "Creating .env file from template..."
  cp .env.example .env
  echo "Please edit the .env file with your database credentials."
  exit 1
fi

# Install dependencies
echo "Installing dependencies..."
npm install

# Setup the database schema
echo "Setting up database schema..."
npm run db:push

# Create admin user if it doesn't exist
echo "Creating admin user..."
cat > create-admin.js << 'EOF'
import { db } from './server/db.js';
import { users } from './shared/schema.js';
import { scrypt, randomBytes } from 'crypto';
import { promisify } from 'util';
import * as dotenv from 'dotenv';

dotenv.config();

const scryptAsync = promisify(scrypt);

async function hashPassword(password) {
  const salt = randomBytes(16).toString('hex');
  const buf = await scryptAsync(password, salt, 64);
  return `${buf.toString('hex')}.${salt}`;
}

async function createAdminUser() {
  try {
    // Check if admin user already exists
    const existingAdmin = await db.query.users.findFirst({
      where: (users, { eq }) => eq(users.username, 'admin')
    });
    
    if (existingAdmin) {
      console.log('Admin user already exists, skipping creation');
      process.exit(0);
    }
    
    // Create admin user
    const hashedPassword = await hashPassword('password');
    
    await db.insert(users).values({
      username: 'admin',
      email: 'admin@example.com',
      password: hashedPassword,
      role: 'ADMIN',
      name: 'Admin User',
      profilePicture: null,
      bio: 'System administrator',
      createdAt: new Date(),
      updatedAt: new Date()
    });
    
    console.log('Admin user created successfully');
  } catch (error) {
    console.error('Error creating admin user:', error);
    process.exit(1);
  }
}

createAdminUser();
EOF

# Run the admin user creation script
node create-admin.js

echo "==================================================="
echo "Setup complete! You can now start the server with:"
echo "npm run dev"
echo "==================================================="
echo "Admin credentials:"
echo "Username: admin"
echo "Password: password"
echo "==================================================="