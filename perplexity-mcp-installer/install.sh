#!/bin/bash

# Perplexity Custom MCP Server for Claude Code CLI 一鍵安裝腳本
# 版本: 1.0.0
# 日期: 2025-06-23

set -e

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印函數
print_header() {
    echo -e "${BLUE}================================================================${NC}"
    echo -e "${BLUE}   Perplexity Custom MCP Server for Claude Code CLI 安裝程式   ${NC}"
    echo -e "${BLUE}================================================================${NC}"
    echo ""
}

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# 環境檢查函數
check_environment() {
    print_info "開始環境檢查..."
    
    # 1. 檢查是否在虛擬環境中
    if [ -n "$VIRTUAL_ENV" ]; then
        print_success "檢測到虛擬環境: $VIRTUAL_ENV"
        VENV_DIR="$VIRTUAL_ENV"
    else
        # 檢查常見的虛擬環境位置
        if [ -d "venv" ] && [ -f "venv/bin/python3" ]; then
            VENV_DIR="$(pwd)/venv"
            print_warn "未激活虛擬環境，但找到 venv 目錄: $VENV_DIR"
        elif [ -d ".venv" ] && [ -f ".venv/bin/python3" ]; then
            VENV_DIR="$(pwd)/.venv"
            print_warn "未激活虛擬環境，但找到 .venv 目錄: $VENV_DIR"
        elif [ -d "$HOME/projects" ] && [ -f "$HOME/projects/bin/python3" ]; then
            VENV_DIR="$HOME/projects"
            print_info "找到共用虛擬環境: $VENV_DIR"
        else
            print_error "未檢測到虛擬環境！"
            echo ""
            echo "請先激活虛擬環境或創建新的虛擬環境："
            echo "  source /path/to/venv/bin/activate"
            echo "或"
            echo "  python3 -m venv venv && source venv/bin/activate"
            exit 1
        fi
    fi
    
    # 2. 設定 Python 和 pip 路徑
    if [ -f "$VENV_DIR/bin/python3" ]; then
        PYTHON_BIN="$VENV_DIR/bin/python3"
        PIP_BIN="$VENV_DIR/bin/pip3"
    else
        print_error "在虛擬環境中找不到 python3！"
        exit 1
    fi
    
    # 3. 驗證 Python 和 pip
    print_info "驗證 Python 環境..."
    if ! "$PYTHON_BIN" --version &> /dev/null; then
        print_error "無法執行 Python！"
        exit 1
    fi
    
    PYTHON_VERSION=$("$PYTHON_BIN" --version 2>&1 | cut -d' ' -f2)
    print_success "Python 版本: $PYTHON_VERSION"
    
    if ! "$PIP_BIN" --version &> /dev/null; then
        print_error "無法執行 pip！"
        exit 1
    fi
    
    PIP_VERSION=$("$PIP_BIN" --version | cut -d' ' -f2)
    print_success "pip 版本: $PIP_VERSION"
    
    # 4. 檢查 Node.js 和 npm
    print_info "檢查 Node.js 環境..."
    if ! command -v node &> /dev/null; then
        print_error "未安裝 Node.js！請先安裝 Node.js 14 或更高版本。"
        echo "訪問 https://nodejs.org/ 下載安裝"
        exit 1
    fi
    
    NODE_VERSION=$(node --version)
    print_success "Node.js 版本: $NODE_VERSION"
    
    if ! command -v npm &> /dev/null; then
        print_error "未安裝 npm！"
        exit 1
    fi
    
    NPM_VERSION=$(npm --version)
    print_success "npm 版本: $NPM_VERSION"
    
    # 5. 檢查 Claude Code CLI
    print_info "檢查 Claude Code CLI..."
    if ! command -v claude &> /dev/null; then
        print_error "未安裝 Claude Code CLI！"
        echo ""
        echo "請先安裝 Claude Code CLI："
        echo "  npm install -g @anthropic-ai/claude-cli"
        exit 1
    fi
    
    CLAUDE_VERSION=$(claude --version 2>&1 || echo "unknown")
    print_success "Claude Code CLI 已安裝: $CLAUDE_VERSION"
    
    # 6. 檢查 Git（用於獲取專案資訊）
    if ! command -v git &> /dev/null; then
        print_warn "未安裝 Git，部分功能可能受限"
    fi
    
    echo ""
    print_success "環境檢查完成！"
    echo ""
    echo "檢測到的環境配置："
    echo "  虛擬環境目錄: $VENV_DIR"
    echo "  Python 路徑: $PYTHON_BIN"
    echo "  pip 路徑: $PIP_BIN"
    echo ""
}

# 檢查現有安裝
check_existing_installation() {
    print_info "檢查現有 MCP 安裝..."
    
    # 檢查 Claude Code CLI 中的 MCP 列表
    if claude mcp list 2>/dev/null | grep -q "perplexity"; then
        print_warn "檢測到已安裝的 Perplexity MCP Server"
        echo ""
        read -p "是否要移除現有安裝並重新安裝？(y/N) " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "移除現有安裝..."
            claude mcp remove perplexity -s user 2>/dev/null || true
            claude mcp remove perplexity -s project 2>/dev/null || true
            claude mcp remove perplexity 2>/dev/null || true
            print_success "已移除現有安裝"
        else
            print_info "保留現有安裝，退出安裝程序"
            exit 0
        fi
    fi
}

# 創建包裝腳本
create_wrapper_script() {
    print_info "創建 MCP Server 包裝腳本..."
    
    WRAPPER_SCRIPT="$HOME/.claude-code-perplexity.sh"
    
    cat > "$WRAPPER_SCRIPT" << EOF
#!/bin/bash
# Perplexity Custom MCP Server 包裝腳本
# 自動生成於: $(date)
# Python 環境: $VENV_DIR

# 設定環境變數
export PERPLEXITY_API_KEY="\${PERPLEXITY_API_KEY:-}"
export PERPLEXITY_MODEL="\${PERPLEXITY_MODEL:-sonar-pro}"

# 檢查 API Key
if [ -z "\$PERPLEXITY_API_KEY" ]; then
    echo "錯誤: 未設定 PERPLEXITY_API_KEY 環境變數" >&2
    echo "請設定: export PERPLEXITY_API_KEY='your-api-key'" >&2
    exit 1
fi

# 使用虛擬環境中的 Python 執行
exec "$PYTHON_BIN" -m perplexity_mcp_custom
EOF
    
    chmod +x "$WRAPPER_SCRIPT"
    print_success "包裝腳本已創建: $WRAPPER_SCRIPT"
}

# 安裝 Python 套件
install_python_package() {
    print_info "安裝 Perplexity MCP Custom Python 套件..."
    
    # 先升級 pip
    print_info "升級 pip..."
    "$PIP_BIN" install --upgrade pip
    
    # 檢查是否已安裝
    if "$PIP_BIN" show perplexity-mcp-custom &> /dev/null; then
        print_info "升級現有套件..."
        "$PIP_BIN" install --upgrade perplexity-mcp-custom
    else
        print_info "安裝新套件..."
        "$PIP_BIN" install perplexity-mcp-custom
    fi
    
    # 驗證安裝
    if "$PYTHON_BIN" -c "import perplexity_mcp_custom" 2>/dev/null; then
        print_success "Python 套件安裝成功！"
    else
        print_error "Python 套件安裝失敗！"
        exit 1
    fi
}

# 註冊到 Claude Code CLI
register_to_claude() {
    print_info "註冊 MCP Server 到 Claude Code CLI..."
    
    echo ""
    echo "請選擇安裝範圍："
    echo "1) 專案範圍（僅在當前專案可用）"
    echo "2) 使用者範圍（所有專案都可用）"
    echo ""
    read -p "請選擇 (1/2): " -n 1 -r
    echo ""
    
    case $REPLY in
        1)
            print_info "註冊到專案範圍..."
            if claude mcp add perplexity "$HOME/.claude-code-perplexity.sh"; then
                print_success "成功註冊到專案範圍！"
            else
                print_error "註冊失敗！"
                exit 1
            fi
            ;;
        2)
            print_info "註冊到使用者範圍..."
            if claude mcp add perplexity "$HOME/.claude-code-perplexity.sh" -s user; then
                print_success "成功註冊到使用者範圍！"
            else
                print_warn "使用者範圍註冊可能失敗（JSON Schema 相容性問題）"
                print_info "嘗試註冊到專案範圍..."
                if claude mcp add perplexity "$HOME/.claude-code-perplexity.sh"; then
                    print_success "成功註冊到專案範圍！"
                else
                    print_error "註冊失敗！"
                    exit 1
                fi
            fi
            ;;
        *)
            print_error "無效選擇！"
            exit 1
            ;;
    esac
}

# 配置 API Key
configure_api_key() {
    print_info "配置 Perplexity API Key..."
    
    echo ""
    echo "請提供您的 Perplexity API Key"
    echo "（可從 https://www.perplexity.ai/settings/api 獲取）"
    echo ""
    read -p "API Key: " -s API_KEY
    echo ""
    
    if [ -z "$API_KEY" ]; then
        print_warn "未提供 API Key，稍後需要手動設定"
    else
        # 將 API Key 添加到 shell 配置文件
        SHELL_CONFIG=""
        if [ -f "$HOME/.zshrc" ]; then
            SHELL_CONFIG="$HOME/.zshrc"
        elif [ -f "$HOME/.bashrc" ]; then
            SHELL_CONFIG="$HOME/.bashrc"
        fi
        
        if [ -n "$SHELL_CONFIG" ]; then
            echo "" >> "$SHELL_CONFIG"
            echo "# Perplexity MCP API Key" >> "$SHELL_CONFIG"
            echo "export PERPLEXITY_API_KEY='$API_KEY'" >> "$SHELL_CONFIG"
            print_success "API Key 已保存到 $SHELL_CONFIG"
            
            # 立即導出
            export PERPLEXITY_API_KEY="$API_KEY"
        else
            print_warn "無法自動保存 API Key，請手動設定："
            echo "export PERPLEXITY_API_KEY='$API_KEY'"
        fi
    fi
}

# 測試安裝
test_installation() {
    print_info "測試 MCP Server 安裝..."
    
    # 測試包裝腳本
    if [ -f "$HOME/.claude-code-perplexity.sh" ]; then
        print_info "測試包裝腳本..."
        if timeout 5 "$HOME/.claude-code-perplexity.sh" < /dev/null 2>&1 | grep -q "PERPLEXITY_API_KEY"; then
            print_warn "需要設定 API Key 才能正常運行"
        else
            print_success "包裝腳本測試通過！"
        fi
    fi
    
    # 測試 Claude Code CLI 集成
    print_info "驗證 Claude Code CLI 集成..."
    if claude mcp list | grep -q "perplexity"; then
        print_success "MCP Server 已成功註冊到 Claude Code CLI！"
    else
        print_error "未能在 Claude Code CLI 中找到 Perplexity MCP Server"
        exit 1
    fi
}

# 顯示使用說明
show_usage() {
    echo ""
    print_header
    print_success "安裝完成！"
    echo ""
    echo "使用方法："
    echo ""
    echo "1. 設定 API Key（如果尚未設定）："
    echo "   export PERPLEXITY_API_KEY='your-api-key-here'"
    echo ""
    echo "2. 可選：設定模型（預設為 sonar-pro）："
    echo "   export PERPLEXITY_MODEL='sonar'  # 或 'sonar-pro', 'sonar-deep-research'"
    echo ""
    echo "3. 在 Claude Code CLI 中使用："
    echo "   claude '搜尋最新的 React 19 特性'"
    echo ""
    echo "4. 查看已安裝的 MCP Servers："
    echo "   claude mcp list"
    echo ""
    echo "5. 如需移除："
    echo "   claude mcp remove perplexity"
    echo ""
    echo "注意事項："
    echo "- 本安裝僅適用於 Claude Code CLI，不支援 Claude Desktop"
    echo "- 確保 API Key 安全，不要分享或提交到版本控制"
    echo "- 深度研究模式（sonar-deep-research）可能需要較長時間"
    echo ""
}

# 主安裝流程
main() {
    print_header
    
    print_warn "重要提醒：本安裝程序專為 Claude Code CLI 設計"
    print_warn "請勿用於 Claude Desktop！"
    echo ""
    
    # 執行環境檢查
    check_environment
    
    # 檢查現有安裝
    check_existing_installation
    
    # 安裝 Python 套件
    install_python_package
    
    # 創建包裝腳本
    create_wrapper_script
    
    # 註冊到 Claude Code CLI
    register_to_claude
    
    # 配置 API Key
    configure_api_key
    
    # 測試安裝
    test_installation
    
    # 顯示使用說明
    show_usage
}

# 執行主流程
main "$@"