import { db } from './server/db';
import { messages } from './shared/schema';

// Create sample messages
async function createTestMessages() {
  try {
    console.log('Creating test messages...');
    
    // Admin (ID 7) to Client (ID 3) messages
    const adminToClientMessages = [
      {
        senderId: 7,
        receiverId: 3,
        content: 'Hello, how can I help you with your event planning?',
        read: true,
        createdAt: new Date(Date.now() - 86400000 * 2) // 2 days ago
      },
      {
        senderId: 3,
        receiverId: 7,
        content: 'I need help with planning my wedding',
        read: true,
        createdAt: new Date(Date.now() - 86400000 * 2 + 3600000) // 2 days ago + 1 hour
      },
      {
        senderId: 7,
        receiverId: 3,
        content: 'Sure, we have several packages available. When is your wedding date?',
        read: true,
        createdAt: new Date(Date.now() - 86400000 * 2 + 7200000) // 2 days ago + 2 hours
      },
      {
        senderId: 3,
        receiverId: 7,
        content: 'We are planning for November 15th next year',
        read: true,
        createdAt: new Date(Date.now() - 86400000) // 1 day ago
      },
      {
        senderId: 7,
        receiverId: 3,
        content: 'Perfect! I will prepare some options for you',
        read: false,
        createdAt: new Date(Date.now() - 43200000) // 12 hours ago
      }
    ];
    
    // Admin (ID 7) to Vendor (ID 4) messages
    const adminToVendorMessages = [
      {
        senderId: 7,
        receiverId: 4,
        content: 'We have a new client looking for event planning services',
        read: true,
        createdAt: new Date(Date.now() - 86400000 * 3) // 3 days ago
      },
      {
        senderId: 4,
        receiverId: 7,
        content: 'Great! What kind of event?',
        read: true,
        createdAt: new Date(Date.now() - 86400000 * 3 + 3600000) // 3 days ago + 1 hour
      },
      {
        senderId: 7,
        receiverId: 4,
        content: 'A wedding for about 200 guests',
        read: true,
        createdAt: new Date(Date.now() - 86400000 * 3 + 7200000) // 3 days ago + 2 hours
      },
      {
        senderId: 4,
        receiverId: 7,
        content: 'We can handle that. Do they have a specific theme in mind?',
        read: true,
        createdAt: new Date(Date.now() - 86400000 * 2) // 2 days ago
      },
      {
        senderId: 7,
        receiverId: 4,
        content: 'They mentioned a beach theme',
        read: false,
        createdAt: new Date(Date.now() - 3600000) // 1 hour ago
      }
    ];
    
    // Insert all messages
    const insertedMessages = await db.insert(messages).values([
      ...adminToClientMessages,
      ...adminToVendorMessages
    ]).returning();
    
    console.log(`Created ${insertedMessages.length} test messages`);
    console.log('Test data creation complete!');
    
  } catch (error) {
    console.error('Error creating test messages:', error);
  } finally {
    process.exit(0);
  }
}

createTestMessages();