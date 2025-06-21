#!/usr/bin/env node
import { spawn } from 'child_process';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

console.log('🔬 Testing Perplexity MCP Server Deep Research\n');

// Start the server
const server = spawn('node', ['dist/index.js'], {
  env: {
    ...process.env,
    PERPLEXITY_API_KEY: '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',
    DEBUG: 'true'
  },
  stdio: ['pipe', 'pipe', 'pipe'],
  cwd: __dirname
});

// Handle server output
server.stderr.on('data', (data) => {
  const msg = data.toString();
  if (msg.includes('API Request:') || msg.includes('API Response:')) {
    console.log('[API Debug]', msg.trim());
  } else {
    console.log('[Debug]', msg.trim());
  }
});

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
          console.log('\n🔬 Deep Research Results:');
          console.log('═'.repeat(80));
          
          if (response.result.content) {
            response.result.content.forEach(content => {
              if (content.type === 'text') {
                console.log(content.text);
              }
            });
          }
          
          console.log('═'.repeat(80));
        } else if (response.error) {
          console.log('\n❌ Error:', response.error.message);
        }
      } catch (e) {
        // Not JSON
      }
    }
  });
});

// Test deep research
const requests = [
  {
    jsonrpc: '2.0',
    method: 'initialize',
    params: {
      protocolVersion: '2024-11-05',
      capabilities: {},
      clientInfo: { name: 'test-client', version: '1.0.0' }
    },
    id: 1
  },
  {
    jsonrpc: '2.0',
    method: 'tools/call',
    params: {
      name: 'perplexity_deep_research',
      arguments: {
        topic: 'Model Context Protocol MCP implementation best practices',
        depth: 'comprehensive',
        focus_areas: ['TypeScript SDK', 'JSON Schema compliance', 'Error handling']
      }
    },
    id: 3
  }
];

// Run test
async function runTest() {
  for (const request of requests) {
    await new Promise(resolve => setTimeout(resolve, 300));
    
    if (request.method === 'tools/call') {
      console.log(`🎯 Topic: "${request.params.arguments.topic}"`);
      console.log(`📊 Depth: ${request.params.arguments.depth}`);
      console.log(`🔍 Focus areas: ${request.params.arguments.focus_areas.join(', ')}`);
      console.log('⏳ Conducting deep research...\n');
    }
    
    server.stdin.write(JSON.stringify(request) + '\n');
  }
  
  // Wait for response
  await new Promise(resolve => setTimeout(resolve, 10000));
  
  console.log('\n✨ Test completed!');
  server.kill();
  process.exit(0);
}

runTest();