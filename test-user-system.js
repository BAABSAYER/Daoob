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

// Test user registration
async function testUserRegistration() {
  console.log('\n--- Testing User Registration ---');
  
  const testUsers = [
    {
      username: 'testclient1',
      password: 'password123',
      email: 'client1@test.com',
      fullName: 'John Doe',
      phone: '+1234567890',
      userType: 'client'
    },
    {
      username: 'testclient2', 
      password: 'password123',
      email: 'client2@test.com',
      fullName: 'Jane Smith',
      phone: '+1234567891',
      userType: 'client'
    }
  ];
  
  for (const userData of testUsers) {
    try {
      console.log(`Registering user: ${userData.username}...`);
      
      const response = await fetch(`${API_BASE}/api/register`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(userData)
      });
      
      if (response.ok) {
        const user = await response.json();
        console.log(`✓ Registered: ${user.username} (ID: ${user.id}) - ${user.email}`);
      } else {
        const error = await response.text();
        console.log(`✗ Failed to register ${userData.username}: ${error}`);
      }
    } catch (error) {
      console.log(`✗ Error registering ${userData.username}: ${error.message}`);
    }
  }
}

// Test user display in web dashboard
async function testUserDisplay(cookies) {
  console.log('\n--- Testing Web Dashboard User Display ---');
  
  // Test regular users API (should show all users)
  console.log('Testing all users API...');
  const allUsersResponse = await fetch(`${API_BASE}/api/users`, {
    headers: { 'Cookie': cookies }
  });
  
  if (allUsersResponse.ok) {
    const users = await allUsersResponse.json();
    console.log(`All users found: ${users.length}`);
    users.forEach(user => {
      console.log(`  - ${user.username} (${user.userType}) - ${user.email || 'No email'}`);
    });
  } else {
    console.log(`Failed to fetch all users: ${allUsersResponse.status} - ${await allUsersResponse.text()}`);
  }
  
  // Test admin users API (admin-only endpoint)
  console.log('\nTesting admin users management...');
  const adminUsersResponse = await fetch(`${API_BASE}/api/admin/users`, {
    headers: { 'Cookie': cookies }
  });
  
  if (adminUsersResponse.ok) {
    const adminUsers = await adminUsersResponse.json();
    console.log(`Admin users found: ${adminUsers.length}`);
    adminUsers.forEach(user => {
      console.log(`  - ${user.username} (${user.userType}) - ${user.email || 'No email'}`);
      if (user.permissions) {
        console.log(`    Permissions: ${user.permissions.join(', ')}`);
      }
    });
  } else {
    console.log(`Failed to fetch admin users: ${adminUsersResponse.status} - ${await adminUsersResponse.text()}`);
  }
}

// Test user login functionality
async function testUserLogin() {
  console.log('\n--- Testing User Login ---');
  
  const loginData = {
    username: 'testclient1',
    password: 'password123'
  };
  
  try {
    const response = await fetch(`${API_BASE}/api/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(loginData)
    });
    
    if (response.ok) {
      const user = await response.json();
      console.log(`✓ Login successful: ${user.username} (${user.userType})`);
      
      // Test user session
      const userCookies = response.headers.get('set-cookie');
      const userCheckResponse = await fetch(`${API_BASE}/api/user`, {
        headers: { 'Cookie': userCookies }
      });
      
      if (userCheckResponse.ok) {
        const sessionUser = await userCheckResponse.json();
        console.log(`✓ Session valid: ${sessionUser.username}`);
      } else {
        console.log('✗ Session validation failed');
      }
      
    } else {
      console.log(`✗ Login failed: ${await response.text()}`);
    }
  } catch (error) {
    console.log(`✗ Login error: ${error.message}`);
  }
}

// Check database directly
async function checkDatabase(cookies) {
  console.log('\n--- Testing Database Storage ---');
  
  try {
    // Use a simple endpoint to check if users are in database
    const response = await fetch(`${API_BASE}/api/users`, {
      headers: { 'Cookie': cookies }
    });
    
    if (response.ok) {
      const users = await response.json();
      console.log(`Total users in database: ${users.length}`);
      
      const clientUsers = users.filter(u => u.userType === 'client');
      const adminUsers = users.filter(u => u.userType === 'admin');
      
      console.log(`Client users: ${clientUsers.length}`);
      console.log(`Admin users: ${adminUsers.length}`);
      
      // Show recent registrations
      const sortedUsers = users.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
      console.log('\nMost recent users:');
      sortedUsers.slice(0, 5).forEach(user => {
        const date = new Date(user.createdAt).toLocaleDateString();
        console.log(`  - ${user.username} (${user.userType}) registered ${date}`);
      });
      
    } else {
      console.log(`Failed to check database: ${response.status}`);
    }
  } catch (error) {
    console.log(`Database check error: ${error.message}`);
  }
}

// Main test function
async function runUserTests() {
  try {
    console.log('Testing user registration and display functionality...\n');
    
    // Test user registration
    await testUserRegistration();
    
    // Login as admin
    const cookies = await loginAdmin();
    
    // Test user display in web dashboard
    await testUserDisplay(cookies);
    
    // Test user login
    await testUserLogin();
    
    // Check database storage
    await checkDatabase(cookies);
    
    console.log('\n--- User System Tests Completed ---');
  } catch (error) {
    console.error('User system test failed:', error);
  }
}

runUserTests();