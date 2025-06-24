#!/bin/bash

# Perplexity MCP 測試腳本
# 用於驗證安裝是否成功

set -e

# 顏色定義
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Perplexity MCP Server 測試 ===${NC}"
echo ""

# 1. 檢查環境變數
echo -e "${GREEN}[1/4] 檢查環境變數...${NC}"
if [ -z "$PERPLEXITY_API_KEY" ]; then
    echo -e "${RED}❌ PERPLEXITY_API_KEY 未設定${NC}"
    echo "請設定: export PERPLEXITY_API_KEY='your-key'"
    exit 1
else
    echo -e "${GREEN}✅ API Key 已設定${NC}"
fi

echo "當前模型: ${PERPLEXITY_MODEL:-sonar-pro}"
echo ""

# 2. 檢查 MCP 註冊
echo -e "${GREEN}[2/4] 檢查 Claude Code CLI 註冊...${NC}"
if claude mcp list 2>/dev/null | grep -q "perplexity"; then
    echo -e "${GREEN}✅ 已註冊到 Claude Code CLI${NC}"
else
    echo -e "${RED}❌ 未註冊到 Claude Code CLI${NC}"
    exit 1
fi
echo ""

# 3. 測試包裝腳本
echo -e "${GREEN}[3/4] 測試包裝腳本...${NC}"
if [ -f "$HOME/.claude-code-perplexity.sh" ]; then
    # 發送測試請求
    TEST_REQUEST='{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2024-11-05"},"id":1}'
    
    RESPONSE=$(echo "$TEST_REQUEST" | timeout 5 "$HOME/.claude-code-perplexity.sh" 2>&1 || true)
    
    if echo "$RESPONSE" | grep -q '"serverInfo"'; then
        echo -e "${GREEN}✅ 包裝腳本運行正常${NC}"
    else
        echo -e "${RED}❌ 包裝腳本測試失敗${NC}"
        echo "回應: $RESPONSE"
    fi
else
    echo -e "${RED}❌ 找不到包裝腳本${NC}"
fi
echo ""

# 4. 測試工具列表
echo -e "${GREEN}[4/4] 測試工具列表...${NC}"
TOOLS_REQUEST='{"jsonrpc":"2.0","method":"tools/list","id":2}'

echo "發送工具列表請求..."
TOOLS_RESPONSE=$(echo -e "$TEST_REQUEST\n$TOOLS_REQUEST" | "$HOME/.claude-code-perplexity.sh" 2>&1 | tail -n 1 || true)

if echo "$TOOLS_RESPONSE" | grep -q "perplexity_search_web"; then
    echo -e "${GREEN}✅ 工具列表正常${NC}"
    echo ""
    echo "可用工具："
    echo "  - perplexity_search_web"
    echo "  - perplexity_pro_search"
    echo "  - perplexity_deep_research"
    echo "  - perplexity_reasoning"
else
    echo -e "${RED}❌ 無法獲取工具列表${NC}"
fi

echo ""
echo -e "${BLUE}=== 測試完成 ===${NC}"
echo ""
echo "如果所有測試都通過，您可以開始使用："
echo "  claude '搜尋最新的 AI 發展趨勢'"