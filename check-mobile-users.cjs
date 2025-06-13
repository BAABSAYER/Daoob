#!/usr/bin/env node

const http = require('http');

// Check actual mobile app created users
async function checkMobileCreatedUsers() {
  console.log('=== Checking Mobile App Created Users ===\n');
  
  const SERVER = 'http://localhost:5000';
  
  try {
    // Login as admin to get user list
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
    
    // Filter users created recently (likely from mobile app)
    const recentUsers = users.filter(user => {
      const createdDate = new Date(user.createdAt);
      const today = new Date();
      const daysDiff = (today - createdDate) / (1000 * 60 * 60 * 24);
      return daysDiff < 2 && user.userType === 'client' && user.username !== 'admin';
    });
    
    console.log(`Found ${recentUsers.length} recent client users (likely from mobile app):\n`);
    
    recentUsers.forEach(user => {
      console.log(`- Username: ${user.username}`);
      console.log(`  Email: ${user.email}`);
      console.log(`  Full Name: ${user.fullName || 'Not set'}`);
      console.log(`  Created: ${new Date(user.createdAt).toLocaleString()}`);
      console.log('');
    });
    
    if (recentUsers.length === 0) {
      console.log('No recent mobile app users found. Creating a test mobile user...');
      
      // Create a mobile user simulation
      const mobileUser = {
        username: `mobileuser_${Date.now()}`,
        email: `mobile_${Date.now()}@example.com`,
        password: 'mobile123',
        fullName: 'Mobile App User',
        userType: 'client'
      };
      
      console.log('Creating mobile user with credentials:');
      console.log(`Username: ${mobileUser.username}`);
      console.log(`Password: ${mobileUser.password}`);
      console.log(`Email: ${mobileUser.email}\n`);
      
      const regResponse = await makeRequest('POST', `${SERVER}/api/register`, mobileUser);
      if (regResponse.status === 201) {
        console.log('✓ Mobile user created successfully');
        console.log(`User ID: ${regResponse.data.id}\n`);
        
        // Test login
        console.log('Testing login with mobile user credentials...');
        const loginResponse = await makeRequest('POST', `${SERVER}/api/login`, {
          username: mobileUser.username,
          password: mobileUser.password
        });
        
        if (loginResponse.status === 200) {
          console.log('✓ Mobile user can login successfully');
          console.log('Login response:', JSON.stringify(loginResponse.data, null, 2));
          
          // Test creating an event request
          console.log('\nTesting event request creation...');
          
          // Get event types first
          const eventTypesResponse = await makeRequest('GET', `${SERVER}/api/event-types`, null, loginResponse.cookies);
          if (eventTypesResponse.status === 200 && eventTypesResponse.data.length > 0) {
            const eventType = eventTypesResponse.data[0];
            
            const bookingData = {
              eventTypeId: eventType.id,
              eventDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
              eventTime: '19:00',
              estimatedGuests: 75,
              questionnaireResponses: {
                "1": "Mobile app test response"
              },
              notes: 'Event request created via mobile app simulation'
            };
            
            const bookingResponse = await makeRequest('POST', `${SERVER}/api/bookings`, bookingData, loginResponse.cookies);
            if (bookingResponse.status === 201) {
              console.log('✓ Event request created successfully');
              console.log(`Booking ID: ${bookingResponse.data.id}`);
              console.log(`Event Type: ${eventType.name}`);
              console.log(`Event Date: ${bookingResponse.data.eventDate}`);
            } else {
              console.log('✗ Failed to create event request:', bookingResponse.data);
            }
          }
          
        } else {
          console.log('✗ Mobile user cannot login:', loginResponse.data);
        }
      } else {
        console.log('✗ Failed to create mobile user:', regResponse.data);
      }
    } else {
      console.log('Testing login for recent mobile users...\n');
      
      // For actual mobile users, we don't know their passwords
      // So we'll show instructions for the user
      console.log('To test login with actual mobile app users, you need to:');
      console.log('1. Use the mobile app to register a new user');
      console.log('2. Remember the password you set during registration');
      console.log('3. Use those same credentials to login to the web dashboard\n');
      
      console.log('Recent mobile users found:');
      recentUsers.forEach(user => {
        console.log(`- ${user.username} (created ${new Date(user.createdAt).toLocaleString()})`);
      });
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

checkMobileCreatedUsers().catch(console.error);