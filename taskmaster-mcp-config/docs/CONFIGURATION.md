# Claude Task Master 詳細配置指南

本文檔詳細說明 Claude Task Master 的所有配置選項和最佳實踐。

## 目錄

1. [配置檔案結構](#配置檔案結構)
2. [環境變數配置](#環境變數配置)
3. [AI 模型配置](#ai-模型配置)
4. [全域設定](#全域設定)
5. [進階配置](#進階配置)
6. [配置範例](#配置範例)

## 配置檔案結構

Task Master 使用多層配置系統：

```
優先級（高到低）：
1. 命令列參數
2. 環境變數
3. .taskmaster/config.json
4. 預設值
```

### 配置檔案位置

```
project-root/
├── .env                        # 環境變數（API keys）
├── .taskmaster/
│   ├── config.json            # 主要配置檔案
│   ├── tasks.json             # 任務資料
│   └── memory/                # 專案記憶
└── ~/.taskmaster/             # 全域配置（可選）
    └── global-config.json     # 全域預設值
```

## 環境變數配置

### 必需的 API Keys

至少需要配置一個 AI 提供者的 API key：

```bash
# Anthropic Claude（推薦）
ANTHROPIC_API_KEY=sk-ant-api03-xxxxx

# Perplexity（研究功能必需）
PERPLEXITY_API_KEY=pplx-xxxxx

# OpenAI
OPENAI_API_KEY=sk-xxxxx

# Google (Gemini)
GOOGLE_API_KEY=AIzaSyxxxxx

# Mistral
MISTRAL_API_KEY=xxxxx

# OpenRouter（支援多種模型）
OPENROUTER_API_KEY=sk-or-xxxxx

# X.AI (Grok)
XAI_API_KEY=xai-xxxxx

# Azure OpenAI
AZURE_OPENAI_API_KEY=xxxxx
AZURE_OPENAI_ENDPOINT=https://your-resource.openai.azure.com/
```

### Task Master 特定環境變數

```bash
# 專案設定
TASKMASTER_PROJECT_NAME="My Awesome Project"
TASKMASTER_DEFAULT_TAG=main

# 任務預設值
TASKMASTER_DEFAULT_SUBTASKS=5
TASKMASTER_DEFAULT_PRIORITY=medium  # low, medium, high

# 日誌設定
TASKMASTER_LOG_LEVEL=info          # debug, info, warn, error
TASKMASTER_DEBUG=false              # true 啟用詳細輸出

# 效能設定
TASKMASTER_MAX_CONCURRENT_TASKS=10
TASKMASTER_CACHE_TTL=3600          # 快取時間（秒）
```

### 端點覆蓋

```bash
# 使用自定義 API 端點
OPENAI_BASE_URL=https://api.custom-provider.com/v1
MISTRAL_BASE_URL=https://custom-mistral.com/api

# Ollama 本地模型
OLLAMA_BASE_URL=http://localhost:11434/api

# Google Vertex AI
VERTEX_PROJECT_ID=my-gcp-project
VERTEX_LOCATION=us-central1
GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
```

## AI 模型配置

### 基本配置結構

`.taskmaster/config.json`:

```json
{
  "models": {
    "main": {
      "provider": "anthropic",
      "modelId": "claude-3-5-sonnet",
      "maxTokens": 64000,
      "temperature": 0.2,
      "maxInputTokens": 100000,
      "maxOutputTokens": 8192
    },
    "research": {
      "provider": "perplexity",
      "modelId": "sonar-pro",
      "maxTokens": 8700,
      "temperature": 0.1
    },
    "fallback": {
      "provider": "openai",
      "modelId": "gpt-4o",
      "maxTokens": 16000,
      "temperature": 0.2
    }
  }
}
```

### 支援的 AI 提供者和模型

#### Anthropic Claude
```json
{
  "provider": "anthropic",
  "modelId": "claude-3-5-sonnet",     // 最新、最強大
  "modelId": "claude-3-opus",         // 高品質輸出
  "modelId": "claude-3-haiku",        // 快速、經濟
  "maxTokens": 64000,
  "temperature": 0.2
}
```

#### OpenAI
```json
{
  "provider": "openai",
  "modelId": "gpt-4o",                // 最新多模態
  "modelId": "gpt-4-turbo",           // 高性能
  "modelId": "gpt-3.5-turbo",         // 快速、經濟
  "maxTokens": 16000,
  "temperature": 0.2
}
```

#### Perplexity
```json
{
  "provider": "perplexity",
  "modelId": "sonar-pro",             // 深度研究
  "modelId": "sonar",                 // 標準研究
  "modelId": "sonar-deep-research",   // 最深入研究
  "maxTokens": 8700,
  "temperature": 0.1
}
```

#### Google Gemini
```json
{
  "provider": "google",
  "modelId": "gemini-2-flash",        // 快速
  "modelId": "gemini-2-pro",          // 專業
  "maxTokens": 32000,
  "temperature": 0.2
}
```

#### Ollama（本地模型）
```json
{
  "provider": "ollama",
  "modelId": "llama3.3:70b",         // 本地 LLaMA
  "modelId": "codellama:34b",        // 程式碼專用
  "modelId": "mixtral:8x7b",         // Mixtral
  "maxTokens": 4096,
  "temperature": 0.2,
  "baseURL": "http://localhost:11434/api"
}
```

### 角色特定配置

```json
{
  "models": {
    "main": {
      // 主要任務生成和管理
      "provider": "anthropic",
      "modelId": "claude-3-5-sonnet",
      "maxTokens": 64000,
      "temperature": 0.2,
      "systemPrompt": "You are a senior project manager..."
    },
    "research": {
      // 技術研究和資訊收集
      "provider": "perplexity",
      "modelId": "sonar-pro",
      "maxTokens": 8700,
      "temperature": 0.1,
      "includeSearch": true,
      "searchDepth": "comprehensive"
    },
    "fallback": {
      // 備用模型（當主模型失敗時）
      "provider": "openai",
      "modelId": "gpt-4o-mini",
      "maxTokens": 8000,
      "temperature": 0.3
    }
  }
}
```

## 全域設定

### 基本全域設定

```json
{
  "global": {
    // 日誌設定
    "logLevel": "info",              // debug, info, warn, error
    "debug": false,                  // 詳細調試輸出
    
    // 專案設定
    "projectName": "My Project",
    "projectDescription": "A revolutionary app",
    
    // 任務預設值
    "defaultSubtasks": 5,            // 預設子任務數量
    "defaultPriority": "medium",     // low, medium, high
    "defaultTag": "master",          // 預設標籤
    
    // 行為設定
    "autoSave": true,                // 自動儲存變更
    "autoBackup": true,              // 自動備份
    "backupInterval": 3600,          // 備份間隔（秒）
    
    // UI 設定
    "colorOutput": true,             // 彩色輸出
    "progressBar": true,             // 顯示進度條
    "verboseMode": false,            // 詳細模式
    
    // 限制設定
    "maxTasksPerPRD": 50,            // PRD 最大任務數
    "maxSubtasksPerTask": 10,        // 每任務最大子任務數
    "maxDependencyDepth": 5          // 最大依賴深度
  }
}
```

### 進階全域設定

```json
{
  "global": {
    // API 設定
    "apiTimeout": 30000,             // API 超時（毫秒）
    "maxRetries": 3,                 // 最大重試次數
    "retryDelay": 1000,              // 重試延遲（毫秒）
    
    // 快取設定
    "enableCache": true,             // 啟用快取
    "cacheSize": 100,                // 快取大小（MB）
    "cacheTTL": 3600,                // 快取存活時間（秒）
    
    // 並發設定
    "maxConcurrentRequests": 5,      // 最大並發請求
    "rateLimitPerMinute": 60,        // 每分鐘請求限制
    
    // 整合設定
    "enableGitIntegration": true,    // Git 整合
    "enableWebhooks": false,         // Webhook 支援
    "webhookUrl": "",                // Webhook URL
    
    // 安全設定
    "sanitizeOutput": true,          // 清理輸出
    "maskSensitiveData": true,       // 遮罩敏感資料
    "allowedFileTypes": [".txt", ".md", ".json"]
  }
}
```

## 進階配置

### 1. 多環境配置

建立環境特定配置：

```json
// .taskmaster/config.development.json
{
  "models": {
    "main": {
      "provider": "ollama",
      "modelId": "llama3.3:70b",
      "baseURL": "http://localhost:11434/api"
    }
  },
  "global": {
    "debug": true,
    "logLevel": "debug"
  }
}

// .taskmaster/config.production.json
{
  "models": {
    "main": {
      "provider": "anthropic",
      "modelId": "claude-3-5-sonnet"
    }
  },
  "global": {
    "debug": false,
    "logLevel": "error"
  }
}
```

使用環境變數切換：
```bash
export TASKMASTER_ENV=development
task-master list
```

### 2. 團隊共享配置

```json
// .taskmaster/team-config.json
{
  "team": {
    "name": "Development Team",
    "members": ["alice", "bob", "charlie"],
    "sharedModels": {
      "main": {
        "provider": "openrouter",
        "modelId": "anthropic/claude-3-5-sonnet",
        "apiKeyEnv": "TEAM_OPENROUTER_KEY"
      }
    },
    "permissions": {
      "alice": ["all"],
      "bob": ["read", "create", "update"],
      "charlie": ["read"]
    }
  }
}
```

### 3. 工作流配置

```json
{
  "workflows": {
    "prReview": {
      "triggers": ["pull_request"],
      "steps": [
        {
          "action": "validate-dependencies",
          "onError": "warn"
        },
        {
          "action": "check-completion",
          "onError": "block"
        },
        {
          "action": "generate-report",
          "output": "pr-comment"
        }
      ]
    },
    "dailyStandup": {
      "schedule": "0 9 * * *",
      "steps": [
        {
          "action": "list-in-progress",
          "format": "markdown"
        },
        {
          "action": "identify-blockers"
        },
        {
          "action": "suggest-next-tasks"
        }
      ]
    }
  }
}
```

### 4. 自定義提示模板

```json
{
  "prompts": {
    "taskGeneration": {
      "system": "You are an expert project manager specializing in {projectType}. Generate tasks that are specific, measurable, and actionable.",
      "variables": {
        "projectType": "web development",
        "techStack": ["React", "Node.js", "PostgreSQL"],
        "teamSize": 5
      }
    },
    "research": {
      "system": "You are a technical researcher. Focus on practical, implementation-ready solutions. Always cite sources.",
      "includeContext": true,
      "maxSources": 10
    }
  }
}
```

## 配置範例

### 最小配置（快速開始）

```json
{
  "models": {
    "main": {
      "provider": "anthropic",
      "modelId": "claude-3-5-sonnet"
    }
  }
}
```

### 標準配置（推薦）

```json
{
  "models": {
    "main": {
      "provider": "anthropic",
      "modelId": "claude-3-5-sonnet",
      "maxTokens": 64000,
      "temperature": 0.2
    },
    "research": {
      "provider": "perplexity",
      "modelId": "sonar-pro",
      "maxTokens": 8700,
      "temperature": 0.1
    },
    "fallback": {
      "provider": "openai",
      "modelId": "gpt-4o-mini",
      "maxTokens": 8000,
      "temperature": 0.3
    }
  },
  "global": {
    "projectName": "E-Commerce Platform",
    "logLevel": "info",
    "defaultPriority": "medium",
    "defaultSubtasks": 5,
    "autoSave": true
  }
}
```

### 企業級配置

```json
{
  "models": {
    "main": {
      "provider": "azure",
      "modelId": "gpt-4o",
      "baseURL": "https://company.openai.azure.com/",
      "maxTokens": 32000,
      "temperature": 0.2
    },
    "research": {
      "provider": "perplexity",
      "modelId": "sonar-pro",
      "maxTokens": 8700,
      "temperature": 0.1
    },
    "fallback": {
      "provider": "azure",
      "modelId": "gpt-35-turbo",
      "baseURL": "https://company.openai.azure.com/",
      "maxTokens": 4000,
      "temperature": 0.3
    }
  },
  "global": {
    "projectName": "Enterprise Application",
    "logLevel": "warn",
    "debug": false,
    "enableAudit": true,
    "auditLog": "/var/log/taskmaster/audit.log",
    "maxConcurrentRequests": 10,
    "rateLimitPerMinute": 100,
    "sanitizeOutput": true,
    "maskSensitiveData": true
  },
  "security": {
    "requireAuth": true,
    "authProvider": "ldap",
    "ldapServer": "ldap://company.com",
    "allowedDomains": ["@company.com"],
    "encryption": {
      "enabled": true,
      "algorithm": "aes-256-gcm"
    }
  }
}
```

## 配置驗證

使用內建命令驗證配置：

```bash
# 驗證配置檔案
task-master validate-config

# 測試 AI 模型連接
task-master test-models

# 顯示當前配置
task-master config --show

# 檢查環境變數
task-master config --check-env
```

## 最佳實踐

1. **安全性**：
   - 永遠不要將 API keys 存入版本控制
   - 使用環境變數管理敏感資訊
   - 定期輪換 API keys

2. **效能**：
   - 為不同任務類型使用適當的模型
   - 啟用快取減少 API 調用
   - 設定合理的並發限制

3. **可維護性**：
   - 使用描述性的專案名稱
   - 保持配置檔案簡潔
   - 記錄特殊配置的原因

4. **團隊協作**：
   - 共享基本配置
   - 個人化環境變數
   - 使用版本控制管理配置模板

---

**文檔版本**：1.0  
**更新日期**：2025-06-22