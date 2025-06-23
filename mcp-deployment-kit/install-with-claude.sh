#!/bin/bash

# MCP Server 一鍵部署腳本 - Claude Code 優化版
# 適用於 macOS 15.5+

set -euo pipefail

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# 全域變數
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/install.log"
CLAUDE_MODE=${CLAUDE_MODE:-false}
STEP_COUNT=0
TOTAL_STEPS=10

# 初始化日誌
init_log() {
    echo "=== MCP Server 部署開始 $(date) ===" > "$LOG_FILE"
    echo "腳本目錄: $SCRIPT_DIR" >> "$LOG_FILE"
    echo "Claude Mode: $CLAUDE_MODE" >> "$LOG_FILE"
}

# Claude 友好的輸出
claude_output() {
    local task=$1
    local status=$2
    local message=${3:-""}
    
    echo -e "${BLUE}[TASK:$task]${NC} Status: $status"
    if [ -n "$message" ]; then
        echo "  $message"
    fi
    echo "---"
    
    # 同時記錄到日誌
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$task] $status - $message" >> "$LOG_FILE"
}

# 進度顯示
show_progress() {
    local current=$1
    local total=$2
    local task=$3
    
    local percentage=$((current * 100 / total))
    echo -e "${PURPLE}進度: [$current/$total] $percentage% - $task${NC}"
}

# 錯誤處理
handle_error() {
    local error_code=$?
    local error_context=$1
    
    claude_output "error" "failed" "錯誤代碼: $error_code, 上下文: $error_context"
    
    if [ "$CLAUDE_MODE" = true ]; then
        echo -e "${RED}🤖 Claude，請協助處理此錯誤：${NC}"
        echo "1. 使用 WebSearch 搜尋錯誤解決方案"
        echo "2. 查看 troubleshooting.md"
        echo "3. 嘗試替代方法"
    fi
    
    exit $error_code
}

# 檢測 Claude Code 環境
detect_claude_code() {
    echo -e "${BLUE}🤖 檢測 Claude Code 環境...${NC}"
    
    if [ -n "${CLAUDE_CODE_VERSION:-}" ]; then
        CLAUDE_MODE=true
        claude_output "claude-detection" "completed" "偵測到 Claude Code v$CLAUDE_CODE_VERSION"
    else
        claude_output "claude-detection" "completed" "標準模式執行"
    fi
}

# 環境檢查
check_environment() {
    STEP_COUNT=$((STEP_COUNT + 1))
    show_progress $STEP_COUNT $TOTAL_STEPS "環境檢查"
    
    claude_output "environment-check" "in_progress" "開始環境檢查..."
    
    # macOS 版本
    OS_VERSION=$(sw_vers -productVersion)
    claude_output "os-check" "completed" "macOS $OS_VERSION"
    
    # 檢查各種依賴
    local deps_missing=false
    
    # Homebrew
    if command -v brew >/dev/null 2>&1; then
        claude_output "homebrew-check" "completed" "$(brew --version | head -1)"
    else
        claude_output "homebrew-check" "missing" "需要安裝 Homebrew"
        deps_missing=true
    fi
    
    # Node.js
    if command -v node >/dev/null 2>&1; then
        NODE_VERSION=$(node --version)
        claude_output "nodejs-check" "completed" "Node.js $NODE_VERSION"
    else
        claude_output "nodejs-check" "missing" "需要安裝 Node.js"
        deps_missing=true
    fi
    
    # Python
    if command -v python3 >/dev/null 2>&1; then
        PYTHON_VERSION=$(python3 --version)
        claude_output "python-check" "completed" "$PYTHON_VERSION"
    else
        claude_output "python-check" "missing" "需要安裝 Python 3"
        deps_missing=true
    fi
    
    # Docker
    if command -v docker >/dev/null 2>&1; then
        if docker info >/dev/null 2>&1; then
            claude_output "docker-check" "completed" "Docker 運行中"
        else
            claude_output "docker-check" "warning" "Docker 已安裝但未運行"
        fi
    else
        claude_output "docker-check" "missing" "需要安裝 Docker Desktop"
    fi
    
    # Claude CLI
    if command -v claude >/dev/null 2>&1; then
        claude_output "claude-cli-check" "completed" "Claude CLI 已安裝"
    else
        claude_output "claude-cli-check" "critical" "必須先安裝 Claude Code CLI！"
        echo -e "${RED}錯誤：未檢測到 Claude Code CLI${NC}"
        echo "請先安裝 Claude Code CLI 再執行此腳本"
        exit 1
    fi
    
    claude_output "environment-check" "completed" "環境檢查完成"
    
    if [ "$deps_missing" = true ]; then
        echo -e "${YELLOW}發現缺失的依賴，需要先安裝${NC}"
        if [ "$1" != "--check-only" ]; then
            read -p "是否自動安裝缺失的依賴？(y/N) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                install_dependencies
            fi
        fi
    fi
}

# 檢查端口
check_ports() {
    STEP_COUNT=$((STEP_COUNT + 1))
    show_progress $STEP_COUNT $TOTAL_STEPS "端口檢查"
    
    claude_output "port-check" "in_progress" "檢查 MCP 保留端口..."
    
    # MCP 保留端口
    local ports=(8765 6333 5432 3000 8080 9997 1234 11434)
    local port_names=(
        "OpenMemory API"
        "Qdrant"
        "PostgreSQL"
        "Web UI"
        "Perplexity"
        "Xinference"
        "LM Studio"
        "Ollama"
    )
    
    local conflicts=0
    for i in "${!ports[@]}"; do
        local port=${ports[$i]}
        local name=${port_names[$i]}
        
        if lsof -ti:$port >/dev/null 2>&1; then
            local process=$(lsof -ti:$port | xargs ps -p 2>/dev/null | tail -n 1 | awk '{print $4}')
            claude_output "port-$port" "conflict" "$name - 被 $process 占用"
            ((conflicts++))
        else
            claude_output "port-$port" "available" "$name"
        fi
    done
    
    if [ $conflicts -gt 0 ]; then
        echo -e "${YELLOW}⚠️  發現 $conflicts 個端口衝突${NC}"
        read -p "是否繼續？(y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    claude_output "port-check" "completed" "端口檢查完成"
}

# 安裝依賴
install_dependencies() {
    STEP_COUNT=$((STEP_COUNT + 1))
    show_progress $STEP_COUNT $TOTAL_STEPS "安裝依賴"
    
    claude_output "dependencies" "in_progress" "開始安裝系統依賴..."
    
    # 執行依賴安裝腳本
    if [ -f "$SCRIPT_DIR/lib/install_dependencies.sh" ]; then
        source "$SCRIPT_DIR/lib/install_dependencies.sh"
    else
        echo -e "${YELLOW}警告：依賴安裝腳本不存在${NC}"
    fi
    
    claude_output "dependencies" "completed" "依賴安裝完成"
}

# 部署 MCP Servers
deploy_mcp_servers() {
    STEP_COUNT=$((STEP_COUNT + 1))
    show_progress $STEP_COUNT $TOTAL_STEPS "部署 MCP Servers"
    
    claude_output "mcp-deployment" "in_progress" "開始部署 MCP Servers..."
    
    local servers=(
        "perplexity:perplexity-mcp-custom"
        "zen:zen-mcp-server"
        "openmemory:openmemory-mcp-config"
        "serena:serena-mcp-server"
        "taskmaster:taskmaster-mcp-config"
    )
    
    for server in "${servers[@]}"; do
        IFS=':' read -r name full_name <<< "$server"
        
        claude_output "deploy-$name" "in_progress" "部署 $full_name..."
        
        if [ -f "$SCRIPT_DIR/services/$name/deploy.sh" ]; then
            bash "$SCRIPT_DIR/services/$name/deploy.sh" || {
                claude_output "deploy-$name" "failed" "部署失敗"
                continue
            }
        else
            claude_output "deploy-$name" "skipped" "部署腳本不存在"
        fi
        
        claude_output "deploy-$name" "completed" "完成"
    done
    
    claude_output "mcp-deployment" "completed" "所有 MCP Servers 部署完成"
}

# 更新 CLAUDE.md
update_claude_md() {
    STEP_COUNT=$((STEP_COUNT + 1))
    show_progress $STEP_COUNT $TOTAL_STEPS "更新 CLAUDE.md"
    
    claude_output "claude-md-update" "in_progress" "更新全域開發規範..."
    
    if [ -f "$SCRIPT_DIR/lib/claude_md_updater.sh" ]; then
        bash "$SCRIPT_DIR/lib/claude_md_updater.sh" || {
            claude_output "claude-md-update" "failed" "更新失敗"
            return 1
        }
    fi
    
    claude_output "claude-md-update" "completed" "CLAUDE.md 更新完成"
}

# 驗證安裝
verify_installation() {
    STEP_COUNT=$((STEP_COUNT + 1))
    show_progress $STEP_COUNT $TOTAL_STEPS "驗證安裝"
    
    claude_output "verification" "in_progress" "驗證 MCP Servers..."
    
    # 檢查註冊的 MCP Servers
    local registered_count=$(claude mcp list 2>/dev/null | grep -c "registered" || echo "0")
    
    claude_output "verification" "completed" "發現 $registered_count 個已註冊的 MCP Server"
    
    # 生成報告
    generate_report
}

# 生成安裝報告
generate_report() {
    local report_file="$SCRIPT_DIR/installation_report.md"
    
    cat > "$report_file" << EOF
# MCP Server 安裝報告

生成時間: $(date)

## 環境資訊
- macOS 版本: $OS_VERSION
- Node.js: $(node --version 2>/dev/null || echo "未安裝")
- Python: $(python3 --version 2>/dev/null || echo "未安裝")
- Docker: $(docker --version 2>/dev/null || echo "未安裝")

## MCP Servers 狀態
$(claude mcp list 2>/dev/null || echo "無法獲取 MCP 列表")

## 安裝日誌
詳見: $LOG_FILE
EOF
    
    echo -e "${GREEN}✅ 安裝報告已生成: $report_file${NC}"
}

# 主函數
main() {
    echo -e "${BLUE}╔══════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║   MCP Server 一鍵部署工具 v1.0.0    ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════╝${NC}"
    echo
    
    init_log
    detect_claude_code
    
    # 解析參數
    case "${1:-}" in
        --check-only)
            check_environment --check-only
            check_ports
            ;;
        --install)
            check_environment
            check_ports
            deploy_mcp_servers
            update_claude_md
            verify_installation
            ;;
        --help)
            echo "使用方法："
            echo "  $0 --check-only  # 只檢查環境"
            echo "  $0 --install     # 執行完整安裝"
            echo "  $0 --help        # 顯示幫助"
            ;;
        *)
            # 預設：互動式安裝
            check_environment
            check_ports
            
            echo
            echo -e "${GREEN}環境檢查完成！${NC}"
            read -p "是否開始安裝 MCP Servers？(y/N) " -n 1 -r
            echo
            
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                deploy_mcp_servers
                update_claude_md
                verify_installation
            else
                echo "安裝已取消"
            fi
            ;;
    esac
    
    echo
    echo -e "${GREEN}✅ 完成！${NC}"
}

# 錯誤捕捉
trap 'handle_error "未預期的錯誤"' ERR

# 執行主函數
main "$@"