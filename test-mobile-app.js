const fetch = require('node-fetch');

const API_BASE = 'http://localhost:5000';

// Login and get cookies
async function loginAdmin() {
  const response = await fetch(`${API_BASE}/api/login`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      username: 'admin',
      password: 'admin123'
    })
  });
  
  const cookies = response.headers.get('set-cookie');
  const user = await response.json();
  console.log('Logged in as:', user.username);
  return cookies;
}

// Create test event types
async function createTestEventTypes(cookies) {
  const eventTypes = [
    {
      name: 'Wedding',
      description: 'Wedding celebrations and ceremonies',
      isActive: true
    },
    {
      name: 'Corporate',
      description: 'Corporate events and business functions',
      isActive: true
    },
    {
      name: 'Birthday',
      description: 'Birthday parties and celebrations',
      isActive: true
    }
  ];
  
  const createdEventTypes = [];
  
  for (const eventType of eventTypes) {
    try {
      const response = await fetch(`${API_BASE}/api/admin/event-types`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Cookie': cookies
        },
        body: JSON.stringify(eventType)
      });
      
      if (response.ok) {
        const created = await response.json();
        console.log('Created event type:', created.name);
        createdEventTypes.push(created);
      } else {
        console.log('Failed to create event type:', eventType.name, await response.text());
      }
    } catch (error) {
      console.error('Error creating event type:', error);
    }
  }
  
  return createdEventTypes;
}

// Create test questionnaire items
async function createTestQuestions(cookies, eventTypeId) {
  const questions = [
    {
      eventTypeId: eventTypeId,
      questionText: 'What is your preferred venue type?',
      questionType: 'select',
      options: ['Indoor', 'Outdoor', 'Beach', 'Garden'],
      isRequired: true,
      orderIndex: 1
    },
    {
      eventTypeId: eventTypeId,
      questionText: 'Do you need catering services?',
      questionType: 'boolean',
      isRequired: true,
      orderIndex: 2
    },
    {
      eventTypeId: eventTypeId,
      questionText: 'What is your estimated budget?',
      questionType: 'number',
      isRequired: false,
      orderIndex: 3
    },
    {
      eventTypeId: eventTypeId,
      questionText: 'Any special requirements?',
      questionType: 'text',
      isRequired: false,
      orderIndex: 4
    }
  ];
  
  for (const question of questions) {
    try {
      const response = await fetch(`${API_BASE}/api/admin/event-types/${eventTypeId}/questions`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Cookie': cookies
        },
        body: JSON.stringify(question)
      });
      
      if (response.ok) {
        const created = await response.json();
        console.log('Created question:', created.questionText);
      } else {
        console.log('Failed to create question:', await response.text());
      }
    } catch (error) {
      console.error('Error creating question:', error);
    }
  }
}

// Test mobile app functionality
async function testMobileAppFlow(cookies) {
  console.log('\n--- Testing Mobile App Flow ---');
  
  // 1. Test event types endpoint
  console.log('\n1. Testing event types API...');
  const eventTypesResponse = await fetch(`${API_BASE}/api/event-types`, {
    headers: { 'Cookie': cookies }
  });
  
  if (eventTypesResponse.ok) {
    const eventTypes = await eventTypesResponse.json();
    console.log('Event types available:', eventTypes.length);
    eventTypes.forEach(et => console.log(`  - ${et.name} (ID: ${et.id})`));
    
    if (eventTypes.length > 0) {
      const firstEventType = eventTypes[0];
      
      // 2. Test questionnaire items endpoint
      console.log(`\n2. Testing questionnaire for ${firstEventType.name}...`);
      const questionsResponse = await fetch(`${API_BASE}/api/event-types/${firstEventType.id}/questions`, {
        headers: { 'Cookie': cookies }
      });
      
      if (questionsResponse.ok) {
        const questions = await questionsResponse.json();
        console.log('Questions available:', questions.length);
        questions.forEach(q => console.log(`  - ${q.questionText} (${q.questionType})`));
        
        // 3. Test booking submission
        console.log('\n3. Testing booking submission...');
        const bookingData = {
          clientId: 7, // Admin user ID for testing
          eventDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(), // 30 days from now
          eventTime: '18:00',
          estimatedGuests: 100,
          status: 'pending',
          eventTypeId: firstEventType.id,
          questionnaireResponses: {
            [questions[0]?.id || '1']: 'Indoor',
            [questions[1]?.id || '2']: true,
            [questions[2]?.id || '3']: 5000,
            [questions[3]?.id || '4']: 'Test booking from mobile app'
          },
          notes: 'Test booking created via mobile app simulation'
        };
        
        const bookingResponse = await fetch(`${API_BASE}/api/bookings`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies
          },
          body: JSON.stringify(bookingData)
        });
        
        if (bookingResponse.ok) {
          const booking = await bookingResponse.json();
          console.log('Booking created successfully:', booking.id);
          console.log('Event date:', booking.eventDate);
          console.log('Questionnaire responses:', JSON.stringify(booking.questionnaireResponses, null, 2));
        } else {
          console.log('Failed to create booking:', await bookingResponse.text());
        }
      } else {
        console.log('Failed to fetch questions:', await questionsResponse.text());
      }
    }
  } else {
    console.log('Failed to fetch event types:', await eventTypesResponse.text());
  }
}

// Main test function
async function runTests() {
  try {
    console.log('Starting mobile app functionality tests...\n');
    
    const cookies = await loginAdmin();
    const eventTypes = await createTestEventTypes(cookies);
    
    // Create questions for each event type
    for (const eventType of eventTypes) {
      await createTestQuestions(cookies, eventType.id);
    }
    
    await testMobileAppFlow(cookies);
    
    console.log('\n--- Tests Completed ---');
  } catch (error) {
    console.error('Test failed:', error);
  }
}

runTests();