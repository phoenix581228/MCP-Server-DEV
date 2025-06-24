#!/bin/bash

# Serena MCP Server 解除安裝腳本
# 版本: 1.0.0

set -e

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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
echo -e "${RED}"
echo "╔══════════════════════════════════════════════════╗"
echo "║         Serena MCP Server 解除安裝程式           ║"
echo "╚══════════════════════════════════════════════════╝"
echo -e "${NC}"

# 確認解除安裝
confirm_uninstall() {
    warning "即將解除安裝 Serena MCP Server"
    echo "這將會："
    echo "  • 移除 Claude CLI 中的 Serena MCP 註冊"
    echo "  • 刪除包裝腳本"
    echo "  • 解除安裝 Python 套件（可選）"
    echo "  • 保留專案記憶和配置"
    echo ""
    echo -n "確定要繼續嗎？[y/N] "
    read -r response
    
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        info "取消解除安裝"
        exit 0
    fi
}

# 檢查 Claude CLI
check_claude_cli() {
    if ! command -v claude &> /dev/null; then
        warning "找不到 Claude Code CLI，可能已經解除安裝"
        return 1
    fi
    return 0
}

# 移除 MCP 註冊
remove_mcp_registration() {
    info "檢查 Serena MCP 註冊..."
    
    if ! check_claude_cli; then
        warning "跳過 MCP 註冊移除"
        return
    fi
    
    # 檢查是否有註冊
    if claude mcp list 2>/dev/null | grep -q "serena"; then
        info "移除 Serena MCP 註冊..."
        
        # 嘗試從各個範圍移除
        claude mcp remove serena -s user 2>/dev/null || true
        claude mcp remove serena -s project 2>/dev/null || true
        claude mcp remove serena -s local 2>/dev/null || true
        claude mcp remove serena 2>/dev/null || true
        
        success "已移除 Serena MCP 註冊"
    else
        info "未發現 Serena MCP 註冊"
    fi
}

# 移除包裝腳本
remove_wrapper_script() {
    info "檢查包裝腳本..."
    
    WRAPPER_PATH="$HOME/.claude-code-serena.sh"
    
    if [ -f "$WRAPPER_PATH" ]; then
        info "移除包裝腳本..."
        rm -f "$WRAPPER_PATH"
        success "已移除包裝腳本"
    else
        info "未發現包裝腳本"
    fi
}

# 解除安裝 Python 套件
uninstall_python_package() {
    echo ""
    echo -n "是否要解除安裝 Serena Python 套件？[y/N] "
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        info "解除安裝 Serena Python 套件..."
        
        # 檢測虛擬環境
        if [ -n "$VIRTUAL_ENV" ]; then
            PIP_BIN="$VIRTUAL_ENV/bin/pip3"
        elif [ -d "$HOME/projects" ] && [ -f "$HOME/projects/bin/pip3" ]; then
            PIP_BIN="$HOME/projects/bin/pip3"
        else
            PIP_BIN="pip3"
        fi
        
        if $PIP_BIN uninstall -y serena-mcp 2>/dev/null; then
            success "已解除安裝 Python 套件"
        else
            warning "Python 套件可能已經被解除安裝或未安裝"
        fi
    else
        info "保留 Python 套件"
    fi
}

# 檢查殘留進程
check_processes() {
    info "檢查 Serena MCP 相關進程..."
    
    # 查找相關進程
    SERENA_PIDS=$(ps aux | grep -E "(serena|serena-mcp)" | grep -v grep | awk '{print $2}' || true)
    
    if [ -n "$SERENA_PIDS" ]; then
        warning "發現執行中的 Serena MCP 進程"
        echo "PID: $SERENA_PIDS"
        echo -n "是否要終止這些進程？[y/N] "
        read -r response
        
        if [[ "$response" =~ ^[Yy]$ ]]; then
            for pid in $SERENA_PIDS; do
                kill $pid 2>/dev/null || true
            done
            success "已終止相關進程"
        fi
    else
        info "沒有發現執行中的進程"
    fi
}

# 清理範例配置
clean_examples() {
    echo ""
    echo -n "是否要刪除範例配置檔案？[y/N] "
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        EXAMPLE_DIR="$HOME/.serena-examples"
        if [ -d "$EXAMPLE_DIR" ]; then
            rm -rf "$EXAMPLE_DIR"
            success "已刪除範例配置"
        fi
    else
        info "保留範例配置"
    fi
}

# 顯示專案記憶提醒
show_memory_reminder() {
    echo ""
    echo -e "${YELLOW}重要提醒：${NC}"
    echo "專案記憶和配置檔案不會被自動刪除。"
    echo "這些檔案通常位於："
    echo "  • 各專案的 .serena/ 目錄"
    echo "  • 包含 memories/ 和 config.json"
    echo ""
    echo "如需完全清理，請手動刪除這些目錄。"
}

# 清理日誌檔案
clean_logs() {
    info "清理日誌檔案..."
    
    # 清理可能的日誌位置
    rm -f /tmp/serena*.log 2>/dev/null || true
    rm -f ./serena*.log 2>/dev/null || true
    
    success "已清理日誌檔案"
}

# 顯示解除安裝完成訊息
show_completion() {
    echo ""
    echo -e "${GREEN}══════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✓ Serena MCP Server 已成功解除安裝${NC}"
    echo -e "${GREEN}══════════════════════════════════════════════════${NC}"
    echo ""
    echo "已執行的操作："
    echo "  • 移除 Claude CLI 中的 MCP 註冊"
    echo "  • 刪除包裝腳本"
    if [[ "$UNINSTALLED_PACKAGE" == "yes" ]]; then
        echo "  • 解除安裝 Python 套件"
    fi
    echo "  • 終止相關進程"
    echo "  • 清理日誌檔案"
    echo ""
    echo "保留的項目："
    echo "  • 專案記憶（.serena/memories/）"
    echo "  • 專案配置（.serena/config.json）"
    echo ""
    echo "如需重新安裝，請執行 ./install.sh"
}

# 主要解除安裝流程
main() {
    # 確認解除安裝
    confirm_uninstall
    
    # 執行解除安裝步驟
    remove_mcp_registration
    remove_wrapper_script
    
    # 可選步驟
    UNINSTALLED_PACKAGE="no"
    uninstall_python_package && UNINSTALLED_PACKAGE="yes"
    clean_examples
    
    # 清理步驟
    check_processes
    clean_logs
    
    # 顯示提醒
    show_memory_reminder
    
    # 顯示完成訊息
    show_completion
    
    # 寫入解除安裝日誌
    cat > uninstall.log << EOF
Serena MCP Server 解除安裝日誌
時間: $(date)
Python 套件解除安裝: $UNINSTALLED_PACKAGE
狀態: 成功
EOF
    
    success "解除安裝日誌已保存到 uninstall.log"
}

# 錯誤處理
trap 'error "解除安裝過程中發生錯誤"; exit 1' ERR

# 執行主程式
main