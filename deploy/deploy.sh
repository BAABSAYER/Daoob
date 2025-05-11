#!/bin/bash

# Daoob Deployment Script for Alibaba Cloud

# Load environment variables
if [ -f .env ]; then
  source .env
else
  echo "❌ .env file not found"
  exit 1
fi

# Check for DATABASE_URL
if [ -z "$DATABASE_URL" ]; then
  echo "❌ DATABASE_URL is not set in .env file"
  exit 1
fi

# Build the application
echo "🔨 Building application..."
npm run build

# Run database migrations
echo "🗄️ Running database migrations..."
node deploy/migrate-db.js

# Install PM2 if not already installed
if ! command -v pm2 &> /dev/null; then
  echo "📦 Installing PM2..."
  npm install -g pm2
fi

# Deploy with PM2
echo "🚀 Deploying application..."
pm2 start deploy/ecosystem.config.js
pm2 save

echo "✅ Deployment completed"
echo ""
echo "To monitor the application, run: pm2 monit"
echo "To view logs, run: pm2 logs daoob-api"