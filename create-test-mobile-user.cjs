#!/usr/bin/env node

const http = require('http');

// Create a mobile user with known credentials for testing
async function createTestMobileUser() {
  console.log('=== Creating Test Mobile User ===\n');
  
  const SERVER = 'http://localhost:5000';
  
  // Create a mobile user with simple, memorable credentials
  const timestamp = Date.now();
  const mobileUser = {
    username: 'mobileuser',
    email: `mobileuser_${timestamp}@example.com`,
    password: 'mobile123',
    fullName: 'Mobile App User',
    userType: 'client'
  };
  
  try {
    console.log('Creating mobile user with these credentials:');
    console.log(`Username: ${mobileUser.username}`);
    console.log(`Password: ${mobileUser.password}`);
    console.log(`Email: ${mobileUser.email}`);
    console.log(`Full Name: ${mobileUser.fullName}\n`);
    
    // Register the user
    const regResponse = await makeRequest('POST', `${SERVER}/api/register`, mobileUser);
    
    if (regResponse.status === 201) {
      console.log('✓ Mobile user created successfully');
      console.log(`User ID: ${regResponse.data.id}\n`);
      
      // Test login immediately
      console.log('Testing login...');
      const loginResponse = await makeRequest('POST', `${SERVER}/api/login`, {
        username: mobileUser.username,
        password: mobileUser.password
      });
      
      if (loginResponse.status === 200) {
        console.log('✓ Login successful');
        console.log(`Logged in as: ${loginResponse.data.fullName} (${loginResponse.data.username})\n`);
        
        // Get available event types
        console.log('Getting available event types...');
        const eventTypesResponse = await makeRequest('GET', `${SERVER}/api/event-types`, null, loginResponse.cookies);
        
        if (eventTypesResponse.status === 200 && eventTypesResponse.data.length > 0) {
          const eventType = eventTypesResponse.data[0];
          console.log(`Found event type: ${eventType.name} (ID: ${eventType.id})`);
          
          // Get questionnaire for this event type
          console.log('Getting questionnaire items...');
          const questionnaireResponse = await makeRequest('GET', 
            `${SERVER}/api/event-types/${eventType.id}/questionnaire-items`, 
            null, loginResponse.cookies);
          
          if (questionnaireResponse.status === 200) {
            console.log(`Found ${questionnaireResponse.data.length} questionnaire items`);
            
            // Create event request
            console.log('\nCreating event request...');
            const bookingData = {
              eventTypeId: eventType.id,
              eventDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
              eventTime: '18:30',
              estimatedGuests: 100,
              questionnaireResponses: {
                [questionnaireResponse.data[0]?.id || '1']: 'Outdoor venue preferred',
                [questionnaireResponse.data[1]?.id || '2']: 'Yes, catering needed',
                [questionnaireResponse.data[2]?.id || '3']: '5000',
                [questionnaireResponse.data[3]?.id || '4']: 'Need DJ and decorations'
              },
              notes: 'Event request created by mobile test user'
            };
            
            const bookingResponse = await makeRequest('POST', `${SERVER}/api/bookings`, bookingData, loginResponse.cookies);
            
            if (bookingResponse.status === 201) {
              console.log('✓ Event request created successfully');
              console.log(`Booking ID: ${bookingResponse.data.id}`);
              console.log(`Event Type: ${eventType.name}`);
              console.log(`Event Date: ${new Date(bookingResponse.data.eventDate).toLocaleDateString()}`);
              console.log(`Guests: ${bookingResponse.data.estimatedGuests}`);
              
              console.log('\n=== SUCCESS ===');
              console.log('The mobile user workflow is complete:');
              console.log('1. ✓ User registered');
              console.log('2. ✓ User logged in');
              console.log('3. ✓ Event types loaded');
              console.log('4. ✓ Questionnaire loaded');
              console.log('5. ✓ Event request submitted');
              
              console.log('\n=== LOGIN CREDENTIALS FOR WEB DASHBOARD ===');
              console.log(`Username: ${mobileUser.username}`);
              console.log(`Password: ${mobileUser.password}`);
              console.log('\nYou can now use these credentials to login to the web dashboard');
              console.log('and see this user and their event request.');
              
            } else {
              console.log('✗ Failed to create event request:', bookingResponse.data);
            }
          } else {
            console.log('✗ Failed to get questionnaire items');
          }
        } else {
          console.log('✗ No event types available');
        }
      } else {
        console.log('✗ Login failed:', loginResponse.data);
      }
    } else {
      console.log('✗ Registration failed:', regResponse.data);
    }
    
  } catch (error) {
    console.log(`✗ Failed: ${error.message}`);
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

createTestMobileUser().catch(console.error);