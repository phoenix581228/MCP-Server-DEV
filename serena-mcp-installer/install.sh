#!/bin/bash

# Serena MCP Server 安裝腳本
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
echo "║         Serena MCP Server 安裝程式               ║"
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

# 檢查 Git
check_git() {
    info "檢查 Git..."
    
    if ! command -v git &> /dev/null; then
        error "找不到 Git，請先安裝 Git"
        exit 1
    fi
    
    GIT_VERSION=$(git --version | awk '{print $3}')
    success "Git 版本: $GIT_VERSION"
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
    info "檢查現有的 Serena MCP 註冊..."
    
    if claude mcp list 2>/dev/null | grep -q "serena"; then
        warning "發現已註冊的 Serena MCP"
        echo -n "是否要重新安裝？[y/N] "
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            info "取消安裝"
            exit 0
        fi
        
        info "移除現有的 Serena MCP..."
        claude mcp remove serena 2>/dev/null || true
        success "已移除舊版本"
    fi
}

# 檢查並安裝 uv
check_and_install_uv() {
    info "檢查 uv (Python 套件管理器)..."
    
    if ! command -v uv &> /dev/null; then
        warning "找不到 uv，正在安裝..."
        
        # 安裝 uv
        if curl -LsSf https://astral.sh/uv/install.sh | sh; then
            success "uv 安裝成功"
            
            # 將 uv 加入 PATH
            export PATH="$HOME/.cargo/bin:$PATH"
            
            # 檢查 uv 是否可用
            if ! command -v uv &> /dev/null; then
                error "uv 安裝後無法使用，請重新開啟終端機"
                echo "或手動執行: export PATH=\"\$HOME/.cargo/bin:\$PATH\""
                exit 1
            fi
        else
            error "uv 安裝失敗"
            echo "請手動安裝 uv："
            echo "  curl -LsSf https://astral.sh/uv/install.sh | sh"
            exit 1
        fi
    else
        UV_VERSION=$(uv --version 2>&1 || echo "unknown")
        success "uv 已安裝: $UV_VERSION"
    fi
}

# 檢查 uvx
check_uvx() {
    info "檢查 uvx..."
    
    # uvx 是 uv 的一部分，所以只要有 uv 就有 uvx
    if command -v uv &> /dev/null; then
        success "uvx 可用"
    else
        error "uvx 不可用"
        exit 1
    fi
}

# 創建包裝腳本
create_wrapper_script() {
    info "創建包裝腳本..."
    
    WRAPPER_PATH="$HOME/.claude-code-serena.sh"
    PROJECT_DIR="${SERENA_PROJECT_DIR:-$(pwd)}"
    
    # 創建包裝腳本，使用 uvx 執行 Serena
    cat > "$WRAPPER_PATH" << EOF
#!/bin/bash
# Serena MCP Server 包裝腳本
# 自動生成，請勿手動編輯

# 確保 uv 在 PATH 中
export PATH="\$HOME/.cargo/bin:\$PATH"

# 設定專案目錄
PROJECT_DIR="\${SERENA_PROJECT_DIR:-$PROJECT_DIR}"

# 設定環境變數（可在此處自訂）
export SERENA_DEFAULT_MODE="\${SERENA_DEFAULT_MODE:-editing}"
export SERENA_DEBUG="\${SERENA_DEBUG:-false}"

# 執行 Serena MCP Server
# 使用 uvx 從 GitHub 執行最新版本
exec uvx --from git+https://github.com/oraios/serena serena-mcp-server \\
    --context ide-assistant \\
    --project "\$PROJECT_DIR" \\
    "\$@"
EOF
    
    chmod +x "$WRAPPER_PATH"
    success "包裝腳本已創建: $WRAPPER_PATH"
}

# 註冊到 Claude Code CLI
register_to_claude() {
    info "註冊 Serena MCP 到 Claude Code CLI..."
    
    # 使用包裝腳本
    MCP_COMMAND="$HOME/.claude-code-serena.sh"
    
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
            if claude mcp add serena "$MCP_COMMAND" -s user; then
                success "成功註冊到使用者範圍"
            else
                warning "使用者範圍註冊失敗，嘗試專案範圍..."
                claude mcp add serena "$MCP_COMMAND"
                success "成功註冊到專案範圍"
            fi
            ;;
        *)
            info "註冊到專案範圍..."
            claude mcp add serena "$MCP_COMMAND"
            success "成功註冊到專案範圍"
            ;;
    esac
}

# 創建範例專案配置
create_example_config() {
    info "創建範例專案配置..."
    
    EXAMPLE_DIR="$HOME/.serena-examples"
    mkdir -p "$EXAMPLE_DIR"
    
    # 創建範例 .serena 配置
    cat > "$EXAMPLE_DIR/serena-config-example.json" << 'EOF'
{
  "project_name": "my-project",
  "modes": ["editing", "interactive"],
  "language_server": "auto",
  "ignored_patterns": [
    "*.log",
    "*.pyc",
    "__pycache__/",
    "node_modules/",
    ".git/",
    "dist/",
    "build/"
  ],
  "memory_settings": {
    "auto_save": true,
    "max_memories": 100
  }
}
EOF
    
    # 創建範例記憶
    cat > "$EXAMPLE_DIR/memory-example.md" << 'EOF'
# 專案架構記憶

## 技術棧
- 前端：React + TypeScript
- 後端：Node.js + Express
- 資料庫：PostgreSQL
- 測試：Jest + React Testing Library

## 重要慣例
- 使用 ESLint 和 Prettier 進行程式碼格式化
- 所有 API 端點都在 /api 路徑下
- 使用 feature-based 的目錄結構
- 環境變數儲存在 .env 檔案中

## 常用命令
- `npm run dev` - 啟動開發伺服器
- `npm test` - 執行測試
- `npm run build` - 建置生產版本
EOF
    
    success "範例配置已創建在: $EXAMPLE_DIR"
}

# 測試安裝
test_installation() {
    info "測試 Serena MCP 安裝..."
    
    # 檢查註冊
    if claude mcp list | grep -q "serena"; then
        success "Serena MCP 已成功註冊"
    else
        error "Serena MCP 註冊失敗"
        exit 1
    fi
    
    # 測試包裝腳本
    if [ -f "$HOME/.claude-code-serena.sh" ]; then
        info "測試 Serena MCP 通訊..."
        
        # 創建測試腳本
        cat > test-serena.sh << 'EOF'
#!/bin/bash
# 測試 Serena MCP 連接
# 設定超時時間
timeout 30 bash -c 'echo "{\"jsonrpc\":\"2.0\",\"method\":\"initialize\",\"params\":{\"protocolVersion\":\"2024-11-05\"},\"id\":1}" | "$HOME/.claude-code-serena.sh"' 2>&1
EOF
        
        chmod +x test-serena.sh
        
        # 執行測試
        TEST_OUTPUT=$(./test-serena.sh 2>&1)
        
        if echo "$TEST_OUTPUT" | grep -q "serverInfo"; then
            success "Serena MCP 通訊測試成功"
        elif echo "$TEST_OUTPUT" | grep -q "Downloading"; then
            info "首次執行，正在下載 Serena..."
            warning "測試可能需要較長時間，請耐心等待"
        else
            warning "Serena MCP 通訊測試未完成"
            echo "這可能是因為首次下載需要時間"
        fi
        
        rm -f test-serena.sh
    fi
}

# 顯示使用說明
show_usage() {
    echo ""
    echo -e "${GREEN}══════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✨ Serena MCP Server 安裝成功！${NC}"
    echo -e "${GREEN}══════════════════════════════════════════════════${NC}"
    echo ""
    echo "核心功能："
    echo "  檔案操作："
    echo "    • read_file - 讀取檔案"
    echo "    • create_text_file - 創建檔案"
    echo "    • list_dir - 列出目錄"
    echo "    • find_file - 搜尋檔案"
    echo ""
    echo "  符號操作："
    echo "    • find_symbol - 查找符號"
    echo "    • replace_symbol_body - 替換符號內容"
    echo "    • insert_before/after_symbol - 插入程式碼"
    echo ""
    echo "  專案管理："
    echo "    • activate_project - 啟動專案"
    echo "    • write_memory - 儲存專案記憶"
    echo "    • execute_shell_command - 執行命令"
    echo ""
    echo "使用範例："
    echo "  claude '使用 Serena 啟動 my-project 專案'"
    echo "  claude '用 Serena 重構 calculateTotal 函數'"
    echo "  claude '請 Serena 記住這個專案使用 TypeScript'"
    echo ""
    echo "配置說明："
    echo "  包裝腳本位置: $HOME/.claude-code-serena.sh"
    echo "  範例配置位置: $HOME/.serena-examples/"
    echo ""
    echo "專案設定："
    echo "  1. 在專案根目錄創建 .serena/ 資料夾"
    echo "  2. 複製範例配置到 .serena/config.json"
    echo "  3. 使用 activate_project 啟動專案"
    echo ""
    echo "更多資訊："
    echo "  https://github.com/oraios/serena"
}

# 主要安裝流程
main() {
    # 執行檢查
    check_os
    check_python_env
    check_git
    check_node
    check_claude_cli
    check_existing_mcp
    check_and_install_uv
    check_uvx
    
    # 執行安裝
    create_wrapper_script
    register_to_claude
    create_example_config
    test_installation
    
    # 顯示完成訊息
    show_usage
    
    # 寫入安裝日誌
    cat > install.log << EOF
Serena MCP Server 安裝日誌
時間: $(date)
作業系統: $OS
Python: $PYTHON_VERSION
Python 路徑: $PYTHON_BIN
虛擬環境: ${VENV_DIR:-無}
Git: $GIT_VERSION
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