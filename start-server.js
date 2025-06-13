#!/usr/bin/env node

const { spawn } = require('child_process');

// Set environment variables
process.env.PORT = '3001';
process.env.NODE_ENV = 'development';

console.log('Starting DAOOB server on port 3001...');

// Start the server
const server = spawn('tsx', ['server/index.ts'], {
  stdio: 'inherit',
  env: process.env
});

server.on('error', (err) => {
  console.error('Failed to start server:', err);
});

server.on('close', (code) => {
  console.log(`Server process exited with code ${code}`);
});

// Handle graceful shutdown
process.on('SIGINT', () => {
  console.log('Shutting down server...');
  server.kill('SIGINT');
});

process.on('SIGTERM', () => {
  console.log('Shutting down server...');
  server.kill('SIGTERM');
});