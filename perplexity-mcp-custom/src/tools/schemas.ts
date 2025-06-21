import { z } from 'zod';

export const SEARCH_TOOL_SCHEMA = z.object({
  query: z
    .string()
    .min(1, 'Query cannot be empty')
    .max(1000, 'Query too long')
    .describe('搜尋查詢字串'),
  model: z
    .enum(['sonar', 'sonar-pro', 'sonar-reasoning', 'sonar-reasoning-pro', 'sonar-deep-research'])
    .optional()
    .default('sonar-pro')
    .describe('Perplexity model to use'),
  options: z
    .object({
      search_domain: z.string().optional().describe('限定搜尋的網域'),
      search_recency: z
        .enum(['day', 'week', 'month', 'year'])
        .optional()
        .describe('搜尋時間範圍'),
      return_citations: z.boolean().optional().default(true).describe('是否返回引用來源'),
      return_images: z.boolean().optional().default(false).describe('是否返回圖片'),
      return_related_questions: z
        .boolean()
        .optional()
        .default(false)
        .describe('是否返回相關問題'),
    })
    .optional()
    .default({}),
});

export const PRO_SEARCH_TOOL_SCHEMA = z.object({
  query: z
    .string()
    .min(1, 'Query cannot be empty')
    .max(1000, 'Query too long')
    .describe('搜尋查詢字串'),
  model: z
    .enum(['sonar-pro', 'sonar-reasoning-pro'])
    .optional()
    .default('sonar-pro')
    .describe('Pro model to use'),
  options: z
    .object({
      search_domain: z.string().optional().describe('限定搜尋的網域'),
      search_recency: z
        .enum(['day', 'week', 'month', 'year'])
        .optional()
        .describe('搜尋時間範圍'),
      return_citations: z.boolean().optional().default(true).describe('是否返回引用來源'),
      return_images: z.boolean().optional().default(true).describe('是否返回圖片'),
      return_related_questions: z
        .boolean()
        .optional()
        .default(true)
        .describe('是否返回相關問題'),
    })
    .optional()
    .default({
      return_citations: true,
      return_images: true,
      return_related_questions: true,
    }),
});

export const REASONING_TOOL_SCHEMA = z.object({
  query: z
    .string()
    .min(1, 'Query cannot be empty')
    .max(1000, 'Query too long')
    .describe('推理查詢字串'),
  model: z
    .enum(['sonar-reasoning', 'sonar-reasoning-pro'])
    .optional()
    .default('sonar-reasoning')
    .describe('Reasoning model to use'),
  context: z
    .string()
    .optional()
    .describe('額外的上下文資訊'),
});

export const DEEP_RESEARCH_TOOL_SCHEMA = z.object({
  topic: z
    .string()
    .min(1, 'Topic cannot be empty')
    .max(500, 'Topic too long')
    .describe('研究主題'),
  depth: z
    .enum(['quick', 'standard', 'comprehensive'])
    .optional()
    .default('standard')
    .describe('研究深度'),
  focus_areas: z
    .array(z.string())
    .optional()
    .describe('重點研究領域'),
});

export type SearchToolInput = z.infer<typeof SEARCH_TOOL_SCHEMA>;
export type ProSearchToolInput = z.infer<typeof PRO_SEARCH_TOOL_SCHEMA>;
export type ReasoningToolInput = z.infer<typeof REASONING_TOOL_SCHEMA>;
export type DeepResearchToolInput = z.infer<typeof DEEP_RESEARCH_TOOL_SCHEMA>;