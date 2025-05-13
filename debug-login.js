// Debug login script to generate and save a working cookie
import { writeFileSync } from 'fs';
import fetch from 'node-fetch';

async function debugLogin() {
  try {
    console.log('Attempting login...');
    const loginRes = await fetch('http://localhost:5000/api/login', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        username: 'admin',
        password: 'password'
      }),
      redirect: 'manual'
    });
    
    console.log('Login status:', loginRes.status);
    
    const cookies = loginRes.headers.raw()['set-cookie'];
    if (cookies) {
      console.log('Cookies received:', cookies);
      writeFileSync('admin_cookies.txt', cookies.join('\n'));
      console.log('Cookies saved to admin_cookies.txt');
      
      // Now try to verify authentication using the cookies
      const authRes = await fetch('http://localhost:5000/api/auth-status', {
        headers: {
          'Cookie': cookies.join('; ')
        }
      });
      
      const authText = await authRes.text();
      console.log('Auth Response:', authText);
      
      try {
        const authStatus = JSON.parse(authText);
        console.log('Auth Status:', JSON.stringify(authStatus, null, 2));
      } catch (error) {
        console.log('Error parsing auth response as JSON:', error.message);
      }
      
      // Try to access event requests with the cookie
      const eventsRes = await fetch('http://localhost:5000/api/event-requests', {
        headers: {
          'Cookie': cookies.join('; ')
        }
      });
      
      console.log('Event requests status:', eventsRes.status);
      const eventsText = await eventsRes.text();
      console.log('Event requests raw response:', eventsText);
      
      try {
        if (eventsText.trim()) {
          const events = JSON.parse(eventsText);
          console.log('Successfully retrieved events:', JSON.stringify(events, null, 2));
        } else {
          console.log('Empty response from event requests');
        }
      } catch (error) {
        console.log('Error parsing events response as JSON:', error.message);
      }
    } else {
      console.log('No cookies received from login');
    }
  } catch (error) {
    console.error('Error:', error);
  }
}

debugLogin();