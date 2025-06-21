#!/usr/bin/env node
import { spawn } from 'child_process';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

console.log('🔍 Testing Perplexity Search...\n');

// Start the server
const server = spawn('node', ['dist/index.js'], {
  env: {
    ...process.env,
    PATH: process.env.PATH,
    NODE_PATH: process.env.NODE_PATH,
  },
  stdio: ['pipe', 'pipe', 'pipe'],
  cwd: __dirname
});

// Handle server stderr (debug output)
server.stderr.on('data', (data) => {
  console.log('[Debug]', data.toString().trim());
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
        if (response.id === 3 && response.result) {
          console.log('\n✅ Search completed!');
          console.log('\n📄 Result:');
          const content = response.result.content[0];
          if (content && content.type === 'text') {
            console.log(content.text);
          }
        }
      } catch (e) {
        // Not JSON, skip
      }
    }
  });
});

// Initialize and search
const initialize = {
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
};

const search = {
  jsonrpc: '2.0',
  method: 'tools/call',
  params: {
    name: 'perplexity_search_web',
    arguments: {
      query: 'What is Model Context Protocol MCP latest 2025 updates?',
      options: {
        return_citations: true,
        search_recency: 'month'
      }
    }
  },
  id: 3
};

// Send requests
setTimeout(() => {
  server.stdin.write(JSON.stringify(initialize) + '\n');
}, 100);

setTimeout(() => {
  console.log('🌐 Searching for: "What is Model Context Protocol MCP latest 2025 updates?"');
  console.log('⏳ Please wait...\n');
  server.stdin.write(JSON.stringify(search) + '\n');
}, 500);

// Timeout
setTimeout(() => {
  console.log('\n✨ Test completed!');
  server.kill();
  process.exit(0);
}, 10000);