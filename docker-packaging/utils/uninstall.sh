#!/bin/bash
# 北斗七星陣完整解除安裝腳本
# Big Dipper Formation - Complete Uninstall Script

set -e

# 顏色定義
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# 全域變數
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$HOME/.bigdipper"
UNINSTALL_LOG="$INSTALL_DIR/uninstall-$(date +%Y%m%d_%H%M%S).log"
BACKUP_DIR="$INSTALL_DIR/uninstall-backup"

# 確保日誌目錄存在
mkdir -p "$INSTALL_DIR"
mkdir -p "$BACKUP_DIR"

# 日誌函數
log_info() {
    echo -e "${GREEN}[解除安裝]${NC} $1" | tee -a "$UNINSTALL_LOG"
}

log_warn() {
    echo -e "${YELLOW}[警告]${NC} $1" | tee -a "$UNINSTALL_LOG"
}

log_error() {
    echo -e "${RED}[錯誤]${NC} $1" | tee -a "$UNINSTALL_LOG"
}

log_step() {
    echo -e "${CYAN}[步驟]${NC} $1" | tee -a "$UNINSTALL_LOG"
}

log_success() {
    echo -e "${GREEN}[成功]${NC} $1" | tee -a "$UNINSTALL_LOG"
}

log_remove() {
    echo -e "${RED}[移除]${NC} $1" | tee -a "$UNINSTALL_LOG"
}

# 顯示解除安裝橫幅
show_uninstall_banner() {
    clear
    echo -e "${RED}"
    cat << 'EOF'
    ╔══════════════════════════════════════════════════════════════════════╗
    ║                    🗑️  北斗七星陣解除安裝工具                        ║
    ║                 Big Dipper Formation Uninstaller                     ║
    ║                                                                      ║
    ║                  完整移除系統和相關組件                               ║
    ║               Complete System and Component Removal                  ║
    ╚══════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo
}

# 顯示解除安裝選項
show_uninstall_options() {
    echo -e "${BOLD}請選擇解除安裝選項：${NC}"
    echo
    echo "1. 🔄 停止服務但保留資料 (推薦)"
    echo "2. 🗑️  完整解除安裝 (移除所有檔案和資料)"
    echo "3. 🧹 深度清理 (包含 Docker 映像和網路)"
    echo "4. ⚙️  自訂解除安裝"
    echo "5. ❌ 取消"
    echo
    
    while true; do
        read -p "請輸入選項 (1-5): " choice
        case $choice in
            1) return 1 ;;
            2) return 2 ;;
            3) return 3 ;;
            4) return 4 ;;
            5) 
                log_info "解除安裝已取消"
                exit 0
                ;;
            *)
                echo "無效選項，請重新輸入"
                ;;
        esac
    done
}

# 備份重要資料
backup_important_data() {
    log_step "備份重要資料..."
    
    local backup_created=false
    
    # 備份 MCP 配置
    if command -v claude >/dev/null 2>&1; then
        log_info "備份 MCP 配置..."
        claude mcp list > "$BACKUP_DIR/mcp-servers-backup.txt" 2>/dev/null || true
        backup_created=true
    fi
    
    # 備份環境變數
    local env_files=(
        "$INSTALL_DIR/deployment/*/.env"
        "$HOME/.bigdipper/bigdipper/.env"
    )
    
    for env_pattern in "${env_files[@]}"; do
        for env_file in $env_pattern; do
            if [ -f "$env_file" ]; then
                log_info "備份環境檔案: $env_file"
                cp "$env_file" "$BACKUP_DIR/$(basename "$env_file").backup"
                backup_created=true
            fi
        done
    done
    
    # 備份 Docker Compose 檔案
    local compose_files=(
        "$INSTALL_DIR/deployment/*/docker-compose-bigdipper.yml"
        "$HOME/.bigdipper/bigdipper/docker-compose-bigdipper.yml"
    )
    
    for compose_pattern in "${compose_files[@]}"; do
        for compose_file in $compose_pattern; do
            if [ -f "$compose_file" ]; then
                log_info "備份 Docker Compose 檔案: $compose_file"
                cp "$compose_file" "$BACKUP_DIR/$(basename "$compose_file").backup"
                backup_created=true
            fi
        done
    done
    
    # 備份配置檔案
    if [ -f "$INSTALL_DIR/config.yaml" ]; then
        log_info "備份配置檔案..."
        cp "$INSTALL_DIR/config.yaml" "$BACKUP_DIR/config.yaml.backup"
        backup_created=true
    fi
    
    # 備份資料庫資料（如果使用者要求）
    if docker ps --filter "name=postgres" --filter "status=running" | grep -q postgres; then
        read -p "是否備份 PostgreSQL 資料庫？(y/N): " -r
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log_info "備份 PostgreSQL 資料庫..."
            docker exec postgres pg_dump -U postgres openmemory > "$BACKUP_DIR/openmemory-db-backup.sql" 2>/dev/null || log_warn "資料庫備份失敗"
            backup_created=true
        fi
    fi
    
    if [ "$backup_created" = true ]; then
        log_success "資料備份完成，備份位置: $BACKUP_DIR"
        echo "備份檔案列表:" >> "$UNINSTALL_LOG"
        ls -la "$BACKUP_DIR" >> "$UNINSTALL_LOG"
    else
        log_info "未找到需要備份的資料"
    fi
}

# 停止 Docker 服務
stop_docker_services() {
    log_step "停止 Docker 服務..."
    
    # 查找所有 BigDipper 相關的 Docker Compose 檔案
    local compose_files=(
        "$INSTALL_DIR/deployment/*/docker-compose-bigdipper.yml"
        "$HOME/.bigdipper/bigdipper/docker-compose-bigdipper.yml"
        "$(pwd)/docker-compose-bigdipper.yml"
    )
    
    local services_stopped=false
    
    for compose_pattern in "${compose_files[@]}"; do
        for compose_file in $compose_pattern; do
            if [ -f "$compose_file" ]; then
                log_info "停止服務: $compose_file"
                local compose_dir=$(dirname "$compose_file")
                cd "$compose_dir"
                
                if command -v docker-compose >/dev/null 2>&1; then
                    docker-compose -f "$compose_file" down 2>/dev/null || log_warn "停止服務失敗: $compose_file"
                else
                    docker compose -f "$compose_file" down 2>/dev/null || log_warn "停止服務失敗: $compose_file"
                fi
                services_stopped=true
            fi
        done
    done
    
    # 直接停止 BigDipper 相關容器
    local bigdipper_containers=$(docker ps -a --filter "label=bigdipper.service" --format "{{.Names}}" 2>/dev/null || true)
    
    if [ ! -z "$bigdipper_containers" ]; then
        log_info "直接停止 BigDipper 容器..."
        echo "$bigdipper_containers" | xargs docker stop 2>/dev/null || true
        echo "$bigdipper_containers" | xargs docker rm 2>/dev/null || true
        services_stopped=true
    fi
    
    # 停止特定名稱的容器
    local known_containers=(
        "taskmaster_mcp_server"
        "perplexity_mcp_server"
        "context7_mcp_server"
        "zen_mcp_server"
        "serena_mcp_server"
        "sequential_thinking_server"
        "openmemory_api"
        "openmemory_ui"
        "qdrant"
        "postgres"
        "redis-perplexity"
        "redis-context7"
        "redis-zen"
    )
    
    for container in "${known_containers[@]}"; do
        if docker ps -a --filter "name=$container" | grep -q "$container"; then
            log_info "停止容器: $container"
            docker stop "$container" 2>/dev/null || true
            docker rm "$container" 2>/dev/null || true
            services_stopped=true
        fi
    done
    
    if [ "$services_stopped" = true ]; then
        log_success "Docker 服務已停止"
    else
        log_info "未找到運行中的 BigDipper 服務"
    fi
}

# 移除 Docker 映像
remove_docker_images() {
    log_step "移除 Docker 映像..."
    
    local removed_images=false
    
    # 移除 BigDipper 相關映像
    local bigdipper_images=$(docker images --filter "label=bigdipper.service" --format "{{.Repository}}:{{.Tag}}" 2>/dev/null || true)
    
    if [ ! -z "$bigdipper_images" ]; then
        log_info "移除 BigDipper 標記的映像..."
        echo "$bigdipper_images" | xargs docker rmi -f 2>/dev/null || true
        removed_images=true
    fi
    
    # 移除已知的 BigDipper 映像
    local known_images=(
        "bigdipper/taskmaster"
        "bigdipper/perplexity"
        "bigdipper/context7"
        "bigdipper/zen-mcp"
        "bigdipper/serena"
        "bigdipper/sequential"
        "bigdipper/openmemory"
    )
    
    for image in "${known_images[@]}"; do
        if docker images | grep -q "$image"; then
            log_info "移除映像: $image"
            docker rmi -f "$image" 2>/dev/null || true
            removed_images=true
        fi
    done
    
    # 清理懸空映像
    local dangling_images=$(docker images -f "dangling=true" -q 2>/dev/null || true)
    if [ ! -z "$dangling_images" ]; then
        log_info "清理懸空映像..."
        echo "$dangling_images" | xargs docker rmi -f 2>/dev/null || true
        removed_images=true
    fi
    
    if [ "$removed_images" = true ]; then
        log_success "Docker 映像已移除"
    else
        log_info "未找到需要移除的 Docker 映像"
    fi
}

# 移除 Docker 網路
remove_docker_networks() {
    log_step "移除 Docker 網路..."
    
    local networks_removed=false
    
    # 移除 BigDipper 網路
    if docker network ls | grep -q "bigdipper_mcp_network"; then
        log_info "移除 bigdipper_mcp_network 網路..."
        docker network rm bigdipper_mcp_network 2>/dev/null || log_warn "無法移除網路，可能有容器仍在使用"
        networks_removed=true
    fi
    
    # 移除其他 BigDipper 相關網路
    local bigdipper_networks=$(docker network ls --filter "label=bigdipper.network" --format "{{.Name}}" 2>/dev/null || true)
    
    if [ ! -z "$bigdipper_networks" ]; then
        log_info "移除 BigDipper 標記的網路..."
        echo "$bigdipper_networks" | xargs docker network rm 2>/dev/null || true
        networks_removed=true
    fi
    
    if [ "$networks_removed" = true ]; then
        log_success "Docker 網路已移除"
    else
        log_info "未找到需要移除的 Docker 網路"
    fi
}

# 移除 Docker 卷
remove_docker_volumes() {
    log_step "移除 Docker 卷..."
    
    local volumes_removed=false
    
    # 移除 BigDipper 相關卷
    local bigdipper_volumes=$(docker volume ls --filter "label=bigdipper.volume" --format "{{.Name}}" 2>/dev/null || true)
    
    if [ ! -z "$bigdipper_volumes" ]; then
        log_info "移除 BigDipper 標記的卷..."
        echo "$bigdipper_volumes" | xargs docker volume rm 2>/dev/null || true
        volumes_removed=true
    fi
    
    # 移除已知的資料卷
    local known_volumes=(
        "postgres_data"
        "qdrant_storage"
        "redis_data"
        "openmemory_data"
    )
    
    for volume in "${known_volumes[@]}"; do
        if docker volume ls | grep -q "$volume"; then
            log_info "移除卷: $volume"
            docker volume rm "$volume" 2>/dev/null || log_warn "無法移除卷: $volume"
            volumes_removed=true
        fi
    done
    
    if [ "$volumes_removed" = true ]; then
        log_success "Docker 卷已移除"
    else
        log_info "未找到需要移除的 Docker 卷"
    fi
}

# 解除 MCP Server 註冊
unregister_mcp_servers() {
    log_step "解除 MCP Server 註冊..."
    
    if ! command -v claude >/dev/null 2>&1; then
        log_warn "Claude CLI 未安裝，跳過 MCP 解除註冊"
        return 0
    fi
    
    local mcp_servers=(
        "taskmaster"
        "perplexity"
        "context7"
        "openmemory" 
        "zen"
        "serena"
        "sequential"
    )
    
    local unregistered_count=0
    
    for server in "${mcp_servers[@]}"; do
        if claude mcp list 2>/dev/null | grep -q "$server"; then
            log_info "解除註冊 $server MCP Server..."
            
            # 嘗試從不同範圍移除
            claude mcp remove "$server" -s user 2>/dev/null || true
            claude mcp remove "$server" -s project 2>/dev/null || true
            claude mcp remove "$server" -s local 2>/dev/null || true
            claude mcp remove "$server" 2>/dev/null || true
            
            unregistered_count=$((unregistered_count + 1))
        fi
    done
    
    if [ $unregistered_count -gt 0 ]; then
        log_success "已解除 $unregistered_count 個 MCP Server 註冊"
    else
        log_info "未找到已註冊的 BigDipper MCP Servers"
    fi
}

# 移除檔案和目錄
remove_files_and_directories() {
    log_step "移除檔案和目錄..."
    
    local removed_items=false
    
    # 移除安裝目錄（保留備份）
    if [ -d "$INSTALL_DIR" ]; then
        log_info "移除安裝目錄（保留備份）..."
        
        # 保留備份目錄和日誌
        find "$INSTALL_DIR" -mindepth 1 -not -path "$BACKUP_DIR*" -not -name "*.log" -not -name "uninstall-backup*" -exec rm -rf {} + 2>/dev/null || true
        removed_items=true
    fi
    
    # 移除全域指令連結
    if [ -L "/usr/local/bin/bigdipper" ]; then
        log_info "移除全域指令連結..."
        sudo rm -f /usr/local/bin/bigdipper 2>/dev/null || log_warn "無法移除全域指令連結（需要 sudo 權限）"
        removed_items=true
    fi
    
    # 移除專案目錄（如果指定）
    if [ "$REMOVE_PROJECT_DIR" = true ] && [ -d "$PROJECT_DIR" ]; then
        read -p "是否移除專案目錄 $PROJECT_DIR？這將無法復原！(y/N): " -r
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log_warn "移除專案目錄: $PROJECT_DIR"
            rm -rf "$PROJECT_DIR"
            removed_items=true
        fi
    fi
    
    if [ "$removed_items" = true ]; then
        log_success "檔案和目錄已移除"
    else
        log_info "未移除任何檔案或目錄"
    fi
}

# 清理系統配置
cleanup_system_config() {
    log_step "清理系統配置..."
    
    local cleaned_items=false
    
    # 清理環境變數（如果在 shell 配置中）
    local shell_configs=(
        "$HOME/.bashrc"
        "$HOME/.zshrc"
        "$HOME/.profile"
    )
    
    for config in "${shell_configs[@]}"; do
        if [ -f "$config" ] && grep -q "bigdipper\|BIGDIPPER" "$config"; then
            log_info "清理 $config 中的 BigDipper 配置..."
            # 備份原始檔案
            cp "$config" "$BACKUP_DIR/$(basename "$config").backup"
            # 移除 BigDipper 相關行
            sed -i.bak '/bigdipper\|BIGDIPPER/d' "$config" 2>/dev/null || true
            cleaned_items=true
        fi
    done
    
    # 清理 Crontab（如果有定時任務）
    if crontab -l 2>/dev/null | grep -q "bigdipper\|BIGDIPPER"; then
        log_info "清理 Crontab 中的 BigDipper 任務..."
        crontab -l 2>/dev/null | grep -v "bigdipper\|BIGDIPPER" | crontab - 2>/dev/null || true
        cleaned_items=true
    fi
    
    if [ "$cleaned_items" = true ]; then
        log_success "系統配置已清理"
    else
        log_info "未找到需要清理的系統配置"
    fi
}

# 自訂解除安裝選項
custom_uninstall() {
    echo
    echo -e "${BOLD}自訂解除安裝選項：${NC}"
    echo
    
    # 停止服務
    read -p "停止 Docker 服務？(Y/n): " -r
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        STOP_SERVICES=true
    else
        STOP_SERVICES=false
    fi
    
    # 移除映像
    read -p "移除 Docker 映像？(y/N): " -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        REMOVE_IMAGES=true
    else
        REMOVE_IMAGES=false
    fi
    
    # 移除卷
    read -p "移除 Docker 卷（包含資料）？(y/N): " -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        REMOVE_VOLUMES=true
    else
        REMOVE_VOLUMES=false
    fi
    
    # 解除 MCP 註冊
    read -p "解除 MCP Server 註冊？(Y/n): " -r
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        UNREGISTER_MCP=true
    else
        UNREGISTER_MCP=false
    fi
    
    # 移除檔案
    read -p "移除安裝檔案？(y/N): " -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        REMOVE_FILES=true
    else
        REMOVE_FILES=false
    fi
    
    # 清理配置
    read -p "清理系統配置？(y/N): " -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        CLEANUP_CONFIG=true
    else
        CLEANUP_CONFIG=false
    fi
}

# 執行解除安裝
execute_uninstall() {
    local uninstall_type="$1"
    
    case $uninstall_type in
        1)  # 停止服務但保留資料
            log_info "執行服務停止..."
            backup_important_data
            stop_docker_services
            unregister_mcp_servers
            log_success "服務已停止，資料已保留"
            ;;
        2)  # 完整解除安裝
            log_info "執行完整解除安裝..."
            backup_important_data
            stop_docker_services
            remove_docker_images
            remove_docker_networks
            remove_docker_volumes
            unregister_mcp_servers
            remove_files_and_directories
            cleanup_system_config
            log_success "完整解除安裝完成"
            ;;
        3)  # 深度清理
            log_info "執行深度清理..."
            backup_important_data
            stop_docker_services
            remove_docker_images
            remove_docker_networks
            remove_docker_volumes
            unregister_mcp_servers
            remove_files_and_directories
            cleanup_system_config
            
            # 額外的深度清理
            log_info "執行深度清理..."
            docker system prune -a -f --volumes 2>/dev/null || true
            log_success "深度清理完成"
            ;;
        4)  # 自訂解除安裝
            custom_uninstall
            backup_important_data
            
            [ "$STOP_SERVICES" = true ] && stop_docker_services
            [ "$REMOVE_IMAGES" = true ] && remove_docker_images
            [ "$REMOVE_VOLUMES" = true ] && remove_docker_volumes
            [ "$UNREGISTER_MCP" = true ] && unregister_mcp_servers
            [ "$REMOVE_FILES" = true ] && remove_files_and_directories
            [ "$CLEANUP_CONFIG" = true ] && cleanup_system_config
            
            log_success "自訂解除安裝完成"
            ;;
    esac
}

# 顯示解除安裝完成訊息
show_completion_message() {
    echo
    echo -e "${GREEN}"
    cat << 'EOF'
    ╔════════════════════════════════════════════════════════════════════════╗
    ║                     ✅ 解除安裝完成                                    ║
    ║                    Uninstallation Complete                            ║
    ╚════════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    echo -e "${CYAN}解除安裝摘要：${NC}"
    echo "============="
    echo "解除安裝日誌: $UNINSTALL_LOG"
    echo "資料備份位置: $BACKUP_DIR"
    echo
    
    if [ -d "$BACKUP_DIR" ] && [ "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]; then
        echo -e "${YELLOW}重要提醒：${NC}"
        echo "• 您的重要資料已備份到 $BACKUP_DIR"
        echo "• 如需復原，請參考備份檔案"
        echo "• 備份檔案不會自動清理，請手動管理"
        echo
    fi
    
    echo -e "${GREEN}感謝您使用北斗七星陣 MCP 團隊！${NC}"
    echo "如有任何問題，請參考文檔或聯繫支援團隊"
    echo
}

# 主要解除安裝流程
main() {
    show_uninstall_banner
    
    log_info "開始北斗七星陣解除安裝程序..."
    echo
    
    # 顯示警告
    echo -e "${YELLOW}⚠️  警告：${NC}"
    echo "解除安裝將停止所有 BigDipper 服務並可能移除資料"
    echo "建議在執行前確保已備份重要資料"
    echo
    
    read -p "確定要繼續嗎？(y/N): " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "解除安裝已取消"
        exit 0
    fi
    
    # 顯示解除安裝選項
    show_uninstall_options
    local choice=$?
    
    echo
    log_info "開始執行解除安裝（選項 $choice）..."
    
    # 執行解除安裝
    execute_uninstall $choice
    
    # 顯示完成訊息
    show_completion_message
}

# 處理命令列參數
case "${1:-}" in
    --help|-h)
        echo "北斗七星陣解除安裝工具"
        echo ""
        echo "用法: $0 [選項]"
        echo ""
        echo "選項:"
        echo "  --help, -h       顯示此幫助資訊"
        echo "  --stop-only      僅停止服務，不移除檔案"
        echo "  --force          強制完整解除安裝（跳過確認）"
        echo "  --deep-clean     執行深度清理"
        echo "  --no-backup      不備份資料（危險）"
        echo ""
        echo "範例:"
        echo "  $0               # 互動式解除安裝"
        echo "  $0 --stop-only   # 僅停止服務"
        echo "  $0 --force       # 強制完整解除安裝"
        echo ""
        exit 0
        ;;
    --stop-only)
        show_uninstall_banner
        backup_important_data
        stop_docker_services
        unregister_mcp_servers
        log_success "服務已停止"
        exit 0
        ;;
    --force)
        show_uninstall_banner
        log_warn "強制執行完整解除安裝..."
        backup_important_data
        stop_docker_services
        remove_docker_images
        remove_docker_networks  
        remove_docker_volumes
        unregister_mcp_servers
        remove_files_and_directories
        cleanup_system_config
        show_completion_message
        exit 0
        ;;
    --deep-clean)
        show_uninstall_banner
        log_warn "執行深度清理..."
        backup_important_data
        stop_docker_services
        remove_docker_images
        remove_docker_networks
        remove_docker_volumes
        unregister_mcp_servers
        remove_files_and_directories
        cleanup_system_config
        docker system prune -a -f --volumes 2>/dev/null || true
        show_completion_message
        exit 0
        ;;
    --no-backup)
        # 設定標記跳過備份
        SKIP_BACKUP=true
        main
        ;;
    *)
        main
        ;;
esac