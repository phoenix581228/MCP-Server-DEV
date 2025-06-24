#!/bin/bash

# TaskMaster MCP Server 自動安裝腳本
# 使用現有環境變數，無需互動

set -e

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 配置
WRAPPER_SCRIPT="$HOME/.claude-code-taskmaster.sh"

echo -e "${BLUE}[開始]${NC} TaskMaster MCP Server 自動安裝"

# 檢查 Claude Code CLI
if ! command -v claude &> /dev/null; then
    echo -e "${RED}[錯誤]${NC} 未找到 Claude Code CLI"
    exit 1
fi

# 移除現有註冊
echo -e "${BLUE}[資訊]${NC} 清理現有註冊..."
claude mcp remove taskmaster 2>/dev/null || true
claude mcp remove taskmaster -s local 2>/dev/null || true
claude mcp remove taskmaster -s project 2>/dev/null || true
claude mcp remove taskmaster -s user 2>/dev/null || true

# 建立包裝腳本
echo -e "${BLUE}[資訊]${NC} 建立包裝腳本..."
cat << 'EOF' > "$WRAPPER_SCRIPT"
#!/bin/bash

# Claude Task Master MCP Server 包裝腳本

# 載入環境變數（使用現有的環境變數）
export ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY}"
export PERPLEXITY_API_KEY="${PERPLEXITY_API_KEY}"
export OPENAI_API_KEY="${OPENAI_API_KEY}"
export GOOGLE_API_KEY="${GOOGLE_API_KEY}"

# TaskMaster 配置
export TASKMASTER_PROJECT_NAME="${TASKMASTER_PROJECT_NAME:-MCP-Server-DEV}"
export TASKMASTER_DEFAULT_SUBTASKS="${TASKMASTER_DEFAULT_SUBTASKS:-5}"
export TASKMASTER_DEFAULT_PRIORITY="${TASKMASTER_DEFAULT_PRIORITY:-medium}"
export TASKMASTER_LOG_LEVEL="${TASKMASTER_LOG_LEVEL:-info}"

# 執行 Task Master MCP Server
exec npx -y task-master-ai
EOF

chmod +x "$WRAPPER_SCRIPT"
echo -e "${GREEN}[成功]${NC} 包裝腳本建立完成"

# 註冊到 Claude Code（專案範圍）
echo -e "${BLUE}[資訊]${NC} 註冊 TaskMaster 到 Claude Code..."
if claude mcp add taskmaster "$WRAPPER_SCRIPT"; then
    echo -e "${GREEN}[成功]${NC} TaskMaster 註冊成功"
else
    echo -e "${RED}[錯誤]${NC} 註冊失敗"
    exit 1
fi

# 驗證安裝
echo -e "${BLUE}[資訊]${NC} 驗證安裝..."
if claude mcp list | grep -q "taskmaster"; then
    echo -e "${GREEN}[成功]${NC} 安裝驗證通過"
    
    echo
    echo -e "${GREEN}✅ TaskMaster 安裝完成！${NC}"
    echo
    echo "可用命令："
    echo "- task-master init"
    echo "- task-master parse-prd"
    echo "- task-master list"
    echo "- task-master next"
    echo
    echo "在 Claude Code 中輸入：\"請列出 Task Master 的所有命令\""
else
    echo -e "${RED}[錯誤]${NC} 安裝驗證失敗"
    exit 1
fi