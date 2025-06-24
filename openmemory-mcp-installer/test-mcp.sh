#!/bin/bash

# OpenMemory MCP 測試腳本
# 用於驗證安裝是否成功

set -e

# 顏色定義
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}=== OpenMemory MCP Server 測試 ===${NC}"
echo ""

# 1. 檢查 Docker 服務
echo -e "${GREEN}[1/6] 檢查 Docker 服務...${NC}"

check_container() {
    local container=$1
    local name=$2
    
    if docker ps | grep -q "$container"; then
        echo -e "${GREEN}✅ $name 運行中${NC}"
        return 0
    else
        echo -e "${RED}❌ $name 未運行${NC}"
        return 1
    fi
}

# 檢查各個容器
SERVICES_OK=0
check_container "openmemory-postgres" "PostgreSQL" && ((SERVICES_OK++))
check_container "openmemory-qdrant" "Qdrant" && ((SERVICES_OK++))
check_container "openmemory-api" "API Server" && ((SERVICES_OK++))
check_container "openmemory-mcp" "MCP Bridge" && ((SERVICES_OK++))

echo "運行中的服務: $SERVICES_OK/4"
echo ""

# 2. 檢查端口
echo -e "${GREEN}[2/6] 檢查服務端口...${NC}"

check_port() {
    local port=$1
    local service=$2
    
    if nc -z localhost $port 2>/dev/null; then
        echo -e "${GREEN}✅ $service (port $port) 可訪問${NC}"
        return 0
    else
        echo -e "${RED}❌ $service (port $port) 無法訪問${NC}"
        return 1
    fi
}

PORTS_OK=0
check_port 8765 "API Server" && ((PORTS_OK++))
check_port 6333 "Qdrant" && ((PORTS_OK++))
check_port 5432 "PostgreSQL" && ((PORTS_OK++))
check_port 3000 "Web UI" && ((PORTS_OK++))

echo "可訪問的端口: $PORTS_OK/4"
echo ""

# 3. 檢查 API 健康狀態
echo -e "${GREEN}[3/6] 檢查 API 健康狀態...${NC}"

API_HEALTH=$(curl -s http://localhost:8765/health 2>/dev/null || echo '{"status":"error"}')
if echo "$API_HEALTH" | grep -q '"status":"healthy"'; then
    echo -e "${GREEN}✅ API Server 健康${NC}"
    echo "回應: $API_HEALTH"
else
    echo -e "${RED}❌ API Server 不健康${NC}"
    echo "回應: $API_HEALTH"
fi
echo ""

# 4. 檢查 MCP 註冊
echo -e "${GREEN}[4/6] 檢查 Claude Code CLI 註冊...${NC}"
if claude mcp list 2>/dev/null | grep -q "openmemory"; then
    echo -e "${GREEN}✅ 已註冊到 Claude Code CLI${NC}"
    
    # 顯示註冊詳情
    echo "註冊資訊："
    claude mcp list | grep -A 2 "openmemory" || true
else
    echo -e "${RED}❌ 未註冊到 Claude Code CLI${NC}"
fi
echo ""

# 5. 測試 MCP 通訊
echo -e "${GREEN}[5/6] 測試 MCP 通訊...${NC}"

WRAPPER_PATH="$HOME/.claude-code-openmemory.sh"

if [ -f "$WRAPPER_PATH" ]; then
    # 準備測試請求
    INIT_REQUEST='{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2024-11-05"},"id":1}'
    
    echo "發送初始化請求..."
    RESPONSE=$(echo "$INIT_REQUEST" | timeout 5 "$WRAPPER_PATH" 2>&1 || true)
    
    if echo "$RESPONSE" | grep -q '"serverInfo"'; then
        echo -e "${GREEN}✅ MCP 初始化成功${NC}"
    else
        echo -e "${YELLOW}⚠️ MCP 初始化可能需要更多時間${NC}"
    fi
else
    echo -e "${RED}❌ 找不到包裝腳本${NC}"
fi
echo ""

# 6. 測試記憶功能
echo -e "${GREEN}[6/6] 測試記憶功能...${NC}"

# 測試新增記憶
echo "測試新增記憶..."
ADD_RESPONSE=$(curl -s -X POST http://localhost:8765/memories \
  -H "Content-Type: application/json" \
  -d '{"content":"Test memory from installation","metadata":{},"tags":["test"]}' \
  2>/dev/null || echo "error")

if echo "$ADD_RESPONSE" | grep -q '"id"'; then
    echo -e "${GREEN}✅ 新增記憶成功${NC}"
    MEMORY_ID=$(echo "$ADD_RESPONSE" | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
    echo "記憶 ID: $MEMORY_ID"
else
    echo -e "${RED}❌ 新增記憶失敗${NC}"
fi

# 測試列出記憶
echo ""
echo "測試列出記憶..."
LIST_RESPONSE=$(curl -s http://localhost:8765/memories 2>/dev/null || echo "[]")
MEMORY_COUNT=$(echo "$LIST_RESPONSE" | grep -o '"id"' | wc -l || echo "0")
echo "找到 $MEMORY_COUNT 個記憶"

echo ""
echo -e "${BLUE}=== 測試完成 ===${NC}"
echo ""
echo "測試摘要："
echo "  • Docker 服務: $SERVICES_OK/4 運行中"
echo "  • 服務端口: $PORTS_OK/4 可訪問"
echo "  • API 健康: $(echo "$API_HEALTH" | grep -q "healthy" && echo "✓" || echo "✗")"
echo "  • MCP 註冊: $(claude mcp list 2>/dev/null | grep -q "openmemory" && echo "✓" || echo "✗")"
echo ""
echo "可用的工具："
echo "  - add_memories: 新增記憶"
echo "  - search_memory: 搜尋記憶"
echo "  - list_memories: 列出記憶"
echo "  - delete_all_memories: 刪除記憶"
echo ""
echo "Web UI："
echo "  訪問 http://localhost:3000 管理記憶"
echo ""
echo "使用範例："
echo "  claude '請記住我喜歡使用 TypeScript'"
echo "  claude '搜尋關於程式語言偏好的記憶'"
echo ""

# 提供故障排除建議
if [ $SERVICES_OK -lt 4 ] || [ $PORTS_OK -lt 4 ]; then
    echo -e "${YELLOW}故障排除建議：${NC}"
    echo "1. 檢查 Docker 服務狀態："
    echo "   cd docker && docker-compose ps"
    echo "2. 查看服務日誌："
    echo "   cd docker && docker-compose logs"
    echo "3. 重啟服務："
    echo "   cd docker && docker-compose restart"
fi