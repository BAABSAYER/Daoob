const { Pool } = require('pg');

async function checkMobileUser() {
  try {
    if (!process.env.DATABASE_URL) {
      throw new Error('DATABASE_URL not found');
    }
    
    const pool = new Pool({ connectionString: process.env.DATABASE_URL });
    
    // Get all users to see mobile registration
    const result = await pool.query(`
      SELECT id, username, email, "fullName", "userType", "createdAt" 
      FROM users 
      ORDER BY "createdAt" DESC
    `);
    
    console.log('All users in database:');
    console.log('========================');
    result.rows.forEach(user => {
      console.log(`ID: ${user.id}`);
      console.log(`Username: ${user.username}`);
      console.log(`Email: ${user.email}`);
      console.log(`Full Name: ${user.fullName}`);
      console.log(`User Type: ${user.userType}`);
      console.log(`Created: ${user.createdAt}`);
      console.log('------------------------');
    });
    
    await pool.end();
    
  } catch (error) {
    console.error('Error checking users:', error);
  }
}

checkMobileUser();