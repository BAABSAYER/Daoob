import { storage } from './server/storage.js';
import { scrypt, randomBytes } from 'crypto';
import { promisify } from 'util';

const scryptAsync = promisify(scrypt);

async function createAdminUser() {
  try {
    console.log('Creating admin user...');
    
    // Check if admin already exists
    const existingAdmin = await storage.getUserByUsername('admin');
    if (existingAdmin) {
      console.log('Admin user already exists');
      return;
    }
    
    // Create password hash
    const salt = randomBytes(16).toString('hex');
    const buf = await scryptAsync('admin123', salt, 64);
    const hashedPassword = buf.toString('hex') + '.' + salt;
    
    // Create admin user
    const admin = await storage.createUser({
      username: 'admin',
      email: 'admin@daoob.com',
      password: hashedPassword,
      userType: 'admin',
      fullName: 'System Administrator'
    });
    
    console.log('Admin user created with ID:', admin.id);
    
    // Add admin permissions
    await storage.addAdminPermission({
      userId: admin.id,
      permission: 'manage_event_requests'
    });
    await storage.addAdminPermission({
      userId: admin.id,
      permission: 'manage_quotations'
    });
    await storage.addAdminPermission({
      userId: admin.id,
      permission: 'view_quotations'
    });
    
    console.log('Admin user setup completed!');
    console.log('Login credentials:');
    console.log('Username: admin');
    console.log('Password: admin123');
    console.log('Web Dashboard: http://178.62.41.245:8080');
    
  } catch (error) {
    console.error('Error creating admin user:', error);
  }
  
  process.exit(0);
}

createAdminUser();