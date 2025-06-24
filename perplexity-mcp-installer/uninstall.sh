#!/bin/bash

# Perplexity Custom MCP Server 卸載腳本
# 版本: 1.0.0

set -e

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}================================================================${NC}"
    echo -e "${BLUE}   Perplexity Custom MCP Server 卸載程式   ${NC}"
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

# 主卸載流程
main() {
    print_header
    
    print_warn "此操作將移除 Perplexity Custom MCP Server"
    echo ""
    read -p "確定要繼續嗎？(y/N) " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "取消卸載"
        exit 0
    fi
    
    # 1. 從 Claude Code CLI 移除
    print_info "從 Claude Code CLI 移除註冊..."
    
    # 嘗試從不同範圍移除
    claude mcp remove perplexity -s user 2>/dev/null || true
    claude mcp remove perplexity -s project 2>/dev/null || true
    claude mcp remove perplexity 2>/dev/null || true
    
    if claude mcp list 2>/dev/null | grep -q "perplexity"; then
        print_warn "可能未完全移除，請手動檢查：claude mcp list"
    else
        print_success "已從 Claude Code CLI 移除"
    fi
    
    # 2. 刪除包裝腳本
    if [ -f "$HOME/.claude-code-perplexity.sh" ]; then
        print_info "刪除包裝腳本..."
        rm -f "$HOME/.claude-code-perplexity.sh"
        print_success "包裝腳本已刪除"
    fi
    
    # 3. 卸載 Python 套件
    print_info "檢查並卸載 Python 套件..."
    
    # 檢測虛擬環境
    if [ -n "$VIRTUAL_ENV" ]; then
        PIP_BIN="$VIRTUAL_ENV/bin/pip3"
    elif [ -f "$HOME/projects/bin/pip3" ]; then
        PIP_BIN="$HOME/projects/bin/pip3"
    else
        PIP_BIN="pip3"
    fi
    
    if "$PIP_BIN" show perplexity-mcp-custom &> /dev/null; then
        print_info "卸載 perplexity-mcp-custom..."
        "$PIP_BIN" uninstall -y perplexity-mcp-custom
        print_success "Python 套件已卸載"
    else
        print_info "未找到已安裝的 Python 套件"
    fi
    
    # 4. 清理環境變數提示
    print_info "環境變數清理提示："
    echo ""
    echo "如果您在 shell 配置文件中設定了 PERPLEXITY_API_KEY，"
    echo "請手動從以下文件中移除相關行："
    echo ""
    
    if [ -f "$HOME/.zshrc" ]; then
        if grep -q "PERPLEXITY_API_KEY" "$HOME/.zshrc"; then
            echo "  ~/.zshrc"
        fi
    fi
    
    if [ -f "$HOME/.bashrc" ]; then
        if grep -q "PERPLEXITY_API_KEY" "$HOME/.bashrc"; then
            echo "  ~/.bashrc"
        fi
    fi
    
    echo ""
    print_success "卸載完成！"
    echo ""
    echo "如需重新安裝，請執行 install.sh"
}

# 執行主流程
main "$@"