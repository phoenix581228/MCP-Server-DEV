import express, { Request, Response } from 'express';
import { Server as HttpServer } from 'http';
import { StreamableHTTPServerTransport } from '@modelcontextprotocol/sdk/server/streamableHttp.js';
import { isInitializeRequest } from '@modelcontextprotocol/sdk/types.js';
import { randomUUID } from 'node:crypto';

import { PerplexityMCPServer } from './index.js';
import { TransportManager } from '../transport/index.js';
import { 
  SecurityConfig, 
  createCorsMiddleware, 
  createAuthMiddleware, 
  createRateLimiter,
  errorHandler 
} from './middleware.js';

export interface HttpServerConfig {
  port: number;
  host?: string;
  security?: SecurityConfig;
}

export class PerplexityHttpServer {
  private app: express.Application;
  private httpServer?: HttpServer;
  private mcpServer: PerplexityMCPServer;
  private transportManager: TransportManager;
  private config: HttpServerConfig;

  constructor(mcpServer: PerplexityMCPServer, config: HttpServerConfig) {
    this.mcpServer = mcpServer;
    this.config = config;
    this.transportManager = new TransportManager();
    this.app = express();
    
    this.setupMiddleware();
    this.setupRoutes();
  }

  private setupMiddleware(): void {
    // Enable trust proxy for accurate IP addresses behind reverse proxies
    this.app.set('trust proxy', true);
    
    // Parse JSON bodies
    this.app.use(express.json({ limit: '4mb' }));
    
    // CORS
    this.app.use(createCorsMiddleware(this.config.security || {}));
    
    // Rate limiting
    this.app.use(createRateLimiter(this.config.security || {}));
    
    // Authentication (if configured)
    if (this.config.security?.bearerToken) {
      this.app.use(createAuthMiddleware(this.config.security));
    }
    
    // Error handler
    this.app.use(errorHandler);
  }

  private setupRoutes(): void {
    // Health check endpoint
    this.app.get('/health', (_req: Request, res: Response) => {
      res.json({ status: 'ok', service: 'perplexity-mcp-server' });
    });

    // MCP POST endpoint - handles JSON-RPC requests
    this.app.post('/mcp', async (req: Request, res: Response): Promise<void> => {
      console.log(`[POST] /mcp - IP: ${req.ip}, Body:`, JSON.stringify(req.body).substring(0, 200));
      try {
        const sessionId = req.headers['mcp-session-id'] as string;
        
        // Check if this is an initialization request
        if (isInitializeRequest(req.body)) {
          await this.handleInitializeRequest(req, res);
        } else {
          // Regular request - requires session
          if (!sessionId) {
            res.status(400).json({
              jsonrpc: '2.0',
              error: {
                code: -32000,
                message: 'Bad Request: No session ID provided',
              },
              id: null,
            });
            return;
          }
          
          await this.handleRegularRequest(req, res, sessionId);
        }
      } catch (error) {
        console.error('Error handling MCP request:', error);
        if (!res.headersSent) {
          res.status(500).json({
            jsonrpc: '2.0',
            error: {
              code: -32603,
              message: 'Internal server error',
            },
            id: null,
          });
        }
      }
    });

    // MCP GET endpoint - establishes SSE stream
    this.app.get('/mcp', async (req: Request, res: Response): Promise<void> => {
      const sessionId = req.headers['mcp-session-id'] as string;
      console.log(`[GET] /mcp - IP: ${req.ip}, Session: ${sessionId || 'none'}`);
      
      if (!sessionId || !this.transportManager.hasTransport(sessionId)) {
        res.status(400).send('Invalid or missing session ID');
        return;
      }
      
      const transport = this.transportManager.getHttpTransport(sessionId);
      if (!transport) {
        res.status(404).send('Session not found');
        return;
      }
      
      // Log SSE connection
      const lastEventId = req.headers['last-event-id'] as string;
      if (lastEventId) {
        console.log(`Client reconnecting with Last-Event-ID: ${lastEventId}`);
      } else {
        console.log(`Establishing new SSE stream for session ${sessionId}`);
      }
      
      await transport.handleRequest(req, res);
    });

    // MCP DELETE endpoint - terminates session
    this.app.delete('/mcp', async (req: Request, res: Response): Promise<void> => {
      const sessionId = req.headers['mcp-session-id'] as string;
      console.log(`[DELETE] /mcp - IP: ${req.ip}, Session: ${sessionId || 'none'}`);
      
      if (!sessionId || !this.transportManager.hasTransport(sessionId)) {
        res.status(400).send('Invalid or missing session ID');
        return;
      }
      
      console.log(`Terminating session: ${sessionId}`);
      
      const transport = this.transportManager.getHttpTransport(sessionId);
      if (transport) {
        await transport.handleRequest(req, res);
      }
    });
  }

  private async handleInitializeRequest(req: Request, res: Response): Promise<void> {
    // Create new transport for this session
    const transport = new StreamableHTTPServerTransport({
      sessionIdGenerator: () => randomUUID(),
      enableJsonResponse: false, // Use SSE
      onsessioninitialized: (sessionId) => {
        console.log(`[INIT] New session: ${sessionId}, Client: ${req.body?.params?.clientInfo?.name || 'unknown'}`);
        // Store the transport for future use
        this.transportManager.storeTransport(sessionId, transport);
      }
    });
    
    
    // Connect transport to MCP server
    const server = this.mcpServer.getServer();
    await server.connect(transport);
    
    // Handle the request
    await transport.handleRequest(req, res, req.body);
  }

  private async handleRegularRequest(req: Request, res: Response, sessionId: string): Promise<void> {
    const transport = this.transportManager.getHttpTransport(sessionId);
    
    if (!transport) {
      res.status(404).json({
        jsonrpc: '2.0',
        error: {
          code: -32000,
          message: 'Session not found',
        },
        id: null,
      });
      return;
    }
    
    await transport.handleRequest(req, res, req.body);
  }

  async start(): Promise<void> {
    const { port, host = '0.0.0.0' } = this.config;
    
    return new Promise((resolve) => {
      this.httpServer = this.app.listen(port, host, () => {
        console.log(`
🚀 Perplexity MCP HTTP Server listening on http://${host}:${port}
        Debug mode: ${process.env.DEBUG === 'true' ? 'ON' : 'OFF'}
        Bearer token: ${this.config.security?.bearerToken ? 'CONFIGURED' : 'DISABLED'}
        Rate limiting: ${this.config.security?.rateLimit ? `${this.config.security.rateLimit.maxRequests} req/${this.config.security.rateLimit.windowMs}ms` : 'DISABLED'}

Endpoints:
  POST   http://${host}:${port}/mcp   - JSON-RPC requests
  GET    http://${host}:${port}/mcp   - SSE stream
  DELETE http://${host}:${port}/mcp   - Terminate session
  GET    http://${host}:${port}/health - Health check`);
        resolve();
      });
    });
  }

  async stop(): Promise<void> {
    return new Promise((resolve) => {
      if (this.httpServer) {
        this.httpServer.close(() => {
          console.log('HTTP Server stopped');
          // Clean up transport manager
          this.transportManager.destroy();
          resolve();
        });
      } else {
        // Clean up transport manager even if server wasn't started
        this.transportManager.destroy();
        resolve();
      }
    });
  }
}