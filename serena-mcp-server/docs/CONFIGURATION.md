# Serena MCP Server 配置指南

本文檔詳細說明 Serena MCP Server 的配置選項和最佳實踐。

## 配置檔案結構

Serena 使用兩層配置系統：

1. **全域配置** (`serena_config.yml`) - Serena 的一般設定
2. **專案配置** (`.serena/project.yml`) - 特定專案的設定

## 全域配置 (serena_config.yml)

### 基本結構

```yaml
# serena_config.yml
version: "1.0"

# 日誌設定
logging:
  level: "INFO"  # DEBUG, INFO, WARNING, ERROR
  file: "serena.log"
  format: "%(asctime)s - %(name)s - %(levelname)s - %(message)s"

# Language Server 設定
language_servers:
  python:
    command: ["pylsp"]
    args: []
  typescript:
    command: ["typescript-language-server", "--stdio"]
    args: []
  java:
    auto_download: true
    version: "latest"

# 快取設定
cache:
  enabled: true
  directory: "~/.serena/cache"
  max_size: "1GB"
  ttl: 86400  # 秒

# 效能設定
performance:
  max_workers: 4
  timeout: 30  # 秒
  batch_size: 100
```

### 進階選項

```yaml
# 記憶體儲存
memory:
  backend: "file"  # file, sqlite, redis
  file:
    directory: "~/.serena/memory"
  sqlite:
    path: "~/.serena/memory.db"
  redis:
    url: "redis://localhost:6379"

# 安全設定
security:
  allowed_paths:
    - "/home/user/projects"
    - "/workspace"
  forbidden_paths:
    - "/etc"
    - "/var"
    - "~/.ssh"

# 擴展功能
extensions:
  enable_git_integration: true
  enable_docker_support: false
  enable_test_runner: true
```

## 專案配置 (.serena/project.yml)

### 基本範例

```yaml
# .serena/project.yml
name: "my-awesome-project"
description: "A great project using Serena"
language: "python"  # primary language
version: "1.0.0"

# 專案結構
structure:
  source_dirs:
    - "src"
    - "lib"
  test_dirs:
    - "tests"
    - "spec"
  ignore_patterns:
    - "*.pyc"
    - "__pycache__"
    - ".git"
    - "node_modules"

# 建置和測試命令
commands:
  build: "make build"
  test: "pytest"
  lint: "pylint src/"
  format: "black src/"
```

### 多語言專案

```yaml
name: "fullstack-app"
languages:
  - name: "python"
    paths: ["backend/"]
    config:
      interpreter: "python3.11"
      virtualenv: ".venv"
  - name: "typescript"
    paths: ["frontend/"]
    config:
      tsconfig: "frontend/tsconfig.json"
      node_version: "18"
```

### 自訂工具配置

```yaml
# 工具特定設定
tools:
  # 搜尋工具設定
  search:
    max_results: 100
    exclude_tests: false
    case_sensitive: false
  
  # 重構工具設定
  refactor:
    preserve_comments: true
    auto_format: true
    validation: "strict"
  
  # 記憶體工具設定
  memory:
    auto_save: true
    max_entries: 1000
    compression: true
```

## MCP 整合配置

### Claude Desktop 配置

在 Claude Desktop 的設定檔中：

```json
{
  "mcpServers": {
    "serena": {
      "command": "/path/to/uv",
      "args": [
        "run",
        "--directory",
        "/path/to/serena",
        "serena-mcp-server",
        "/path/to/project/.serena/project.yml",
        "--context",
        "ide-assistant"
      ]
    }
  }
}
```

### Claude Code CLI 配置

使用包裝腳本提供更靈活的配置：

```bash
#!/bin/bash
# serena-wrapper.sh

# 設定環境變數
export SERENA_CONFIG=/path/to/serena_config.yml
export SERENA_LOG_LEVEL=DEBUG
export SERENA_CACHE_DIR=/tmp/serena-cache

# 執行 Serena
exec uvx --from git+https://github.com/oraios/serena serena-mcp-server \
  --context ide-assistant \
  --project "$1" \
  --config "$SERENA_CONFIG"
```

然後註冊：

```bash
claude mcp add serena -- /path/to/serena-wrapper.sh $(pwd)
```

## 上下文 (Context) 配置

### 內建上下文

```yaml
# contexts/ide-assistant.yml
name: "ide-assistant"
prompt: |
  You are an IDE assistant focused on helping developers navigate and modify code.
  Prioritize accuracy and maintain code quality.
description: "Optimized for IDE integration"
excluded_tools:
  - "execute_shell_command"
```

### 自訂上下文

創建 `contexts/my-context.yml`：

```yaml
name: "code-reviewer"
prompt: |
  You are a senior code reviewer. Focus on:
  - Code quality and best practices
  - Security vulnerabilities
  - Performance issues
  - Maintainability
description: "Specialized for code review tasks"
excluded_tools:
  - "delete_lines"
  - "create_text_file"
additional_tools:
  - "security_scan"
  - "performance_profile"
```

使用自訂上下文：

```bash
serena-mcp-server --context code-reviewer
```

## 模式 (Mode) 配置

### 內建模式

```yaml
# modes/planning.yml
name: "planning"
prompt: |
  Focus on high-level planning and architecture.
  Break down complex tasks into manageable steps.
description: "Planning and architecture mode"
tool_modifications:
  think_about_task_adherence:
    priority: "high"
  execute_shell_command:
    enabled: false
```

### 組合模式

啟動時可以組合多個模式：

```bash
serena-mcp-server --mode planning --mode no-onboarding
```

## 環境變數

Serena 支援以下環境變數：

| 變數名稱 | 說明 | 預設值 |
|---------|------|--------|
| `SERENA_CONFIG` | 配置檔案路徑 | `./serena_config.yml` |
| `SERENA_LOG_LEVEL` | 日誌級別 | `INFO` |
| `SERENA_CACHE_DIR` | 快取目錄 | `~/.serena/cache` |
| `SERENA_MEMORY_DIR` | 記憶體儲存目錄 | `~/.serena/memory` |
| `SERENA_DOCKER` | 是否在 Docker 中執行 | `0` |
| `SERENA_MAX_WORKERS` | 最大工作執行緒數 | `4` |
| `SERENA_TIMEOUT` | 操作超時時間（秒） | `30` |

## 效能優化配置

### 大型專案優化

```yaml
# 針對大型專案的配置
performance:
  max_workers: 8
  batch_size: 500
  cache:
    enabled: true
    preload: true
    size: "4GB"
  
indexing:
  enabled: true
  incremental: true
  exclude_patterns:
    - "*.min.js"
    - "dist/"
    - "build/"
    
language_servers:
  startup_timeout: 60
  idle_timeout: 300
  max_instances: 2
```

### 資源限制

```yaml
# 資源使用限制
limits:
  memory:
    max_heap: "2GB"
    max_cache: "1GB"
  cpu:
    max_usage: 80  # 百分比
  disk:
    max_temp: "5GB"
    cleanup_interval: 3600  # 秒
```

## 安全配置

### 路徑限制

```yaml
security:
  # 白名單模式
  allowed_paths:
    - "/home/user/projects"
    - "/workspace"
  
  # 黑名單（優先級高於白名單）
  forbidden_paths:
    - "**/.git/objects"
    - "**/.env"
    - "**/secrets"
    - "**/credentials"
  
  # 檔案類型限制
  allowed_extensions:
    - ".py"
    - ".js"
    - ".ts"
    - ".java"
    - ".md"
  
  # 操作限制
  readonly_mode: false
  disable_shell_commands: true
  max_file_size: "10MB"
```

### 敏感資料保護

```yaml
privacy:
  # 遮罩敏感資料
  mask_patterns:
    - regex: "api[_-]?key.*?=.*"
      replacement: "API_KEY=***"
    - regex: "password.*?=.*"
      replacement: "PASSWORD=***"
  
  # 排除敏感檔案
  exclude_files:
    - "**/*.pem"
    - "**/*.key"
    - "**/id_rsa*"
```

## 故障排除配置

### 偵錯模式

```yaml
debug:
  enabled: true
  verbose: true
  trace_calls: true
  dump_requests: true
  output_dir: "./debug_output"
  
  # Language Server 偵錯
  lsp_debug:
    enabled: true
    log_messages: true
    trace_file: "./lsp_trace.log"
```

### 錯誤處理

```yaml
error_handling:
  # 重試策略
  retry:
    max_attempts: 3
    backoff_factor: 2
    max_delay: 30
  
  # 錯誤回報
  reporting:
    enabled: true
    include_context: true
    sanitize_paths: true
  
  # 復原選項
  recovery:
    auto_restart_lsp: true
    clear_cache_on_error: false
    create_checkpoint: true
```

## 最佳實踐

1. **版本控制**：將 `.serena/project.yml` 加入版本控制
2. **環境分離**：為不同環境使用不同的配置檔案
3. **安全優先**：總是配置路徑限制和敏感資料保護
4. **效能監控**：定期檢查快取使用和 Language Server 效能
5. **備份配置**：定期備份全域配置和專案配置

## 配置驗證

驗證配置檔案的正確性：

```bash
# 驗證全域配置
serena-mcp-server --validate-config

# 驗證專案配置
serena-mcp-server --validate-project /path/to/project

# 顯示有效配置（合併後）
serena-mcp-server --show-config
```

---

如需更多協助，請參考 [故障排除指南](TROUBLESHOOTING.md) 或查看 [官方文檔](https://github.com/oraios/serena)。