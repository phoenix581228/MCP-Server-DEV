#!/bin/bash
# 北斗七星陣 MCP 團隊管理腳本

set -e

# 顏色定義
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 日誌函數
log_info() {
    echo -e "${GREEN}[管理]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[管理]${NC} $1"
}

log_error() {
    echo -e "${RED}[管理]${NC} $1"
}

log_bigdipper() {
    echo -e "${BLUE}[北斗七星陣]${NC} $1"
}

# 配置變數
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
COMPOSE_FILE="$PROJECT_DIR/docker-compose-bigdipper.yml"

# 檢查 Docker Compose
check_compose() {
    if command -v docker-compose >/dev/null 2>&1; then
        COMPOSE_CMD="docker-compose"
    elif docker compose version >/dev/null 2>&1; then
        COMPOSE_CMD="docker compose"
    else
        log_error "Docker Compose 未安裝"
        exit 1
    fi
}

# 顯示服務狀態
status() {
    log_info "北斗七星陣服務狀態："
    echo
    cd "$PROJECT_DIR"
    $COMPOSE_CMD -f "$COMPOSE_FILE" ps
    echo
    
    # 顯示資源使用情況
    log_info "資源使用情況："
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" | grep -E "(taskmaster|perplexity|context7|openmemory|zen|serena|sequential)" || true
}

# 啟動服務
start() {
    local service=$1
    cd "$PROJECT_DIR"
    
    if [ -z "$service" ]; then
        log_bigdipper "啟動所有北斗七星陣服務..."
        $COMPOSE_CMD -f "$COMPOSE_FILE" up -d
    else
        log_info "啟動服務: $service"
        $COMPOSE_CMD -f "$COMPOSE_FILE" up -d "$service"
    fi
    
    log_info "✓ 服務啟動完成"
}

# 停止服務
stop() {
    local service=$1
    cd "$PROJECT_DIR"
    
    if [ -z "$service" ]; then
        log_bigdipper "停止所有北斗七星陣服務..."
        $COMPOSE_CMD -f "$COMPOSE_FILE" down
    else
        log_info "停止服務: $service"
        $COMPOSE_CMD -f "$COMPOSE_FILE" stop "$service"
    fi
    
    log_info "✓ 服務停止完成"
}

# 重啟服務
restart() {
    local service=$1
    cd "$PROJECT_DIR"
    
    if [ -z "$service" ]; then
        log_bigdipper "重啟所有北斗七星陣服務..."
        $COMPOSE_CMD -f "$COMPOSE_FILE" restart
    else
        log_info "重啟服務: $service"
        $COMPOSE_CMD -f "$COMPOSE_FILE" restart "$service"
    fi
    
    log_info "✓ 服務重啟完成"
}

# 查看日誌
logs() {
    local service=$1
    local lines=${2:-100}
    cd "$PROJECT_DIR"
    
    if [ -z "$service" ]; then
        log_info "顯示所有服務日誌（最近 $lines 行）..."
        $COMPOSE_CMD -f "$COMPOSE_FILE" logs --tail="$lines" -f
    else
        log_info "顯示 $service 服務日誌（最近 $lines 行）..."
        $COMPOSE_CMD -f "$COMPOSE_FILE" logs --tail="$lines" -f "$service"
    fi
}

# 健康檢查
health() {
    local service=$1
    cd "$PROJECT_DIR"
    
    if [ -z "$service" ]; then
        log_info "執行所有服務健康檢查..."
        
        local services=("taskmaster" "perplexity" "context7" "zen-mcp" "serena" "sequential-thinking")
        local healthy_count=0
        
        for svc in "${services[@]}"; do
            log_info "檢查 $svc 服務..."
            if $COMPOSE_CMD -f "$COMPOSE_FILE" exec -T "$svc" ./healthcheck.sh >/dev/null 2>&1; then
                log_info "✓ $svc 健康"
                healthy_count=$((healthy_count + 1))
            else
                log_warn "✗ $svc 不健康"
            fi
        done
        
        # 檢查 OpenMemory
        if curl -f -s http://localhost:8765/health >/dev/null 2>&1; then
            log_info "✓ OpenMemory 健康"
            healthy_count=$((healthy_count + 1))
        else
            log_warn "✗ OpenMemory 不健康"
        fi
        
        log_info "健康檢查結果: $healthy_count/7 服務健康"
    else
        log_info "執行 $service 健康檢查..."
        if [ "$service" = "openmemory" ]; then
            curl -f http://localhost:8765/health
        else
            $COMPOSE_CMD -f "$COMPOSE_FILE" exec "$service" ./healthcheck.sh
        fi
    fi
}

# 更新服務
update() {
    local service=$1
    cd "$PROJECT_DIR"
    
    if [ -z "$service" ]; then
        log_bigdipper "更新所有北斗七星陣服務..."
        
        log_info "拉取最新映像..."
        $COMPOSE_CMD -f "$COMPOSE_FILE" pull
        
        log_info "重建服務..."
        $COMPOSE_CMD -f "$COMPOSE_FILE" build --no-cache
        
        log_info "重新啟動服務..."
        $COMPOSE_CMD -f "$COMPOSE_FILE" up -d
        
        log_info "清理舊映像..."
        docker image prune -f
    else
        log_info "更新服務: $service"
        
        $COMPOSE_CMD -f "$COMPOSE_FILE" pull "$service"
        $COMPOSE_CMD -f "$COMPOSE_FILE" build --no-cache "$service"
        $COMPOSE_CMD -f "$COMPOSE_FILE" up -d --no-deps "$service"
    fi
    
    log_info "✓ 更新完成"
}

# 擴展服務
scale() {
    local service=$1
    local replicas=$2
    cd "$PROJECT_DIR"
    
    if [ -z "$service" ] || [ -z "$replicas" ]; then
        log_error "用法: scale <service> <replicas>"
        exit 1
    fi
    
    log_info "擴展 $service 服務到 $replicas 個實例..."
    $COMPOSE_CMD -f "$COMPOSE_FILE" up -d --scale "$service=$replicas"
    
    log_info "✓ 擴展完成"
}

# 備份數據
backup() {
    local backup_dir="$PROJECT_DIR/backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    log_info "開始備份北斗七星陣數據到: $backup_dir"
    
    # 備份各服務數據
    local volumes=(
        "bigdipper_taskmaster_data:taskmaster_data.tar.gz"
        "bigdipper_perplexity_data:perplexity_data.tar.gz"
        "bigdipper_context7_data:context7_data.tar.gz"
        "bigdipper_openmemory_data:openmemory_data.tar.gz"
        "bigdipper_qdrant_data:qdrant_data.tar.gz"
        "bigdipper_postgres_data:postgres_data.tar.gz"
        "bigdipper_zen_data:zen_data.tar.gz"
        "bigdipper_serena_data:serena_data.tar.gz"
        "bigdipper_sequential_data:sequential_data.tar.gz"
    )
    
    for volume_mapping in "${volumes[@]}"; do
        IFS=':' read -r volume_name backup_name <<< "$volume_mapping"
        log_info "備份 $volume_name..."
        docker run --rm -v "$volume_name":/data -v "$backup_dir":/backup alpine tar czf "/backup/$backup_name" -C /data . 2>/dev/null || log_warn "跳過 $volume_name（可能不存在）"
    done
    
    # 備份配置檔案
    cp "$PROJECT_DIR/.env" "$backup_dir/" 2>/dev/null || log_warn "未找到 .env 檔案"
    cp "$COMPOSE_FILE" "$backup_dir/"
    
    log_info "✓ 備份完成: $backup_dir"
}

# 還原數據
restore() {
    local backup_dir=$1
    
    if [ -z "$backup_dir" ] || [ ! -d "$backup_dir" ]; then
        log_error "用法: restore <backup_directory>"
        exit 1
    fi
    
    log_warn "這將覆蓋現有數據，確定要繼續嗎？"
    read -p "輸入 'yes' 確認: " -r
    if [ "$REPLY" != "yes" ]; then
        log_info "還原已取消"
        exit 0
    fi
    
    log_info "從 $backup_dir 還原數據..."
    
    # 停止服務
    cd "$PROJECT_DIR"
    $COMPOSE_CMD -f "$COMPOSE_FILE" down
    
    # 還原各服務數據
    local volumes=(
        "taskmaster_data.tar.gz:bigdipper_taskmaster_data"
        "perplexity_data.tar.gz:bigdipper_perplexity_data"
        "context7_data.tar.gz:bigdipper_context7_data"
        "openmemory_data.tar.gz:bigdipper_openmemory_data"
        "qdrant_data.tar.gz:bigdipper_qdrant_data"
        "postgres_data.tar.gz:bigdipper_postgres_data"
        "zen_data.tar.gz:bigdipper_zen_data"
        "serena_data.tar.gz:bigdipper_serena_data"
        "sequential_data.tar.gz:bigdipper_sequential_data"
    )
    
    for volume_mapping in "${volumes[@]}"; do
        IFS=':' read -r backup_name volume_name <<< "$volume_mapping"
        if [ -f "$backup_dir/$backup_name" ]; then
            log_info "還原 $volume_name..."
            docker run --rm -v "$volume_name":/data -v "$backup_dir":/backup alpine sh -c "cd /data && rm -rf * && tar xzf /backup/$backup_name"
        else
            log_warn "跳過 $backup_name（備份檔案不存在）"
        fi
    done
    
    # 還原配置檔案
    if [ -f "$backup_dir/.env" ]; then
        cp "$backup_dir/.env" "$PROJECT_DIR/"
        log_info "✓ 還原 .env 檔案"
    fi
    
    log_info "✓ 還原完成"
}

# 清理系統
cleanup() {
    log_warn "這將清理未使用的 Docker 資源，確定要繼續嗎？"
    read -p "輸入 'yes' 確認: " -r
    if [ "$REPLY" != "yes" ]; then
        log_info "清理已取消"
        exit 0
    fi
    
    log_info "清理 Docker 系統..."
    
    # 清理停止的容器
    docker container prune -f
    
    # 清理未使用的映像
    docker image prune -f
    
    # 清理未使用的網路
    docker network prune -f
    
    # 清理未使用的卷（謹慎操作）
    log_warn "是否清理未使用的 Docker 卷？（這可能會刪除數據）"
    read -p "輸入 'yes' 確認: " -r
    if [ "$REPLY" = "yes" ]; then
        docker volume prune -f
    fi
    
    log_info "✓ 清理完成"
}

# 進入服務容器
exec_service() {
    local service=$1
    local command=${2:-bash}
    cd "$PROJECT_DIR"
    
    if [ -z "$service" ]; then
        log_error "用法: exec <service> [command]"
        exit 1
    fi
    
    log_info "進入 $service 容器..."
    $COMPOSE_CMD -f "$COMPOSE_FILE" exec "$service" "$command"
}

# 監控服務
monitor() {
    log_info "監控北斗七星陣服務（按 Ctrl+C 退出）..."
    
    while true; do
        clear
        echo -e "${CYAN}北斗七星陣 MCP 團隊監控面板${NC}"
        echo "更新時間: $(date)"
        echo "======================================"
        
        # 服務狀態
        echo -e "\n${GREEN}服務狀態:${NC}"
        cd "$PROJECT_DIR"
        $COMPOSE_CMD -f "$COMPOSE_FILE" ps
        
        # 資源使用
        echo -e "\n${GREEN}資源使用:${NC}"
        docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" | head -8
        
        # 磁碟使用
        echo -e "\n${GREEN}磁碟使用:${NC}"
        docker system df
        
        sleep 5
    done
}

# 顯示幫助
show_help() {
    echo "北斗七星陣 MCP 團隊管理腳本"
    echo ""
    echo "用法: $0 <command> [options]"
    echo ""
    echo "指令:"
    echo "  status                    顯示所有服務狀態"
    echo "  start [service]           啟動服務（不指定則啟動所有）"
    echo "  stop [service]            停止服務（不指定則停止所有）"
    echo "  restart [service]         重啟服務（不指定則重啟所有）"
    echo "  logs [service] [lines]    查看日誌（預設 100 行）"
    echo "  health [service]          健康檢查（不指定則檢查所有）"
    echo "  update [service]          更新服務（不指定則更新所有）"
    echo "  scale <service> <num>     擴展服務實例數量"
    echo "  backup                    備份所有數據"
    echo "  restore <backup_dir>      還原數據"
    echo "  cleanup                   清理 Docker 系統"
    echo "  exec <service> [cmd]      進入服務容器執行指令"
    echo "  monitor                   監控面板（即時狀態）"
    echo ""
    echo "可用服務:"
    echo "  taskmaster, perplexity, context7, openmemory"
    echo "  zen-mcp, serena, sequential-thinking"
    echo ""
    echo "範例:"
    echo "  $0 status                 # 查看所有服務狀態"
    echo "  $0 restart zen-mcp        # 重啟 Zen MCP 服務"
    echo "  $0 logs taskmaster 50     # 查看 TaskMaster 最近 50 行日誌"
    echo "  $0 exec serena bash       # 進入 Serena 容器"
    echo "  $0 scale perplexity 3     # 擴展 Perplexity 到 3 個實例"
}

# 主程式
main() {
    check_compose
    
    case "${1:-}" in
        status)
            status
            ;;
        start)
            start "$2"
            ;;
        stop)
            stop "$2"
            ;;
        restart)
            restart "$2"
            ;;
        logs)
            logs "$2" "$3"
            ;;
        health)
            health "$2"
            ;;
        update)
            update "$2"
            ;;
        scale)
            scale "$2" "$3"
            ;;
        backup)
            backup
            ;;
        restore)
            restore "$2"
            ;;
        cleanup)
            cleanup
            ;;
        exec)
            exec_service "$2" "$3"
            ;;
        monitor)
            monitor
            ;;
        help|--help|-h)
            show_help
            ;;
        "")
            log_error "請指定指令"
            echo "使用 '$0 help' 查看可用指令"
            exit 1
            ;;
        *)
            log_error "未知指令: $1"
            echo "使用 '$0 help' 查看可用指令"
            exit 1
            ;;
    esac
}

main "$@"