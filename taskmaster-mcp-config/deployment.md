# Claude Task Master MCP Server 部署指南

本指南詳細說明如何部署和配置 Claude Task Master MCP Server。

## 目錄

1. [系統需求](#系統需求)
2. [安裝步驟](#安裝步驟)
3. [配置方式](#配置方式)
4. [部署選項](#部署選項)
5. [驗證與測試](#驗證與測試)
6. [故障排除](#故障排除)

## 系統需求

### 最低需求
- Node.js 18.0 或更高版本
- npm 8.0 或更高版本
- 至少一個 AI 服務的 API key
- macOS、Linux 或 Windows（WSL）

### 建議配置
- Node.js 20.x（LTS）
- 4GB RAM（用於處理大型專案）
- 穩定的網路連接（用於 AI API 調用）

## 安裝步驟

### 1. 全域安裝（推薦）

```bash
# 使用 npm 全域安裝
npm install -g task-master-ai

# 或使用 npx 直接執行（無需安裝）
npx task-master-ai
```

### 2. 專案本地安裝

```bash
# 在專案目錄中
npm install task-master-ai

# 使用本地安裝
npx task-master
```

### 3. MCP Server 整合

#### 方式一：使用包裝腳本（推薦）

1. 建立包裝腳本：

```bash
cat << 'EOF' > ~/.claude-code-taskmaster.sh
#!/bin/bash

# Claude Task Master MCP Server 包裝腳本

# 載入環境變數
export ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:-your-key-here}"
export PERPLEXITY_API_KEY="${PERPLEXITY_API_KEY:-your-key-here}"
export OPENAI_API_KEY="${OPENAI_API_KEY:-your-key-here}"
export GOOGLE_API_KEY="${GOOGLE_API_KEY:-your-key-here}"

# 設定預設值
export TASKMASTER_PROJECT_NAME="${TASKMASTER_PROJECT_NAME:-Development Project}"
export TASKMASTER_DEFAULT_SUBTASKS="${TASKMASTER_DEFAULT_SUBTASKS:-5}"
export TASKMASTER_DEFAULT_PRIORITY="${TASKMASTER_DEFAULT_PRIORITY:-medium}"
export TASKMASTER_LOG_LEVEL="${TASKMASTER_LOG_LEVEL:-info}"

# 執行 Task Master MCP Server
exec npx -y task-master-ai
EOF

chmod +x ~/.claude-code-taskmaster.sh
```

2. 註冊到 Claude Code CLI：

```bash
# 專案範圍註冊
claude mcp add taskmaster ~/.claude-code-taskmaster.sh

# 或全域註冊（謹慎使用）
claude mcp add taskmaster ~/.claude-code-taskmaster.sh -s user
```

#### 方式二：直接配置

在 Claude Code 的 MCP 配置中添加：

```json
{
  "mcpServers": {
    "taskmaster": {
      "command": "npx",
      "args": ["-y", "task-master-ai"],
      "env": {
        "ANTHROPIC_API_KEY": "your-key-here",
        "PERPLEXITY_API_KEY": "your-key-here",
        "OPENAI_API_KEY": "your-key-here"
      }
    }
  }
}
```

## 配置方式

### 1. 環境變數配置

建立 `.env` 檔案：

```bash
cd /path/to/your/project
cp ~/.claude-code-taskmaster/.env.example .env
# 編輯 .env 填入您的 API keys
```

### 2. Task Master 專案配置

初始化專案：

```bash
task-master init
```

這將建立以下結構：

```
.taskmaster/
├── config.json      # AI 模型配置
├── tasks.json       # 任務資料
└── docs/
    └── prd.txt      # PRD 範本
```

### 3. AI 模型配置

編輯 `.taskmaster/config.json`：

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
      "modelId": "gpt-4o",
      "maxTokens": 16000,
      "temperature": 0.2
    }
  },
  "global": {
    "logLevel": "info",
    "debug": false,
    "defaultSubtasks": 5,
    "defaultPriority": "medium",
    "defaultTag": "master",
    "projectName": "Your Project Name"
  }
}
```

## 部署選項

### 1. 個人開發環境

適合個人專案和小型團隊：

```bash
# 初始化
task-master init

# 配置模型
task-master models --setup

# 開始使用
task-master parse-prd your-prd.txt
```

### 2. 團隊協作環境

使用 Git 管理任務：

```bash
# 建立任務標籤
task-master add-tag --from-branch

# 切換工作標籤
task-master use-tag feature-auth

# 同步任務
git add .taskmaster/tasks.json
git commit -m "Update tasks"
```

### 3. CI/CD 整合

在 CI/CD 流程中使用：

```yaml
# .github/workflows/tasks.yml
name: Task Management
on: [push, pull_request]

jobs:
  validate-tasks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
      - run: npm install -g task-master-ai
      - run: task-master validate-dependencies
```

## 驗證與測試

### 1. 基本功能測試

```bash
# 測試 MCP 連接
echo '{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0.0"}},"id":1}' | ~/.claude-code-taskmaster.sh

# 列出可用工具
echo '{"jsonrpc":"2.0","method":"tools/list","id":1}' | ~/.claude-code-taskmaster.sh
```

### 2. Claude Code 整合測試

在 Claude Code 中執行：

```
請列出 Task Master 的所有可用命令
```

預期回應應包含：
- task-master init
- task-master parse-prd
- task-master list
- task-master next
- 等等...

### 3. 任務管理測試

```bash
# 建立測試 PRD
cat > test-prd.txt << EOF
Create a simple todo app with:
- User authentication
- Task CRUD operations
- Priority management
EOF

# 解析 PRD
task-master parse-prd test-prd.txt

# 檢查生成的任務
task-master list
```

## 故障排除

### 常見問題

#### 1. API Key 錯誤

**問題**：`Error: Missing API key`

**解決方案**：
```bash
# 檢查環境變數
echo $ANTHROPIC_API_KEY

# 確保 .env 檔案存在
ls -la .env

# 重新載入環境變數
source ~/.claude-code-taskmaster.sh
```

#### 2. MCP 連接失敗

**問題**：`MCP connection timeout`

**解決方案**：
```bash
# 檢查 MCP 列表
claude mcp list

# 移除並重新添加
claude mcp remove taskmaster
claude mcp add taskmaster ~/.claude-code-taskmaster.sh
```

#### 3. 模型配置錯誤

**問題**：`Invalid model configuration`

**解決方案**：
```bash
# 驗證配置
task-master models

# 重新配置
task-master models --setup
```

#### 4. 任務檔案損壞

**問題**：`Invalid tasks.json`

**解決方案**：
```bash
# 備份現有檔案
cp .taskmaster/tasks.json .taskmaster/tasks.backup.json

# 重新初始化
task-master init --force
```

### 調試模式

啟用詳細日誌：

```bash
# 設定環境變數
export TASKMASTER_DEBUG=true
export TASKMASTER_LOG_LEVEL=debug

# 執行命令
task-master list
```

### 獲取幫助

1. **查看命令幫助**：
   ```bash
   task-master --help
   task-master [command] --help
   ```

2. **查看文檔**：
   - [官方文檔](https://github.com/eyaltoledano/claude-task-master)
   - [MCP 協議規範](https://modelcontextprotocol.io/)

3. **社區支援**：
   - GitHub Issues
   - Discord 社群

## 最佳實踐

1. **定期備份**：
   ```bash
   # 備份任務資料
   cp -r .taskmaster .taskmaster.backup
   ```

2. **版本控制**：
   - 將 `.taskmaster/tasks.json` 加入 Git
   - 忽略 `.env` 和敏感資料

3. **團隊協作**：
   - 使用標籤功能隔離不同功能的任務
   - 定期同步和解決衝突

4. **性能優化**：
   - 定期清理已完成的任務
   - 使用適當的 AI 模型避免過度消耗

---

**文檔版本**：1.0  
**更新日期**：2025-06-22