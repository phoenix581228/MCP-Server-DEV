#!/bin/bash
# Serena MCP Server 執行腳本

# 設定絕對路徑
PROJECT_DIR="/Users/chih-hungtseng/projects/MCP-Server-DEV/serena-mcp-server"
PYTHON_BIN="/Users/chih-hungtseng/projects/bin/python3"

# 確保 PATH 包含 uv 的安裝目錄
export PATH="$HOME/.local/bin:$PATH"

# 設定預設值
SERENA_PROJECT=${1:-$(pwd)}
SERENA_CONTEXT=${SERENA_CONTEXT:-ide-assistant}
SERENA_MODE=${SERENA_MODE:-}
SERENA_LOG_LEVEL=${SERENA_LOG_LEVEL:-INFO}
SERENA_TRANSPORT=${SERENA_TRANSPORT:-stdio}

# 顏色定義
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 顯示啟動資訊
echo -e "${GREEN}====================================${NC}"
echo -e "${GREEN}Serena MCP Server${NC}"
echo -e "${GREEN}====================================${NC}"
echo ""
echo "專案目錄: $SERENA_PROJECT"
echo "上下文: $SERENA_CONTEXT"
echo "模式: ${SERENA_MODE:-default}"
echo "日誌等級: $SERENA_LOG_LEVEL"
echo "傳輸協議: $SERENA_TRANSPORT"
echo ""

# 檢查專案配置
if [ -f "$SERENA_PROJECT/.serena/project.yml" ]; then
    echo -e "${GREEN}✓${NC} 找到專案配置: $SERENA_PROJECT/.serena/project.yml"
else
    echo -e "${YELLOW}!${NC} 未找到專案配置，將使用預設設定"
fi

# 檢查 uv 是否安裝
if ! command -v uv >/dev/null 2>&1; then
    echo -e "${RED}✗${NC} uv 未安裝，請先執行 install.sh"
    exit 1
fi

# 構建參數
ARGS=(
    "--from" "git+https://github.com/oraios/serena"
    "serena-mcp-server"
    "--context" "$SERENA_CONTEXT"
    "--project" "$SERENA_PROJECT"
    "--transport" "$SERENA_TRANSPORT"
)

# 添加模式（如果指定）
if [ -n "$SERENA_MODE" ]; then
    ARGS+=("--mode" "$SERENA_MODE")
fi

# 設定環境變數
export SERENA_LOG_LEVEL
export PYTHONUNBUFFERED=1

# 執行 Serena
echo -e "${GREEN}啟動 Serena MCP Server...${NC}"
echo ""
exec uvx "${ARGS[@]}"