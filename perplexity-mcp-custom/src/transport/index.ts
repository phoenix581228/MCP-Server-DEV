import { Transport } from '@modelcontextprotocol/sdk/shared/transport.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { StreamableHTTPServerTransport } from '@modelcontextprotocol/sdk/server/streamableHttp.js';
import { randomUUID } from 'node:crypto';

import { TransportOptions } from '../types/index.js';

export interface TransportFactory {
  create(options: TransportOptions): Transport | StreamableHTTPServerTransport;
}

interface SessionData {
  transport: StreamableHTTPServerTransport;
  lastAccess: number;
}

export class TransportManager implements TransportFactory {
  private transports: Map<string, SessionData> = new Map();
  private sessionTTL: number = 30 * 60 * 1000; // 30 minutes default
  private cleanupInterval: NodeJS.Timeout | null = null;

  create(options: TransportOptions): Transport | StreamableHTTPServerTransport {
    switch (options.type) {
      case 'stdio':
        return new StdioServerTransport();
      
      case 'http':
        // For HTTP transport, we return a special instance that can be reused
        // The actual transport instances are managed per-session
        return this.createHttpTransport();
      
      default:
        throw new Error(`Unknown transport type: ${options.type}`);
    }
  }

  private createHttpTransport(): StreamableHTTPServerTransport {
    // This creates a transport with session management enabled
    return new StreamableHTTPServerTransport({
      sessionIdGenerator: () => randomUUID(),
      enableJsonResponse: false, // Use SSE by default
      onsessioninitialized: (sessionId) => {
        console.log(`Session initialized: ${sessionId}`);
      }
    });
  }

  getHttpTransport(sessionId?: string): StreamableHTTPServerTransport | undefined {
    if (!sessionId) {
      return undefined;
    }
    
    const sessionData = this.transports.get(sessionId);
    if (!sessionData) {
      return undefined;
    }
    
    // Update last access time
    sessionData.lastAccess = Date.now();
    
    return sessionData.transport;
  }

  storeTransport(sessionId: string, transport: StreamableHTTPServerTransport): void {
    const sessionData: SessionData = {
      transport,
      lastAccess: Date.now(),
    };
    
    this.transports.set(sessionId, sessionData);
    
    // Set up cleanup when transport closes
    transport.onclose = () => {
      console.log(`Transport closed for session: ${sessionId}`);
      this.transports.delete(sessionId);
    };
    
    // Start cleanup interval if not already running
    if (!this.cleanupInterval) {
      this.startCleanupInterval();
    }
  }

  removeTransport(sessionId: string): void {
    this.transports.delete(sessionId);
  }

  hasTransport(sessionId: string): boolean {
    return this.transports.has(sessionId);
  }
  
  private startCleanupInterval(): void {
    // Run cleanup every 5 minutes
    this.cleanupInterval = setInterval(() => {
      this.cleanupExpiredSessions();
    }, 5 * 60 * 1000);
  }
  
  private cleanupExpiredSessions(): void {
    const now = Date.now();
    const expired: string[] = [];
    
    for (const [sessionId, sessionData] of this.transports.entries()) {
      if (now - sessionData.lastAccess > this.sessionTTL) {
        expired.push(sessionId);
      }
    }
    
    for (const sessionId of expired) {
      console.log(`Cleaning up expired session: ${sessionId}`);
      const sessionData = this.transports.get(sessionId);
      if (sessionData && sessionData.transport.onclose) {
        // Trigger the onclose handler
        sessionData.transport.onclose();
      }
      this.transports.delete(sessionId);
    }
    
    // Stop cleanup interval if no more sessions
    if (this.transports.size === 0 && this.cleanupInterval) {
      clearInterval(this.cleanupInterval);
      this.cleanupInterval = null;
    }
  }
  
  // Clean up resources when shutting down
  destroy(): void {
    if (this.cleanupInterval) {
      clearInterval(this.cleanupInterval);
      this.cleanupInterval = null;
    }
    
    // Close all transports
    for (const [, sessionData] of this.transports.entries()) {
      if (sessionData.transport.onclose) {
        sessionData.transport.onclose();
      }
    }
    
    this.transports.clear();
  }
}