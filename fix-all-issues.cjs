const { Pool } = require('pg');

async function fixAllIssues() {
  try {
    if (!process.env.DATABASE_URL) {
      throw new Error('DATABASE_URL not found');
    }
    
    const pool = new Pool({ connectionString: process.env.DATABASE_URL });
    
    console.log('=== FIXING ALL PLATFORM ISSUES ===\n');
    
    // 1. Fix admin permissions
    console.log('1. FIXING ADMIN PERMISSIONS...');
    
    // Find admin user
    const adminResult = await pool.query(`
      SELECT id, username, "userType" FROM users WHERE username = 'admin'
    `);
    
    if (adminResult.rows.length === 0) {
      console.log('✗ Admin user not found!');
      return;
    }
    
    const admin = adminResult.rows[0];
    console.log(`✓ Found admin user: ${admin.username} (ID: ${admin.id})`);
    
    // Update user type to admin
    await pool.query(`
      UPDATE users SET "userType" = 'admin' WHERE id = $1
    `, [admin.id]);
    
    // Clear existing permissions
    await pool.query(`
      DELETE FROM admin_permissions WHERE "userId" = $1
    `, [admin.id]);
    
    // Add all required permissions
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
      'manage_event_types',
      'view_event_requests'
    ];
    
    for (const permission of permissions) {
      await pool.query(`
        INSERT INTO admin_permissions ("userId", permission, granted, "grantedBy", "createdAt", "updatedAt")
        VALUES ($1, $2, true, $1, NOW(), NOW())
      `, [admin.id, permission]);
    }
    
    console.log(`✓ Added ${permissions.length} admin permissions`);
    
    // 2. Check mobile users
    console.log('\n2. CHECKING MOBILE USERS...');
    const mobileUsers = await pool.query(`
      SELECT id, email, "fullName", "userType", "createdAt" 
      FROM users 
      WHERE "userType" = 'client'
      ORDER BY "createdAt" DESC
    `);
    
    console.log(`✓ Found ${mobileUsers.rows.length} mobile users:`);
    mobileUsers.rows.forEach(user => {
      console.log(`  - ${user.fullName} (${user.email})`);
    });
    
    // 3. Fix event types and questionnaire items relationship
    console.log('\n3. CHECKING EVENT TYPES & QUESTIONS...');
    const eventTypesResult = await pool.query(`
      SELECT et.id, et.name, COUNT(qi.id) as question_count
      FROM event_types et
      LEFT JOIN questionnaire_items qi ON et.id = qi."eventTypeId"
      GROUP BY et.id, et.name
      ORDER BY et.id
    `);
    
    console.log('Event Types with Questions:');
    for (const eventType of eventTypesResult.rows) {
      console.log(`  - ${eventType.name}: ${eventType.question_count} questions`);
      
      // Get questions for this event type
      const questionsResult = await pool.query(`
        SELECT "questionText", "questionType", "required", "displayOrder"
        FROM questionnaire_items 
        WHERE "eventTypeId" = $1
        ORDER BY "displayOrder"
      `, [eventType.id]);
      
      if (questionsResult.rows.length > 0) {
        questionsResult.rows.forEach((q, idx) => {
          console.log(`    ${idx + 1}. ${q.questionText} (${q.questionType})`);
        });
      }
    }
    
    // 4. Check event requests
    console.log('\n4. CHECKING EVENT REQUESTS...');
    const eventRequestsResult = await pool.query(`
      SELECT er.id, er.status, er."createdAt",
             u."fullName" as client_name, u.email as client_email,
             et.name as event_type_name
      FROM event_requests er
      JOIN users u ON er."clientId" = u.id
      JOIN event_types et ON er."eventTypeId" = et.id
      ORDER BY er."createdAt" DESC
    `);
    
    console.log(`✓ Found ${eventRequestsResult.rows.length} event requests:`);
    eventRequestsResult.rows.forEach(req => {
      console.log(`  - ${req.event_type_name} by ${req.client_name} (${req.status})`);
      console.log(`    Email: ${req.client_email}, Created: ${req.createdAt}`);
    });
    
    // 5. Check quotations
    console.log('\n5. CHECKING QUOTATIONS...');
    const quotationsResult = await pool.query(`
      SELECT q.id, q.status, q."totalPrice", q."createdAt",
             er.id as request_id, u."fullName" as client_name
      FROM quotations q
      JOIN event_requests er ON q."eventRequestId" = er.id
      JOIN users u ON er."clientId" = u.id
      ORDER BY q."createdAt" DESC
    `);
    
    console.log(`✓ Found ${quotationsResult.rows.length} quotations:`);
    quotationsResult.rows.forEach(quot => {
      console.log(`  - Request ${quot.request_id} for ${quot.client_name}: $${quot.totalPrice} (${quot.status})`);
    });
    
    console.log('\n=== SUMMARY ===');
    console.log('✅ Admin permissions fixed');
    console.log(`✅ ${mobileUsers.rows.length} mobile users verified`);
    console.log(`✅ ${eventTypesResult.rows.length} event types checked`);
    console.log(`✅ ${eventRequestsResult.rows.length} event requests found`);
    console.log(`✅ ${quotationsResult.rows.length} quotations found`);
    
    await pool.end();
    
  } catch (error) {
    console.error('Error fixing issues:', error);
    process.exit(1);
  }
}

fixAllIssues();