#!/usr/bin/env node
import { spawn } from 'child_process';

console.log('🧪 Testing all Perplexity models...\n');

// Test configuration
const testQuery = "What are the latest AI breakthroughs in 2025?";
const models = [
  { tool: 'perplexity_search_web', model: 'sonar', name: 'Sonar (Basic)' },
  { tool: 'perplexity_search_web', model: 'sonar-pro', name: 'Sonar Pro' },
  { tool: 'perplexity_search_web', model: 'sonar-reasoning', name: 'Sonar Reasoning' },
  { tool: 'perplexity_search_web', model: 'sonar-reasoning-pro', name: 'Sonar Reasoning Pro' },
  { tool: 'perplexity_pro_search', model: 'sonar-pro', name: 'Pro Search Tool' },
];

async function testModel(toolName, modelName, displayName) {
  console.log(`\n📊 Testing ${displayName}...`);
  console.log('─'.repeat(60));
  
  const server = spawn('node', ['dist/index.js'], {
    env: {
      ...process.env,
      PERPLEXITY_API_KEY: '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',
      DEBUG: 'false'
    },
    stdio: ['pipe', 'pipe', 'pipe'],
    cwd: process.cwd()
  });

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
        name: toolName,
        arguments: {
          query: testQuery,
          model: modelName,
          options: {
            return_citations: true,
            search_recency: 'week'
          }
        }
      },
      id: 2
    }
  ];

  let responseBuffer = '';
  let responseReceived = false;

  server.stdout.on('data', (data) => {
    responseBuffer += data.toString();
    const lines = responseBuffer.split('\n');
    responseBuffer = lines.pop() || '';
    
    lines.forEach(line => {
      if (line.trim()) {
        try {
          const response = JSON.parse(line);
          if (response.id === 2 && response.result) {
            responseReceived = true;
            console.log('✅ Response received successfully');
            if (response.result.content && response.result.content[0]) {
              const content = response.result.content[0].text;
              console.log('\nFirst 200 characters of response:');
              console.log(content.substring(0, 200) + '...');
            }
          } else if (response.error) {
            console.log('❌ Error:', response.error.message);
          }
        } catch (e) {
          // Not JSON
        }
      }
    });
  });

  // Send requests
  for (const request of requests) {
    server.stdin.write(JSON.stringify(request) + '\n');
    await new Promise(resolve => setTimeout(resolve, 100));
  }

  // Wait for response
  await new Promise(resolve => {
    const timeout = setTimeout(() => {
      if (!responseReceived) {
        console.log('⏱️ Timeout waiting for response');
      }
      resolve();
    }, 8000);
    
    const checkInterval = setInterval(() => {
      if (responseReceived) {
        clearInterval(checkInterval);
        clearTimeout(timeout);
        resolve();
      }
    }, 100);
  });

  server.kill();
  await new Promise(resolve => setTimeout(resolve, 500));
}

async function runTests() {
  console.log(`🔍 Test Query: "${testQuery}"`);
  
  for (const { tool, model, name } of models) {
    await testModel(tool, model, name);
  }
  
  console.log('\n\n✨ All tests completed!');
  console.log('\n📋 Available tools in perplexity-custom:');
  console.log('  - mcp__perplexity-custom__perplexity_search_web (supports all 5 models)');
  console.log('  - mcp__perplexity-custom__perplexity_pro_search (optimized for Pro models)');
  console.log('  - mcp__perplexity-custom__perplexity_deep_research (deep research mode)');
}

runTests().catch(error => {
  console.error('Test failed:', error);
  process.exit(1);
});