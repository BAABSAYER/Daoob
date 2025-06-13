#!/usr/bin/env node

const http = require('http');

// Test booking creation with detailed logging
async function debugBookingCreation() {
  console.log('=== Debug Booking Creation ===\n');
  
  const PROD_SERVER = 'http://178.62.41.245';
  
  try {
    // Login first
    console.log('1. Logging in...');
    const loginResponse = await makeRequest('POST', `${PROD_SERVER}/api/login`, {
      username: 'admin',
      password: 'admin123'
    });
    
    if (loginResponse.status !== 200) {
      console.log('Login failed:', loginResponse.data);
      return;
    }
    
    console.log('Login successful');
    
    // Get event types
    const eventTypesResponse = await makeRequest('GET', `${PROD_SERVER}/api/event-types`, null, loginResponse.cookies);
    if (eventTypesResponse.status !== 200 || !eventTypesResponse.data?.length) {
      console.log('No event types available');
      return;
    }
    
    const eventType = eventTypesResponse.data[0];
    console.log(`Using event type: ${eventType.name} (ID: ${eventType.id})`);
    
    // Test different booking data formats
    const testCases = [
      {
        name: 'Basic booking data',
        data: {
          eventTypeId: eventType.id,
          eventDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
          eventTime: '18:00',
          estimatedGuests: 50
        }
      },
      {
        name: 'Booking with questionnaire responses',
        data: {
          eventTypeId: eventType.id,
          eventDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
          eventTime: '18:00',
          estimatedGuests: 50,
          questionnaireResponses: { "1": "test response" },
          notes: 'Test booking'
        }
      },
      {
        name: 'Booking with all optional fields',
        data: {
          eventTypeId: eventType.id,
          eventDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
          eventTime: '18:00',
          estimatedGuests: 50,
          guestCount: 50,
          totalPrice: 0,
          specialRequests: '',
          questionnaireResponses: {},
          notes: ''
        }
      }
    ];
    
    for (const testCase of testCases) {
      console.log(`\n2. Testing: ${testCase.name}`);
      console.log('Request data:', JSON.stringify(testCase.data, null, 2));
      
      const bookingResponse = await makeRequest('POST', `${PROD_SERVER}/api/bookings`, testCase.data, loginResponse.cookies);
      
      console.log(`Response status: ${bookingResponse.status}`);
      if (bookingResponse.status === 201) {
        console.log('✓ Booking created successfully');
        console.log('Booking ID:', bookingResponse.data.id);
        break; // Success, no need to test more
      } else {
        console.log('✗ Booking creation failed');
        console.log('Error:', JSON.stringify(bookingResponse.data, null, 2));
      }
    }
    
  } catch (error) {
    console.log('Debug failed:', error.message);
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

debugBookingCreation().catch(console.error);