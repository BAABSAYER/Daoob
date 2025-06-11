const { Pool } = require('pg');

async function debugIssues() {
  try {
    if (!process.env.DATABASE_URL) {
      throw new Error('DATABASE_URL not found');
    }
    
    const pool = new Pool({ connectionString: process.env.DATABASE_URL });
    
    console.log('=== DEBUGGING PLATFORM ISSUES ===\n');
    
    // 1. Check mobile user creation
    console.log('1. MOBILE USERS CHECK:');
    const users = await pool.query(`
      SELECT id, username, email, "fullName", "userType", "createdAt" 
      FROM users 
      WHERE "userType" = 'client'
      ORDER BY "createdAt" DESC
    `);
    
    if (users.rows.length > 0) {
      console.log('✓ Mobile users found:');
      users.rows.forEach(user => {
        console.log(`  - ${user.fullName} (${user.email}) - Created: ${user.createdAt}`);
      });
    } else {
      console.log('✗ No mobile users found');
    }
    
    // 2. Check event types and questionnaire items
    console.log('\n2. EVENT TYPES & QUESTIONS:');
    const eventTypes = await pool.query(`
      SELECT et.id, et.name, et.description, 
             COUNT(qi.id) as question_count
      FROM event_types et
      LEFT JOIN questionnaire_items qi ON et.id = qi."eventTypeId"
      GROUP BY et.id, et.name, et.description
      ORDER BY et.id
    `);
    
    eventTypes.rows.forEach(async (eventType) => {
      console.log(`Event Type: ${eventType.name} (ID: ${eventType.id})`);
      console.log(`  Questions: ${eventType.question_count}`);
      
      // Get specific questions
      const questions = await pool.query(`
        SELECT "questionText", "questionType", "required"
        FROM questionnaire_items 
        WHERE "eventTypeId" = $1
        ORDER BY "displayOrder"
      `, [eventType.id]);
      
      questions.rows.forEach(q => {
        console.log(`    - ${q.questionText} (${q.questionType})`);
      });
    });
    
    // 3. Check event requests
    console.log('\n3. EVENT REQUESTS:');
    const requests = await pool.query(`
      SELECT er.id, er.status, er."createdAt", 
             u."fullName" as client_name,
             et.name as event_type_name
      FROM event_requests er
      JOIN users u ON er."clientId" = u.id
      JOIN event_types et ON er."eventTypeId" = et.id
      ORDER BY er."createdAt" DESC
    `);
    
    if (requests.rows.length > 0) {
      console.log('✓ Event requests found:');
      requests.rows.forEach(req => {
        console.log(`  - ${req.event_type_name} by ${req.client_name} (${req.status})`);
      });
    } else {
      console.log('✗ No event requests found');
    }
    
    // 4. Check quotations
    console.log('\n4. QUOTATIONS:');
    const quotations = await pool.query(`
      SELECT q.id, q.status, q."totalPrice", q."createdAt",
             er.id as request_id
      FROM quotations q
      JOIN event_requests er ON q."eventRequestId" = er.id
      ORDER BY q."createdAt" DESC
    `);
    
    if (quotations.rows.length > 0) {
      console.log('✓ Quotations found:');
      quotations.rows.forEach(quot => {
        console.log(`  - Request ${quot.request_id}: $${quot.totalPrice} (${quot.status})`);
      });
    } else {
      console.log('✗ No quotations found');
    }
    
    await pool.end();
    
  } catch (error) {
    console.error('Error debugging:', error);
  }
}

debugIssues();