#!/usr/bin/env node
import { config } from 'dotenv';
config({ override: true });

const apiKey = process.env.PERPLEXITY_API_KEY || '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';

console.log('Testing simple Perplexity API call...');
console.log('API Key:', apiKey.substring(0, 10) + '...\n');

async function testSimple() {
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
          content: 'Hello, please respond with "Hi there!"'
        }
      ]
    })
  });

  console.log('Status:', response.status, response.statusText);
  
  if (response.ok) {
    const data = await response.json();
    console.log('\nResponse:', data.choices[0].message.content);
    console.log('\nFull response structure:');
    console.log(JSON.stringify(data, null, 2));
  } else {
    const error = await response.text();
    console.log('Error:', error);
  }
}

testSimple();