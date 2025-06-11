const { Pool } = require('pg');

async function checkMobileRegistration() {
  try {
    if (!process.env.DATABASE_URL) {
      throw new Error('DATABASE_URL not found');
    }
    
    const pool = new Pool({ connectionString: process.env.DATABASE_URL });
    
    console.log('=== MOBILE USER REGISTRATION CHECK ===\n');
    
    // Check all users
    const allUsers = await pool.query(`
      SELECT id, username, email, "fullName", "userType", "createdAt" 
      FROM users 
      ORDER BY "createdAt" DESC
    `);
    
    console.log(`Total users in database: ${allUsers.rows.length}`);
    console.log('\nAll users:');
    console.log('========================================');
    
    let mobileUserCount = 0;
    allUsers.rows.forEach(user => {
      const userTypeLabel = user.userType === 'client' ? '📱 MOBILE' : '🖥️  ADMIN';
      console.log(`${userTypeLabel} | ID: ${user.id}`);
      console.log(`         | Name: ${user.fullName || 'N/A'}`);
      console.log(`         | Email: ${user.email}`);
      console.log(`         | Username: ${user.username || 'N/A'}`);
      console.log(`         | Created: ${user.createdAt}`);
      console.log('----------------------------------------');
      
      if (user.userType === 'client') {
        mobileUserCount++;
      }
    });
    
    console.log(`\nSUMMARY:`);
    console.log(`📱 Mobile users (clients): ${mobileUserCount}`);
    console.log(`🖥️  Admin users: ${allUsers.rows.length - mobileUserCount}`);
    
    if (mobileUserCount === 0) {
      console.log('\n⚠️  WARNING: No mobile users found!');
      console.log('This could mean:');
      console.log('1. No mobile registration attempts yet');
      console.log('2. Mobile registration is failing');
      console.log('3. Database connection issues from mobile app');
    } else {
      console.log('\n✅ Mobile user registration is working!');
    }
    
    await pool.end();
    
  } catch (error) {
    console.error('Error checking mobile registration:', error);
    process.exit(1);
  }
}

checkMobileRegistration();