import { spawn } from 'child_process';

console.log('🧪 Testing environment variable validation...\n');

// Test 1: Invalid API key format
console.log('Test 1: Invalid API key format');
const test1 = spawn('node', ['dist/index.js'], {
  env: {
    ...process.env,
    PERPLEXITY_API_KEY: 'invalid-key-format',
    DEBUG: 'true'
  },
  stdio: ['ignore', 'pipe', 'pipe']
});

let output1 = '';
test1.stderr.on('data', (data) => {
  output1 += data.toString();
});

test1.on('exit', () => {
  console.log(output1);
  
  // Test 2: Invalid model
  console.log('\nTest 2: Invalid model');
  const test2 = spawn('node', ['dist/index.js'], {
    env: {
      ...process.env,
      PERPLEXITY_API_KEY: 'pplx-valid-key',
      PERPLEXITY_MODEL: 'invalid-model',
      DEBUG: 'true'
    },
    stdio: ['ignore', 'pipe', 'pipe']
  });
  
  let output2 = '';
  test2.stderr.on('data', (data) => {
    output2 += data.toString();
  });
  
  test2.on('exit', () => {
    console.log(output2);
    
    // Test 3: Missing API key
    console.log('\nTest 3: Missing API key');
    const test3 = spawn('node', ['dist/index.js'], {
      env: {
        PATH: process.env.PATH,
        NODE_ENV: 'test'
      },
      stdio: ['ignore', 'pipe', 'pipe']
    });
    
    let output3 = '';
    test3.stderr.on('data', (data) => {
      output3 += data.toString();
    });
    
    test3.on('exit', (code) => {
      console.log(output3);
      console.log(`Exit code: ${code}`);
      process.exit(0);
    });
    
    setTimeout(() => test3.kill(), 1000);
  });
  
  setTimeout(() => test2.kill(), 1000);
});

setTimeout(() => test1.kill(), 1000);