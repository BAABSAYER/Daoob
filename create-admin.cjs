const { Pool } = require('pg');
const { drizzle } = require('drizzle-orm/node-postgres');
const { scrypt, randomBytes } = require('crypto');
const { promisify } = require('util');
const { eq } = require('drizzle-orm');

const scryptAsync = promisify(scrypt);

// Define schema inline to avoid import issues
const { pgTable, serial, varchar, timestamp, text } = require('drizzle-orm/pg-core');

const users = pgTable('users', {
  id: serial('id').primaryKey(),
  username: varchar('username', { length: 255 }).unique().notNull(),
  email: varchar('email', { length: 255 }).unique(),
  password: varchar('password', { length: 255 }).notNull(),
  fullName: varchar('full_name', { length: 255 }),
  userType: varchar('user_type', { length: 50 }).default('client'),
  createdAt: timestamp('created_at').defaultNow(),
  updatedAt: timestamp('updated_at').defaultNow(),
});

const adminPermissions = pgTable('admin_permissions', {
  id: serial('id').primaryKey(),
  userId: serial('user_id').references(() => users.id),
  permission: varchar('permission', { length: 100 }).notNull(),
  createdAt: timestamp('created_at').defaultNow(),
});

async function createAdminUser() {
  try {
    console.log('Creating admin user...');
    
    if (!process.env.DATABASE_URL) {
      throw new Error('DATABASE_URL not found in environment');
    }
    
    const pool = new Pool({ connectionString: process.env.DATABASE_URL });
    const db = drizzle(pool, { schema: { users, adminPermissions } });
    
    // Check if admin already exists
    const existingAdmin = await db.select().from(users).where(eq(users.username, 'admin'));
    if (existingAdmin.length > 0) {
      console.log('Admin user already exists with ID:', existingAdmin[0].id);
      return;
    }
    
    // Create password hash
    const salt = randomBytes(16).toString('hex');
    const buf = await scryptAsync('admin123', salt, 64);
    const hashedPassword = buf.toString('hex') + '.' + salt;
    
    // Create admin user
    const [admin] = await db.insert(users).values({
      username: 'admin',
      email: 'admin@daoob.com',
      password: hashedPassword,
      userType: 'admin',
      fullName: 'System Administrator'
    }).returning();
    
    console.log('Admin user created with ID:', admin.id);
    
    // Add admin permissions
    const permissions = ['manage_event_requests', 'manage_quotations', 'view_quotations'];
    
    for (const permission of permissions) {
      await db.insert(adminPermissions).values({
        userId: admin.id,
        permission: permission
      });
    }
    
    console.log('Admin user setup completed!');
    console.log('Login credentials:');
    console.log('Username: admin');
    console.log('Password: admin123');
    console.log('Web Dashboard: http://178.62.41.245:8080');
    
    await pool.end();
    
  } catch (error) {
    console.error('Error creating admin user:', error);
    process.exit(1);
  }
  
  process.exit(0);
}

createAdminUser();