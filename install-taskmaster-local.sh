#!/bin/bash

# TaskMaster MCP Server 本地化安裝腳本
# 版本：1.0.0
# 日期：2025-06-23

set -e

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WRAPPER_SCRIPT="$HOME/.claude-code-taskmaster.sh"
LOG_FILE="$SCRIPT_DIR/taskmaster-install.log"

# 日誌函數
log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[錯誤]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[成功]${NC} $1" | tee -a "$LOG_FILE"
}

log_info() {
    echo -e "${BLUE}[資訊]${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[警告]${NC} $1" | tee -a "$LOG_FILE"
}

# 顯示歡迎訊息
show_welcome() {
    clear
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║             TaskMaster MCP Server 安裝程式                    ║
║                                                               ║
║         為 Claude Code CLI 安裝智能任務管理系統               ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
    echo
}

# 檢查系統需求
check_requirements() {
    log_info "檢查系統需求..."
    
    # 檢查 Claude Code CLI
    if ! command -v claude &> /dev/null; then
        log_error "未找到 Claude Code CLI。請先安裝 Claude Code CLI。"
        log_info "安裝指南：https://docs.anthropic.com/en/docs/claude-code"
        exit 1
    fi
    
    # 測試 claude mcp 命令
    if ! claude mcp list &> /dev/null; then
        log_error "claude mcp 命令無法執行。請確認 Claude Code CLI 版本。"
        exit 1
    fi
    
    # 檢查 Node.js 和 npm
    if ! command -v node &> /dev/null; then
        log_error "未找到 Node.js。請先安裝 Node.js 18.0 或更高版本。"
        exit 1
    fi
    
    if ! command -v npm &> /dev/null; then
        log_error "未找到 npm。請先安裝 npm。"
        exit 1
    fi
    
    # 檢查版本
    local node_version=$(node --version | cut -d'v' -f2)
    local node_major=$(echo "$node_version" | cut -d'.' -f1)
    
    if [ "$node_major" -lt 18 ]; then
        log_error "Node.js 版本過低。需要 18.0 或更高版本，當前版本：v$node_version"
        exit 1
    fi
    
    log_success "系統需求檢查通過"
}

# 檢查現有安裝
check_existing_installation() {
    log_info "檢查現有安裝..."
    
    # 檢查是否已註冊
    if claude mcp list | grep -q "taskmaster"; then
        log_warning "發現現有的 TaskMaster MCP 註冊"
        read -p "是否要移除現有註冊並重新安裝？(y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log_info "移除現有註冊..."
            claude mcp remove taskmaster 2>/dev/null || true
            claude mcp remove taskmaster -s local 2>/dev/null || true
            claude mcp remove taskmaster -s project 2>/dev/null || true
            claude mcp remove taskmaster -s user 2>/dev/null || true
        else
            log_info "保留現有安裝，退出"
            exit 0
        fi
    fi
    
    # 檢查全域安裝
    if npm list -g task-master-ai 2>/dev/null | grep -q "task-master-ai"; then
        log_info "發現全域安裝的 task-master-ai"
    fi
}

# 收集 API Keys
collect_api_keys() {
    log_info "配置 API Keys..."
    
    # 檢查現有環境變數
    local has_anthropic=${ANTHROPIC_API_KEY:+yes}
    local has_perplexity=${PERPLEXITY_API_KEY:+yes}
    local has_openai=${OPENAI_API_KEY:+yes}
    local has_google=${GOOGLE_API_KEY:+yes}
    
    echo
    echo "TaskMaster 支援多個 AI 模型，請提供相應的 API Keys："
    echo "（按 Enter 跳過，稍後可在包裝腳本中配置）"
    echo
    
    # Anthropic API Key
    if [ -z "$has_anthropic" ]; then
        read -p "Anthropic API Key (Claude): " anthropic_key
    else
        log_info "使用現有的 Anthropic API Key"
        anthropic_key="$ANTHROPIC_API_KEY"
    fi
    
    # Perplexity API Key
    if [ -z "$has_perplexity" ]; then
        read -p "Perplexity API Key: " perplexity_key
    else
        log_info "使用現有的 Perplexity API Key"
        perplexity_key="$PERPLEXITY_API_KEY"
    fi
    
    # OpenAI API Key
    if [ -z "$has_openai" ]; then
        read -p "OpenAI API Key: " openai_key
    else
        log_info "使用現有的 OpenAI API Key"
        openai_key="$OPENAI_API_KEY"
    fi
    
    # Google API Key
    if [ -z "$has_google" ]; then
        read -p "Google API Key (Gemini): " google_key
    else
        log_info "使用現有的 Google API Key"
        google_key="$GOOGLE_API_KEY"
    fi
}

# 建立包裝腳本
create_wrapper_script() {
    log_info "建立包裝腳本..."
    
    cat << EOF > "$WRAPPER_SCRIPT"
#!/bin/bash

# Claude Task Master MCP Server 包裝腳本
# 自動生成於：$(date)

# 載入環境變數
export ANTHROPIC_API_KEY="${anthropic_key:-\${ANTHROPIC_API_KEY:-your-key-here}}"
export PERPLEXITY_API_KEY="${perplexity_key:-\${PERPLEXITY_API_KEY:-your-key-here}}"
export OPENAI_API_KEY="${openai_key:-\${OPENAI_API_KEY:-your-key-here}}"
export GOOGLE_API_KEY="${google_key:-\${GOOGLE_API_KEY:-your-key-here}}"

# TaskMaster 配置
export TASKMASTER_PROJECT_NAME="\${TASKMASTER_PROJECT_NAME:-Development Project}"
export TASKMASTER_DEFAULT_SUBTASKS="\${TASKMASTER_DEFAULT_SUBTASKS:-5}"
export TASKMASTER_DEFAULT_PRIORITY="\${TASKMASTER_DEFAULT_PRIORITY:-medium}"
export TASKMASTER_LOG_LEVEL="\${TASKMASTER_LOG_LEVEL:-info}"

# 執行 Task Master MCP Server
exec npx -y task-master-ai
EOF

    chmod +x "$WRAPPER_SCRIPT"
    log_success "包裝腳本建立完成：$WRAPPER_SCRIPT"
}

# 註冊到 Claude Code
register_mcp() {
    log_info "註冊 TaskMaster 到 Claude Code CLI..."
    
    # 預設使用專案範圍註冊
    if claude mcp add taskmaster "$WRAPPER_SCRIPT"; then
        log_success "TaskMaster 成功註冊到專案範圍"
    else
        log_error "註冊失敗"
        exit 1
    fi
    
    # 詢問是否全域註冊
    echo
    read -p "是否要將 TaskMaster 註冊到全域（所有專案都可使用）？(y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "嘗試全域註冊..."
        if claude mcp add taskmaster "$WRAPPER_SCRIPT" -s user; then
            log_success "TaskMaster 成功註冊到全域"
        else
            log_warning "全域註冊失敗，但專案範圍註冊已成功"
        fi
    fi
}

# 驗證安裝
verify_installation() {
    log_info "驗證安裝..."
    
    # 檢查 MCP 列表
    if claude mcp list | grep -q "taskmaster"; then
        log_success "TaskMaster 已成功註冊"
    else
        log_error "驗證失敗：TaskMaster 未出現在 MCP 列表中"
        exit 1
    fi
    
    # 測試 MCP 連接
    log_info "測試 MCP 連接..."
    
    if echo '{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0.0"}},"id":1}' | "$WRAPPER_SCRIPT" > /dev/null 2>&1; then
        log_success "MCP 連接測試成功"
    else
        log_warning "MCP 連接測試失敗，但這可能是正常的"
    fi
}

# 顯示使用說明
show_usage() {
    cat << EOF

${GREEN}✅ TaskMaster 安裝成功！${NC}

${BLUE}使用方式：${NC}

1. 在 Claude Code 中使用：
   - 輸入 "請列出 Task Master 的所有命令"
   - 或 "使用 Task Master 解析我的 PRD"

2. 可用的主要命令：
   - task-master init          # 初始化專案
   - task-master parse-prd     # 解析 PRD 文件
   - task-master list          # 列出所有任務
   - task-master next          # 獲取下一個任務
   - task-master complete      # 完成當前任務

3. 配置檔案位置：
   - 包裝腳本：$WRAPPER_SCRIPT
   - 專案配置：.taskmaster/config.json
   - 任務資料：.taskmaster/tasks.json

4. 更新 API Keys：
   編輯 $WRAPPER_SCRIPT 並更新相應的環境變數

${YELLOW}提示：${NC}
- 如果遇到 API Key 錯誤，請編輯包裝腳本設定正確的 Keys
- 使用 'claude mcp list' 查看所有已註冊的 MCP 服務
- 日誌檔案：$LOG_FILE

EOF
}

# 主流程
main() {
    show_welcome
    check_requirements
    check_existing_installation
    collect_api_keys
    create_wrapper_script
    register_mcp
    verify_installation
    show_usage
    
    log_success "安裝完成！"
}

# 執行主流程
main "$@"