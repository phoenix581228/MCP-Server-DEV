import cors from 'cors';
import { Request, Response, NextFunction } from 'express';
import { timingSafeEqual } from 'node:crypto';
import { rateLimit } from 'express-rate-limit';

export interface SecurityConfig {
  corsOrigins?: string[];
  bearerToken?: string;
  rateLimit?: {
    windowMs: number;
    maxRequests: number;
  };
}

// CORS configuration
export function createCorsMiddleware(config: SecurityConfig) {
  const corsOptions: cors.CorsOptions = {
    origin: (origin, callback) => {
      // Allow requests with no origin (like mobile apps or curl)
      if (!origin) {
        return callback(null, true);
      }
      
      // If no specific origins configured, allow all
      if (!config.corsOrigins || config.corsOrigins.length === 0) {
        return callback(null, true);
      }
      
      // Check if origin is in whitelist
      if (config.corsOrigins.includes(origin)) {
        callback(null, true);
      } else {
        callback(new Error('Not allowed by CORS'));
      }
    },
    credentials: true,
    methods: ['GET', 'POST', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'MCP-Session-Id', 'MCP-Protocol-Version', 'Accept', 'Last-Event-ID'],
    exposedHeaders: ['MCP-Session-Id'],
  };
  
  return cors(corsOptions);
}

// Bearer token authentication middleware
export function createAuthMiddleware(config: SecurityConfig) {
  return (req: Request, res: Response, next: NextFunction) => {
    // Skip auth if no token configured
    if (!config.bearerToken) {
      return next();
    }
    
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        jsonrpc: '2.0',
        error: {
          code: -32001,
          message: 'Unauthorized: Missing or invalid bearer token',
        },
        id: null,
      });
    }
    
    const token = authHeader.substring(7);
    
    // Use timing-safe comparison to prevent timing attacks
    const expectedBuffer = Buffer.from(config.bearerToken);
    const actualBuffer = Buffer.from(token);
    
    // Ensure both buffers are the same length
    if (expectedBuffer.length !== actualBuffer.length) {
      return res.status(401).json({
        jsonrpc: '2.0',
        error: {
          code: -32001,
          message: 'Unauthorized: Invalid bearer token',
        },
        id: null,
      });
    }
    
    // Timing-safe comparison
    const isValid = timingSafeEqual(expectedBuffer, actualBuffer);
    
    if (!isValid) {
      return res.status(401).json({
        jsonrpc: '2.0',
        error: {
          code: -32001,
          message: 'Unauthorized: Invalid bearer token',
        },
        id: null,
      });
    }
    
    next();
  };
}

// Express rate limiter
export function createRateLimiter(config: SecurityConfig) {
  if (!config.rateLimit) {
    return (_req: Request, _res: Response, next: NextFunction) => next();
  }
  
  const { windowMs, maxRequests } = config.rateLimit;
  
  return rateLimit({
    windowMs,
    max: maxRequests,
    standardHeaders: true, // Return rate limit info in `RateLimit-*` headers
    legacyHeaders: false, // Disable the `X-RateLimit-*` headers
    handler: (_req: Request, res: Response) => {
      res.status(429).json({
        jsonrpc: '2.0',
        error: {
          code: -32002,
          message: 'Too many requests, please try again later',
        },
        id: null,
      });
    },
    // Skip rate limiting for health check endpoint
    skip: (req: Request) => req.path === '/health',
  });
}

// Error handling middleware
export function errorHandler(err: Error, _req: Request, res: Response, _next: NextFunction) {
  console.error('Server error:', err);
  
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