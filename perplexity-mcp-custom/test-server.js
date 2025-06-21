#!/usr/bin/env node
import { spawn } from 'child_process';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

console.log('🚀 Testing Perplexity MCP Server...\n');

// Start the server
const server = spawn('node', ['dist/index.js'], {
  env: {
    ...process.env,
    PERPLEXITY_API_KEY: process.env.PERPLEXITY_API_KEY || 'test-key',
    DEBUG: 'true',
  },
  stdio: ['pipe', 'pipe', 'pipe'],
});

// Handle server stderr (debug output)
server.stderr.on('data', (data) => {
  console.log('[Server]', data.toString().trim());
});

// Handle server stdout (JSON-RPC responses)
let responseBuffer = '';
server.stdout.on('data', (data) => {
  responseBuffer += data.toString();
  const lines = responseBuffer.split('\n');
  responseBuffer = lines.pop() || '';
  
  lines.forEach(line => {
    if (line.trim()) {
      try {
        const response = JSON.parse(line);
        console.log('\n📥 Response:', JSON.stringify(response, null, 2));
      } catch (e) {
        console.log('[Raw]', line);
      }
    }
  });
});

// Test sequence
const tests = [
  {
    name: 'Initialize',
    request: {
      jsonrpc: '2.0',
      method: 'initialize',
      params: {
        protocolVersion: '2024-11-05',
        capabilities: {},
        clientInfo: {
          name: 'test-client',
          version: '1.0.0'
        }
      },
      id: 1
    }
  },
  {
    name: 'List Tools',
    request: {
      jsonrpc: '2.0',
      method: 'tools/list',
      id: 2
    }
  }
];

// Run tests
async function runTests() {
  for (const [index, test] of tests.entries()) {
    await new Promise(resolve => setTimeout(resolve, 500));
    console.log(`\n📤 Test ${index + 1}: ${test.name}`);
    console.log('Request:', JSON.stringify(test.request, null, 2));
    server.stdin.write(JSON.stringify(test.request) + '\n');
  }
  
  // Wait a bit for responses
  await new Promise(resolve => setTimeout(resolve, 1000));
  
  console.log('\n✅ Tests completed!');
  server.kill();
  process.exit(0);
}

runTests().catch(error => {
  console.error('❌ Test failed:', error);
  server.kill();
  process.exit(1);
});