#!/bin/bash
# Script to fix dotenv configuration in all necessary files

echo "🔧 Fixing dotenv configuration..."

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
  echo "Creating .env file..."
  cat > .env << EOF
DATABASE_URL=postgresql://dell:@localhost:5432/daoob
SESSION_SECRET=super_secret_session_key_please_change_in_production
EOF
  echo "✅ .env file created"
else
  echo "ℹ️ .env file already exists"
fi

# Fix server/db.ts
echo "Updating server/db.ts..."
cat > server/db.ts << EOF
import { Pool, neonConfig } from '@neondatabase/serverless';
import { drizzle } from 'drizzle-orm/neon-serverless';
import ws from "ws";
import * as schema from "@shared/schema";
import * as dotenv from 'dotenv';
import { resolve } from 'path';

// Load environment variables from .env file
dotenv.config({ path: resolve(process.cwd(), '.env') });

neonConfig.webSocketConstructor = ws;

console.log("Database URL:", process.env.DATABASE_URL ? "Set (not showing for security)" : "Not set");

if (!process.env.DATABASE_URL) {
  throw new Error(
    "DATABASE_URL must be set. Did you forget to provision a database?",
  );
}

export const pool = new Pool({ connectionString: process.env.DATABASE_URL });
export const db = drizzle({ client: pool, schema });
EOF
echo "✅ server/db.ts updated"

# Fix create-demo-data.ts
echo "Updating create-demo-data.ts..."
sed -i.bak '1i\
// Load environment variables first\
import * as dotenv from "dotenv";\
import { resolve } from "path";\
dotenv.config({ path: resolve(process.cwd(), ".env") });\
' create-demo-data.ts
rm create-demo-data.ts.bak
echo "✅ create-demo-data.ts updated"

# Fix create-event-types.ts
echo "Updating create-event-types.ts..."
sed -i.bak '1i\
// Load environment variables first\
import * as dotenv from "dotenv";\
import { resolve } from "path";\
dotenv.config({ path: resolve(process.cwd(), ".env") });\
' create-event-types.ts
rm create-event-types.ts.bak
echo "✅ create-event-types.ts updated"

# Create simple start script
echo "Creating start script..."
cat > start-local.sh << EOF
#!/bin/bash
echo "🚀 Starting DAOOB local server..."
echo "Make sure your database is set up correctly in .env"

# Start the server
npm run dev
EOF
chmod +x start-local.sh
echo "✅ start-local.sh created"

echo "🎉 All files updated successfully!"
echo ""
echo "Next steps:"
echo "1. Run \`npm install\` to install dependencies"
echo "2. Run \`npm run db:push\` to set up database tables"
echo "3. Run \`npx tsx create-demo-data.ts\` to create demo users"
echo "4. Run \`npx tsx create-event-types.ts\` to create event types"
echo "5. Run \`./start-local.sh\` to start the server"