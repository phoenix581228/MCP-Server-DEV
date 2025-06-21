#!/usr/bin/env node
import { config } from 'dotenv';
config({ override: true });

const apiKey = process.env.PERPLEXITY_API_KEY;
console.log('🔍 Testing Perplexity API with correct models\n');
console.log('API Key:', apiKey?.substring(0, 10) + '...\n');

async function testModel(model, query) {
  console.log(`\n📊 Testing model: ${model}`);
  console.log(`Query: "${query}"`);
  
  try {
    const response = await fetch('https://api.perplexity.ai/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        model: model,
        messages: [
          {
            role: 'system',
            content: 'Be precise and concise.'
          },
          {
            role: 'user',
            content: query
          }
        ]
      })
    });

    console.log(`Status: ${response.status} ${response.statusText}`);
    
    if (response.ok) {
      const data = await response.json();
      console.log('✅ Success!');
      console.log('Response:', data.choices[0].message.content.substring(0, 200) + '...');
      
      // Show citations if available
      if (data.citations && data.citations.length > 0) {
        console.log('\n📚 Citations:');
        data.citations.slice(0, 3).forEach((citation, i) => {
          console.log(`${i + 1}. ${citation.title || citation.url}`);
        });
      }
    } else {
      const error = await response.text();
      console.log('❌ Error:', error.substring(0, 200) + '...');
    }
  } catch (error) {
    console.error('❌ Request failed:', error.message);
  }
}

async function runTests() {
  // Test basic model
  await testModel('sonar', 'What is 2+2?');
  
  // Test pro model with web search
  await testModel('sonar-pro', 'What is the latest news about Model Context Protocol MCP?');
  
  // Test reasoning model
  await testModel('sonar-reasoning', 'Explain step by step how to implement a REST API');
  
  console.log('\n\n✨ All tests completed!');
}

runTests();