#!/usr/bin/env node
import { config } from 'dotenv';
config({ override: true });

const apiKey = process.env.PERPLEXITY_API_KEY;
console.log('Testing with API Key:', apiKey?.substring(0, 10) + '...');

async function testAPI() {
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
            content: 'What is 2+2?'
          }
        ]
      })
    });

    console.log('Status:', response.status, response.statusText);
    
    if (response.ok) {
      const data = await response.json();
      console.log('Success! Response:', data.choices[0].message.content);
    } else {
      const error = await response.text();
      console.log('Error response:', error.substring(0, 200) + '...');
    }
  } catch (error) {
    console.error('Request failed:', error);
  }
}

testAPI();