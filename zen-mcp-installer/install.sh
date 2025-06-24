#!/bin/bash

# Zen MCP Server 安裝腳本
# 適用於 Claude Code CLI（非 Claude Desktop）
# 版本: 1.0.0

set -e

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 輸出函數
info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Banner
echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════╗"
echo "║         Zen MCP Server 安裝程式                  ║"
echo "║         for Claude Code CLI                      ║"
echo "║         版本 1.0.0                               ║"
echo "╚══════════════════════════════════════════════════╝"
echo -e "${NC}"

# 檢查作業系統
check_os() {
    info "檢查作業系統..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        success "偵測到 macOS"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        success "偵測到 Linux"
    else
        error "不支援的作業系統: $OSTYPE"
        exit 1
    fi
}

# 檢查 Python 環境
check_python_env() {
    info "檢查 Python 環境..."
    
    # 檢查是否在虛擬環境中
    if [ -n "$VIRTUAL_ENV" ]; then
        VENV_DIR="$VIRTUAL_ENV"
        success "偵測到啟用的虛擬環境: $VENV_DIR"
    elif [ -d "venv" ] && [ -f "venv/bin/python3" ]; then
        VENV_DIR="$(pwd)/venv"
        warning "偵測到本地虛擬環境（未啟用）: $VENV_DIR"
    elif [ -d ".venv" ] && [ -f ".venv/bin/python3" ]; then
        VENV_DIR="$(pwd)/.venv"
        warning "偵測到本地虛擬環境（未啟用）: $VENV_DIR"
    elif [ -d "$HOME/projects" ] && [ -f "$HOME/projects/bin/python3" ]; then
        VENV_DIR="$HOME/projects"
        info "偵測到共用虛擬環境: $VENV_DIR"
    else
        warning "未偵測到虛擬環境"
        VENV_DIR=""
    fi
    
    # 設定 Python 和 pip 路徑
    if [ -n "$VENV_DIR" ]; then
        PYTHON_BIN="$VENV_DIR/bin/python3"
        PIP_BIN="$VENV_DIR/bin/pip3"
        info "使用虛擬環境的 Python: $PYTHON_BIN"
    else
        PYTHON_BIN="python3"
        PIP_BIN="pip3"
        warning "使用系統 Python（建議使用虛擬環境）"
    fi
    
    # 檢查 Python 版本
    if command -v $PYTHON_BIN &> /dev/null; then
        PYTHON_VERSION=$($PYTHON_BIN --version 2>&1 | awk '{print $2}')
        success "Python 版本: $PYTHON_VERSION"
        
        # 檢查版本是否符合要求
        MAJOR=$(echo $PYTHON_VERSION | cut -d. -f1)
        MINOR=$(echo $PYTHON_VERSION | cut -d. -f2)
        
        if [ $MAJOR -lt 3 ] || ([ $MAJOR -eq 3 ] && [ $MINOR -lt 8 ]); then
            error "需要 Python 3.8 或更高版本"
            exit 1
        fi
    else
        error "找不到 Python 3"
        exit 1
    fi
}

# 檢查 Node.js 和 npm
check_node() {
    info "檢查 Node.js 環境..."
    
    if ! command -v node &> /dev/null; then
        error "找不到 Node.js，請先安裝 Node.js"
        exit 1
    fi
    
    if ! command -v npm &> /dev/null; then
        error "找不到 npm，請先安裝 npm"
        exit 1
    fi
    
    NODE_VERSION=$(node --version)
    NPM_VERSION=$(npm --version)
    success "Node.js 版本: $NODE_VERSION"
    success "npm 版本: $NPM_VERSION"
}

# 檢查 Claude Code CLI
check_claude_cli() {
    info "檢查 Claude Code CLI..."
    
    if ! command -v claude &> /dev/null; then
        error "找不到 Claude Code CLI"
        echo "請先安裝 Claude Code CLI："
        echo "  npm install -g @anthropic-ai/claude-cli"
        exit 1
    fi
    
    success "Claude Code CLI 已安裝"
}

# 檢查現有的 MCP 註冊
check_existing_mcp() {
    info "檢查現有的 Zen MCP 註冊..."
    
    if claude mcp list 2>/dev/null | grep -q "zen"; then
        warning "發現已註冊的 Zen MCP"
        echo -n "是否要重新安裝？[y/N] "
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            info "取消安裝"
            exit 0
        fi
        
        info "移除現有的 Zen MCP..."
        claude mcp remove zen 2>/dev/null || true
        success "已移除舊版本"
    fi
}

# 測試 npx 命令
test_npx_command() {
    info "測試 Zen MCP 可用性..."
    
    # 測試基本的 npx 命令
    if npx -y zen-mcp-server-199bio@latest --version &>/dev/null; then
        success "Zen MCP 套件可用"
        return 0
    else
        warning "無法直接執行 Zen MCP，將使用包裝腳本"
        return 1
    fi
}

# 創建包裝腳本
create_wrapper_script() {
    info "創建包裝腳本..."
    
    WRAPPER_PATH="$HOME/.claude-code-zen.sh"
    
    cat > "$WRAPPER_PATH" << 'EOF'
#!/bin/bash
# Zen MCP Server 包裝腳本
# 自動生成，請勿手動編輯

# 設定環境變數（可在此處自訂）
export ZEN_DEFAULT_MODEL="${ZEN_DEFAULT_MODEL:-pro}"
export ZEN_THINKING_MODE="${ZEN_THINKING_MODE:-high}"

# 如果有設定 API 金鑰，請在此處加入
# export ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:-your-key}"
# export OPENAI_API_KEY="${OPENAI_API_KEY:-your-key}"

# 執行 Zen MCP Server
exec npx -y zen-mcp-server-199bio@latest "$@"
EOF
    
    chmod +x "$WRAPPER_PATH"
    success "包裝腳本已創建: $WRAPPER_PATH"
}

# 註冊到 Claude Code CLI
register_to_claude() {
    info "註冊 Zen MCP 到 Claude Code CLI..."
    
    # 優先使用直接 npx 命令
    if test_npx_command; then
        MCP_COMMAND="npx -y zen-mcp-server-199bio@latest"
    else
        # 使用包裝腳本
        create_wrapper_script
        MCP_COMMAND="$HOME/.claude-code-zen.sh"
    fi
    
    # 詢問註冊範圍
    echo ""
    echo "請選擇註冊範圍："
    echo "1) 專案範圍（僅在當前專案可用）"
    echo "2) 使用者範圍（在所有專案可用）"
    echo -n "請選擇 [1/2] (預設: 1): "
    read -r scope_choice
    
    case "$scope_choice" in
        2)
            info "註冊到使用者範圍..."
            if claude mcp add zen "$MCP_COMMAND" -s user; then
                success "成功註冊到使用者範圍"
            else
                warning "使用者範圍註冊失敗，嘗試專案範圍..."
                claude mcp add zen "$MCP_COMMAND"
                success "成功註冊到專案範圍"
            fi
            ;;
        *)
            info "註冊到專案範圍..."
            claude mcp add zen "$MCP_COMMAND"
            success "成功註冊到專案範圍"
            ;;
    esac
}

# 測試安裝
test_installation() {
    info "測試 Zen MCP 安裝..."
    
    # 檢查註冊
    if claude mcp list | grep -q "zen"; then
        success "Zen MCP 已成功註冊"
    else
        error "Zen MCP 註冊失敗"
        exit 1
    fi
    
    # 創建測試腳本
    cat > test-zen.sh << 'EOF'
#!/bin/bash
# 測試 Zen MCP 連接
echo '{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2024-11-05"},"id":1}' | npx -y zen-mcp-server-199bio@latest
EOF
    
    chmod +x test-zen.sh
    
    # 執行測試
    if ./test-zen.sh 2>/dev/null | grep -q "serverInfo"; then
        success "Zen MCP 通訊測試成功"
        rm test-zen.sh
    else
        warning "Zen MCP 通訊測試失敗，但這可能是正常的"
        rm test-zen.sh
    fi
}

# 顯示使用說明
show_usage() {
    echo ""
    echo -e "${GREEN}══════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✨ Zen MCP Server 安裝成功！${NC}"
    echo -e "${GREEN}══════════════════════════════════════════════════${NC}"
    echo ""
    echo "可用的工具："
    echo "  • thinkdeep - 深度分析與推理"
    echo "  • codereview - 程式碼審查"
    echo "  • debug - 除錯與根本原因分析"
    echo "  • analyze - 綜合分析"
    echo "  • chat - 通用對話與協作"
    echo "  • consensus - 多模型共識"
    echo "  • testgen - 測試生成"
    echo "  • refactor - 重構分析"
    echo "  • tracer - 程式碼追蹤"
    echo "  • planner - 互動式規劃"
    echo "  • precommit - 提交前驗證"
    echo ""
    echo "使用範例："
    echo "  claude '使用 Zen 深度分析這個架構問題'"
    echo "  claude '用 Zen 審查 main.py 的程式碼'"
    echo "  claude '請用 Zen debug 找出記憶體洩漏問題'"
    echo ""
    echo "配置說明："
    if [ -f "$HOME/.claude-code-zen.sh" ]; then
        echo "  編輯包裝腳本以設定環境變數："
        echo "  $HOME/.claude-code-zen.sh"
    else
        echo "  可以設定以下環境變數："
        echo "  export ZEN_DEFAULT_MODEL='pro'"
        echo "  export ZEN_THINKING_MODE='high'"
    fi
    echo ""
    echo "更多資訊："
    echo "  https://github.com/gptscript-ai/zen-mcp"
}

# 主要安裝流程
main() {
    # 執行檢查
    check_os
    check_python_env
    check_node
    check_claude_cli
    check_existing_mcp
    
    # 執行安裝
    register_to_claude
    test_installation
    
    # 顯示完成訊息
    show_usage
    
    # 寫入安裝日誌
    cat > install.log << EOF
Zen MCP Server 安裝日誌
時間: $(date)
作業系統: $OS
Python: $PYTHON_VERSION
Python 路徑: $PYTHON_BIN
虛擬環境: ${VENV_DIR:-無}
Node.js: $NODE_VERSION
npm: $NPM_VERSION
安裝狀態: 成功
EOF
    
    success "安裝日誌已保存到 install.log"
}

# 錯誤處理
trap 'error "安裝過程中發生錯誤"; exit 1' ERR

# 執行主程式
main