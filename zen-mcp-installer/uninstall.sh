#!/bin/bash

# Zen MCP Server 解除安裝腳本
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
echo "║         Zen MCP Server 解除安裝程式              ║"
echo "╚══════════════════════════════════════════════════╝"
echo -e "${NC}"

# 確認解除安裝
confirm_uninstall() {
    warning "即將解除安裝 Zen MCP Server"
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
    info "檢查 Zen MCP 註冊..."
    
    if ! check_claude_cli; then
        warning "跳過 MCP 註冊移除"
        return
    fi
    
    # 檢查是否有註冊
    if claude mcp list 2>/dev/null | grep -q "zen"; then
        info "移除 Zen MCP 註冊..."
        
        # 嘗試從各個範圍移除
        claude mcp remove zen -s user 2>/dev/null || true
        claude mcp remove zen -s project 2>/dev/null || true
        claude mcp remove zen -s local 2>/dev/null || true
        claude mcp remove zen 2>/dev/null || true
        
        success "已移除 Zen MCP 註冊"
    else
        info "未發現 Zen MCP 註冊"
    fi
}

# 移除包裝腳本
remove_wrapper_script() {
    info "檢查包裝腳本..."
    
    WRAPPER_PATH="$HOME/.claude-code-zen.sh"
    
    if [ -f "$WRAPPER_PATH" ]; then
        info "移除包裝腳本..."
        rm -f "$WRAPPER_PATH"
        success "已移除包裝腳本"
    else
        info "未發現包裝腳本"
    fi
}

# 清理 npm 快取
clean_npm_cache() {
    info "清理 npm 快取..."
    
    # 清理 npx 快取中的 zen-mcp
    if [ -d "$HOME/.npm/_npx" ]; then
        find "$HOME/.npm/_npx" -name "*zen-mcp*" -type d -exec rm -rf {} + 2>/dev/null || true
        success "已清理 npm 快取"
    fi
}

# 檢查殘留進程
check_processes() {
    info "檢查 Zen MCP 相關進程..."
    
    # 查找相關進程
    ZEN_PIDS=$(ps aux | grep -E "(zen-mcp|@gptscript-ai/zen-mcp)" | grep -v grep | awk '{print $2}' || true)
    
    if [ -n "$ZEN_PIDS" ]; then
        warning "發現執行中的 Zen MCP 進程"
        echo "PID: $ZEN_PIDS"
        echo -n "是否要終止這些進程？[y/N] "
        read -r response
        
        if [[ "$response" =~ ^[Yy]$ ]]; then
            for pid in $ZEN_PIDS; do
                kill $pid 2>/dev/null || true
            done
            success "已終止相關進程"
        fi
    else
        info "沒有發現執行中的進程"
    fi
}

# 清理日誌檔案
clean_logs() {
    info "清理日誌檔案..."
    
    # 清理可能的日誌位置
    rm -f /tmp/zen-mcp*.log 2>/dev/null || true
    rm -f ./zen-mcp*.log 2>/dev/null || true
    
    success "已清理日誌檔案"
}

# 顯示解除安裝完成訊息
show_completion() {
    echo ""
    echo -e "${GREEN}══════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✓ Zen MCP Server 已成功解除安裝${NC}"
    echo -e "${GREEN}══════════════════════════════════════════════════${NC}"
    echo ""
    echo "已執行的操作："
    echo "  • 移除 Claude CLI 中的 MCP 註冊"
    echo "  • 刪除包裝腳本"
    echo "  • 清理 npm 快取"
    echo "  • 終止相關進程"
    echo "  • 清理日誌檔案"
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
    clean_npm_cache
    check_processes
    clean_logs
    
    # 顯示完成訊息
    show_completion
    
    # 寫入解除安裝日誌
    cat > uninstall.log << EOF
Zen MCP Server 解除安裝日誌
時間: $(date)
狀態: 成功
EOF
    
    success "解除安裝日誌已保存到 uninstall.log"
}

# 錯誤處理
trap 'error "解除安裝過程中發生錯誤"; exit 1' ERR

# 執行主程式
main