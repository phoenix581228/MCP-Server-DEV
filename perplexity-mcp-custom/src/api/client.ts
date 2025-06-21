import { PerplexityAPIError, SearchResult, SearchOptions, PerplexityModel } from '../types/index.js';

export class PerplexityAPIClient {
  private readonly baseURL: string;
  private readonly apiKey: string;
  private readonly debug: boolean;

  constructor(apiKey: string, baseURL = 'https://api.perplexity.ai', debug = false) {
    if (!apiKey) {
      throw new Error('Perplexity API key is required');
    }
    this.apiKey = apiKey;
    this.baseURL = baseURL;
    this.debug = debug;
  }

  async search(
    query: string,
    model: PerplexityModel = 'sonar-pro',
    options: SearchOptions = {},
  ): Promise<SearchResult> {
    const requestBody = {
      model,
      messages: [
        {
          role: 'user',
          content: query,
        },
      ],
      ...this.transformOptions(options),
    };

    if (this.debug) {
      console.error('Perplexity API Request:', JSON.stringify(requestBody, null, 2));
    }

    try {
      const response = await fetch(`${this.baseURL}/chat/completions`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${this.apiKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(requestBody),
      });

      if (!response.ok) {
        const errorText = await response.text();
        throw new PerplexityAPIError(response.status, errorText);
      }

      const data = await response.json();
      
      if (this.debug) {
        console.error('Perplexity API Response:', JSON.stringify(data, null, 2));
      }

      return this.formatResponse(data);
    } catch (error) {
      if (error instanceof PerplexityAPIError) {
        throw error;
      }
      throw new Error(`Failed to connect to Perplexity API: ${(error as Error).message}`);
    }
  }

  async deepResearch(
    topic: string,
    depth: 'quick' | 'standard' | 'comprehensive' = 'standard',
    focusAreas?: string[],
  ): Promise<SearchResult> {
    // Deep research 使用 sonar-deep-research 模型
    const query = this.buildDeepResearchQuery(topic, depth, focusAreas);
    return this.search(query, 'sonar-deep-research');
  }

  private transformOptions(options: SearchOptions): Record<string, unknown> {
    const transformed: Record<string, unknown> = {};

    if (options.search_domain) {
      transformed.search_domain = options.search_domain;
    }

    if (options.search_recency) {
      transformed.search_recency_filter = options.search_recency;
    }

    if (options.return_citations !== undefined) {
      transformed.return_citations = options.return_citations;
    }

    if (options.return_images !== undefined) {
      transformed.return_images = options.return_images;
    }

    if (options.return_related_questions !== undefined) {
      transformed.return_related_questions = options.return_related_questions;
    }

    return transformed;
  }

  private formatResponse(rawResponse: any): SearchResult {
    const message = rawResponse.choices?.[0]?.message;
    if (!message) {
      throw new Error('Invalid response format from Perplexity API');
    }

    // Format citations from search_results
    const citations = (rawResponse.search_results || []).map((result: any) => ({
      url: result.url,
      title: result.title,
      snippet: result.snippet || '',
    }));

    return {
      content: message.content || '',
      citations: citations,
      images: rawResponse.images || [],
      related_questions: rawResponse.related_questions || [],
    };
  }

  private buildDeepResearchQuery(
    topic: string,
    depth: 'quick' | 'standard' | 'comprehensive',
    focusAreas?: string[],
  ): string {
    let query = `Please conduct a ${depth} research on: ${topic}`;

    if (focusAreas && focusAreas.length > 0) {
      query += `\n\nFocus particularly on these areas:\n${focusAreas.map((area) => `- ${area}`).join('\n')}`;
    }

    switch (depth) {
      case 'quick':
        query += '\n\nProvide a brief overview with key points.';
        break;
      case 'comprehensive':
        query += '\n\nProvide an in-depth analysis with detailed explanations, examples, and comprehensive coverage.';
        break;
      default:
        query += '\n\nProvide a balanced analysis with reasonable depth.';
    }

    return query;
  }
}