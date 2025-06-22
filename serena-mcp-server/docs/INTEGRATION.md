# Serena MCP Server 整合指南

本文檔詳細說明如何將 Serena MCP Server 整合到不同的開發環境和工作流程中。

## Claude Code CLI 整合

### 基本整合

最簡單的整合方式：

```bash
# 使用 uvx
claude mcp add serena -- uvx --from git+https://github.com/oraios/serena serena-mcp-server

# 使用 Docker
claude mcp add serena -- docker run --rm -i --network host -v "$(pwd):/workspace" ghcr.io/oraios/serena:latest serena-mcp-server --transport stdio

# 使用本地安裝
claude mcp add serena -- /path/to/uv run --directory /path/to/serena serena-mcp-server
```

### 進階整合（推薦）

#### 1. 建立包裝腳本

創建 `~/.serena/run-serena.sh`：

```bash
#!/bin/bash
# Serena MCP Server 包裝腳本

# 設定預設值
SERENA_PROJECT=${1:-$(pwd)}
SERENA_CONTEXT=${SERENA_CONTEXT:-ide-assistant}
SERENA_MODE=${SERENA_MODE:-}
SERENA_LOG_LEVEL=${SERENA_LOG_LEVEL:-INFO}

# 檢查專案配置
if [ ! -f "$SERENA_PROJECT/.serena/project.yml" ]; then
    echo "警告：專案配置不存在，將使用預設設定" >&2
fi

# 構建參數
ARGS=(
    "--from" "git+https://github.com/oraios/serena"
    "serena-mcp-server"
    "--context" "$SERENA_CONTEXT"
    "--project" "$SERENA_PROJECT"
)

# 添加模式（如果指定）
if [ -n "$SERENA_MODE" ]; then
    ARGS+=("--mode" "$SERENA_MODE")
fi

# 執行 Serena
exec uvx "${ARGS[@]}"
```

賦予執行權限：

```bash
chmod +x ~/.serena/run-serena.sh
```

#### 2. 註冊到 Claude Code CLI

```bash
claude mcp add serena -- ~/.serena/run-serena.sh $(pwd)
```

#### 3. 使用環境變數自訂行為

```bash
# 使用規劃模式
SERENA_MODE=planning claude

# 使用除錯日誌
SERENA_LOG_LEVEL=DEBUG claude

# 使用不同的上下文
SERENA_CONTEXT=code-reviewer claude
```

### 專案特定配置

#### 1. 創建專案配置

在專案根目錄：

```bash
mkdir -p .serena
cat > .serena/project.yml << EOF
name: "my-project"
language: "python"
description: "My awesome Python project"

structure:
  source_dirs: ["src", "lib"]
  test_dirs: ["tests"]
  
commands:
  test: "pytest"
  lint: "pylint src/"
  format: "black src/"
EOF
```

#### 2. 創建專案特定的 MCP 配置

`.serena/mcp-config.json`:

```json
{
  "name": "serena-myproject",
  "description": "Serena for My Project",
  "tools": {
    "excluded": ["execute_shell_command"],
    "custom_prompts": {
      "onboarding": "Focus on Django-specific patterns and structure"
    }
  }
}
```

#### 3. 使用專案配置

```bash
# 在專案目錄中
claude mcp add serena-myproject -- ~/.serena/run-serena.sh $(pwd)
```

## VS Code 整合

雖然 Serena 主要設計用於 Claude，但可以透過 MCP 橋接整合到 VS Code。

### 1. 安裝 MCP 擴展

（假設有相容的 VS Code MCP 擴展）

### 2. 配置 settings.json

```json
{
  "mcp.servers": {
    "serena": {
      "command": "uvx",
      "args": [
        "--from",
        "git+https://github.com/oraios/serena",
        "serena-mcp-server",
        "--context",
        "ide-assistant",
        "--project",
        "${workspaceFolder}"
      ]
    }
  }
}
```

## CI/CD 整合

### GitHub Actions

`.github/workflows/code-analysis.yml`:

```yaml
name: Serena Code Analysis

on: [push, pull_request]

jobs:
  analyze:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.11'
    
    - name: Install uv
      run: |
        curl -LsSf https://astral.sh/uv/install.sh | sh
        echo "$HOME/.local/bin" >> $GITHUB_PATH
    
    - name: Run Serena Analysis
      run: |
        # 創建專案配置
        mkdir -p .serena
        echo "name: ${{ github.repository }}" > .serena/project.yml
        echo "language: python" >> .serena/project.yml
        
        # 執行分析
        uvx --from git+https://github.com/oraios/serena serena-cli analyze \
          --output-format json \
          --output-file serena-report.json
    
    - name: Upload Analysis Report
      uses: actions/upload-artifact@v3
      with:
        name: serena-analysis
        path: serena-report.json
```

### GitLab CI

`.gitlab-ci.yml`:

```yaml
serena-analysis:
  stage: test
  image: python:3.11
  
  before_script:
    - curl -LsSf https://astral.sh/uv/install.sh | sh
    - export PATH="$HOME/.local/bin:$PATH"
  
  script:
    - mkdir -p .serena
    - |
      cat > .serena/project.yml << EOF
      name: "$CI_PROJECT_NAME"
      language: "python"
      EOF
    - uvx --from git+https://github.com/oraios/serena serena-cli analyze
  
  artifacts:
    reports:
      junit: serena-report.xml
```

## Docker Compose 整合

`docker-compose.yml`:

```yaml
version: '3.8'

services:
  app:
    build: .
    volumes:
      - .:/app
    environment:
      - SERENA_ENABLED=true

  serena:
    image: ghcr.io/oraios/serena:latest
    volumes:
      - .:/workspace:ro
      - serena-cache:/cache
    environment:
      - SERENA_CACHE_DIR=/cache
      - SERENA_PROJECT=/workspace
    ports:
      - "9121:9121"  # MCP 端口
      - "24282:24282"  # Dashboard 端口
    command: serena-mcp-server --transport sse --port 9121

volumes:
  serena-cache:
```

## 團隊協作整合

### 1. 共享配置

創建團隊配置倉庫：

```bash
# serena-team-config/
├── contexts/
│   ├── backend-dev.yml
│   ├── frontend-dev.yml
│   └── code-review.yml
├── modes/
│   ├── strict-typing.yml
│   └── performance-focus.yml
└── projects/
    ├── api-server.yml
    ├── web-client.yml
    └── mobile-app.yml
```

### 2. 團隊成員設定

```bash
# 克隆團隊配置
git clone https://github.com/team/serena-config ~/.serena-team

# 創建個人包裝腳本
cat > ~/.serena/team-wrapper.sh << 'EOF'
#!/bin/bash
TEAM_CONFIG_DIR=~/.serena-team
PROJECT_TYPE=${PROJECT_TYPE:-backend}

uvx --from git+https://github.com/oraios/serena serena-mcp-server \
  --context-dir "$TEAM_CONFIG_DIR/contexts" \
  --mode-dir "$TEAM_CONFIG_DIR/modes" \
  --project "$1" \
  --context "${PROJECT_TYPE}-dev"
EOF

chmod +x ~/.serena/team-wrapper.sh
```

### 3. 使用團隊配置

```bash
# 後端開發者
PROJECT_TYPE=backend claude mcp add serena -- ~/.serena/team-wrapper.sh $(pwd)

# 前端開發者
PROJECT_TYPE=frontend claude mcp add serena -- ~/.serena/team-wrapper.sh $(pwd)
```

## 自動化工作流程

### 1. Pre-commit Hook

`.pre-commit-config.yaml`:

```yaml
repos:
  - repo: local
    hooks:
      - id: serena-check
        name: Serena Code Check
        entry: bash -c 'uvx --from git+https://github.com/oraios/serena serena-cli check --modified-only'
        language: system
        types: [python]
        pass_filenames: false
```

### 2. 自動化重構腳本

`scripts/serena-refactor.sh`:

```bash
#!/bin/bash
# 自動化重構腳本

REFACTOR_TYPE=$1
TARGET_PATH=$2

# 創建臨時 MCP 客戶端配置
cat > /tmp/serena-refactor.json << EOF
{
  "task": "refactor",
  "type": "$REFACTOR_TYPE",
  "target": "$TARGET_PATH",
  "options": {
    "preserve_tests": true,
    "update_imports": true,
    "create_backup": true
  }
}
EOF

# 執行重構
uvx --from git+https://github.com/oraios/serena serena-cli \
  execute --task-file /tmp/serena-refactor.json

# 清理
rm /tmp/serena-refactor.json
```

## 監控和日誌

### 1. 集中式日誌

配置 Serena 將日誌發送到集中式系統：

```yaml
# serena_config.yml
logging:
  handlers:
    - type: file
      path: /var/log/serena/serena.log
    - type: syslog
      address: syslog.company.com:514
      facility: local0
    - type: http
      url: https://logs.company.com/api/v1/logs
      api_key: ${LOG_API_KEY}
```

### 2. Prometheus 指標

啟用 Prometheus 指標：

```bash
serena-mcp-server --metrics-port 9090
```

Prometheus 配置：

```yaml
scrape_configs:
  - job_name: 'serena'
    static_configs:
      - targets: ['localhost:9090']
    metrics_path: '/metrics'
```

### 3. 健康檢查

```bash
# 健康檢查端點
curl http://localhost:9121/health

# 預期回應
{
  "status": "healthy",
  "version": "1.0.0",
  "language_servers": {
    "python": "running",
    "typescript": "running"
  },
  "memory_usage": "45MB",
  "uptime": "2h 15m"
}
```

## 疑難排解

### 常見整合問題

1. **MCP 連線失敗**
   ```bash
   # 檢查 Serena 是否正在執行
   ps aux | grep serena-mcp-server
   
   # 檢查端口是否被佔用
   lsof -i :9121
   ```

2. **專案配置未載入**
   ```bash
   # 驗證配置
   serena-mcp-server --validate-project $(pwd)
   ```

3. **Language Server 問題**
   ```bash
   # 檢查 Language Server 狀態
   serena-mcp-server --lsp-status
   ```

### 除錯模式

啟用詳細除錯：

```bash
SERENA_LOG_LEVEL=DEBUG \
SERENA_TRACE_CALLS=1 \
SERENA_DUMP_MESSAGES=1 \
claude mcp add serena-debug -- ~/.serena/run-serena.sh $(pwd)
```

## 最佳實踐

1. **版本固定**：在生產環境中固定 Serena 版本
   ```bash
   uvx --from git+https://github.com/oraios/serena@v1.0.0 serena-mcp-server
   ```

2. **資源限制**：為 Docker 容器設定資源限制
   ```yaml
   deploy:
     resources:
       limits:
         cpus: '2'
         memory: 2G
   ```

3. **安全隔離**：使用唯讀掛載保護原始碼
   ```bash
   -v "$(pwd):/workspace:ro"
   ```

4. **定期更新**：設定自動更新檢查
   ```bash
   # cron job
   0 0 * * 1 uvx --from git+https://github.com/oraios/serena serena-cli update-check
   ```

---

更多資訊請參考 [配置指南](CONFIGURATION.md) 和 [工具參考](TOOLS_REFERENCE.md)。