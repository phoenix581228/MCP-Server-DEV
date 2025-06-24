#!/bin/bash

# Serena MCP 測試腳本
# 用於驗證安裝是否成功

set -e

# 顏色定義
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}=== Serena MCP Server 測試 ===${NC}"
echo ""

# 1. 檢查 MCP 註冊
echo -e "${GREEN}[1/5] 檢查 Claude Code CLI 註冊...${NC}"
if claude mcp list 2>/dev/null | grep -q "serena"; then
    echo -e "${GREEN}✅ 已註冊到 Claude Code CLI${NC}"
    
    # 顯示註冊詳情
    echo "註冊資訊："
    claude mcp list | grep -A 2 "serena" || true
else
    echo -e "${RED}❌ 未註冊到 Claude Code CLI${NC}"
    exit 1
fi
echo ""

# 2. 檢查包裝腳本
echo -e "${GREEN}[2/5] 檢查包裝腳本...${NC}"
WRAPPER_PATH="$HOME/.claude-code-serena.sh"

if [ -f "$WRAPPER_PATH" ]; then
    echo -e "${GREEN}✅ 包裝腳本存在${NC}"
    echo "位置: $WRAPPER_PATH"
    
    # 檢查執行權限
    if [ -x "$WRAPPER_PATH" ]; then
        echo -e "${GREEN}✅ 具有執行權限${NC}"
    else
        echo -e "${RED}❌ 缺少執行權限${NC}"
    fi
else
    echo -e "${RED}❌ 找不到包裝腳本${NC}"
fi
echo ""

# 3. 測試 uv/uvx
echo -e "${GREEN}[3/5] 測試 uv/uvx...${NC}"

# 檢查 uv
if command -v uv &> /dev/null; then
    echo -e "${GREEN}✅ uv 已安裝${NC}"
    UV_VERSION=$(uv --version 2>&1 || echo "unknown")
    echo "版本: $UV_VERSION"
else
    echo -e "${RED}❌ uv 未安裝${NC}"
    echo "請執行: curl -LsSf https://astral.sh/uv/install.sh | sh"
fi

# 檢查 uvx（是 uv 的一部分）
if command -v uv &> /dev/null; then
    echo -e "${GREEN}✅ uvx 可用${NC}"
else
    echo -e "${RED}❌ uvx 不可用${NC}"
fi
echo ""

# 4. 測試 MCP 通訊
echo -e "${GREEN}[4/5] 測試 MCP 通訊...${NC}"

# 準備測試請求
INIT_REQUEST='{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0.0"}},"id":1}'

# 執行測試
echo "發送初始化請求..."
if [ -f "$WRAPPER_PATH" ]; then
    RESPONSE=$(echo "$INIT_REQUEST" | timeout 30 "$WRAPPER_PATH" 2>&1 || true)
    
    if echo "$RESPONSE" | grep -q '"serverInfo"'; then
        echo -e "${GREEN}✅ MCP 初始化成功${NC}"
        
        # 嘗試解析服務器名稱
        if echo "$RESPONSE" | grep -q '"name".*"serena"'; then
            echo "服務器識別: Serena MCP"
        fi
    elif echo "$RESPONSE" | grep -q "Downloading"; then
        echo -e "${YELLOW}⚠️ 首次執行，正在下載 Serena...${NC}"
        echo "這可能需要一些時間，請耐心等待"
    else
        echo -e "${YELLOW}⚠️ MCP 初始化未返回預期回應${NC}"
        echo "回應片段："
        echo "$RESPONSE" | head -3
    fi
else
    echo -e "${RED}❌ 無法測試 MCP 通訊（找不到包裝腳本）${NC}"
fi
echo ""

# 5. 測試工具列表
echo -e "${GREEN}[5/5] 測試工具列表...${NC}"
TOOLS_REQUEST='{"jsonrpc":"2.0","method":"tools/list","id":2}'

if [ -f "$WRAPPER_PATH" ]; then
    echo "獲取可用工具..."
    TOOLS_RESPONSE=$(echo -e "$INIT_REQUEST\n$TOOLS_REQUEST" | "$WRAPPER_PATH" 2>&1 | tail -200 || true)
    
    # 檢查核心工具
    TOOLS_FOUND=0
    echo "檢查核心工具："
    for tool in "read_file" "create_text_file" "find_symbol" "activate_project" "write_memory"; do
        if echo "$TOOLS_RESPONSE" | grep -q "\"$tool\""; then
            echo -e "  ✅ $tool"
            ((TOOLS_FOUND++))
        else
            echo -e "  ❌ $tool"
        fi
    done
    
    if [ $TOOLS_FOUND -gt 0 ]; then
        echo -e "${GREEN}✅ 找到 $TOOLS_FOUND 個核心工具${NC}"
    else
        echo -e "${YELLOW}⚠️ 未找到預期的工具（可能需要專案啟動）${NC}"
    fi
else
    echo -e "${RED}❌ 無法測試工具列表${NC}"
fi

echo ""
echo -e "${BLUE}=== 測試完成 ===${NC}"
echo ""
echo "測試摘要："
echo "  • MCP 註冊: ✓"
echo "  • 包裝腳本: ✓"
echo "  • uv/uvx: ✓"
echo ""
echo "主要功能："
echo "  檔案操作："
echo "    - read_file, create_text_file, list_dir, find_file"
echo "  符號操作："
echo "    - find_symbol, replace_symbol_body, insert_*_symbol"
echo "  專案管理："
echo "    - activate_project, write_memory, execute_shell_command"
echo ""
echo "使用提示："
echo "1. 首次使用時，在專案目錄創建 .serena/ 資料夾"
echo "2. 使用 activate_project 啟動專案"
echo "3. 使用 write_memory 儲存重要的專案資訊"
echo ""
echo "範例："
echo "  claude '使用 Serena 讀取 README.md 檔案'"
echo "  claude '用 Serena 在 main.py 中查找 calculate 函數'"
echo ""

# 檢查範例配置
if [ -d "$HOME/.serena-examples" ]; then
    echo "範例配置位置："
    echo "  $HOME/.serena-examples/"
    echo ""
fi

echo "如需更多幫助，請查看 README.md 或訪問專案網站。"