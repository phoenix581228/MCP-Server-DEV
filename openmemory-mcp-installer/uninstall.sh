#!/bin/bash

# OpenMemory MCP Server 解除安裝腳本
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
echo "║         OpenMemory MCP Server 解除安裝程式       ║"
echo "╚══════════════════════════════════════════════════╝"
echo -e "${NC}"

# 確認解除安裝
confirm_uninstall() {
    warning "即將解除安裝 OpenMemory MCP Server"
    echo "這將會："
    echo "  • 停止所有 Docker 容器"
    echo "  • 移除 Claude CLI 中的 MCP 註冊"
    echo "  • 刪除包裝腳本"
    echo "  • 可選：刪除 Docker 映像"
    echo "  • 可選：刪除資料卷"
    echo ""
    echo -n "確定要繼續嗎？[y/N] "
    read -r response
    
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        info "取消解除安裝"
        exit 0
    fi
}

# 檢查 Docker
check_docker() {
    if ! command -v docker &> /dev/null; then
        warning "找不到 Docker，可能已經解除安裝"
        return 1
    fi
    
    # 檢查 Docker Compose
    if command -v docker-compose &> /dev/null; then
        COMPOSE_CMD="docker-compose"
    elif docker compose version &> /dev/null; then
        COMPOSE_CMD="docker compose"
    else
        warning "找不到 Docker Compose"
        return 1
    fi
    
    return 0
}

# 停止 Docker 服務
stop_docker_services() {
    info "停止 Docker 服務..."
    
    if [ -d "docker" ]; then
        cd docker
        
        # 停止服務
        if $COMPOSE_CMD ps 2>/dev/null | grep -q "Up"; then
            info "停止運行中的容器..."
            $COMPOSE_CMD down
            success "容器已停止"
        else
            info "沒有運行中的容器"
        fi
        
        cd ..
    else
        warning "找不到 docker 目錄"
    fi
}

# 移除 Docker 映像
remove_docker_images() {
    echo ""
    echo -n "是否要刪除 Docker 映像？[y/N] "
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        info "移除 Docker 映像..."
        
        IMAGES=("openmemory/api" "openmemory/web" "openmemory/mcp")
        
        for image in "${IMAGES[@]}"; do
            if docker images | grep -q "$image"; then
                docker rmi "$image:latest" 2>/dev/null || true
                success "已移除映像: $image"
            fi
        done
    else
        info "保留 Docker 映像"
    fi
}

# 移除資料卷
remove_data_volumes() {
    echo ""
    warning "資料卷包含所有儲存的記憶！"
    echo -n "是否要刪除資料卷？[y/N] "
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo -n "請再次確認要刪除所有資料？[yes/NO] "
        read -r confirm
        
        if [[ "$confirm" == "yes" ]]; then
            info "移除資料卷..."
            
            # 移除命名卷
            docker volume rm openmemory-mcp-installer_postgres_data 2>/dev/null || true
            docker volume rm openmemory-mcp-installer_qdrant_data 2>/dev/null || true
            
            # 移除本地卷目錄
            rm -rf docker/volumes 2>/dev/null || true
            
            success "資料卷已刪除"
        else
            info "取消刪除資料卷"
        fi
    else
        info "保留資料卷"
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
    info "檢查 OpenMemory MCP 註冊..."
    
    if ! check_claude_cli; then
        warning "跳過 MCP 註冊移除"
        return
    fi
    
    # 檢查是否有註冊
    if claude mcp list 2>/dev/null | grep -q "openmemory"; then
        info "移除 OpenMemory MCP 註冊..."
        
        # 嘗試從各個範圍移除
        claude mcp remove openmemory -s user 2>/dev/null || true
        claude mcp remove openmemory -s project 2>/dev/null || true
        claude mcp remove openmemory -s local 2>/dev/null || true
        claude mcp remove openmemory 2>/dev/null || true
        
        success "已移除 OpenMemory MCP 註冊"
    else
        info "未發現 OpenMemory MCP 註冊"
    fi
}

# 移除包裝腳本
remove_wrapper_script() {
    info "檢查包裝腳本..."
    
    WRAPPER_PATH="$HOME/.claude-code-openmemory.sh"
    
    if [ -f "$WRAPPER_PATH" ]; then
        info "移除包裝腳本..."
        rm -f "$WRAPPER_PATH"
        success "已移除包裝腳本"
    else
        info "未發現包裝腳本"
    fi
}

# 清理配置檔案
clean_config_files() {
    echo ""
    echo -n "是否要刪除配置檔案和備份？[y/N] "
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        info "清理配置檔案..."
        
        # 保留備份提醒
        if [ -d "docker/backups" ] && [ "$(ls -A docker/backups)" ]; then
            warning "發現備份檔案！"
            echo -n "是否要保留備份？[Y/n] "
            read -r keep_backup
            
            if [[ ! "$keep_backup" =~ ^[Nn]$ ]]; then
                mv docker/backups ./openmemory_backups_$(date +%Y%m%d_%H%M%S)
                success "備份已移至當前目錄"
            else
                rm -rf docker/backups
            fi
        fi
        
        # 刪除 docker 目錄
        rm -rf docker
        success "配置檔案已清理"
    else
        info "保留配置檔案"
    fi
}

# 清理管理腳本
clean_management_scripts() {
    info "清理管理腳本..."
    
    SCRIPTS=("health-check.sh" "backup.sh" "check-ports.sh" "update.sh" "reset-services.sh")
    
    for script in "${SCRIPTS[@]}"; do
        if [ -f "$script" ]; then
            rm -f "$script"
        fi
    done
    
    success "管理腳本已清理"
}

# 清理日誌檔案
clean_logs() {
    info "清理日誌檔案..."
    
    rm -f install.log 2>/dev/null || true
    rm -f uninstall.log 2>/dev/null || true
    rm -f /tmp/openmemory*.log 2>/dev/null || true
    
    success "日誌檔案已清理"
}

# 顯示解除安裝完成訊息
show_completion() {
    echo ""
    echo -e "${GREEN}══════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✓ OpenMemory MCP Server 已成功解除安裝${NC}"
    echo -e "${GREEN}══════════════════════════════════════════════════${NC}"
    echo ""
    echo "已執行的操作："
    echo "  • 停止 Docker 容器"
    echo "  • 移除 Claude CLI 中的 MCP 註冊"
    echo "  • 刪除包裝腳本"
    echo "  • 清理管理腳本"
    if [[ "$REMOVED_IMAGES" == "yes" ]]; then
        echo "  • 移除 Docker 映像"
    fi
    if [[ "$REMOVED_VOLUMES" == "yes" ]]; then
        echo "  • 刪除資料卷"
    fi
    echo ""
    if [[ "$KEPT_BACKUP" == "yes" ]]; then
        echo "保留的項目："
        echo "  • 備份檔案已移至當前目錄"
    fi
    echo ""
    echo "如需重新安裝，請執行 ./install.sh"
}

# 主要解除安裝流程
main() {
    # 確認解除安裝
    confirm_uninstall
    
    # 停止服務
    if check_docker; then
        stop_docker_services
    fi
    
    # 移除 MCP 註冊
    remove_mcp_registration
    remove_wrapper_script
    
    # 可選操作
    REMOVED_IMAGES="no"
    REMOVED_VOLUMES="no"
    KEPT_BACKUP="no"
    
    if check_docker; then
        remove_docker_images && REMOVED_IMAGES="yes"
        remove_data_volumes && REMOVED_VOLUMES="yes"
    fi
    
    # 清理檔案
    clean_config_files
    clean_management_scripts
    clean_logs
    
    # 顯示完成訊息
    show_completion
    
    # 寫入解除安裝日誌
    cat > uninstall.log << EOF
OpenMemory MCP Server 解除安裝日誌
時間: $(date)
移除映像: $REMOVED_IMAGES
刪除資料: $REMOVED_VOLUMES
狀態: 成功
EOF
    
    success "解除安裝日誌已保存到 uninstall.log"
}

# 錯誤處理
trap 'error "解除安裝過程中發生錯誤"; exit 1' ERR

# 執行主程式
main