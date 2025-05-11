require('dotenv').config();
const { execSync } = require('child_process');

console.log('🗄️ Running database migrations...');

// Check for DATABASE_URL
if (!process.env.DATABASE_URL) {
  console.error('❌ ERROR: DATABASE_URL environment variable not set');
  process.exit(1);
}

try {
  // Run drizzle migration
  console.log('Running schema push...');
  execSync('npm run db:push', { stdio: 'inherit' });
  
  // Run seed scripts if requested
  if (process.argv.includes('--seed')) {
    console.log('Seeding database...');
    execSync('npx tsx create-admin-user.ts', { stdio: 'inherit' });
    execSync('npx tsx create-event-types.ts', { stdio: 'inherit' });
  }
  
  console.log('✅ Database migration completed');
} catch (error) {
  console.error(`❌ Migration failed: ${error.message}`);
  process.exit(1);
}