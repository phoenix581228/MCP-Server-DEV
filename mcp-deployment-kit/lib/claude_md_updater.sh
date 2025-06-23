#!/bin/bash

# CLAUDE.md 更新腳本
# 將 MCP Server 開發原則加入目標系統的 CLAUDE.md

set -euo pipefail

# 顏色定義
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 路徑定義
CLAUDE_DIR="$HOME/.claude"
CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/../templates"
BACKUP_DIR="$CLAUDE_DIR/backups"

# 建立必要目錄
ensure_directories() {
    mkdir -p "$CLAUDE_DIR"
    mkdir -p "$BACKUP_DIR"
}

# 備份現有 CLAUDE.md
backup_claude_md() {
    if [ -f "$CLAUDE_MD" ]; then
        local backup_file="$BACKUP_DIR/CLAUDE.md.$(date +%Y%m%d_%H%M%S).bak"
        cp "$CLAUDE_MD" "$backup_file"
        echo -e "${GREEN}✅ 已備份現有 CLAUDE.md 到: $backup_file${NC}"
    fi
}

# 創建或初始化 CLAUDE.md
init_claude_md() {
    if [ ! -f "$CLAUDE_MD" ]; then
        echo -e "${YELLOW}📝 創建新的 CLAUDE.md...${NC}"
        cat > "$CLAUDE_MD" << 'EOF'
# Claude 全域開發規範

此檔案包含 Claude 在所有專案中應遵循的全域開發規範。

## 重要提醒：請使用繁體中文

**關鍵規則**：與使用者溝通時，除非使用者明確要求使用其他語言，否則請一律使用繁體中文回應。

EOF
        echo -e "${GREEN}✅ CLAUDE.md 已創建${NC}"
    fi
}

# 檢查是否已有 MCP 開發原則
check_existing_mcp_section() {
    if grep -q "MCP Server 開發原則" "$CLAUDE_MD" 2>/dev/null; then
        echo -e "${YELLOW}⚠️  發現現有的 MCP Server 開發原則部分${NC}"
        read -p "是否要更新現有內容？(y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "跳過 MCP 開發原則更新"
            return 1
        fi
        # 移除現有的 MCP 部分
        remove_mcp_section
    fi
    return 0
}

# 移除現有的 MCP 部分
remove_mcp_section() {
    # 使用標記來識別和移除自動管理的區塊
    if grep -q "MCP_AUTO_START:mcp_dev_principles" "$CLAUDE_MD"; then
        # 創建臨時文件
        local temp_file=$(mktemp)
        
        # 移除標記之間的內容
        awk '
        /<!-- MCP_AUTO_START:mcp_dev_principles -->/ { skip = 1 }
        /<!-- MCP_AUTO_END:mcp_dev_principles -->/ { skip = 0; next }
        !skip { print }
        ' "$CLAUDE_MD" > "$temp_file"
        
        mv "$temp_file" "$CLAUDE_MD"
        echo -e "${GREEN}✅ 已移除現有的 MCP 部分${NC}"
    fi
}

# 添加 MCP 開發原則
add_mcp_principles() {
    echo -e "${YELLOW}📝 添加 MCP Server 開發原則...${NC}"
    
    # 檢查模板文件
    local template_file="$TEMPLATE_DIR/mcp_dev_principles.md"
    if [ ! -f "$template_file" ]; then
        echo -e "${RED}❌ 錯誤：找不到模板文件 $template_file${NC}"
        return 1
    fi
    
    # 添加內容到 CLAUDE.md
    echo "" >> "$CLAUDE_MD"
    cat "$template_file" >> "$CLAUDE_MD"
    echo "" >> "$CLAUDE_MD"
    
    echo -e "${GREEN}✅ MCP Server 開發原則已添加${NC}"
}

# 添加端口保護函數
add_port_protection() {
    echo -e "${YELLOW}📝 更新端口保護設定...${NC}"
    
    # 檢查是否已有端口保護函數
    if ! grep -q "check_mcp_ports" "$CLAUDE_MD"; then
        cat >> "$CLAUDE_MD" << 'EOF'

## MCP Server Port Protection

### 保留端口檢查函數
```bash
# MCP Server 端口保護檢查
check_mcp_ports() {
    local MCP_PORTS=(8765 6333 5432 3000 8080 9997 1234 11434)
    echo "=== MCP Server Port Protection Check ==="
    local conflict=0
    
    for port in "${MCP_PORTS[@]}"; do
        if lsof -ti:$port >/dev/null 2>&1; then
            local process_info=$(lsof -ti:$port | xargs ps -p 2>/dev/null | tail -n 1)
            if [[ ! "$process_info" =~ (openmemory|perplexity|mcp|qdrant|postgres) ]]; then
                echo "❌ WARNING: Non-MCP process using MCP reserved port $port"
                echo "   $process_info"
                conflict=1
            else
                echo "✅ Port $port is used by MCP service"
            fi
        else
            echo "✅ Port $port is available"
        fi
    done
    
    if [ $conflict -eq 1 ]; then
        echo "⚠️  Please resolve port conflicts before starting MCP services"
        return 1
    fi
    
    echo "✅ All MCP ports are protected"
    return 0
}
```
EOF
    fi
}

# 更新 COMMON_PORTS 陣列
update_common_ports() {
    echo -e "${YELLOW}📝 更新 COMMON_PORTS 陣列...${NC}"
    
    # 檢查是否已有 COMMON_PORTS
    if grep -q "COMMON_PORTS=" "$CLAUDE_MD"; then
        # 使用 sed 更新現有陣列，確保包含 MCP 端口
        sed -i.bak 's/COMMON_PORTS=.*/COMMON_PORTS=(3000 3001 4000 4200 5000 5173 5174 8000 8080 8081 8082 8083 8765 6333 5432 9997 1234 11434)/' "$CLAUDE_MD"
    else
        echo -e "${YELLOW}未找到 COMMON_PORTS 陣列，跳過更新${NC}"
    fi
}

# 驗證更新
verify_update() {
    echo -e "\n${YELLOW}🔍 驗證更新...${NC}"
    
    if grep -q "MCP Server 開發原則" "$CLAUDE_MD"; then
        echo -e "${GREEN}✅ MCP 開發原則已成功添加${NC}"
    else
        echo -e "${RED}❌ MCP 開發原則添加失敗${NC}"
        return 1
    fi
    
    if grep -q "check_mcp_ports" "$CLAUDE_MD"; then
        echo -e "${GREEN}✅ 端口保護函數已添加${NC}"
    else
        echo -e "${YELLOW}⚠️  端口保護函數未添加${NC}"
    fi
}

# 主函數
main() {
    echo -e "${GREEN}=== CLAUDE.md 更新工具 ===${NC}"
    echo -e "將 MCP Server 開發原則加入全域配置\n"
    
    # 確保目錄存在
    ensure_directories
    
    # 備份現有文件
    backup_claude_md
    
    # 初始化 CLAUDE.md
    init_claude_md
    
    # 檢查並更新 MCP 部分
    if check_existing_mcp_section; then
        add_mcp_principles
        add_port_protection
        update_common_ports
    fi
    
    # 驗證更新
    verify_update
    
    echo -e "\n${GREEN}✅ CLAUDE.md 更新完成！${NC}"
    echo -e "文件位置: $CLAUDE_MD"
}

# 執行主函數
main "$@"