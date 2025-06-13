#!/usr/bin/env node

const http = require('http');
const https = require('https');

// Production server configuration
const PROD_SERVER = 'http://178.62.41.245';

// Test mobile app endpoints and functionality
async function testMobileAppEndpoints() {
  console.log('=== Testing Mobile App API Endpoints ===\n');
  
  // Test 1: User Registration
  console.log('1. Testing User Registration...');
  const newUser = {
    username: `testuser_${Date.now()}`,
    email: `test_${Date.now()}@example.com`,
    password: 'password123',
    fullName: 'Test User Mobile',
    userType: 'client'
  };
  
  try {
    const regResponse = await makeRequest('POST', `${PROD_SERVER}/api/register`, newUser);
    console.log(`   Registration Status: ${regResponse.status}`);
    if (regResponse.status === 201) {
      console.log(`   ✓ User created successfully: ${regResponse.data.username}`);
      console.log(`   User ID: ${regResponse.data.id}`);
      
      // Test login with new user
      console.log('\n2. Testing Login with New User...');
      const loginResponse = await makeRequest('POST', `${PROD_SERVER}/api/login`, {
        username: newUser.username,
        password: newUser.password
      }, regResponse.cookies);
      
      console.log(`   Login Status: ${loginResponse.status}`);
      if (loginResponse.status === 200) {
        console.log(`   ✓ Login successful for: ${loginResponse.data.username}`);
        
        // Test event types endpoint
        console.log('\n3. Testing Event Types Endpoint...');
        const eventTypesResponse = await makeRequest('GET', `${PROD_SERVER}/api/event-types`, null, loginResponse.cookies);
        console.log(`   Event Types Status: ${eventTypesResponse.status}`);
        console.log(`   Event Types Count: ${eventTypesResponse.data?.length || 0}`);
        
        if (eventTypesResponse.data && eventTypesResponse.data.length > 0) {
          const firstEventType = eventTypesResponse.data[0];
          console.log(`   First Event Type: ${firstEventType.name} (ID: ${firstEventType.id})`);
          
          // Test questionnaire items for first event type
          console.log('\n4. Testing Questionnaire Items...');
          const questionnaireResponse = await makeRequest('GET', 
            `${PROD_SERVER}/api/event-types/${firstEventType.id}/questionnaire-items`, 
            null, loginResponse.cookies);
          
          console.log(`   Questionnaire Status: ${questionnaireResponse.status}`);
          console.log(`   Questions Count: ${questionnaireResponse.data?.length || 0}`);
          
          if (questionnaireResponse.data && questionnaireResponse.data.length > 0) {
            console.log('   ✓ Questions loaded successfully');
            questionnaireResponse.data.forEach((q, i) => {
              console.log(`     Q${i+1}: ${q.questionText} (${q.questionType})`);
            });
            
            // Test event request submission (booking creation)
            console.log('\n5. Testing Event Request Submission...');
            const bookingData = {
              eventTypeId: firstEventType.id,
              eventDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(), // 30 days from now
              eventTime: '18:00',
              estimatedGuests: 50,
              questionnaireResponses: {
                [questionnaireResponse.data[0].id]: 'Test response from mobile app'
              },
              notes: 'Test booking created via mobile app endpoint testing'
            };
            
            const bookingResponse = await makeRequest('POST', `${PROD_SERVER}/api/bookings`, bookingData, loginResponse.cookies);
            console.log(`   Booking Status: ${bookingResponse.status}`);
            if (bookingResponse.status === 201) {
              console.log(`   ✓ Event request submitted successfully: Booking ID ${bookingResponse.data.id}`);
            } else {
              console.log(`   ✗ Event request failed: ${bookingResponse.data?.message || 'Unknown error'}`);
            }
          } else {
            console.log('   ✗ No questions found for event type');
          }
        } else {
          console.log('   ✗ No event types found');
        }
      } else {
        console.log(`   ✗ Login failed: ${loginResponse.data?.message || 'Unknown error'}`);
      }
    } else {
      console.log(`   ✗ Registration failed: ${regResponse.data?.message || 'Unknown error'}`);
    }
  } catch (error) {
    console.log(`   ✗ Test failed: ${error.message}`);
  }
  
  // Test admin dashboard user list
  console.log('\n6. Testing Admin Dashboard User Recognition...');
  try {
    // Login as admin
    const adminLogin = await makeRequest('POST', `${PROD_SERVER}/api/login`, {
      username: 'admin',
      password: 'admin123'
    });
    
    if (adminLogin.status === 200) {
      // Get all users from admin endpoint
      const usersResponse = await makeRequest('GET', `${PROD_SERVER}/api/admin/users`, null, adminLogin.cookies);
      console.log(`   Admin Users Status: ${usersResponse.status}`);
      if (usersResponse.status === 200) {
        console.log(`   Total Users in System: ${usersResponse.data?.length || 0}`);
        console.log('   Recent Users:');
        if (usersResponse.data) {
          usersResponse.data.slice(-3).forEach(user => {
            console.log(`     - ${user.username} (${user.userType}) - Created: ${new Date(user.createdAt).toLocaleDateString()}`);
          });
        }
      } else {
        console.log(`   ✗ Failed to fetch admin users: ${usersResponse.data?.message || 'Permission denied'}`);
      }
    } else {
      console.log('   ✗ Admin login failed');
    }
  } catch (error) {
    console.log(`   ✗ Admin test failed: ${error.message}`);
  }
  
  console.log('\n=== Test Summary ===');
  console.log('If users registered via mobile app are not appearing in web dashboard,');
  console.log('the issue may be environment mismatch or permission configuration.');
  console.log('Check that both mobile app and web dashboard connect to the same server.');
}

function makeRequest(method, url, data = null, cookies = null) {
  return new Promise((resolve, reject) => {
    const urlObj = new URL(url);
    const isHttps = urlObj.protocol === 'https:';
    const httpModule = isHttps ? https : http;
    
    const options = {
      hostname: urlObj.hostname,
      port: urlObj.port || (isHttps ? 443 : 80),
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
    
    const req = httpModule.request(options, (res) => {
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

// Run the test
testMobileAppEndpoints().catch(console.error);