#!/usr/bin/env node

const http = require('http');

// Test user login functionality
async function debugUserLogin() {
  console.log('=== Debug User Login Issues ===\n');
  
  const SERVER = 'http://localhost:5000';
  
  try {
    // First, create a test user
    console.log('1. Creating a test user...');
    const newUser = {
      username: `logintest_${Date.now()}`,
      email: `logintest_${Date.now()}@example.com`,
      password: 'testpassword123',
      fullName: 'Login Test User',
      userType: 'client'
    };
    
    const regResponse = await makeRequest('POST', `${SERVER}/api/register`, newUser);
    console.log(`Registration Status: ${regResponse.status}`);
    
    if (regResponse.status === 201) {
      console.log(`✓ User created: ${regResponse.data.username}`);
      console.log(`User ID: ${regResponse.data.id}`);
      
      // Try to login with the same credentials
      console.log('\n2. Testing login with correct credentials...');
      const loginResponse = await makeRequest('POST', `${SERVER}/api/login`, {
        username: newUser.username,
        password: newUser.password
      });
      
      console.log(`Login Status: ${loginResponse.status}`);
      console.log('Login Response:', JSON.stringify(loginResponse.data, null, 2));
      
      if (loginResponse.status === 200) {
        console.log('✓ Login successful');
      } else {
        console.log('✗ Login failed with correct credentials');
      }
      
      // Try with wrong password
      console.log('\n3. Testing login with wrong password...');
      const wrongPassResponse = await makeRequest('POST', `${SERVER}/api/login`, {
        username: newUser.username,
        password: 'wrongpassword'
      });
      
      console.log(`Wrong Password Status: ${wrongPassResponse.status}`);
      console.log('Wrong Password Response:', JSON.stringify(wrongPassResponse.data, null, 2));
      
      // Check user details in database
      console.log('\n4. Checking user details...');
      // Login as admin to check user details
      const adminLogin = await makeRequest('POST', `${SERVER}/api/login`, {
        username: 'admin',
        password: 'admin123'
      });
      
      if (adminLogin.status === 200) {
        const usersResponse = await makeRequest('GET', `${SERVER}/api/admin/users`, null, adminLogin.cookies);
        if (usersResponse.status === 200) {
          const user = usersResponse.data.find(u => u.username === newUser.username);
          if (user) {
            console.log('Found user in database:');
            console.log(`- ID: ${user.id}`);
            console.log(`- Username: ${user.username}`);
            console.log(`- Email: ${user.email}`);
            console.log(`- User Type: ${user.userType}`);
            console.log(`- Full Name: ${user.fullName}`);
            console.log(`- Created: ${user.createdAt}`);
            console.log(`- Has password hash: ${user.password ? 'Yes' : 'No'}`);
          } else {
            console.log('✗ User not found in admin users list');
          }
        }
      }
      
    } else {
      console.log(`✗ Registration failed: ${regResponse.data?.message || 'Unknown error'}`);
    }
    
  } catch (error) {
    console.log(`✗ Debug failed: ${error.message}`);
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

debugUserLogin().catch(console.error);