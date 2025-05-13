import { db } from './server/db.ts';
import { users } from './shared/schema.ts';
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

async function initializeReplitDatabase() {
  try {
    console.log('Initializing Replit database...');
    
    // Check if admin user already exists
    const existingAdmin = await db.query.users.findFirst({
      where: (users, { eq }) => eq(users.username, 'admin')
    });
    
    if (existingAdmin) {
      console.log('Admin user already exists, skipping creation');
    } else {
      // Create admin user
      const hashedPassword = await hashPassword('password');
      
      console.log('Creating admin user with username: admin, password: password');
      
      await db.insert(users).values({
        username: 'admin',
        email: 'admin@example.com',
        password: hashedPassword,
        userType: 'admin',
        fullName: 'Admin User',
        avatarUrl: null
      });
      
      console.log('Admin user created successfully');
    }
    
    // Create a test user account if it doesn't exist
    const existingTestUser = await db.query.users.findFirst({
      where: (users, { eq }) => eq(users.username, 'testuser')
    });
    
    if (existingTestUser) {
      console.log('Test user already exists, skipping creation');
    } else {
      // Create test user
      const hashedPassword = await hashPassword('password');
      
      console.log('Creating test user with username: testuser, password: password');
      
      await db.insert(users).values({
        username: 'testuser',
        email: 'test@example.com',
        password: hashedPassword,
        userType: 'client',
        fullName: 'Test User',
        avatarUrl: null
      });
      
      console.log('Test user created successfully');
    }
    
    console.log('Database initialization complete!');
    process.exit(0);
  } catch (error) {
    console.error('Error initializing database:', error);
    process.exit(1);
  }
}

initializeReplitDatabase();