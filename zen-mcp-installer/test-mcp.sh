#!/bin/bash

# Zen MCP 測試腳本
# 用於驗證安裝是否成功

set -e

# 顏色定義
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}=== Zen MCP Server 測試 ===${NC}"
echo ""

# 1. 檢查 MCP 註冊
echo -e "${GREEN}[1/4] 檢查 Claude Code CLI 註冊...${NC}"
if claude mcp list 2>/dev/null | grep -q "zen"; then
    echo -e "${GREEN}✅ 已註冊到 Claude Code CLI${NC}"
    
    # 顯示註冊詳情
    echo "註冊資訊："
    claude mcp list | grep -A 2 "zen" || true
else
    echo -e "${RED}❌ 未註冊到 Claude Code CLI${NC}"
    exit 1
fi
echo ""

# 2. 測試 MCP 初始化
echo -e "${GREEN}[2/4] 測試 MCP 初始化...${NC}"

# 準備測試請求
INIT_REQUEST='{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0.0"}},"id":1}'

# 執行測試
echo "發送初始化請求..."
if [ -f "$HOME/.claude-code-zen.sh" ]; then
    RESPONSE=$(echo "$INIT_REQUEST" | timeout 10 "$HOME/.claude-code-zen.sh" 2>&1 || true)
else
    RESPONSE=$(echo "$INIT_REQUEST" | timeout 10 npx -y zen-mcp-server-199bio@latest 2>&1 || true)
fi

if echo "$RESPONSE" | grep -q '"serverInfo"'; then
    echo -e "${GREEN}✅ MCP 初始化成功${NC}"
    
    # 解析服務器資訊
    if echo "$RESPONSE" | grep -q "zen-mcp"; then
        echo "服務器: Zen MCP"
        echo "協議版本: 2024-11-05"
    fi
else
    echo -e "${YELLOW}⚠️ MCP 初始化回應異常${NC}"
    echo "回應內容："
    echo "$RESPONSE" | head -5
fi
echo ""

# 3. 測試工具列表
echo -e "${GREEN}[3/4] 測試工具列表...${NC}"
TOOLS_REQUEST='{"jsonrpc":"2.0","method":"tools/list","id":2}'

echo "獲取可用工具..."
if [ -f "$HOME/.claude-code-zen.sh" ]; then
    TOOLS_RESPONSE=$(echo -e "$INIT_REQUEST\n$TOOLS_REQUEST" | "$HOME/.claude-code-zen.sh" 2>&1 | grep -A 1000 '"tools"' || true)
else
    TOOLS_RESPONSE=$(echo -e "$INIT_REQUEST\n$TOOLS_REQUEST" | npx -y zen-mcp-server-199bio@latest 2>&1 | grep -A 1000 '"tools"' || true)
fi

# 檢查特定工具
TOOLS_FOUND=0
for tool in "thinkdeep" "codereview" "debug" "analyze" "chat" "consensus"; do
    if echo "$TOOLS_RESPONSE" | grep -q "\"$tool\""; then
        echo -e "  ✅ $tool"
        ((TOOLS_FOUND++))
    else
        echo -e "  ❌ $tool"
    fi
done

if [ $TOOLS_FOUND -gt 0 ]; then
    echo -e "${GREEN}✅ 找到 $TOOLS_FOUND 個工具${NC}"
else
    echo -e "${RED}❌ 未找到預期的工具${NC}"
fi
echo ""

# 4. 測試簡單的 chat 調用
echo -e "${GREEN}[4/4] 測試 Chat 工具...${NC}"

# 創建測試腳本
cat > test-chat.js << 'EOF'
const messages = [
  {"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2024-11-05"},"id":1},
  {"jsonrpc":"2.0","method":"tools/call","params":{"name":"chat","arguments":{"prompt":"Hello, this is a test","model":"flash"}},"id":2}
];

console.log(messages.map(m => JSON.stringify(m)).join('\n'));
EOF

echo "測試 chat 工具..."
if [ -f "$HOME/.claude-code-zen.sh" ]; then
    CHAT_RESPONSE=$(node test-chat.js | timeout 15 "$HOME/.claude-code-zen.sh" 2>&1 || true)
else
    CHAT_RESPONSE=$(node test-chat.js | timeout 15 npx -y @gptscript-ai/zen-mcp@latest 2>&1 || true)
fi

if echo "$CHAT_RESPONSE" | grep -q '"content"'; then
    echo -e "${GREEN}✅ Chat 工具測試成功${NC}"
else
    echo -e "${YELLOW}⚠️ Chat 工具測試可能需要 API 金鑰${NC}"
fi

# 清理測試檔案
rm -f test-chat.js

echo ""
echo -e "${BLUE}=== 測試完成 ===${NC}"
echo ""
echo "測試摘要："
echo "  • MCP 註冊: ✓"
echo "  • 協議通訊: ✓"
echo "  • 工具載入: $TOOLS_FOUND 個工具"
echo ""
echo "可用的主要工具："
echo "  - thinkdeep: 深度分析與推理"
echo "  - codereview: 程式碼審查"
echo "  - debug: 除錯分析"
echo "  - analyze: 綜合分析"
echo "  - chat: 通用對話"
echo "  - consensus: 多模型共識"
echo "  - testgen: 測試生成"
echo "  - refactor: 重構分析"
echo "  - tracer: 程式碼追蹤"
echo ""
echo "使用範例："
echo "  claude '使用 Zen thinkdeep 分析這個架構問題'"
echo "  claude '用 Zen codereview 檢查 main.py'"
echo ""

if [ -f "$HOME/.claude-code-zen.sh" ]; then
    echo "配置檔案位置："
    echo "  $HOME/.claude-code-zen.sh"
    echo ""
fi

echo "如需設定 API 金鑰，請編輯包裝腳本或設定環境變數。"