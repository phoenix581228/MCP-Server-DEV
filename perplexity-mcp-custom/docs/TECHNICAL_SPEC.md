# Perplexity MCP Server 技術規格書

**版本**: 1.0.0  
**最後更新**: 2025-06-20  
**狀態**: Draft

## 一、系統架構

### 1.1 整體架構圖
```
┌─────────────────┐
│   Claude CLI    │
└────────┬────────┘
         │ stdio (JSON-RPC)
┌────────┴────────┐
│  MCP Transport  │
└────────┬────────┘
         │
┌────────┴────────┐     ┌──────────────┐
│ Perplexity MCP  │────►│ Perplexity   │
│    Server       │     │   API        │
└────────┬────────┘     └──────────────┘
         │
   ┌─────┴─────┬──────────┬────────────┐
   │           │          │            │
┌──┴───┐  ┌───┴──┐  ┌────┴────┐  ┌────┴────┐
│Tools │  │Cache │  │ Logger  │  │ Metrics │
└──────┘  └──────┘  └─────────┘  └─────────┘
```

### 1.2 核心模組

#### MCP Server Core
- 處理 JSON-RPC 請求
- 管理工具註冊
- 協議版本協商

#### Perplexity API Client
- API 認證管理
- 請求/回應處理
- 錯誤處理和重試

#### Tools Module
- 搜尋工具實作
- 深度研究工具
- Schema 驗證

#### Cache Module
- LRU 快取策略
- TTL 管理
- 快取統計

## 二、API 規格

### 2.1 Perplexity API

#### 端點
```
POST https://api.perplexity.ai/chat/completions
```

#### 請求格式
```typescript
interface PerplexityRequest {
  model: "sonar" | "sonar-pro" | "sonar-deep-research";
  messages: Array<{
    role: "user" | "assistant" | "system";
    content: string;
  }>;
  max_tokens?: number;
  temperature?: number;
  top_p?: number;
  search_domain?: string;
  search_recency?: "day" | "week" | "month" | "year";
  return_citations?: boolean;
  return_images?: boolean;
  return_related_questions?: boolean;
}
```

#### 回應格式
```typescript
interface PerplexityResponse {
  id: string;
  model: string;
  created: number;
  choices: Array<{
    index: number;
    message: {
      role: "assistant";
      content: string;
    };
    finish_reason: string;
  }>;
  citations?: string[];
  images?: string[];
  related_questions?: string[];
  usage: {
    prompt_tokens: number;
    completion_tokens: number;
    total_tokens: number;
  };
}
```

### 2.2 MCP 協議

#### 工具定義
```typescript
interface MCPTool {
  name: string;
  description?: string;
  inputSchema: JSONSchema;
}

type JSONSchema = {
  type: "object";
  properties?: Record<string, JSONSchemaProperty>;
  required?: string[];
  additionalProperties?: boolean;
};

type JSONSchemaProperty = {
  type: "string" | "number" | "boolean" | "array" | "object";
  description?: string;
  enum?: any[];
  default?: any;
  minimum?: number;
  maximum?: number;
  minLength?: number;
  maxLength?: number;
  pattern?: string;
  items?: JSONSchemaProperty;
  properties?: Record<string, JSONSchemaProperty>;
  required?: string[];
};
```

## 三、工具規格

### 3.1 搜尋工具 (perplexity_search)

#### 輸入 Schema
```json
{
  "type": "object",
  "properties": {
    "query": {
      "type": "string",
      "description": "搜尋查詢字串",
      "minLength": 1,
      "maxLength": 1000
    },
    "model": {
      "type": "string",
      "enum": ["sonar", "sonar-pro"],
      "default": "sonar-pro",
      "description": "使用的 Perplexity 模型"
    },
    "search_domain": {
      "type": "string",
      "description": "限制搜尋的網域，例如 'wikipedia.org'"
    },
    "search_recency": {
      "type": "string",
      "enum": ["day", "week", "month", "year"],
      "description": "結果時效性過濾"
    },
    "return_citations": {
      "type": "boolean",
      "default": true,
      "description": "是否返回引用來源"
    },
    "max_results": {
      "type": "integer",
      "minimum": 1,
      "maximum": 20,
      "default": 5,
      "description": "最大結果數量"
    }
  },
  "required": ["query"],
  "additionalProperties": false
}
```

#### 輸出格式
```typescript
interface SearchResult {
  content: Array<{
    type: "text";
    text: string;
  }>;
  citations?: Array<{
    title: string;
    url: string;
    snippet?: string;
  }>;
  metadata?: {
    model: string;
    tokens_used: number;
    search_time_ms: number;
  };
}
```

### 3.2 深度研究工具 (perplexity_deep_research)

#### 輸入 Schema
```json
{
  "type": "object",
  "properties": {
    "topic": {
      "type": "string",
      "description": "研究主題",
      "minLength": 1,
      "maxLength": 500
    },
    "depth": {
      "type": "string",
      "enum": ["quick", "standard", "comprehensive"],
      "default": "standard",
      "description": "研究深度級別"
    },
    "focus_areas": {
      "type": "array",
      "items": {
        "type": "string"
      },
      "maxItems": 5,
      "description": "重點研究領域"
    },
    "output_format": {
      "type": "string",
      "enum": ["summary", "detailed", "structured"],
      "default": "detailed",
      "description": "輸出格式"
    },
    "language": {
      "type": "string",
      "default": "zh-TW",
      "description": "輸出語言"
    }
  },
  "required": ["topic"],
  "additionalProperties": false
}
```

## 四、資料模型

### 4.1 快取資料結構
```typescript
interface CacheEntry {
  key: string;          // 快取鍵（query hash）
  value: SearchResult;  // 搜尋結果
  timestamp: number;    // 建立時間
  hits: number;         // 命中次數
  size: number;         // 資料大小（bytes）
}

interface CacheStats {
  totalEntries: number;
  totalSize: number;
  hitRate: number;
  evictions: number;
}
```

### 4.2 錯誤模型
```typescript
enum ErrorCode {
  // API 錯誤
  API_KEY_INVALID = "API_KEY_INVALID",
  API_QUOTA_EXCEEDED = "API_QUOTA_EXCEEDED",
  API_SERVER_ERROR = "API_SERVER_ERROR",
  
  // 輸入錯誤
  INVALID_INPUT = "INVALID_INPUT",
  SCHEMA_VALIDATION_FAILED = "SCHEMA_VALIDATION_FAILED",
  
  // 系統錯誤
  CACHE_ERROR = "CACHE_ERROR",
  NETWORK_ERROR = "NETWORK_ERROR",
  TIMEOUT_ERROR = "TIMEOUT_ERROR"
}

interface MCPError {
  code: ErrorCode;
  message: string;
  details?: any;
  timestamp: string;
  requestId?: string;
}
```

## 五、配置規格

### 5.1 環境變數
```bash
# 必需
PERPLEXITY_API_KEY=pplx-xxxxxxxxxxxxx

# 可選
PERPLEXITY_MODEL=sonar-pro          # 預設模型
PERPLEXITY_TIMEOUT=30000            # API 超時（毫秒）
PERPLEXITY_MAX_RETRIES=3            # 最大重試次數
PERPLEXITY_CACHE_TTL=3600           # 快取 TTL（秒）
PERPLEXITY_CACHE_MAX_SIZE=100       # 快取最大條目數
LOG_LEVEL=info                      # 日誌級別
```

### 5.2 配置檔案 (可選)
```json
{
  "api": {
    "key": "${PERPLEXITY_API_KEY}",
    "baseUrl": "https://api.perplexity.ai",
    "timeout": 30000,
    "retries": 3
  },
  "cache": {
    "enabled": true,
    "ttl": 3600,
    "maxSize": 100,
    "strategy": "lru"
  },
  "logging": {
    "level": "info",
    "format": "json"
  },
  "features": {
    "citations": true,
    "images": true,
    "relatedQuestions": true
  }
}
```

## 六、效能規格

### 6.1 效能目標
| 指標 | 目標值 | 測量方法 |
|------|--------|----------|
| 啟動時間 | < 1s | 冷啟動測量 |
| 平均回應時間 | < 200ms (cached) | P50 延遲 |
| 記憶體使用 | < 100MB | RSS 測量 |
| CPU 使用率 | < 5% (idle) | 平均使用率 |

### 6.2 並發處理
- 最大並發請求：10
- 請求佇列大小：50
- 超時時間：30 秒

### 6.3 快取策略
- 策略：LRU (Least Recently Used)
- 最大條目：100
- TTL：1 小時
- 最大大小：50MB

## 七、安全規格

### 7.1 認證
- API Key 必須通過環境變數提供
- 不允許在程式碼中硬編碼
- 支援金鑰輪換

### 7.2 資料保護
- 不儲存敏感查詢
- 快取資料加密（可選）
- 日誌脫敏

### 7.3 輸入驗證
- 嚴格的 Schema 驗證
- 輸入長度限制
- 特殊字元過濾

## 八、監控規格

### 8.1 健康檢查
```typescript
interface HealthStatus {
  status: "healthy" | "degraded" | "unhealthy";
  version: string;
  uptime: number;
  checks: {
    api: boolean;
    cache: boolean;
    memory: boolean;
  };
}
```

### 8.2 指標收集
```typescript
interface Metrics {
  requests: {
    total: number;
    success: number;
    failed: number;
    cached: number;
  };
  latency: {
    p50: number;
    p95: number;
    p99: number;
  };
  api: {
    calls: number;
    tokens: number;
    cost: number;
  };
}
```

## 九、相容性

### 9.1 Node.js 版本
- 最低：18.0.0
- 建議：20.0.0+
- 測試：18.x, 20.x, 22.x

### 9.2 MCP 協議版本
- 支援：2024-11-05, 2025-06-18
- 預設：2025-06-18

### 9.3 作業系統
- Linux (Ubuntu 20.04+)
- macOS (12.0+)
- Windows (10+, WSL2)

## 十、測試規格

### 10.1 測試覆蓋率要求
- 整體覆蓋率：> 80%
- 核心邏輯：> 90%
- 錯誤處理：100%

### 10.2 測試類型
1. **單元測試**
   - 工具邏輯
   - Schema 驗證
   - 快取機制

2. **整合測試**
   - API 整合
   - MCP 協議
   - 端到端流程

3. **效能測試**
   - 負載測試
   - 壓力測試
   - 記憶體洩漏測試

## 附錄

### A. 錯誤碼對照表
| 錯誤碼 | HTTP 狀態 | 描述 |
|-------|-----------|------|
| API_KEY_INVALID | 401 | API 金鑰無效 |
| API_QUOTA_EXCEEDED | 429 | 超過配額限制 |
| INVALID_INPUT | 400 | 輸入參數無效 |
| TIMEOUT_ERROR | 504 | 請求超時 |

### B. 版本相容性矩陣
| MCP Server | MCP Protocol | Node.js | 狀態 |
|------------|--------------|---------|------|
| 1.0.0 | 2025-06-18 | 20.x | 穩定 |
| 1.0.0 | 2024-11-05 | 20.x | 相容 |
| 1.0.0 | 2025-06-18 | 18.x | 測試 |