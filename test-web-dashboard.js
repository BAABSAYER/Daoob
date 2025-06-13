import fetch from 'node-fetch';

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

// Test web dashboard functionality
async function testWebDashboard(cookies) {
  console.log('\n--- Testing Web Dashboard Functionality ---');
  
  // 1. Test admin users API
  console.log('\n1. Testing admin users API...');
  const usersResponse = await fetch(`${API_BASE}/api/admin/users`, {
    headers: { 'Cookie': cookies }
  });
  
  if (usersResponse.ok) {
    const users = await usersResponse.json();
    console.log(`Users found: ${users.length}`);
    users.slice(0, 3).forEach(user => {
      console.log(`  - ${user.username} (${user.userType}) - ${user.email}`);
    });
  } else {
    console.log('Failed to fetch users:', await usersResponse.text());
  }
  
  // 2. Test admin bookings API
  console.log('\n2. Testing admin bookings API...');
  const bookingsResponse = await fetch(`${API_BASE}/api/admin/bookings`, {
    headers: { 'Cookie': cookies }
  });
  
  if (bookingsResponse.ok) {
    const bookings = await bookingsResponse.json();
    console.log(`Bookings found: ${bookings.length}`);
    bookings.slice(0, 3).forEach(booking => {
      console.log(`  - ID ${booking.id}: ${booking.clientName || 'Unknown'} - ${booking.status} - ${booking.eventDate ? booking.eventDate.substring(0, 10) : 'No date'}`);
      if (booking.questionnaireResponses) {
        console.log(`    Questionnaire: ${Object.keys(booking.questionnaireResponses).length} responses`);
      }
    });
  } else {
    console.log('Failed to fetch bookings:', await bookingsResponse.text());
  }
  
  // 3. Test event types management
  console.log('\n3. Testing event types management...');
  const eventTypesResponse = await fetch(`${API_BASE}/api/event-types`, {
    headers: { 'Cookie': cookies }
  });
  
  if (eventTypesResponse.ok) {
    const eventTypes = await eventTypesResponse.json();
    console.log(`Event types available: ${eventTypes.length}`);
    eventTypes.slice(0, 5).forEach(et => {
      console.log(`  - ${et.name} (ID: ${et.id}) - ${et.isActive ? 'Active' : 'Inactive'}`);
    });
    
    // Test questionnaire items for first event type
    if (eventTypes.length > 0) {
      const firstEventType = eventTypes[0];
      console.log(`\n4. Testing questionnaire management for ${firstEventType.name}...`);
      
      const questionsResponse = await fetch(`${API_BASE}/api/event-types/${firstEventType.id}/questions`, {
        headers: { 'Cookie': cookies }
      });
      
      if (questionsResponse.ok) {
        const questions = await questionsResponse.json();
        console.log(`Questions for ${firstEventType.name}: ${questions.length}`);
        questions.slice(0, 3).forEach(q => {
          console.log(`  - ${q.questionText} (${q.questionType}) - ${q.isRequired ? 'Required' : 'Optional'}`);
        });
      } else {
        console.log('Failed to fetch questions:', await questionsResponse.text());
      }
    }
  } else {
    console.log('Failed to fetch event types:', await eventTypesResponse.text());
  }
  
  // 5. Test booking update functionality
  console.log('\n5. Testing booking update functionality...');
  const allBookingsResponse = await fetch(`${API_BASE}/api/admin/bookings`, {
    headers: { 'Cookie': cookies }
  });
  
  if (allBookingsResponse.ok) {
    const allBookings = await allBookingsResponse.json();
    if (allBookings.length > 0) {
      const testBooking = allBookings[allBookings.length - 1]; // Get the latest booking
      console.log(`Testing update for booking ID ${testBooking.id}...`);
      
      const updateData = {
        status: 'quoted',
        quotationNotes: 'Test quotation from web dashboard',
        totalPrice: 1500
      };
      
      const updateResponse = await fetch(`${API_BASE}/api/admin/bookings/${testBooking.id}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'Cookie': cookies
        },
        body: JSON.stringify(updateData)
      });
      
      if (updateResponse.ok) {
        const updatedBooking = await updateResponse.json();
        console.log(`Booking updated successfully: ${updatedBooking.status} - $${updatedBooking.totalPrice}`);
      } else {
        console.log('Failed to update booking:', await updateResponse.text());
      }
    } else {
      console.log('No bookings available to test update functionality');
    }
  }
  
  // 6. Test messaging functionality
  console.log('\n6. Testing messaging functionality...');
  const messagesResponse = await fetch(`${API_BASE}/api/messages`, {
    headers: { 'Cookie': cookies }
  });
  
  if (messagesResponse.ok) {
    const messages = await messagesResponse.json();
    console.log(`Messages found: ${messages.length}`);
    messages.slice(0, 3).forEach(msg => {
      console.log(`  - From User ${msg.senderId} to User ${msg.receiverId}: ${msg.content.substring(0, 50)}...`);
    });
  } else {
    console.log('Failed to fetch messages:', await messagesResponse.text());
  }
  
  console.log('\n--- Web Dashboard Tests Completed ---');
}

// Main test function
async function runWebTests() {
  try {
    console.log('Starting web dashboard functionality tests...\n');
    
    const cookies = await loginAdmin();
    await testWebDashboard(cookies);
    
    console.log('\n--- All Web Tests Completed Successfully ---');
  } catch (error) {
    console.error('Web test failed:', error);
  }
}

runWebTests();