#!/usr/bin/env node

const http = require('http');

// Check login for existing users in the system
async function checkExistingUsersLogin() {
  console.log('=== Checking Existing Users Login ===\n');
  
  const SERVER = 'http://localhost:5000';
  
  try {
    // Login as admin to get user list
    console.log('1. Getting list of existing users...');
    const adminLogin = await makeRequest('POST', `${SERVER}/api/login`, {
      username: 'admin',
      password: 'admin123'
    });
    
    if (adminLogin.status !== 200) {
      console.log('Failed to login as admin');
      return;
    }
    
    const usersResponse = await makeRequest('GET', `${SERVER}/api/admin/users`, null, adminLogin.cookies);
    if (usersResponse.status !== 200) {
      console.log('Failed to get users list');
      return;
    }
    
    const users = usersResponse.data;
    console.log(`Found ${users.length} users in system:\n`);
    
    // Show all users
    users.forEach(user => {
      console.log(`- ${user.username} (${user.userType}) - Created: ${new Date(user.createdAt).toLocaleDateString()}`);
    });
    
    console.log('\n2. Testing login for non-admin users...');
    
    // Try to login with common passwords for existing users
    const testPasswords = ['password123', 'admin123', 'test123', '123456', 'password'];
    const clientUsers = users.filter(u => u.userType === 'client');
    
    for (const user of clientUsers) {
      console.log(`\nTesting login for: ${user.username}`);
      
      let loginSuccessful = false;
      for (const password of testPasswords) {
        const loginResponse = await makeRequest('POST', `${SERVER}/api/login`, {
          username: user.username,
          password: password
        });
        
        if (loginResponse.status === 200) {
          console.log(`  ✓ Successfully logged in with password: ${password}`);
          loginSuccessful = true;
          break;
        }
      }
      
      if (!loginSuccessful) {
        console.log(`  ✗ Could not login with any test passwords`);
        console.log(`  → This user may have been created with a different password`);
        console.log(`  → Or there may be a password hashing issue`);
      }
    }
    
    // Check if password hashing is working for new users
    console.log('\n3. Testing password verification system...');
    const testUser = {
      username: `pwtest_${Date.now()}`,
      email: `pwtest_${Date.now()}@example.com`,
      password: 'knownpassword123',
      fullName: 'Password Test User',
      userType: 'client'
    };
    
    const regResponse = await makeRequest('POST', `${SERVER}/api/register`, testUser);
    if (regResponse.status === 201) {
      console.log('✓ New user created successfully');
      
      // Try login immediately
      const loginResponse = await makeRequest('POST', `${SERVER}/api/login`, {
        username: testUser.username,
        password: testUser.password
      });
      
      if (loginResponse.status === 200) {
        console.log('✓ New user can login immediately after registration');
      } else {
        console.log('✗ New user cannot login after registration - password hashing issue!');
      }
    }
    
  } catch (error) {
    console.log(`✗ Check failed: ${error.message}`);
  }
}

function makeRequest(method, url, data = null, cookies = null) {
  return new Promise((resolve, reject) => {
    const urlObj = new URL(url);
    
    const options = {
      hostname: urlObj.hostname,
      port: urlObj.port || 80,
      path: urlObj.pathname + urlObj.search,
      method: method,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      }
    };
    
    if (cookies) {
      options.headers['Cookie'] = cookies;
    }
    
    const req = http.request(options, (res) => {
      let body = '';
      
      res.on('data', (chunk) => {
        body += chunk;
      });
      
      res.on('end', () => {
        let responseData;
        try {
          responseData = body ? JSON.parse(body) : null;
        } catch (e) {
          responseData = { message: body };
        }
        
        const cookies = res.headers['set-cookie']?.join('; ');
        
        resolve({
          status: res.statusCode,
          data: responseData,
          cookies: cookies
        });
      });
    });
    
    req.on('error', (err) => {
      reject(err);
    });
    
    if (data) {
      req.write(JSON.stringify(data));
    }
    
    req.end();
  });
}

checkExistingUsersLogin().catch(console.error);