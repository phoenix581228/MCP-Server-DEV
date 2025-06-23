#!/bin/bash

# Claude CLI MCP Server 自動註冊腳本
# 智能處理 MCP Server 註冊，避免重複和錯誤

set -euo pipefail

# 顏色定義
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# 全域變數
REGISTERED_SERVERS=""
LOG_FILE="registration.log"

# 初始化
init_registration() {
    echo "=== Claude CLI MCP 註冊開始 $(date) ===" > "$LOG_FILE"
    
    # 獲取已註冊的服務列表
    echo "📋 檢查現有註冊..."
    if command -v claude >/dev/null 2>&1; then
        REGISTERED_SERVERS=$(claude mcp list 2>/dev/null | grep -E "^\s*-" | awk '{print $2}' || echo "")
        echo "已註冊的服務: $REGISTERED_SERVERS" >> "$LOG_FILE"
    else
        echo -e "${RED}❌ 錯誤：Claude CLI 未安裝${NC}"
        exit 1
    fi
}

# 檢查服務是否已註冊
is_registered() {
    local service_name=$1
    echo "$REGISTERED_SERVERS" | grep -q "^$service_name$"
}

# 測試 JSON Schema 相容性
test_json_schema_compatibility() {
    local command=$1
    local test_output=$(mktemp)
    
    # 發送測試請求
    echo '{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2024-11-05"},"id":1}' | \
    timeout 5 $command > "$test_output" 2>&1 || true
    
    # 檢查是否有 JSON Schema 錯誤
    if grep -q "JSON schema is invalid" "$test_output"; then
        rm -f "$test_output"
        return 1
    fi
    
    rm -f "$test_output"
    return 0
}

# 智能註冊 MCP Server
register_mcp_server() {
    local name=$1
    local command=$2
    local preferred_scope=${3:-"auto"}  # auto, user, project
    
    echo -e "\n${BLUE}處理 $name...${NC}"
    
    # 檢查是否已註冊
    if is_registered "$name"; then
        echo -e "${YELLOW}⚠️  $name 已註冊，跳過${NC}"
        echo "[$name] 已存在，跳過註冊" >> "$LOG_FILE"
        return 0
    fi
    
    # 決定註冊範圍
    local scope="project"
    if [ "$preferred_scope" = "auto" ]; then
        # 測試 JSON Schema 相容性
        echo "測試 JSON Schema 相容性..."
        if test_json_schema_compatibility "$command"; then
            scope="user"
            echo "✅ JSON Schema 相容，可以全域註冊"
        else
            scope="project"
            echo "⚠️  JSON Schema 不相容，使用專案範圍"
        fi
    else
        scope="$preferred_scope"
    fi
    
    # 執行註冊
    echo "註冊 $name (範圍: $scope)..."
    if [ "$scope" = "user" ]; then
        if claude mcp add "$name" "$command" -s user >> "$LOG_FILE" 2>&1; then
            echo -e "${GREEN}✅ $name 已成功全域註冊${NC}"
        else
            # 降級到專案範圍
            echo "全域註冊失敗，嘗試專案範圍..."
            if claude mcp add "$name" "$command" >> "$LOG_FILE" 2>&1; then
                echo -e "${GREEN}✅ $name 已成功註冊（專案範圍）${NC}"
            else
                echo -e "${RED}❌ $name 註冊失敗${NC}"
                return 1
            fi
        fi
    else
        if claude mcp add "$name" "$command" >> "$LOG_FILE" 2>&1; then
            echo -e "${GREEN}✅ $name 已成功註冊${NC}"
        else
            echo -e "${RED}❌ $name 註冊失敗${NC}"
            return 1
        fi
    fi
    
    return 0
}

# 註冊 Perplexity MCP
register_perplexity() {
    local wrapper_script="$HOME/.claude-code-perplexity.sh"
    
    if [ -f "$wrapper_script" ]; then
        register_mcp_server "perplexity" "$wrapper_script" "project"
    else
        echo -e "${YELLOW}⚠️  Perplexity 包裝腳本未找到${NC}"
        echo "創建 Perplexity 包裝腳本..."
        
        cat > "$wrapper_script" << 'EOF'
#!/bin/bash
export PERPLEXITY_API_KEY=$(security find-generic-password -a "mcp-deployment" -s "PERPLEXITY_API_KEY" -w 2>/dev/null)
if [ -z "$PERPLEXITY_API_KEY" ]; then
    echo "錯誤：未找到 Perplexity API 金鑰" >&2
    exit 1
fi
exec npx -y @jschuller/perplexity-mcp@latest
EOF
        chmod +x "$wrapper_script"
        register_mcp_server "perplexity" "$wrapper_script" "project"
    fi
}

# 註冊 Zen MCP
register_zen() {
    local zen_script="$HOME/.claude-code-zen.sh"
    local zen_path="$HOME/mcp-servers/zen-mcp-server"
    
    if [ -d "$zen_path" ]; then
        if [ ! -f "$zen_script" ]; then
            cat > "$zen_script" << EOF
#!/bin/bash
cd "$zen_path"
source venv/bin/activate 2>/dev/null || true
exec python -m server
EOF
            chmod +x "$zen_script"
        fi
        register_mcp_server "zen" "$zen_script" "project"
    else
        echo -e "${YELLOW}⚠️  Zen MCP Server 未安裝${NC}"
    fi
}

# 註冊 OpenMemory
register_openmemory() {
    echo -e "${YELLOW}ℹ️  OpenMemory 使用 SSE 協議，需要特殊配置${NC}"
    echo "OpenMemory API 端點: http://localhost:8765"
    # OpenMemory 通常需要通過 HTTP API 而非 stdio 訪問
}

# 註冊 Serena
register_serena() {
    local serena_path="$HOME/mcp-servers/serena"
    
    if [ -d "$serena_path" ] && [ -f "$serena_path/run-serena.sh" ]; then
        register_mcp_server "serena" "$serena_path/run-serena.sh" "project"
    else
        echo -e "${YELLOW}⚠️  Serena MCP Server 未安裝${NC}"
    fi
}

# 註冊 Task Master
register_taskmaster() {
    if command -v claude-task-master >/dev/null 2>&1; then
        register_mcp_server "taskmaster" "claude-task-master" "auto"
    else
        echo -e "${YELLOW}⚠️  Task Master 未安裝${NC}"
    fi
}

# 生成註冊摘要
generate_summary() {
    echo -e "\n${BLUE}=== 註冊摘要 ===${NC}"
    
    # 重新獲取註冊列表
    local new_list=$(claude mcp list 2>/dev/null || echo "無法獲取列表")
    
    echo "$new_list"
    
    # 統計
    local registered_count=$(echo "$new_list" | grep -c "registered" || echo "0")
    echo -e "\n${GREEN}✅ 總共 $registered_count 個 MCP Server 已註冊${NC}"
}

# 主函數
main() {
    echo -e "${BLUE}╔══════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║   Claude CLI MCP 自動註冊工具        ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════╝${NC}"
    
    # 初始化
    init_registration
    
    # 註冊各個服務
    echo -e "\n開始註冊 MCP Servers..."
    
    register_perplexity
    register_zen
    register_openmemory
    register_serena
    register_taskmaster
    
    # 生成摘要
    generate_summary
    
    echo -e "\n📄 詳細日誌: $LOG_FILE"
    echo -e "${GREEN}✅ 註冊流程完成！${NC}"
}

# 執行主函數
main "$@"