#!/usr/bin/env node
import { config } from 'dotenv';
import { PerplexityMCPServer } from './server/index.js';
import { TransportOptions } from './types/index.js';

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

function parseCommandLineArgs(): TransportOptions {
  const args = process.argv.slice(2);
  
  // Default to stdio
  let transport: TransportOptions = { type: 'stdio' };
  
  // Check for command line arguments
  for (let i = 0; i < args.length; i++) {
    const arg = args[i];
    
    if (arg === '--http' || arg === '-h') {
      transport = { type: 'http', port: 3000 };
    } else if ((arg === '--port' || arg === '-p') && i + 1 < args.length) {
      const portStr = args[i + 1];
      const port = parseInt(portStr!, 10);
      if (!isNaN(port)) {
        if (transport.type === 'http') {
          transport.port = port;
        }
        i++; // Skip next argument
      }
    } else if (arg === '--host' && i + 1 < args.length) {
      transport.host = args[i + 1];
      i++; // Skip next argument
    } else if (arg === '--help') {
      console.log(`
Perplexity MCP Server

Usage:
  perplexity-mcp [options]

Options:
  --http, -h        Use HTTP transport instead of stdio
  --port, -p <port> Set HTTP port (default: 3000)
  --host <host>     Set HTTP host (default: 0.0.0.0)
  --help            Show this help message

Environment Variables:
  PERPLEXITY_API_KEY           Required. Your Perplexity API key
  PERPLEXITY_BASE_URL          Optional. Custom API endpoint
  PERPLEXITY_MODEL             Optional. Default model to use
  PERPLEXITY_CORS_ORIGINS      Optional. Comma-separated CORS origins
  PERPLEXITY_BEARER_TOKEN      Optional. Bearer token for authentication
  PERPLEXITY_RATE_LIMIT        Optional. Max requests per minute
  MCP_TRANSPORT                Optional. Transport type (stdio/http)
  MCP_PORT                     Optional. HTTP port
  DEBUG                        Optional. Enable debug logging

Examples:
  # Stdio mode (default)
  perplexity-mcp
  
  # HTTP mode
  perplexity-mcp --http
  perplexity-mcp --http --port 8080
  perplexity-mcp --http --port 8080 --host localhost
`);
      process.exit(0);
    }
  }
  
  // Check environment variables as fallback
  if (!transport.type || transport.type === 'stdio') {
    if (process.env.MCP_TRANSPORT === 'http') {
      transport = { 
        type: 'http', 
        port: process.env.MCP_PORT ? parseInt(process.env.MCP_PORT, 10) : 3000,
        host: process.env.MCP_HOST,
      };
    }
  }
  
  return transport;
}

async function main() {
  try {
    // Validate environment first
    validateEnvironment();
    
    // Parse command line arguments
    const transport = parseCommandLineArgs();
    
    // Debug: Log configuration
    if (process.env.DEBUG === 'true') {
      console.error('Configuration:');
      console.error('- API Key:', process.env.PERPLEXITY_API_KEY?.substring(0, 10) + '...');
      console.error('- Base URL:', process.env.PERPLEXITY_BASE_URL || '(default)');
      console.error('- Model:', process.env.PERPLEXITY_MODEL || '(default)');
      console.error('- Transport:', transport.type);
      if (transport.type === 'http') {
        console.error('- HTTP Port:', transport.port);
        console.error('- HTTP Host:', transport.host || '0.0.0.0');
      }
    }

    const server = new PerplexityMCPServer({
      apiKey: process.env.PERPLEXITY_API_KEY!,
      baseUrl: process.env.PERPLEXITY_BASE_URL,
      model: process.env.PERPLEXITY_MODEL as any,
      debug: process.env.DEBUG === 'true',
    });

    await server.start(transport);
    
    // Keep process alive for HTTP mode
    if (transport.type === 'http') {
      process.on('SIGINT', async () => {
        console.log('\nShutting down...');
        await server.stop();
        process.exit(0);
      });
      
      process.on('SIGTERM', async () => {
        console.log('\nShutting down...');
        await server.stop();
        process.exit(0);
      });
    }
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
}

// Handle graceful shutdown for stdio mode
// (HTTP mode handles its own shutdown)

main().catch((error) => {
  console.error('Unhandled error:', error);
  process.exit(1);
});