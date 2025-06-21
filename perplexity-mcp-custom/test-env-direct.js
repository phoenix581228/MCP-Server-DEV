// Test environment validation directly
console.log('🧪 Testing environment variable validation directly...\n');

// Save original env
const originalEnv = { ...process.env };

// Test 1: Invalid API key format
console.log('Test 1: Invalid API key format');
process.env = {
  ...originalEnv,
  PERPLEXITY_API_KEY: 'invalid-key-format',
  DEBUG: 'true'
};

import('./dist/index.js').then(() => {
  console.log('Unexpected: Server started with invalid key');
}).catch(err => {
  console.log('Expected error:', err.message);
});

// Reset after a moment
setTimeout(() => {
  // Test 2: Missing API key
  console.log('\nTest 2: Missing API key');
  delete process.env.PERPLEXITY_API_KEY;
  
  import('./dist/index.js?t=2').then(() => {
    console.log('Unexpected: Server started without key');
  }).catch(err => {
    console.log('Expected error:', err.message);
  });
}, 100);