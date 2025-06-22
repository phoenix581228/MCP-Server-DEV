import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
  Tool,
  TextContent,
  ImageContent,
  EmbeddedResource,
} from '@modelcontextprotocol/sdk/types.js';

import { ServerConfig, SearchResult, TransportOptions } from '../types/index.js';
import { PerplexityAPIClient } from '../api/client.js';
import { LRUCache } from '../utils/cache.js';
import { 
  SEARCH_TOOL_SCHEMA, 
  PRO_SEARCH_TOOL_SCHEMA, 
  DEEP_RESEARCH_TOOL_SCHEMA,
  REASONING_TOOL_SCHEMA 
} from '../tools/schemas.js';
import { PerplexityHttpServer, HttpServerConfig } from './http.js';

export class PerplexityMCPServer {
  private server: Server;
  private apiClient: PerplexityAPIClient;
  private cache: LRUCache<string, SearchResult>;
  private config: ServerConfig;
  private httpServer?: PerplexityHttpServer;

  constructor(config: ServerConfig) {
    this.config = config;
    
    if (!config.apiKey) {
      throw new Error('PERPLEXITY_API_KEY is required');
    }

    this.server = new Server(
      {
        name: 'perplexity-mcp-custom',
        version: '1.0.0',
      },
      {
        capabilities: {
          tools: {},
        },
      },
    );

    this.apiClient = new PerplexityAPIClient(
      config.apiKey,
      config.baseUrl,
      config.debug,
    );

    // 1 hour TTL, max 100 items
    this.cache = new LRUCache({ max: 100, ttl: 1000 * 60 * 60 });

    this.setupHandlers();
  }

  private setupHandlers(): void {
    // Handle tool list requests
    this.server.setRequestHandler(ListToolsRequestSchema, async () => {
      const tools: Tool[] = [
        {
          name: 'perplexity_search_web',
          description: 'Search the web using Perplexity AI for up-to-date information',
          inputSchema: {
            type: 'object',
            properties: {
              query: {
                type: 'string',
                description: '搜尋查詢字串',
                minLength: 1,
                maxLength: 1000,
              },
              model: {
                type: 'string',
                enum: ['sonar', 'sonar-pro', 'sonar-reasoning', 'sonar-reasoning-pro', 'sonar-deep-research'],
                default: 'sonar-pro',
                description: 'Perplexity model to use',
              },
              options: {
                type: 'object',
                properties: {
                  search_domain: {
                    type: 'string',
                    description: '限定搜尋的網域',
                  },
                  search_recency: {
                    type: 'string',
                    enum: ['day', 'week', 'month', 'year'],
                    description: '搜尋時間範圍',
                  },
                  return_citations: {
                    type: 'boolean',
                    default: true,
                    description: '是否返回引用來源',
                  },
                  return_images: {
                    type: 'boolean',
                    default: false,
                    description: '是否返回圖片',
                  },
                  return_related_questions: {
                    type: 'boolean',
                    default: false,
                    description: '是否返回相關問題',
                  },
                },
                additionalProperties: false,
              },
            },
            required: ['query'],
            additionalProperties: false,
          },
        },
        {
          name: 'perplexity_pro_search',
          description: 'Advanced search using Perplexity Pro models with enhanced capabilities',
          inputSchema: {
            type: 'object',
            properties: {
              query: {
                type: 'string',
                description: '搜尋查詢字串',
                minLength: 1,
                maxLength: 1000,
              },
              model: {
                type: 'string',
                enum: ['sonar-pro', 'sonar-reasoning-pro'],
                default: 'sonar-pro',
                description: 'Pro model to use',
              },
              options: {
                type: 'object',
                properties: {
                  search_domain: {
                    type: 'string',
                    description: '限定搜尋的網域',
                  },
                  search_recency: {
                    type: 'string',
                    enum: ['day', 'week', 'month', 'year'],
                    description: '搜尋時間範圍',
                  },
                  return_citations: {
                    type: 'boolean',
                    default: true,
                    description: '是否返回引用來源',
                  },
                  return_images: {
                    type: 'boolean',
                    default: true,
                    description: '是否返回圖片',
                  },
                  return_related_questions: {
                    type: 'boolean',
                    default: true,
                    description: '是否返回相關問題',
                  },
                },
                additionalProperties: false,
              },
            },
            required: ['query'],
            additionalProperties: false,
          },
        },
        {
          name: 'perplexity_deep_research',
          description: 'Conduct deep research on a topic using Perplexity AI',
          inputSchema: {
            type: 'object',
            properties: {
              topic: {
                type: 'string',
                description: '研究主題',
                minLength: 1,
                maxLength: 500,
              },
              depth: {
                type: 'string',
                enum: ['quick', 'standard', 'comprehensive'],
                default: 'standard',
                description: '研究深度',
              },
              focus_areas: {
                type: 'array',
                items: {
                  type: 'string',
                },
                description: '重點研究領域',
              },
            },
            required: ['topic'],
            additionalProperties: false,
          },
        },
        {
          name: 'perplexity_reasoning',
          description: 'Complex reasoning and step-by-step analysis using Perplexity reasoning models',
          inputSchema: {
            type: 'object',
            properties: {
              query: {
                type: 'string',
                description: '推理查詢字串',
                minLength: 1,
                maxLength: 1000,
              },
              model: {
                type: 'string',
                enum: ['sonar-reasoning', 'sonar-reasoning-pro'],
                default: 'sonar-reasoning',
                description: 'Reasoning model to use',
              },
              context: {
                type: 'string',
                description: '額外的上下文資訊',
              },
            },
            required: ['query'],
            additionalProperties: false,
          },
        },
      ];

      return { tools };
    });

    // Handle tool execution
    this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
      const { name, arguments: args } = request.params;

      try {
        switch (name) {
          case 'perplexity_search_web':
            return await this.handleSearch(args);
          case 'perplexity_pro_search':
            return await this.handleProSearch(args);
          case 'perplexity_deep_research':
            return await this.handleDeepResearch(args);
          case 'perplexity_reasoning':
            return await this.handleReasoning(args);
          default:
            throw new Error(`Unknown tool: ${name}`);
        }
      } catch (error) {
        return {
          content: [
            {
              type: 'text',
              text: `Error: ${(error as Error).message}`,
            },
          ],
          isError: true,
        };
      }
    });
  }

  private async handleSearch(args: unknown): Promise<{ content: Array<TextContent | ImageContent | EmbeddedResource> }> {
    // Validate input
    const input = SEARCH_TOOL_SCHEMA.parse(args);
    
    // Create cache key
    const cacheKey = JSON.stringify(input);
    
    // Check cache
    const cached = this.cache.get(cacheKey);
    if (cached) {
      return this.formatSearchResult(cached, true);
    }

    // Make API call
    const result = await this.apiClient.search(
      input.query,
      input.model,
      input.options || {},
    );

    // Store in cache
    this.cache.set(cacheKey, result);

    return this.formatSearchResult(result, false);
  }

  private async handleProSearch(args: unknown): Promise<{ content: Array<TextContent | ImageContent | EmbeddedResource> }> {
    // Validate input
    const input = PRO_SEARCH_TOOL_SCHEMA.parse(args);
    
    // Create cache key
    const cacheKey = `pro_${JSON.stringify(input)}`;
    
    // Check cache
    const cached = this.cache.get(cacheKey);
    if (cached) {
      return this.formatSearchResult(cached, true);
    }

    // Make API call with enhanced options
    const result = await this.apiClient.search(
      input.query,
      input.model,
      input.options || {},
    );

    // Store in cache
    this.cache.set(cacheKey, result);

    return this.formatSearchResult(result, false);
  }

  private async handleDeepResearch(args: unknown): Promise<{ content: Array<TextContent | ImageContent | EmbeddedResource> }> {
    // Validate input
    const input = DEEP_RESEARCH_TOOL_SCHEMA.parse(args);
    
    // Create cache key
    const cacheKey = `deep_${JSON.stringify(input)}`;
    
    // Check cache
    const cached = this.cache.get(cacheKey);
    if (cached) {
      return this.formatSearchResult(cached, true);
    }

    // Make API call
    const result = await this.apiClient.deepResearch(
      input.topic,
      input.depth,
      input.focus_areas,
    );

    // Store in cache
    this.cache.set(cacheKey, result);

    return this.formatSearchResult(result, false);
  }

  private async handleReasoning(args: unknown): Promise<{ content: Array<TextContent | ImageContent | EmbeddedResource> }> {
    // Validate input
    const input = REASONING_TOOL_SCHEMA.parse(args);
    
    // Create cache key
    const cacheKey = `reasoning_${JSON.stringify(input)}`;
    
    // Check cache
    const cached = this.cache.get(cacheKey);
    if (cached) {
      return this.formatSearchResult(cached, true);
    }

    // Build query with context if provided
    let fullQuery = input.query;
    if (input.context) {
      fullQuery = `Context: ${input.context}\n\nQuery: ${input.query}`;
    }

    // Make API call using reasoning model
    const result = await this.apiClient.search(
      fullQuery,
      input.model,
      {
        return_citations: true,
        return_related_questions: true,
      },
    );

    // Store in cache
    this.cache.set(cacheKey, result);

    return this.formatSearchResult(result, false);
  }

  private formatSearchResult(
    result: SearchResult,
    fromCache: boolean,
  ): { content: Array<TextContent | ImageContent | EmbeddedResource> } {
    const content: Array<TextContent | ImageContent | EmbeddedResource> = [];

    // Add main content
    let text = result.content;

    // Add citations if available
    if (result.citations.length > 0) {
      text += '\n\n## 參考來源\n';
      result.citations.forEach((citation, index) => {
        text += `${index + 1}. [${citation.title}](${citation.url})`;
        if (citation.snippet) {
          text += `\n   ${citation.snippet}`;
        }
        text += '\n';
      });
    }

    // Add related questions if available
    if (result.related_questions.length > 0) {
      text += '\n\n## 相關問題\n';
      result.related_questions.forEach((question) => {
        text += `- ${question}\n`;
      });
    }

    // Add cache indicator
    if (fromCache) {
      text += '\n\n*（此結果來自快取）*';
    }

    content.push({
      type: 'text',
      text,
    });

    // Add images if available
    if (result.images.length > 0) {
      result.images.forEach((imageUrl) => {
        content.push({
          type: 'image',
          data: imageUrl,
          mimeType: 'image/jpeg', // Assume JPEG, could be improved
        });
      });
    }

    return { content };
  }

  getServer(): Server {
    return this.server;
  }

  async start(transportOptions?: TransportOptions): Promise<void> {
    const transport = transportOptions || { type: 'stdio' };
    
    switch (transport.type) {
      case 'stdio':
        await this.startStdio();
        break;
        
      case 'http':
        await this.startHttp(transport.port || 3000, transport.host);
        break;
        
      default:
        throw new Error(`Unknown transport type: ${transport.type}`);
    }
  }

  private async startStdio(): Promise<void> {
    const transport = new StdioServerTransport();
    await this.server.connect(transport);
    
    if (this.config.debug) {
      console.error('Perplexity MCP Server started (stdio mode)');
    }
  }

  private async startHttp(port: number, host?: string): Promise<void> {
    const httpConfig: HttpServerConfig = {
      port,
      host,
      security: {
        corsOrigins: process.env.PERPLEXITY_CORS_ORIGINS?.split(','),
        bearerToken: process.env.PERPLEXITY_BEARER_TOKEN,
        rateLimit: process.env.PERPLEXITY_RATE_LIMIT ? {
          windowMs: 60000, // 1 minute
          maxRequests: parseInt(process.env.PERPLEXITY_RATE_LIMIT, 10),
        } : undefined,
      },
    };
    
    this.httpServer = new PerplexityHttpServer(this, httpConfig);
    await this.httpServer.start();
    
    if (this.config.debug) {
      console.error(`Perplexity MCP Server started (HTTP mode on port ${port})`);
    }
  }

  async stop(): Promise<void> {
    if (this.httpServer) {
      await this.httpServer.stop();
    }
  }
}