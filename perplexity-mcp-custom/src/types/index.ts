export interface ServerConfig {
  apiKey?: string;
  baseUrl?: string;
  model?: PerplexityModel;
  debug?: boolean;
}

export type PerplexityModel = 'sonar' | 'sonar-pro' | 'sonar-reasoning' | 'sonar-reasoning-pro' | 'sonar-deep-research';

export interface SearchOptions {
  search_domain?: string;
  search_recency?: 'day' | 'week' | 'month' | 'year';
  return_citations?: boolean;
  return_images?: boolean;
  return_related_questions?: boolean;
}

export interface SearchResult {
  content: string;
  citations: Citation[];
  images: string[];
  related_questions: string[];
}

export interface Citation {
  url: string;
  title: string;
  snippet?: string;
}

export interface DeepResearchOptions {
  depth: 'quick' | 'standard' | 'comprehensive';
  focus_areas?: string[];
}

export class PerplexityAPIError extends Error {
  constructor(
    public status: number,
    message: string,
  ) {
    super(message);
    this.name = 'PerplexityAPIError';
  }
}