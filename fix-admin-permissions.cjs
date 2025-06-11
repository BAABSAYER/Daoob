const { Pool } = require('pg');
const { drizzle } = require('drizzle-orm/node-postgres');
const { eq } = require('drizzle-orm');

// Define schema inline
const { pgTable, serial, varchar, timestamp, text, boolean, integer } = require('drizzle-orm/pg-core');

const users = pgTable('users', {
  id: serial('id').primaryKey(),
  username: text('username').notNull().unique(),
  password: text('password').notNull(),
  email: text('email').notNull().unique(),
  fullName: text('full_name'),
  phone: text('phone'),
  userType: text('user_type').notNull(),
  avatarUrl: text('avatar_url'),
  createdAt: timestamp('created_at').defaultNow(),
});

const adminPermissions = pgTable('admin_permissions', {
  id: serial('id').primaryKey(),
  userId: integer('user_id').notNull().references(() => users.id),
  permission: text('permission').notNull(),
  granted: boolean('granted').default(true),
  grantedBy: integer('granted_by').references(() => users.id),
  createdAt: timestamp('created_at').defaultNow(),
  updatedAt: timestamp('updated_at').defaultNow(),
});

async function fixAdminPermissions() {
  try {
    console.log('Fixing admin permissions...');
    
    if (!process.env.DATABASE_URL) {
      throw new Error('DATABASE_URL not found in environment');
    }
    
    const pool = new Pool({ connectionString: process.env.DATABASE_URL });
    const db = drizzle(pool, { schema: { users, adminPermissions } });
    
    // Find admin user
    const [admin] = await db.select().from(users).where(eq(users.username, 'admin'));
    if (!admin) {
      console.log('Admin user not found!');
      return;
    }
    
    console.log('Found admin user:', admin.id, admin.username);
    
    // Update user type to admin if needed
    if (admin.userType !== 'admin') {
      await db.update(users)
        .set({ userType: 'admin' })
        .where(eq(users.id, admin.id));
      console.log('Updated user type to admin');
    }
    
    // Clear existing permissions
    await db.delete(adminPermissions).where(eq(adminPermissions.userId, admin.id));
    console.log('Cleared existing permissions');
    
    // Add all required admin permissions
    const permissions = [
      'manage_event_requests',
      'manage_quotations', 
      'view_quotations',
      'manage_users',
      'manage_vendors',
      'manage_bookings',
      'manage_admins',
      'view_analytics',
      'manage_settings',
      'manage_event_types'
    ];
    
    for (const permission of permissions) {
      await db.insert(adminPermissions).values({
        userId: admin.id,
        permission: permission,
        granted: true,
        grantedBy: admin.id
      });
      console.log(`Added permission: ${permission}`);
    }
    
    console.log('Admin permissions fixed successfully!');
    console.log('The admin user now has full access to:');
    console.log('- Event Management (create/edit event types)');
    console.log('- User Management');
    console.log('- Quotation Management');
    console.log('- System Administration');
    
    await pool.end();
    
  } catch (error) {
    console.error('Error fixing admin permissions:', error);
    process.exit(1);
  }
  
  process.exit(0);
}

fixAdminPermissions();