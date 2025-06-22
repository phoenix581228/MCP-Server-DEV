#!/bin/bash
# Serena MCP Server 連線測試腳本

# 顏色定義
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}====================================${NC}"
echo -e "${BLUE}Serena MCP Server 連線測試${NC}"
echo -e "${BLUE}====================================${NC}"
echo ""

# 測試函數
test_mcp_command() {
    local description=$1
    local command=$2
    local timeout=${3:-5}
    
    echo -e "${YELLOW}測試：${NC} $description"
    
    # 創建臨時檔案
    local temp_output=$(mktemp)
    
    # 執行命令（macOS 沒有 timeout 命令，直接執行）
    if bash -c "$command" > "$temp_output" 2>&1; then
        echo -e "${GREEN}✓${NC} 成功"
        if [ -s "$temp_output" ]; then
            echo "回應內容："
            cat "$temp_output" | head -n 20
        fi
    else
        echo -e "${RED}✗${NC} 失敗"
        if [ -s "$temp_output" ]; then
            echo "錯誤訊息："
            cat "$temp_output"
        fi
    fi
    
    # 清理臨時檔案
    rm -f "$temp_output"
    echo ""
}

# 測試 1: 檢查 uv 是否安裝
echo -e "${YELLOW}檢查依賴項...${NC}"
if command -v uv >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} uv 已安裝: $(uv --version)"
else
    echo -e "${RED}✗${NC} uv 未安裝，請先執行 install.sh"
    exit 1
fi
echo ""

# 測試 2: 測試 Serena 幫助命令
test_mcp_command "Serena 幫助命令" \
    "uvx --from git+https://github.com/oraios/serena serena-mcp-server --help"

# 測試 3: MCP 初始化測試
echo -e "${YELLOW}測試 MCP 協議通訊...${NC}"

# 創建測試請求
cat > /tmp/serena-test-init.json << 'EOF'
{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0.0"}},"id":1}
EOF

# 測試 stdio 傳輸
test_mcp_command "MCP 初始化 (stdio)" \
    "cat /tmp/serena-test-init.json | uvx --from git+https://github.com/oraios/serena serena-mcp-server --transport stdio"

# 測試 4: 列出工具
cat > /tmp/serena-test-tools.json << 'EOF'
{"jsonrpc":"2.0","method":"tools/list","id":2}
EOF

test_mcp_command "列出可用工具" \
    "cat /tmp/serena-test-tools.json | uvx --from git+https://github.com/oraios/serena serena-mcp-server --transport stdio"

# 測試 5: 測試基本搜尋功能
cat > /tmp/serena-test-search.json << 'EOF'
{"jsonrpc":"2.0","method":"tools/call","params":{"name":"symbol_search","arguments":{"query":"main","project_path":"."}},"id":3}
EOF

test_mcp_command "符號搜尋測試" \
    "cat /tmp/serena-test-search.json | uvx --from git+https://github.com/oraios/serena serena-mcp-server --transport stdio" \
    10

# 清理臨時檔案
rm -f /tmp/serena-test-*.json

# 總結
echo -e "${BLUE}====================================${NC}"
echo -e "${BLUE}測試完成${NC}"
echo -e "${BLUE}====================================${NC}"
echo ""
echo "建議的下一步："
echo ""
echo "1. 如果所有測試通過，註冊到 Claude Code CLI："
echo "   claude mcp add serena -- $PWD/run-serena.sh \$(pwd)"
echo ""
echo "2. 或使用全域包裝腳本："
echo "   claude mcp add serena -- ~/.serena/run-serena.sh \$(pwd)"
echo ""
echo "3. 測試特定專案："
echo "   SERENA_LOG_LEVEL=DEBUG ./run-serena.sh /path/to/project"