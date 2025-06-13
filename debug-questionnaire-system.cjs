#!/usr/bin/env node

const http = require('http');

async function debugQuestionnaireSystem() {
  console.log('=== Testing Custom Questionnaire System ===\n');
  
  const SERVER = 'http://localhost:5000';
  
  try {
    // First, login as admin to check questionnaire management
    console.log('1. Login as admin...');
    const adminLogin = await makeRequest('POST', `${SERVER}/api/login`, {
      username: 'admin',
      password: 'admin123'
    });
    
    if (adminLogin.status !== 200) {
      console.log('   ✗ Admin login failed');
      return;
    }
    
    const adminCookies = adminLogin.cookies;
    console.log('   ✓ Admin logged in');
    
    // Check event types
    console.log('\n2. Fetching event types...');
    const eventTypesRes = await makeRequest('GET', `${SERVER}/api/event-types`, null, adminCookies);
    
    if (eventTypesRes.status === 200 && eventTypesRes.data.length > 0) {
      const firstEventType = eventTypesRes.data[0];
      console.log(`   ✓ Found ${eventTypesRes.data.length} event types`);
      console.log(`   First event type: "${firstEventType.name}" (ID: ${firstEventType.id})`);
      
      // Check existing questionnaire items for this event type
      console.log('\n3. Checking existing questionnaire items...');
      const questionnaireRes = await makeRequest('GET', 
        `${SERVER}/api/event-types/${firstEventType.id}/questionnaire-items`, 
        null, adminCookies);
      
      if (questionnaireRes.status === 200) {
        console.log(`   ✓ Questionnaire endpoint working`);
        console.log(`   Found ${questionnaireRes.data.length} custom questions for "${firstEventType.name}"`);
        
        if (questionnaireRes.data.length === 0) {
          console.log('   ⚠ No custom questions found - creating sample questionnaire...');
          
          // Create custom questions for this event type
          const sampleQuestions = [
            {
              eventTypeId: firstEventType.id,
              questionText: 'What is your preferred venue type?',
              questionType: 'select',
              options: ['Indoor', 'Outdoor', 'Beach', 'Garden'],
              required: true,
              displayOrder: 1
            },
            {
              eventTypeId: firstEventType.id,
              questionText: 'Do you need catering services?',
              questionType: 'boolean',
              options: ['Yes', 'No'],
              required: true,
              displayOrder: 2
            },
            {
              eventTypeId: firstEventType.id,
              questionText: 'What is your estimated budget?',
              questionType: 'number',
              options: null,
              required: false,
              displayOrder: 3
            }
          ];
          
          for (const question of sampleQuestions) {
            const createRes = await makeRequest('POST', `${SERVER}/api/questionnaire-items`, question, adminCookies);
            if (createRes.status === 201) {
              console.log(`   ✓ Created: "${question.questionText}"`);
            } else {
              console.log(`   ✗ Failed to create: "${question.questionText}"`);
            }
          }
          
          // Re-fetch questionnaire items after creation
          const updatedQuestionnaireRes = await makeRequest('GET', 
            `${SERVER}/api/event-types/${firstEventType.id}/questionnaire-items`, 
            null, adminCookies);
          
          if (updatedQuestionnaireRes.status === 200) {
            console.log(`   ✓ Updated questionnaire has ${updatedQuestionnaireRes.data.length} questions`);
          }
        } else {
          console.log('   Custom questions found:');
          questionnaireRes.data.forEach((q, i) => {
            console.log(`   ${i+1}. ${q.questionText} (${q.questionType})`);
          });
        }
        
        // Now test as mobile user
        console.log('\n4. Testing mobile user flow...');
        const mobileLogin = await makeRequest('POST', `${SERVER}/api/login`, {
          username: 'newmobileuser',
          password: 'mobile123'
        });
        
        if (mobileLogin.status === 200) {
          const mobileCookies = mobileLogin.cookies;
          console.log('   ✓ Mobile user logged in');
          
          // Test questionnaire loading from mobile perspective
          const mobileQuestionnaireRes = await makeRequest('GET', 
            `${SERVER}/api/event-types/${firstEventType.id}/questionnaire-items`, 
            null, mobileCookies);
          
          if (mobileQuestionnaireRes.status === 200) {
            console.log(`   ✓ Mobile app can load questionnaire: ${mobileQuestionnaireRes.data.length} questions`);
            
            if (mobileQuestionnaireRes.data.length > 0) {
              // Test event submission with proper questionnaire responses
              console.log('\n5. Testing event submission with questionnaire...');
              
              const questionnaireResponses = {};
              mobileQuestionnaireRes.data.forEach(q => {
                if (q.questionType === 'select') {
                  questionnaireResponses[q.id] = q.options ? q.options[0] : 'Indoor';
                } else if (q.questionType === 'boolean') {
                  questionnaireResponses[q.id] = 'Yes';
                } else if (q.questionType === 'number') {
                  questionnaireResponses[q.id] = '5000';
                } else {
                  questionnaireResponses[q.id] = 'Test response';
                }
              });
              
              const eventRequest = {
                eventTypeId: firstEventType.id,
                eventDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
                eventTime: '19:00',
                estimatedGuests: 80,
                questionnaireResponses: questionnaireResponses,
                notes: 'Test event with custom questionnaire responses'
              };
              
              console.log('   Questionnaire responses:', Object.keys(questionnaireResponses).length);
              
              const submitRes = await makeRequest('POST', `${SERVER}/api/bookings`, eventRequest, mobileCookies);
              
              if (submitRes.status === 201) {
                console.log('   ✓ Event submission successful with custom questionnaire!');
                console.log(`   Booking ID: ${submitRes.data.id}`);
              } else {
                console.log('   ✗ Event submission failed');
                console.log(`   Error: ${JSON.stringify(submitRes.data)}`);
              }
            } else {
              console.log('   ✗ No questions available for event submission test');
            }
          } else {
            console.log('   ✗ Mobile app cannot load questionnaire');
          }
        } else {
          console.log('   ✗ Mobile user login failed');
        }
      } else {
        console.log('   ✗ Cannot load questionnaire items');
      }
    } else {
      console.log('   ✗ No event types found');
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

debugQuestionnaireSystem().catch(console.error);