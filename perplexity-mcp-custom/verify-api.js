#!/usr/bin/env node
import 'dotenv/config';

console.log('🔍 Verifying Perplexity API Key...\n');

const apiKey = process.env.PERPLEXITY_API_KEY;

if (!apiKey) {
  console.log('❌ PERPLEXITY_API_KEY is not set in environment or .env file');
  process.exit(1);
}

// Check format
if (!apiKey.startsWith('pplx-')) {
  console.log('⚠️  API Key does not start with "pplx-"');
  console.log('   Current value:', apiKey.substring(0, 10) + '...');
  console.log('   Please check if this is a valid Perplexity API key');
} else {
  console.log('✅ API Key format looks correct');
  console.log('   Prefix:', apiKey.substring(0, 5));
  console.log('   Length:', apiKey.length, 'characters');
}

// Test API connection
console.log('\n🌐 Testing API connection...');

try {
  const response = await fetch('https://api.perplexity.ai/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${apiKey}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      model: 'sonar',
      messages: [
        {
          role: 'user',
          content: 'Hello, this is a test'
        }
      ]
    })
  });

  if (response.ok) {
    console.log('✅ API connection successful!');
    const data = await response.json();
    console.log('   Model used:', data.model);
    console.log('   Response received');
  } else {
    console.log('❌ API request failed');
    console.log('   Status:', response.status, response.statusText);
    const error = await response.text();
    console.log('   Error:', error);
    
    if (response.status === 401) {
      console.log('\n💡 This usually means the API key is invalid or expired.');
      console.log('   Please get a new API key from: https://www.perplexity.ai/settings/api');
    }
  }
} catch (error) {
  console.log('❌ Failed to connect to API');
  console.log('   Error:', error.message);
}

console.log('\n📝 Current configuration:');
console.log('   API Key:', apiKey.substring(0, 10) + '...' + apiKey.substring(apiKey.length - 4));
console.log('   Debug mode:', process.env.DEBUG || 'false');
console.log('   Default model:', process.env.PERPLEXITY_MODEL || 'sonar-pro');