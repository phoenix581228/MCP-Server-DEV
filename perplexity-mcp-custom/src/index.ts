#!/usr/bin/env node
import { config } from 'dotenv';
import { PerplexityMCPServer } from './server/index.js';

// Load environment variables with override to ensure .env takes precedence
config({ override: true });

// Validate environment variables
function validateEnvironment() {
  // Check required variables
  if (!process.env.PERPLEXITY_API_KEY) {
    console.error('❌ Error: PERPLEXITY_API_KEY is required');
    console.error('Please set it in .env file or as environment variable');
    process.exit(1);
  }
  
  // Validate API key format (basic check)
  if (!process.env.PERPLEXITY_API_KEY.startsWith('pplx-')) {
    console.error('⚠️  Warning: PERPLEXITY_API_KEY should start with "pplx-"');
  }
  
  // Validate model if specified
  const validModels = ['sonar', 'sonar-pro', 'sonar-reasoning', 'sonar-reasoning-pro', 'sonar-deep-research'];
  if (process.env.PERPLEXITY_MODEL && !validModels.includes(process.env.PERPLEXITY_MODEL)) {
    console.error(`⚠️  Warning: Invalid model "${process.env.PERPLEXITY_MODEL}". Valid models are: ${validModels.join(', ')}`);
  }
}

async function main() {
  try {
    // Validate environment first
    validateEnvironment();
    
    // Debug: Log environment
    if (process.env.DEBUG === 'true') {
      console.error('Environment variables loaded:');
      console.error('- API Key:', process.env.PERPLEXITY_API_KEY?.substring(0, 10) + '...');
      console.error('- Base URL:', process.env.PERPLEXITY_BASE_URL || '(default)');
      console.error('- Model:', process.env.PERPLEXITY_MODEL || '(default)');
    }

    const server = new PerplexityMCPServer({
      apiKey: process.env.PERPLEXITY_API_KEY,
      baseUrl: process.env.PERPLEXITY_BASE_URL,
      model: process.env.PERPLEXITY_MODEL as any,
      debug: process.env.DEBUG === 'true',
    });

    await server.start();
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
}

// Handle graceful shutdown
process.on('SIGINT', () => {
  process.exit(0);
});

process.on('SIGTERM', () => {
  process.exit(0);
});

main().catch((error) => {
  console.error('Unhandled error:', error);
  process.exit(1);
});