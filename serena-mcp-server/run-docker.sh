#!/bin/bash
# Serena MCP Server Docker 執行腳本

# 設定預設值
PROJECT_PATH=${1:-$(pwd)}
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
echo -e "${GREEN}Serena MCP Server (Docker)${NC}"
echo -e "${GREEN}====================================${NC}"
echo ""
echo "專案目錄: $PROJECT_PATH"
echo "上下文: $SERENA_CONTEXT"
echo "模式: ${SERENA_MODE:-default}"
echo "日誌等級: $SERENA_LOG_LEVEL"
echo "傳輸協議: $SERENA_TRANSPORT"
echo ""

# 檢查 Docker
if ! command -v docker >/dev/null 2>&1; then
    echo -e "${RED}✗${NC} Docker 未安裝"
    exit 1
fi

# 檢查 Docker 是否運行
if ! docker info >/dev/null 2>&1; then
    echo -e "${RED}✗${NC} Docker 未運行"
    exit 1
fi

# 匯出環境變數
export PROJECT_PATH
export SERENA_CONTEXT
export SERENA_MODE
export SERENA_LOG_LEVEL
export SERENA_TRANSPORT

# 執行方式
case "$SERENA_TRANSPORT" in
    stdio)
        echo -e "${GREEN}使用 stdio 傳輸模式${NC}"
        docker run --rm -i \
            --network host \
            -v "$PROJECT_PATH:/workspace:ro" \
            -e SERENA_CONTEXT \
            -e SERENA_MODE \
            -e SERENA_LOG_LEVEL \
            ghcr.io/oraios/serena:latest \
            serena-mcp-server \
            --transport stdio \
            --context "$SERENA_CONTEXT" \
            --project /workspace
        ;;
    sse)
        echo -e "${GREEN}使用 SSE 傳輸模式${NC}"
        echo "啟動 Docker Compose..."
        docker-compose -f "$(dirname "$0")/docker-compose.yml" up
        ;;
    *)
        echo -e "${RED}不支援的傳輸模式: $SERENA_TRANSPORT${NC}"
        exit 1
        ;;
esac