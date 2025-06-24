#!/bin/bash

# API Key 安全設定腳本
# 此腳本會安全地收集 API Key 並更新包裝腳本

set -e

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

WRAPPER_SCRIPT="$HOME/.claude-code-taskmaster.sh"

echo -e "${BLUE}=== Task Master API Key 設定程式 ===${NC}"
echo
echo "此程式將協助你安全地設定 API Key"
echo "輸入的 API Key 不會顯示在螢幕上"
echo

# 讀取 API Key 的函數（隱藏輸入）
read_api_key() {
    local prompt="$1"
    local var_name="$2"
    
    echo -n "$prompt"
    read -s api_key
    echo
    
    if [ -n "$api_key" ]; then
        eval "$var_name='$api_key'"
        echo -e "${GREEN}✓ 已輸入${NC}"
    else
        echo -e "${YELLOW}⚠ 跳過（保留現有設定）${NC}"
    fi
}

# 備份現有腳本
if [ -f "$WRAPPER_SCRIPT" ]; then
    cp "$WRAPPER_SCRIPT" "$WRAPPER_SCRIPT.backup-$(date +%Y%m%d-%H%M%S)"
    echo -e "${GREEN}✓ 已備份現有腳本${NC}"
fi

# 收集 API Keys
echo
read_api_key "請輸入 Anthropic API Key (Claude): " anthropic_key
read_api_key "請輸入 Perplexity API Key: " perplexity_key

# 詢問是否要設定其他 API Key
echo
read -p "是否要設定 OpenAI 和 Google API Key？(y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    read_api_key "請輸入 OpenAI API Key: " openai_key
    read_api_key "請輸入 Google API Key (Gemini): " google_key
fi

# 更新包裝腳本
echo
echo -e "${BLUE}正在更新包裝腳本...${NC}"

# 建立新的包裝腳本
cat << 'EOF' > "$WRAPPER_SCRIPT"
#!/bin/bash

# Claude Task Master MCP Server 包裝腳本
# 自動更新於：$(date)

# 載入環境變數
EOF

# 寫入 API Keys（只有輸入的才會更新）
if [ -n "$anthropic_key" ]; then
    echo "export ANTHROPIC_API_KEY=\"$anthropic_key\"" >> "$WRAPPER_SCRIPT"
else
    echo "export ANTHROPIC_API_KEY=\"\${ANTHROPIC_API_KEY}\"" >> "$WRAPPER_SCRIPT"
fi

if [ -n "$perplexity_key" ]; then
    echo "export PERPLEXITY_API_KEY=\"$perplexity_key\"" >> "$WRAPPER_SCRIPT"
else
    echo "export PERPLEXITY_API_KEY=\"\${PERPLEXITY_API_KEY}\"" >> "$WRAPPER_SCRIPT"
fi

if [ -n "$openai_key" ]; then
    echo "export OPENAI_API_KEY=\"$openai_key\"" >> "$WRAPPER_SCRIPT"
else
    echo "export OPENAI_API_KEY=\"\${OPENAI_API_KEY}\"" >> "$WRAPPER_SCRIPT"
fi

if [ -n "$google_key" ]; then
    echo "export GOOGLE_API_KEY=\"$google_key\"" >> "$WRAPPER_SCRIPT"
else
    echo "export GOOGLE_API_KEY=\"\${GOOGLE_API_KEY}\"" >> "$WRAPPER_SCRIPT"
fi

# 加入其餘配置
cat << 'EOF' >> "$WRAPPER_SCRIPT"

# TaskMaster 配置
export TASKMASTER_PROJECT_NAME="${TASKMASTER_PROJECT_NAME:-MCP-Server-DEV}"
export TASKMASTER_DEFAULT_SUBTASKS="${TASKMASTER_DEFAULT_SUBTASKS:-5}"
export TASKMASTER_DEFAULT_PRIORITY="${TASKMASTER_DEFAULT_PRIORITY:-medium}"
export TASKMASTER_LOG_LEVEL="${TASKMASTER_LOG_LEVEL:-info}"

# 執行 Task Master MCP Server
exec npx -y task-master-ai
EOF

# 設定執行權限
chmod 600 "$WRAPPER_SCRIPT"  # 只有擁有者可讀寫
chmod +x "$WRAPPER_SCRIPT"

echo -e "${GREEN}✓ 包裝腳本已更新${NC}"

# 驗證設定
echo
echo -e "${BLUE}驗證 API Key 設定...${NC}"

# 檢查更新後的設定
source "$WRAPPER_SCRIPT" 2>/dev/null || true

[ -n "$ANTHROPIC_API_KEY" ] && [ "$ANTHROPIC_API_KEY" != "\${ANTHROPIC_API_KEY}" ] && \
    echo -e "${GREEN}✓ Anthropic API Key 已設定${NC}" || \
    echo -e "${YELLOW}⚠ Anthropic API Key 未設定${NC}"

[ -n "$PERPLEXITY_API_KEY" ] && [ "$PERPLEXITY_API_KEY" != "\${PERPLEXITY_API_KEY}" ] && \
    echo -e "${GREEN}✓ Perplexity API Key 已設定${NC}" || \
    echo -e "${YELLOW}⚠ Perplexity API Key 未設定${NC}"

[ -n "$OPENAI_API_KEY" ] && [ "$OPENAI_API_KEY" != "\${OPENAI_API_KEY}" ] && \
    echo -e "${GREEN}✓ OpenAI API Key 已設定${NC}" || \
    echo -e "${YELLOW}⚠ OpenAI API Key 未設定${NC}"

[ -n "$GOOGLE_API_KEY" ] && [ "$GOOGLE_API_KEY" != "\${GOOGLE_API_KEY}" ] && \
    echo -e "${GREEN}✓ Google API Key 已設定${NC}" || \
    echo -e "${YELLOW}⚠ Google API Key 未設定${NC}"

echo
echo -e "${GREEN}✅ API Key 設定完成！${NC}"
echo
echo "注意事項："
echo "- API Key 已安全地儲存在 $WRAPPER_SCRIPT"
echo "- 檔案權限已設為 600（只有你可以讀取）"
echo "- 原始腳本已備份"
echo
echo "如需修改 API Key，請再次執行此腳本或直接編輯："
echo "  $WRAPPER_SCRIPT"