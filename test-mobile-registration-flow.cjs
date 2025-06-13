#!/usr/bin/env node

const http = require('http');

// Test complete mobile app registration and usage flow
async function testMobileRegistrationFlow() {
  console.log('=== Testing Mobile App Registration & Usage Flow ===\n');
  
  const SERVER = 'http://localhost:5000';
  
  // Create a new mobile user
  const newUser = {
    username: 'newmobileuser',
    email: 'newmobile@example.com',
    password: 'mobile123',
    fullName: 'New Mobile User',
    userType: 'client'
  };
  
  try {
    console.log('1. Testing User Registration...');
    console.log(`   Username: ${newUser.username}`);
    console.log(`   Email: ${newUser.email}`);
    console.log(`   Password: ${newUser.password}`);
    
    const regResponse = await makeRequest('POST', `${SERVER}/api/register`, newUser);
    
    if (regResponse.status === 201) {
      console.log('   ✓ Registration successful');
      console.log(`   User ID: ${regResponse.data.id}`);
      
      // Test immediate login with new credentials
      console.log('\n2. Testing Login with New Credentials...');
      const loginResponse = await makeRequest('POST', `${SERVER}/api/login`, {
        username: newUser.username,
        password: newUser.password
      });
      
      if (loginResponse.status === 200) {
        console.log('   ✓ Login successful');
        console.log(`   Logged in as: ${loginResponse.data.fullName}`);
        
        const cookies = loginResponse.cookies;
        
        // Test accessing user profile
        console.log('\n3. Testing User Profile Access...');
        const userResponse = await makeRequest('GET', `${SERVER}/api/user`, null, cookies);
        
        if (userResponse.status === 200) {
          console.log('   ✓ User profile accessible');
          console.log(`   Profile: ${userResponse.data.fullName} (${userResponse.data.userType})`);
        } else {
          console.log('   ✗ Cannot access user profile');
        }
        
        // Test event types loading
        console.log('\n4. Testing Event Types Loading...');
        const eventTypesResponse = await makeRequest('GET', `${SERVER}/api/event-types`, null, cookies);
        
        if (eventTypesResponse.status === 200) {
          console.log(`   ✓ Event types loaded: ${eventTypesResponse.data.length} types available`);
          
          if (eventTypesResponse.data.length > 0) {
            const firstEventType = eventTypesResponse.data[0];
            console.log(`   First event type: ${firstEventType.name}`);
            
            // Test questionnaire loading
            console.log('\n5. Testing Questionnaire Loading...');
            const questionnaireResponse = await makeRequest('GET', 
              `${SERVER}/api/event-types/${firstEventType.id}/questionnaire-items`, 
              null, cookies);
            
            if (questionnaireResponse.status === 200) {
              console.log(`   ✓ Questionnaire loaded: ${questionnaireResponse.data.length} questions`);
              
              // Test event request submission
              console.log('\n6. Testing Event Request Submission...');
              const eventRequest = {
                eventTypeId: firstEventType.id,
                eventDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
                eventTime: '19:00',
                estimatedGuests: 80,
                questionnaireResponses: {
                  [questionnaireResponse.data[0]?.id || '1']: 'Test response from new mobile user'
                },
                notes: 'Event request submitted by newly registered mobile user'
              };
              
              const bookingResponse = await makeRequest('POST', `${SERVER}/api/bookings`, eventRequest, cookies);
              
              if (bookingResponse.status === 201) {
                console.log('   ✓ Event request submitted successfully');
                console.log(`   Booking ID: ${bookingResponse.data.id}`);
                
                // Test viewing user's bookings
                console.log('\n7. Testing User Bookings Access...');
                const bookingsResponse = await makeRequest('GET', `${SERVER}/api/bookings`, null, cookies);
                
                if (bookingsResponse.status === 200) {
                  console.log(`   ✓ User bookings accessible: ${bookingsResponse.data.length} bookings`);
                  
                  console.log('\n=== MOBILE APP FLOW COMPLETE ===');
                  console.log('✓ User registration successful');
                  console.log('✓ Login with credentials working');
                  console.log('✓ Profile access working');
                  console.log('✓ Event types loading');
                  console.log('✓ Dynamic questionnaires working');
                  console.log('✓ Event request submission working');
                  console.log('✓ Booking management working');
                  
                  console.log('\n=== USER CREDENTIALS FOR TESTING ===');
                  console.log(`Username: ${newUser.username}`);
                  console.log(`Password: ${newUser.password}`);
                  console.log('These credentials work for both mobile app and web dashboard login.');
                  
                } else {
                  console.log('   ✗ Cannot access user bookings');
                }
              } else {
                console.log('   ✗ Event request submission failed');
              }
            } else {
              console.log('   ✗ Cannot load questionnaire');
            }
          }
        } else {
          console.log('   ✗ Cannot load event types');
        }
      } else {
        console.log('   ✗ Login failed');
        console.log(`   Error: ${loginResponse.data?.message || 'Unknown login error'}`);
      }
    } else {
      console.log('   ✗ Registration failed');
      console.log(`   Error: ${regResponse.data?.message || 'Unknown registration error'}`);
    }
    
  } catch (error) {
    console.log(`✗ Test failed: ${error.message}`);
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

testMobileRegistrationFlow().catch(console.error);