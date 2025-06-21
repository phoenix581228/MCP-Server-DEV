#!/usr/bin/env node
import { spawn } from 'child_process';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

console.log('🔍 Testing Perplexity MCP Server Search\n');

// Ensure API key is set
process.env.PERPLEXITY_API_KEY = process.env.PERPLEXITY_API_KEY || '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';

// Start the server
const server = spawn('node', ['dist/index.js'], {
  env: {
    ...process.env,
    DEBUG: 'true'
  },
  stdio: ['pipe', 'pipe', 'pipe'],
  cwd: __dirname
});

// Handle server stderr (debug output)
server.stderr.on('data', (data) => {
  const msg = data.toString().trim();
  if (msg) console.log('[Debug]', msg);
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
        
        // Handle different response types
        if (response.id === 1) {
          console.log('✅ Server initialized successfully\n');
        } else if (response.id === 2) {
          console.log('📋 Available tools:');
          response.result.tools.forEach(tool => {
            console.log(`  - ${tool.name}: ${tool.description}`);
          });
          console.log('');
        } else if (response.id === 3) {
          console.log('🔍 Search Results:');
          console.log('─'.repeat(80));
          
          if (response.result && response.result.content) {
            response.result.content.forEach(content => {
              if (content.type === 'text') {
                console.log(content.text);
              }
            });
          } else if (response.error) {
            console.log('❌ Error:', response.error.message);
          }
          
          console.log('─'.repeat(80));
        }
      } catch (e) {
        // Not JSON, skip
      }
    }
  });
});

// Test sequence
const requests = [
  {
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
  },
  {
    jsonrpc: '2.0',
    method: 'tools/list',
    id: 2
  },
  {
    jsonrpc: '2.0',
    method: 'tools/call',
    params: {
      name: 'perplexity_search_web',
      arguments: {
        query: 'What is Model Context Protocol MCP latest 2025 updates?',
        model: 'sonar-pro',
        options: {
          return_citations: true,
          search_recency: 'month'
        }
      }
    },
    id: 3
  }
];

// Send requests with delays
async function runTest() {
  for (const [index, request] of requests.entries()) {
    await new Promise(resolve => setTimeout(resolve, 500));
    
    if (request.method === 'tools/call') {
      console.log(`🌐 Executing search: "${request.params.arguments.query}"`);
      console.log(`📊 Using model: ${request.params.arguments.model}`);
      console.log('⏳ Please wait...\n');
    }
    
    server.stdin.write(JSON.stringify(request) + '\n');
  }
  
  // Wait for responses (increased timeout for API calls)
  await new Promise(resolve => setTimeout(resolve, 15000));
  
  console.log('\n✨ Test completed!');
  server.kill();
  process.exit(0);
}

runTest().catch(error => {
  console.error('❌ Test failed:', error);
  server.kill();
  process.exit(1);
});