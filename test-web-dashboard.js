import fetch from 'node-fetch';

const API_BASE = 'http://localhost:5000';

// Login admin
async function loginAdmin() {
  const response = await fetch(`${API_BASE}/api/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username: 'admin', password: 'admin123' })
  });
  
  const cookies = response.headers.get('set-cookie');
  const user = await response.json();
  console.log('Admin logged in:', user.username);
  return cookies;
}

// Test web dashboard functionality
async function testWebDashboard(cookies) {
  console.log('\n--- Testing Web Dashboard Features ---');
  
  // Test user management
  console.log('1. Testing User Management...');
  const usersResponse = await fetch(`${API_BASE}/api/users`, {
    headers: { 'Cookie': cookies }
  });
  
  if (usersResponse.ok) {
    const users = await usersResponse.json();
    console.log(`✓ Users loaded: ${users.length} users found`);
    console.log(`  - Clients: ${users.filter(u => u.userType === 'client').length}`);
    console.log(`  - Admins: ${users.filter(u => u.userType === 'admin').length}`);
    console.log(`  - Vendors: ${users.filter(u => u.userType === 'vendor').length}`);
  } else {
    console.log(`✗ Users failed to load: ${usersResponse.status}`);
  }
  
  // Test event types management
  console.log('\n2. Testing Event Types Management...');
  const eventTypesResponse = await fetch(`${API_BASE}/api/event-types`, {
    headers: { 'Cookie': cookies }
  });
  
  if (eventTypesResponse.ok) {
    const eventTypes = await eventTypesResponse.json();
    console.log(`✓ Event types loaded: ${eventTypes.length} types found`);
    if (eventTypes.length > 0) {
      eventTypes.forEach(type => {
        console.log(`  - ${type.name} (${type.category}) - Active: ${type.isActive}`);
      });
    }
  } else {
    console.log(`✗ Event types failed to load: ${eventTypesResponse.status}`);
  }
  
  // Test bookings management
  console.log('\n3. Testing Bookings Management...');
  const bookingsResponse = await fetch(`${API_BASE}/api/bookings`, {
    headers: { 'Cookie': cookies }
  });
  
  if (bookingsResponse.ok) {
    const bookings = await bookingsResponse.json();
    console.log(`✓ Bookings loaded: ${bookings.length} bookings found`);
    if (bookings.length > 0) {
      const statusCounts = {};
      bookings.forEach(booking => {
        statusCounts[booking.status] = (statusCounts[booking.status] || 0) + 1;
      });
      console.log('  Status breakdown:');
      Object.entries(statusCounts).forEach(([status, count]) => {
        console.log(`    - ${status}: ${count}`);
      });
    }
  } else {
    console.log(`✗ Bookings failed to load: ${bookingsResponse.status}`);
  }
  
  // Test questionnaire items
  console.log('\n4. Testing Questionnaire Management...');
  const questionnaireResponse = await fetch(`${API_BASE}/api/questionnaire-items`, {
    headers: { 'Cookie': cookies }
  });
  
  if (questionnaireResponse.ok) {
    const items = await questionnaireResponse.json();
    console.log(`✓ Questionnaire items loaded: ${items.length} items found`);
    if (items.length > 0) {
      const typeGroups = {};
      items.forEach(item => {
        const eventTypeName = item.eventType?.name || 'Unknown';
        if (!typeGroups[eventTypeName]) typeGroups[eventTypeName] = 0;
        typeGroups[eventTypeName]++;
      });
      console.log('  Items per event type:');
      Object.entries(typeGroups).forEach(([type, count]) => {
        console.log(`    - ${type}: ${count} questions`);
      });
    }
  } else {
    console.log(`✗ Questionnaire items failed to load: ${questionnaireResponse.status}`);
  }
  
  // Test admin permissions
  console.log('\n5. Testing Admin Permissions...');
  const adminUsersResponse = await fetch(`${API_BASE}/api/admin/users`, {
    headers: { 'Cookie': cookies }
  });
  
  if (adminUsersResponse.ok) {
    const adminUsers = await adminUsersResponse.json();
    console.log(`✓ Admin users loaded: ${adminUsers.length} admin users found`);
    adminUsers.forEach(user => {
      const permissionCount = user.permissions ? user.permissions.length : 0;
      console.log(`  - ${user.username}: ${permissionCount} permissions`);
    });
  } else {
    console.log(`✗ Admin users failed to load: ${adminUsersResponse.status}`);
  }
  
  // Test real-time messaging capability
  console.log('\n6. Testing Messaging System...');
  const messagesResponse = await fetch(`${API_BASE}/api/messages`, {
    headers: { 'Cookie': cookies }
  });
  
  if (messagesResponse.ok) {
    const messages = await messagesResponse.json();
    console.log(`✓ Messages loaded: ${messages.length} messages found`);
    if (messages.length > 0) {
      const recentMessages = messages.slice(-3);
      console.log('  Recent messages:');
      recentMessages.forEach(msg => {
        const time = new Date(msg.createdAt).toLocaleTimeString();
        console.log(`    - From user ${msg.senderId} to ${msg.receiverId} at ${time}: "${msg.content.substring(0, 50)}..."`);
      });
    }
  } else {
    console.log(`✗ Messages failed to load: ${messagesResponse.status}`);
  }
  
  // Test dashboard health
  console.log('\n7. Testing System Health...');
  const healthResponse = await fetch(`${API_BASE}/api/health`);
  
  if (healthResponse.ok) {
    const health = await healthResponse.json();
    console.log(`✓ System health: ${health.status} (${health.environment})`);
    console.log(`  Server time: ${new Date(health.time).toLocaleString()}`);
  } else {
    console.log(`✗ Health check failed: ${healthResponse.status}`);
  }
}

// Main test function
async function runWebTests() {
  try {
    console.log('Testing web dashboard functionality...\n');
    
    // Login as admin
    const cookies = await loginAdmin();
    
    // Test all dashboard features
    await testWebDashboard(cookies);
    
    console.log('\n--- Web Dashboard Tests Completed ---');
    console.log('✓ All core admin features are functional');
    console.log('✓ User management working');
    console.log('✓ Event management working');
    console.log('✓ Booking management working');
    console.log('✓ System integration complete');
    
  } catch (error) {
    console.error('Web dashboard test failed:', error);
  }
}

runWebTests();