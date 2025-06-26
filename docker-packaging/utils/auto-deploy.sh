#!/bin/bash
# 北斗七星陣自動化部署流程
# Big Dipper Formation - Automated Deployment Pipeline

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
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
INSTALL_DIR="$HOME/.bigdipper"
LOG_FILE="$INSTALL_DIR/auto-deploy.log"
CONFIG_FILE="$INSTALL_DIR/deploy-config.yaml"
DEPLOYMENT_ID="deploy_$(date +%Y%m%d_%H%M%S)"

# 部署配置
SKIP_CHECKS=false
SKIP_DOCKER_INSTALL=false
SKIP_API_CONFIG=false
QUIET_MODE=false
DRY_RUN=false
PARALLEL_BUILD=true
ENABLE_MONITORING=true
AUTO_START=true

# 建立日誌目錄
mkdir -p "$INSTALL_DIR"

# 日誌函數
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$DEPLOYMENT_ID] $1" | tee -a "$LOG_FILE"
}

log_info() {
    echo -e "${GREEN}[部署]${NC} $1" | tee -a "$LOG_FILE"
}

log_warn() {
    echo -e "${YELLOW}[警告]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[錯誤]${NC} $1" | tee -a "$LOG_FILE"
}

log_step() {
    echo -e "${CYAN}[步驟]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[成功]${NC} $1" | tee -a "$LOG_FILE"
}

log_pipeline() {
    echo -e "${PURPLE}[流水線]${NC} $1" | tee -a "$LOG_FILE"
}

# 顯示部署橫幅
show_deploy_banner() {
    if [ "$QUIET_MODE" != true ]; then
        clear
        echo -e "${PURPLE}"
        cat << 'EOF'
    ╔══════════════════════════════════════════════════════════════════════╗
    ║                    🚀 北斗七星陣自動化部署                           ║
    ║                Big Dipper Formation Auto Deploy                     ║
    ║                                                                      ║
    ║              全自動化 CI/CD 部署流水線                                ║
    ║            Fully Automated CI/CD Deployment Pipeline                ║
    ╚══════════════════════════════════════════════════════════════════════╝
EOF
        echo -e "${NC}"
        echo
    fi
}

# 載入部署配置
load_deploy_config() {
    log_step "載入部署配置..."
    
    # 建立預設配置
    if [ ! -f "$CONFIG_FILE" ]; then
        cat > "$CONFIG_FILE" << EOF
deployment:
  mode: "auto"
  parallel_build: true
  enable_monitoring: true
  auto_start: true
  cleanup_on_failure: true

checks:
  skip_system_check: false
  skip_docker_check: false
  skip_port_check: false
  skip_network_check: false

docker:
  build_timeout: 1800
  pull_timeout: 600
  start_timeout: 300
  parallel_limit: 4

monitoring:
  enable_healthcheck: true
  enable_metrics: true
  enable_logging: true
  retention_days: 7

notifications:
  enable_slack: false
  enable_email: false
  webhook_url: ""

security:
  scan_images: false
  use_secrets: false
  enforce_https: false
EOF
        log_info "建立預設部署配置"
    fi
    
    # 載入配置變數
    if command -v yq >/dev/null 2>&1; then
        PARALLEL_BUILD=$(yq eval '.deployment.parallel_build' "$CONFIG_FILE" 2>/dev/null || echo "true")
        ENABLE_MONITORING=$(yq eval '.monitoring.enable_healthcheck' "$CONFIG_FILE" 2>/dev/null || echo "true")
        AUTO_START=$(yq eval '.deployment.auto_start' "$CONFIG_FILE" 2>/dev/null || echo "true")
    fi
    
    log_success "部署配置載入完成"
}

# 預檢查階段
pre_deployment_checks() {
    log_pipeline "執行預檢查階段..."
    
    local checks_passed=true
    
    if [ "$SKIP_CHECKS" != true ]; then
        # 系統需求檢查
        log_step "執行系統需求檢查..."
        if [ -f "$SCRIPT_DIR/system-check.sh" ]; then
            if ! "$SCRIPT_DIR/system-check.sh" --quiet; then
                log_warn "系統檢查發現問題，建議檢查後繼續"
                if [ "$DRY_RUN" != true ]; then
                    read -p "是否繼續部署？(y/N): " -r
                    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                        log_error "部署被使用者取消"
                        exit 1
                    fi
                fi
                checks_passed=false
            fi
        else
            log_warn "系統檢查腳本不存在，跳過檢查"
        fi
        
        # 端口衝突檢查
        log_step "檢查端口衝突..."
        local ports=(8080 8082 8765 9119 9120 9121 9122 3000 6333 5432 24282)
        local conflicts=()
        
        for port in "${ports[@]}"; do
            if command -v lsof >/dev/null 2>&1; then
                if lsof -ti:$port >/dev/null 2>&1; then
                    conflicts+=("$port")
                fi
            fi
        done
        
        if [ ${#conflicts[@]} -gt 0 ]; then
            log_warn "發現端口衝突: ${conflicts[*]}"
            checks_passed=false
        else
            log_success "端口檢查通過"
        fi
        
        # Docker 環境檢查
        log_step "檢查 Docker 環境..."
        if ! command -v docker >/dev/null 2>&1; then
            log_error "Docker 未安裝"
            checks_passed=false
        elif ! docker info >/dev/null 2>&1; then
            log_error "Docker daemon 未運行"
            checks_passed=false
        else
            log_success "Docker 環境正常"
        fi
        
        # 網路連線檢查
        log_step "檢查網路連線..."
        if ! ping -c 1 8.8.8.8 >/dev/null 2>&1; then
            log_warn "網路連線可能有問題"
            checks_passed=false
        else
            log_success "網路連線正常"
        fi
    else
        log_info "跳過預檢查階段"
    fi
    
    if [ "$checks_passed" = true ]; then
        log_success "預檢查階段完成"
        return 0
    else
        log_warn "預檢查階段發現問題"
        return 1
    fi
}

# 準備階段
preparation_phase() {
    log_pipeline "執行準備階段..."
    
    # 建立工作目錄
    log_step "準備工作目錄..."
    local work_dir="$INSTALL_DIR/deployment/$DEPLOYMENT_ID"
    mkdir -p "$work_dir"
    cd "$work_dir"
    
    # 複製部署檔案
    log_step "複製部署檔案..."
    if [ -d "$PROJECT_DIR" ]; then
        cp -r "$PROJECT_DIR"/* "$work_dir/"
        log_success "部署檔案複製完成"
    else
        log_error "找不到專案目錄: $PROJECT_DIR"
        return 1
    fi
    
    # 準備環境配置
    log_step "準備環境配置..."
    if [ ! -f ".env" ]; then
        if [ -f ".env.bigdipper.template" ]; then
            cp ".env.bigdipper.template" ".env"
            log_info "從範本建立環境檔案"
            
            # 自動 API 配置
            if [ "$SKIP_API_CONFIG" != true ] && [ -f "$SCRIPT_DIR/api-wizard.sh" ]; then
                log_info "啟動 API 配置精靈..."
                if [ "$QUIET_MODE" = true ]; then
                    "$SCRIPT_DIR/api-wizard.sh" --quick ".env"
                else
                    "$SCRIPT_DIR/api-wizard.sh" ".env"
                fi
            fi
        else
            log_error "找不到環境檔案範本"
            return 1
        fi
    else
        log_info "環境檔案已存在"
    fi
    
    # 建立 Docker 網路
    log_step "建立 Docker 網路..."
    if ! docker network ls | grep -q "bigdipper_mcp_network"; then
        docker network create bigdipper_mcp_network
        log_success "Docker 網路建立完成"
    else
        log_info "Docker 網路已存在"
    fi
    
    log_success "準備階段完成"
    return 0
}

# 建置階段
build_phase() {
    log_pipeline "執行建置階段..."
    
    # 拉取基礎映像
    log_step "拉取基礎映像..."
    local base_images=(
        "node:20-alpine"
        "python:3.11-slim"
        "redis:7-alpine"
        "postgres:15-alpine"
        "qdrant/qdrant:latest"
    )
    
    if [ "$PARALLEL_BUILD" = true ]; then
        log_info "並行拉取基礎映像..."
        for image in "${base_images[@]}"; do
            {
                log_info "拉取 $image..."
                docker pull "$image"
                log_success "$image 拉取完成"
            } &
        done
        wait
    else
        for image in "${base_images[@]}"; do
            log_info "拉取 $image..."
            docker pull "$image"
        done
    fi
    
    log_success "基礎映像拉取完成"
    
    # 建立服務映像
    log_step "建立服務映像..."
    
    if [ "$DRY_RUN" = true ]; then
        log_info "DRY RUN: 跳過實際建置"
    else
        local compose_cmd=""
        if command -v docker-compose >/dev/null 2>&1; then
            compose_cmd="docker-compose"
        elif docker compose version >/dev/null 2>&1; then
            compose_cmd="docker compose"
        else
            log_error "找不到 Docker Compose"
            return 1
        fi
        
        # 建置映像
        log_info "開始建置所有服務映像..."
        if [ "$PARALLEL_BUILD" = true ]; then
            timeout 1800 $compose_cmd -f docker-compose-bigdipper.yml build --parallel --no-cache
        else
            timeout 1800 $compose_cmd -f docker-compose-bigdipper.yml build --no-cache
        fi
        
        log_success "服務映像建置完成"
    fi
    
    log_success "建置階段完成"
    return 0
}

# 部署階段
deployment_phase() {
    log_pipeline "執行部署階段..."
    
    if [ "$DRY_RUN" = true ]; then
        log_info "DRY RUN: 跳過實際部署"
        return 0
    fi
    
    # 啟動服務
    log_step "啟動北斗七星陣服務..."
    
    local compose_cmd=""
    if command -v docker-compose >/dev/null 2>&1; then
        compose_cmd="docker-compose"
    else
        compose_cmd="docker compose"
    fi
    
    # 按順序啟動服務（依賴關係）
    local service_groups=(
        "redis-perplexity redis-context7 redis-zen postgres qdrant"  # 基礎服務
        "openmemory"                                                  # OpenMemory 服務
        "taskmaster perplexity context7 zen-mcp serena sequential-thinking"  # MCP 服務
    )
    
    for group in "${service_groups[@]}"; do
        log_info "啟動服務群組: $group"
        
        for service in $group; do
            log_info "啟動 $service..."
            timeout 300 $compose_cmd -f docker-compose-bigdipper.yml up -d "$service"
            
            # 等待服務就緒
            local retry_count=0
            local max_retries=30
            
            while [ $retry_count -lt $max_retries ]; do
                if docker ps --filter "name=${service}" --filter "status=running" | grep -q "$service"; then
                    log_success "$service 啟動成功"
                    break
                fi
                
                retry_count=$((retry_count + 1))
                sleep 2
            done
            
            if [ $retry_count -eq $max_retries ]; then
                log_error "$service 啟動超時"
                return 1
            fi
        done
        
        # 群組間等待
        sleep 5
    done
    
    log_success "所有服務啟動完成"
    
    # 等待服務穩定
    log_step "等待服務穩定..."
    sleep 30
    
    log_success "部署階段完成"
    return 0
}

# 驗證階段
verification_phase() {
    log_pipeline "執行驗證階段..."
    
    local verification_passed=true
    
    # 容器狀態檢查
    log_step "檢查容器狀態..."
    local expected_containers=("taskmaster_mcp_server" "perplexity_mcp_server" "context7_mcp_server" "zen_mcp_server" "serena_mcp_server" "sequential_thinking_server")
    
    for container in "${expected_containers[@]}"; do
        if docker ps --filter "name=$container" --filter "status=running" | grep -q "$container"; then
            log_success "✓ $container 運行正常"
        else
            log_error "✗ $container 未運行"
            verification_passed=false
        fi
    done
    
    # 健康檢查
    log_step "執行健康檢查..."
    if [ -f "scripts/manage.sh" ]; then
        if ./scripts/manage.sh health >/dev/null 2>&1; then
            log_success "健康檢查通過"
        else
            log_warn "健康檢查發現問題"
            verification_passed=false
        fi
    fi
    
    # 端口檢查
    log_step "檢查服務端口..."
    local service_ports=(
        "9120:TaskMaster"
        "8080:Perplexity"
        "9119:Context7"
        "8765:OpenMemory"
        "8082:Zen MCP"
        "9121:Serena"
        "9122:Sequential"
    )
    
    for port_service in "${service_ports[@]}"; do
        IFS=':' read -r port service <<< "$port_service"
        
        if command -v nc >/dev/null 2>&1; then
            if nc -z localhost "$port" 2>/dev/null; then
                log_success "✓ $service 端口 $port 可用"
            else
                log_warn "✗ $service 端口 $port 不可用"
                verification_passed=false
            fi
        fi
    done
    
    # API 連線測試
    log_step "測試 API 連線..."
    local api_endpoints=(
        "http://localhost:8765/health:OpenMemory Health"
        "http://localhost:3000:OpenMemory UI"
    )
    
    for endpoint_desc in "${api_endpoints[@]}"; do
        IFS=':' read -r endpoint desc <<< "$endpoint_desc"
        
        if command -v curl >/dev/null 2>&1; then
            if curl -f -s "$endpoint" >/dev/null 2>&1; then
                log_success "✓ $desc 連線正常"
            else
                log_warn "✗ $desc 連線失敗"
                verification_passed=false
            fi
        fi
    done
    
    if [ "$verification_passed" = true ]; then
        log_success "驗證階段完成"
        return 0
    else
        log_warn "驗證階段發現問題"
        return 1
    fi
}

# 後部署配置
post_deployment_config() {
    log_pipeline "執行後部署配置..."
    
    # MCP Server 註冊
    log_step "註冊 MCP Servers..."
    if [ -f "register_bigdipper_mcp.sh" ] && command -v claude >/dev/null 2>&1; then
        if [ "$DRY_RUN" != true ]; then
            chmod +x register_bigdipper_mcp.sh
            ./register_bigdipper_mcp.sh
            log_success "MCP Servers 註冊完成"
        else
            log_info "DRY RUN: 跳過 MCP 註冊"
        fi
    else
        log_warn "無法註冊 MCP Servers（缺少 Claude CLI 或註冊腳本）"
    fi
    
    # 設定監控
    if [ "$ENABLE_MONITORING" = true ]; then
        log_step "設定監控..."
        
        # 建立監控腳本
        cat > "$INSTALL_DIR/monitor-bigdipper.sh" << 'EOF'
#!/bin/bash
# 北斗七星陣監控腳本

BIGDIPPER_DIR="$HOME/.bigdipper/deployment"
LATEST_DEPLOY=$(ls -t "$BIGDIPPER_DIR" | head -1)

if [ ! -z "$LATEST_DEPLOY" ]; then
    cd "$BIGDIPPER_DIR/$LATEST_DEPLOY"
    exec ./scripts/manage.sh monitor
else
    echo "找不到部署目錄"
    exit 1
fi
EOF
        
        chmod +x "$INSTALL_DIR/monitor-bigdipper.sh"
        log_success "監控設定完成"
    fi
    
    # 建立快捷指令
    log_step "建立快捷指令..."
    
    # 控制腳本
    cat > "$INSTALL_DIR/bigdipper-control" << EOF
#!/bin/bash
# 北斗七星陣控制腳本

BIGDIPPER_DIR="$HOME/.bigdipper/deployment"
LATEST_DEPLOY=\$(ls -t "\$BIGDIPPER_DIR" | head -1)

if [ -z "\$LATEST_DEPLOY" ]; then
    echo "找不到部署目錄"
    exit 1
fi

cd "\$BIGDIPPER_DIR/\$LATEST_DEPLOY"

case "\$1" in
    start|stop|restart|status|logs|health|monitor)
        exec ./scripts/manage.sh "\$@"
        ;;
    deploy)
        exec "$SCRIPT_DIR/auto-deploy.sh" "\${@:2}"
        ;;
    *)
        echo "用法: \$0 {start|stop|restart|status|logs|health|monitor|deploy}"
        echo ""
        echo "服務管理："
        echo "  start     啟動所有服務"
        echo "  stop      停止所有服務" 
        echo "  restart   重啟所有服務"
        echo "  status    查看服務狀態"
        echo "  logs      查看服務日誌"
        echo "  health    健康檢查"
        echo "  monitor   監控面板"
        echo ""
        echo "部署管理："
        echo "  deploy    重新部署"
        ;;
esac
EOF
    
    chmod +x "$INSTALL_DIR/bigdipper-control"
    
    # 建立系統連結
    if [ -w "/usr/local/bin" ] || sudo -n true 2>/dev/null; then
        if command -v sudo >/dev/null 2>&1; then
            sudo ln -sf "$INSTALL_DIR/bigdipper-control" /usr/local/bin/bigdipper
            log_success "全域指令 'bigdipper' 建立完成"
        fi
    fi
    
    log_success "後部署配置完成"
}

# 生成部署報告
generate_deployment_report() {
    log_step "生成部署報告..."
    
    local report_file="$INSTALL_DIR/deployment-report-$DEPLOYMENT_ID.md"
    
    cat > "$report_file" << EOF
# 北斗七星陣部署報告

**部署 ID**: $DEPLOYMENT_ID  
**部署時間**: $(date)  
**部署模式**: $([ "$DRY_RUN" = true ] && echo "DRY RUN" || echo "正式部署")

## 部署配置

- **並行建置**: $PARALLEL_BUILD
- **啟用監控**: $ENABLE_MONITORING  
- **自動啟動**: $AUTO_START
- **跳過檢查**: $SKIP_CHECKS

## 服務狀態

$(if [ "$DRY_RUN" != true ]; then
    echo "### 運行中的容器"
    echo '```'
    docker ps --filter "label=bigdipper.service" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo '```'
    
    echo ""
    echo "### 資源使用"
    echo '```'
    docker stats --no-stream --filter "label=bigdipper.service" --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"
    echo '```'
fi)

## 服務端點

- 🌟 TaskMaster AI: http://localhost:9120
- 🌟 Perplexity Custom: http://localhost:8080  
- 🌟 Context7 Cached: http://localhost:9119
- 🌟 OpenMemory API: http://localhost:8765
- 🌟 OpenMemory Web UI: http://localhost:3000
- 🌟 Zen MCP: http://localhost:8082
- 🌟 Serena: http://localhost:9121
- 🌟 Serena Dashboard: http://localhost:24282
- 🌟 Sequential Thinking: http://localhost:9122

## 管理指令

\`\`\`bash
# 服務管理
bigdipper status    # 查看狀態
bigdipper logs      # 查看日誌
bigdipper restart   # 重啟服務
bigdipper monitor   # 監控面板

# 直接管理
cd $INSTALL_DIR/deployment/$DEPLOYMENT_ID
./scripts/manage.sh <command>
\`\`\`

## 部署日誌

部署詳細日誌請查看: $LOG_FILE

## 故障排除

如遇問題，請檢查：
1. 容器狀態: \`docker ps\`
2. 容器日誌: \`docker logs <container_name>\`
3. 系統資源: \`docker stats\`
4. 端口占用: \`netstat -tulpn\`

---
*報告生成時間: $(date)*
EOF
    
    log_success "部署報告已生成: $report_file"
    
    # 在終端顯示摘要
    if [ "$QUIET_MODE" != true ]; then
        echo
        echo -e "${CYAN}部署摘要:${NC}"
        echo "========="
        echo "部署 ID: $DEPLOYMENT_ID"
        echo "工作目錄: $INSTALL_DIR/deployment/$DEPLOYMENT_ID"
        echo "部署日誌: $LOG_FILE"
        echo "部署報告: $report_file"
        echo
        
        if [ "$DRY_RUN" != true ]; then
            echo "服務端點: http://localhost:3000 (OpenMemory UI)"
            echo "管理指令: bigdipper status"
        fi
    fi
}

# 清理函數
cleanup_on_failure() {
    if [ $? -ne 0 ] && [ "$DRY_RUN" != true ]; then
        log_error "部署失敗，執行清理..."
        
        # 停止容器
        local work_dir="$INSTALL_DIR/deployment/$DEPLOYMENT_ID"
        if [ -d "$work_dir" ]; then
            cd "$work_dir"
            if [ -f "docker-compose-bigdipper.yml" ]; then
                local compose_cmd=""
                if command -v docker-compose >/dev/null 2>&1; then
                    compose_cmd="docker-compose"
                else
                    compose_cmd="docker compose"
                fi
                
                $compose_cmd -f docker-compose-bigdipper.yml down 2>/dev/null || true
                log_info "已停止失敗的容器"
            fi
        fi
        
        # 清理映像（可選）
        read -p "是否清理建置失敗的映像？(y/N): " -r
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            docker images --filter "dangling=true" -q | xargs -r docker rmi
            log_info "已清理懸空映像"
        fi
    fi
}

# 顯示部署完成訊息
show_completion_message() {
    if [ "$QUIET_MODE" != true ]; then
        echo
        echo -e "${GREEN}"
        cat << 'EOF'
    ╔════════════════════════════════════════════════════════════════════════╗
    ║                     🎉 自動化部署完成！                                ║
    ║                  Automated Deployment Complete!                       ║
    ╚════════════════════════════════════════════════════════════════════════╝
EOF
        echo -e "${NC}"
        
        if [ "$DRY_RUN" = true ]; then
            echo -e "${YELLOW}DRY RUN 模式完成 - 未進行實際部署${NC}"
        else
            echo -e "${GREEN}🌟 北斗七星陣已成功部署並運行！${NC}"
        fi
        
        echo
        echo -e "${CYAN}快速開始：${NC}"
        echo "1. 檢查狀態: bigdipper status"
        echo "2. 查看服務: docker ps"
        echo "3. 開啟 UI: http://localhost:3000"
        echo "4. 監控服務: bigdipper monitor"
        echo
    fi
}

# 主部署流程
main() {
    trap cleanup_on_failure EXIT
    
    show_deploy_banner
    
    log_pipeline "開始自動化部署流程 - $DEPLOYMENT_ID"
    log_info "部署模式: $([ "$DRY_RUN" = true ] && echo "DRY RUN" || echo "正式部署")"
    
    # 載入配置
    load_deploy_config
    
    # 執行部署流水線
    local pipeline_status=0
    
    # 1. 預檢查階段
    if ! pre_deployment_checks; then
        if [ "$DRY_RUN" != true ]; then
            log_error "預檢查失敗，部署終止"
            exit 1
        fi
        pipeline_status=1
    fi
    
    # 2. 準備階段
    if ! preparation_phase; then
        log_error "準備階段失敗，部署終止"
        exit 1
    fi
    
    # 3. 建置階段
    if ! build_phase; then
        log_error "建置階段失敗，部署終止"
        exit 1
    fi
    
    # 4. 部署階段
    if ! deployment_phase; then
        log_error "部署階段失敗，部署終止"
        exit 1
    fi
    
    # 5. 驗證階段
    if ! verification_phase; then
        log_warn "驗證階段發現問題，請檢查"
        pipeline_status=1
    fi
    
    # 6. 後部署配置
    if ! post_deployment_config; then
        log_warn "後部署配置發現問題，請檢查"
        pipeline_status=1
    fi
    
    # 生成報告
    generate_deployment_report
    
    # 顯示完成訊息
    show_completion_message
    
    if [ $pipeline_status -eq 0 ]; then
        log_success "✨ 自動化部署流程完成！"
    else
        log_warn "⚠️ 部署完成但存在警告，請檢查日誌"
    fi
    
    exit $pipeline_status
}

# 處理命令列參數
while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h)
            echo "北斗七星陣自動化部署工具"
            echo ""
            echo "用法: $0 [選項]"
            echo ""
            echo "選項:"
            echo "  --help, -h          顯示此幫助資訊"
            echo "  --dry-run           DRY RUN 模式（不實際部署）"
            echo "  --quiet             靜默模式"
            echo "  --skip-checks       跳過預檢查"
            echo "  --skip-docker       跳過 Docker 安裝檢查"
            echo "  --skip-api          跳過 API 配置"
            echo "  --no-parallel       停用並行建置"
            echo "  --no-monitoring     停用監控"
            echo "  --no-auto-start     不自動啟動服務"
            echo ""
            echo "範例:"
            echo "  $0                  # 完整自動化部署"
            echo "  $0 --dry-run        # 模擬部署（不實際執行）"
            echo "  $0 --quiet          # 靜默部署"
            echo "  $0 --skip-checks    # 跳過系統檢查"
            echo ""
            exit 0
            ;;
        --dry-run)
            DRY_RUN=true
            ;;
        --quiet)
            QUIET_MODE=true
            ;;
        --skip-checks)
            SKIP_CHECKS=true
            ;;
        --skip-docker)
            SKIP_DOCKER_INSTALL=true
            ;;
        --skip-api)
            SKIP_API_CONFIG=true
            ;;
        --no-parallel)
            PARALLEL_BUILD=false
            ;;
        --no-monitoring)
            ENABLE_MONITORING=false
            ;;
        --no-auto-start)
            AUTO_START=false
            ;;
        *)
            log_error "未知選項: $1"
            exit 1
            ;;
    esac
    shift
done

# 執行主流程
main