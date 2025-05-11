import { db, pool } from './server/db';
import {
  eventTypes,
  questionnaireItems,
  eventRequests,
  quotations
} from './shared/schema';

async function main() {
  console.log('Creating new event management tables...');
  
  // Create event_types table
  await db.execute(`
    CREATE TABLE IF NOT EXISTS event_types (
      id SERIAL PRIMARY KEY,
      name TEXT NOT NULL,
      description TEXT,
      icon TEXT,
      is_active BOOLEAN DEFAULT TRUE,
      created_by INTEGER REFERENCES users(id),
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  `);
  console.log('✅ Created event_types table');
  
  // Create questionnaire_items table
  await db.execute(`
    CREATE TABLE IF NOT EXISTS questionnaire_items (
      id SERIAL PRIMARY KEY,
      event_type_id INTEGER NOT NULL REFERENCES event_types(id),
      question_text TEXT NOT NULL,
      question_type TEXT NOT NULL,
      options JSONB,
      required BOOLEAN DEFAULT FALSE,
      display_order INTEGER,
      created_by INTEGER REFERENCES users(id),
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  `);
  console.log('✅ Created questionnaire_items table');
  
  // Create event_requests table
  await db.execute(`
    CREATE TABLE IF NOT EXISTS event_requests (
      id SERIAL PRIMARY KEY,
      client_id INTEGER NOT NULL REFERENCES users(id),
      event_type_id INTEGER NOT NULL REFERENCES event_types(id),
      status TEXT NOT NULL DEFAULT 'pending',
      responses JSONB NOT NULL,
      event_date TIMESTAMP,
      budget DOUBLE PRECISION,
      special_requests TEXT,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  `);
  console.log('✅ Created event_requests table');
  
  // Create quotations table
  await db.execute(`
    CREATE TABLE IF NOT EXISTS quotations (
      id SERIAL PRIMARY KEY,
      event_request_id INTEGER NOT NULL REFERENCES event_requests(id),
      admin_id INTEGER NOT NULL REFERENCES users(id),
      total_price DOUBLE PRECISION NOT NULL,
      details JSONB NOT NULL,
      notes TEXT,
      expiry_date TIMESTAMP,
      status TEXT NOT NULL DEFAULT 'quotation_sent',
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  `);
  console.log('✅ Created quotations table');
  
  // Insert default event types
  const weddingExists = await db.query.eventTypes.findFirst({
    where: (et, { eq }) => eq(et.name, 'Wedding')
  });
  
  if (!weddingExists) {
    await db.insert(eventTypes).values([
      {
        name: 'Wedding',
        description: 'Plan your perfect wedding day with customized services',
        icon: '💍',
        isActive: true,
        createdAt: new Date(),
        updatedAt: new Date()
      },
      {
        name: 'Corporate Event',
        description: 'Professional event planning for business gatherings',
        icon: '🏢',
        isActive: true,
        createdAt: new Date(),
        updatedAt: new Date()
      },
      {
        name: 'Birthday Party',
        description: 'Create a memorable birthday celebration',
        icon: '🎂',
        isActive: true,
        createdAt: new Date(),
        updatedAt: new Date()
      },
      {
        name: 'Graduation',
        description: 'Celebrate academic achievements',
        icon: '🎓',
        isActive: true,
        createdAt: new Date(),
        updatedAt: new Date()
      }
    ]);
    console.log('✅ Added default event types');
  } else {
    console.log('ℹ️ Default event types already exist');
  }
  
  console.log('Migration completed successfully!');
}

main()
  .catch(e => {
    console.error('Migration failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    // Close pool connection instead of db.end()
    await pool.end();
    process.exit(0);
  });