-- Initialize database with required tables and data
-- This file runs when PostgreSQL container starts for the first time

-- Ensure proper permissions
GRANT ALL PRIVILEGES ON DATABASE daoob_production TO daoob_user;
GRANT ALL ON SCHEMA public TO daoob_user;

-- Create session table (required for session storage)
CREATE TABLE IF NOT EXISTS "sessions" (
  "sid" varchar NOT NULL COLLATE "default",
  "sess" json NOT NULL,
  "expire" timestamp(6) NOT NULL
)
WITH (OIDS=FALSE);

ALTER TABLE "sessions" ADD CONSTRAINT "session_pkey" PRIMARY KEY ("sid") NOT DEFERRABLE INITIALLY IMMEDIATE;
CREATE INDEX "IDX_session_expire" ON "sessions" ("expire");

-- Grant permissions on session table
GRANT ALL PRIVILEGES ON TABLE sessions TO daoob_user;