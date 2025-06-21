#!/usr/bin/env node
import { spawn } from 'child_process';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Start the MCP server
const serverPath = join(__dirname, '..', 'dist', 'index.js');
const server = spawn('node', [serverPath], {
  env: {
    ...process.env,
    PERPLEXITY_API_KEY: process.env.PERPLEXITY_API_KEY || 'demo-key',
    DEBUG: 'true',
  },
  stdio: ['pipe', 'pipe', 'inherit'],
});

// Send a tools/list request
const listToolsRequest = {
  jsonrpc: '2.0',
  method: 'tools/list',
  id: 1,
};

// Send a tool call request
const searchRequest = {
  jsonrpc: '2.0',
  method: 'tools/call',
  params: {
    name: 'perplexity_search_web',
    arguments: {
      query: 'What is Model Context Protocol MCP?',
      options: {
        return_citations: true,
      },
    },
  },
  id: 2,
};

// Handle server output
server.stdout.on('data', (data) => {
  const lines = data.toString().split('\n').filter(line => line.trim());
  lines.forEach(line => {
    try {
      const response = JSON.parse(line);
      console.log('Response:', JSON.stringify(response, null, 2));
    } catch (e) {
      // Not JSON, skip
    }
  });
});

// Send requests
setTimeout(() => {
  console.log('Sending tools/list request...');
  server.stdin.write(JSON.stringify(listToolsRequest) + '\n');
}, 500);

setTimeout(() => {
  console.log('\nSending search request...');
  server.stdin.write(JSON.stringify(searchRequest) + '\n');
}, 1000);

// Clean shutdown
setTimeout(() => {
  console.log('\nShutting down...');
  server.kill();
  process.exit(0);
}, 3000);