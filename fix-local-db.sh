#!/bin/bash
# Script to fix database connection to use local PostgreSQL

echo "🔧 Setting up local PostgreSQL connection..."

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

# Create a local db.ts file that uses pg instead of neon
echo "Creating local database connection file..."
cat > server/db.ts << EOF
import { Pool } from 'pg';
import { drizzle } from 'drizzle-orm/node-postgres';
import * as schema from "@shared/schema";
import * as dotenv from 'dotenv';
import { resolve } from 'path';

// Load environment variables from .env file
dotenv.config({ path: resolve(process.cwd(), '.env') });

console.log("Database URL:", process.env.DATABASE_URL ? "Set (not showing for security)" : "Not set");

if (!process.env.DATABASE_URL) {
  throw new Error(
    "DATABASE_URL must be set. Did you forget to provision a database?",
  );
}

export const pool = new Pool({ 
  connectionString: process.env.DATABASE_URL 
});

// Initialize Drizzle with the PostgreSQL pool
export const db = drizzle(pool, { schema });
EOF
echo "✅ server/db.ts updated for local PostgreSQL"

# Fix create-demo-data.ts to remove web socket references
echo "Updating create-demo-data.ts..."
sed -i.bak '1i\
// Load environment variables first\
import * as dotenv from "dotenv";\
import { resolve } from "path";\
dotenv.config({ path: resolve(process.cwd(), ".env") });\
' create-demo-data.ts
rm -f create-demo-data.ts.bak
echo "✅ create-demo-data.ts updated"

# Fix create-event-types.ts to remove web socket references
echo "Updating create-event-types.ts..."
sed -i.bak '1i\
// Load environment variables first\
import * as dotenv from "dotenv";\
import { resolve } from "path";\
dotenv.config({ path: resolve(process.cwd(), ".env") });\
' create-event-types.ts
rm -f create-event-types.ts.bak
echo "✅ create-event-types.ts updated"

# Create local-server-index.ts as an override to server/index.ts
echo "Creating local server index file to avoid WebSockets initialization..."
mkdir -p local-config
cat > local-config/local-index.ts << EOF
import express, { Request, Response, NextFunction } from "express";
import { registerRoutes } from "../server/routes";
import { setupVite, serveStatic, log } from "../server/vite";
import * as dotenv from 'dotenv';
import { resolve } from 'path';

// Load environment variables
dotenv.config({ path: resolve(process.cwd(), '.env') });

// Initialize Express
const app = express();
app.use(express.json());

// Register all API routes
const httpServer = registerRoutes(app);

// Setup Vite for development or serve static files for production
if (process.env.NODE_ENV === "development") {
  setupVite(app, httpServer).catch(console.error);
} else {
  serveStatic(app);
}

// Error handling
app.use((err: any, _req: Request, res: Response, _next: NextFunction) => {
  console.error(err);
  res.status(500).send("Internal Server Error");
});

// Start the server
const port = process.env.PORT || 5000;
httpServer.listen(port, () => {
  log(\`serving on port \${port}\`);
});
EOF
echo "✅ Local server index file created"

# Create a script to start the local server
echo "Creating script to start the local server..."
cat > start-local-server.sh << EOF
#!/bin/bash
echo "🚀 Starting DAOOB local server..."
echo "Make sure your database is set up correctly in .env"

# Start the server with local configuration
NODE_ENV=development npx tsx local-config/local-index.ts
EOF
chmod +x start-local-server.sh
echo "✅ start-local-server.sh created"

# Install required dependencies
echo "Installing required dependencies..."
npm install pg dotenv
echo "✅ PostgreSQL packages installed"

echo ""
echo "🎉 All files updated successfully!"
echo ""
echo "Next steps:"
echo "1. Make sure you have PostgreSQL running locally"
echo "2. Make sure the 'daoob' database exists (run 'createdb daoob' if needed)"
echo "3. Run \`npm run db:push\` to set up database tables"
echo "4. Run \`npx tsx create-demo-data.ts\` to create demo users"
echo "5. Run \`npx tsx create-event-types.ts\` to create event types"
echo "6. Run \`./start-local-server.sh\` to start the local server"