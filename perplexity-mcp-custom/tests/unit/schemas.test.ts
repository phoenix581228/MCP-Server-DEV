import { describe, it, expect } from 'vitest';
import { SEARCH_TOOL_SCHEMA, DEEP_RESEARCH_TOOL_SCHEMA } from '../../src/tools/schemas';

describe('Search Tool Schema', () => {
  it('should validate valid search input', () => {
    const validInput = {
      query: 'What is Model Context Protocol?',
      model: 'sonar-pro',
      options: {
        return_citations: true,
        search_recency: 'week',
      },
    };

    const result = SEARCH_TOOL_SCHEMA.safeParse(validInput);
    expect(result.success).toBe(true);
    if (result.success) {
      expect(result.data.query).toBe(validInput.query);
      expect(result.data.model).toBe('sonar-pro');
      expect(result.data.options?.return_citations).toBe(true);
    }
  });

  it('should use default values', () => {
    const minimalInput = {
      query: 'test query',
    };

    const result = SEARCH_TOOL_SCHEMA.safeParse(minimalInput);
    expect(result.success).toBe(true);
    if (result.success) {
      expect(result.data.model).toBe('sonar-pro');
      expect(result.data.options).toEqual({
        return_citations: true,
        return_images: false,
        return_related_questions: false,
      });
    }
  });

  it('should reject empty query', () => {
    const invalidInput = {
      query: '',
    };

    const result = SEARCH_TOOL_SCHEMA.safeParse(invalidInput);
    expect(result.success).toBe(false);
  });

  it('should reject query that is too long', () => {
    const invalidInput = {
      query: 'a'.repeat(1001),
    };

    const result = SEARCH_TOOL_SCHEMA.safeParse(invalidInput);
    expect(result.success).toBe(false);
  });

  it('should reject invalid model', () => {
    const invalidInput = {
      query: 'test',
      model: 'invalid-model',
    };

    const result = SEARCH_TOOL_SCHEMA.safeParse(invalidInput);
    expect(result.success).toBe(false);
  });

  it('should reject invalid search_recency', () => {
    const invalidInput = {
      query: 'test',
      options: {
        search_recency: 'invalid',
      },
    };

    const result = SEARCH_TOOL_SCHEMA.safeParse(invalidInput);
    expect(result.success).toBe(false);
  });
});

describe('Deep Research Tool Schema', () => {
  it('should validate valid deep research input', () => {
    const validInput = {
      topic: 'Quantum Computing Applications',
      depth: 'comprehensive',
      focus_areas: ['Healthcare', 'Cryptography'],
    };

    const result = DEEP_RESEARCH_TOOL_SCHEMA.safeParse(validInput);
    expect(result.success).toBe(true);
    if (result.success) {
      expect(result.data.topic).toBe(validInput.topic);
      expect(result.data.depth).toBe('comprehensive');
      expect(result.data.focus_areas).toEqual(validInput.focus_areas);
    }
  });

  it('should use default depth', () => {
    const minimalInput = {
      topic: 'AI Ethics',
    };

    const result = DEEP_RESEARCH_TOOL_SCHEMA.safeParse(minimalInput);
    expect(result.success).toBe(true);
    if (result.success) {
      expect(result.data.depth).toBe('standard');
    }
  });

  it('should reject empty topic', () => {
    const invalidInput = {
      topic: '',
    };

    const result = DEEP_RESEARCH_TOOL_SCHEMA.safeParse(invalidInput);
    expect(result.success).toBe(false);
  });

  it('should reject topic that is too long', () => {
    const invalidInput = {
      topic: 'a'.repeat(501),
    };

    const result = DEEP_RESEARCH_TOOL_SCHEMA.safeParse(invalidInput);
    expect(result.success).toBe(false);
  });

  it('should accept empty focus_areas', () => {
    const validInput = {
      topic: 'Climate Change',
      focus_areas: [],
    };

    const result = DEEP_RESEARCH_TOOL_SCHEMA.safeParse(validInput);
    expect(result.success).toBe(true);
  });
});