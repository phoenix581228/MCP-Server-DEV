#!/bin/bash
# 北斗七星陣 MCP 團隊自動部署腳本

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
    echo -e "${GREEN}[部署]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[部署]${NC} $1"
}

log_error() {
    echo -e "${RED}[部署]${NC} $1"
}

log_step() {
    echo -e "${CYAN}[步驟]${NC} $1"
}

log_bigdipper() {
    echo -e "${BLUE}[北斗七星陣]${NC} $1"
}

# 配置變數
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
COMPOSE_FILE="$PROJECT_DIR/docker-compose-bigdipper.yml"
ENV_FILE="$PROJECT_DIR/.env"
ENV_TEMPLATE="$PROJECT_DIR/.env.bigdipper.template"

# 顯示橫幅
show_banner() {
    echo -e "${CYAN}"
    cat << 'EOF'
    ╔══════════════════════════════════════════════════════════════╗
    ║                    北斗七星陣 MCP 團隊                         ║
    ║                  Big Dipper Formation                        ║
    ║                                                              ║
    ║  🌟 天樞星 TaskMaster    🌟 天璇星 Perplexity               ║
    ║  🌟 天璣星 Context7      🌟 天權星 OpenMemory               ║
    ║  🌟 玉衡星 Zen MCP       🌟 開陽星 Serena                   ║
    ║  🌟 瑤光星 Sequential Thinking                              ║
    ║                                                              ║
    ║           智能協作，引導開發方向                               ║
    ╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# 檢查系統需求
check_requirements() {
    log_step "檢查系統需求..."
    
    # 檢查 Docker
    if ! command -v docker >/dev/null 2>&1; then
        log_error "Docker 未安裝，請先安裝 Docker"
        exit 1
    fi
    
    local docker_version=$(docker --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    log_info "Docker 版本: $docker_version"
    
    # 檢查 Docker Compose
    if ! command -v docker-compose >/dev/null 2>&1 && ! docker compose version >/dev/null 2>&1; then
        log_error "Docker Compose 未安裝，請先安裝 Docker Compose"
        exit 1
    fi
    
    if command -v docker-compose >/dev/null 2>&1; then
        local compose_version=$(docker-compose --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
        log_info "Docker Compose 版本: $compose_version"
    else
        local compose_version=$(docker compose version --short)
        log_info "Docker Compose 版本: $compose_version"
    fi
    
    # 檢查系統資源
    local memory_gb=$(free -g | awk '/^Mem:/{print $2}')
    local cpu_cores=$(nproc)
    local disk_avail=$(df -BG "$PROJECT_DIR" | awk 'NR==2{print $4}' | sed 's/G//')
    
    log_info "系統資源檢查："
    log_info "  CPU 核心數: $cpu_cores"
    log_info "  記憶體: ${memory_gb}GB"
    log_info "  可用磁碟空間: ${disk_avail}GB"
    
    # 檢查最小需求
    if [ "$memory_gb" -lt 8 ]; then
        log_warn "記憶體不足 8GB，可能影響效能"
    fi
    
    if [ "$cpu_cores" -lt 4 ]; then
        log_warn "CPU 核心數不足 4 個，可能影響效能"
    fi
    
    if [ "$disk_avail" -lt 20 ]; then
        log_warn "可用磁碟空間不足 20GB，可能影響運行"
    fi
    
    log_info "✓ 系統需求檢查完成"
}

# 檢查端口衝突
check_ports() {
    log_step "檢查端口衝突..."
    
    local ports=(8080 8082 8765 9119 9120 9121 9122 3000 6333 5432 24282)
    local conflicts=0
    
    for port in "${ports[@]}"; do
        if netstat -tuln 2>/dev/null | grep -q ":$port "; then
            log_warn "端口 $port 已被使用"
            conflicts=1
        else
            log_info "端口 $port 可用"
        fi
    done
    
    if [ $conflicts -eq 1 ]; then
        log_warn "發現端口衝突，請在 .env 檔案中調整端口配置"
        read -p "是否繼續部署？(y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "部署已取消"
            exit 1
        fi
    fi
    
    log_info "✓ 端口檢查完成"
}

# 設定環境變數
setup_environment() {
    log_step "設定環境變數..."
    
    if [ ! -f "$ENV_FILE" ]; then
        if [ -f "$ENV_TEMPLATE" ]; then
            log_info "建立環境變數檔案..."
            cp "$ENV_TEMPLATE" "$ENV_FILE"
            log_warn "請編輯 .env 檔案並填入您的 API 金鑰"
            
            # 檢查是否有編輯器可用
            if command -v nano >/dev/null 2>&1; then
                read -p "是否現在編輯 .env 檔案？(y/N): " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    nano "$ENV_FILE"
                fi
            elif command -v vim >/dev/null 2>&1; then
                read -p "是否現在編輯 .env 檔案？(y/N): " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    vim "$ENV_FILE"
                fi
            else
                log_info "請手動編輯 $ENV_FILE 檔案"
            fi
        else
            log_error "環境變數範本檔案不存在: $ENV_TEMPLATE"
            exit 1
        fi
    else
        log_info "環境變數檔案已存在"
    fi
    
    # 檢查必要的 API 金鑰
    source "$ENV_FILE"
    
    local required_keys=0
    if [ ! -z "$ANTHROPIC_API_KEY" ] && [ "$ANTHROPIC_API_KEY" != "your_claude_api_key_here" ]; then
        log_info "✓ Anthropic API 金鑰已設定"
        required_keys=1
    fi
    
    if [ ! -z "$PERPLEXITY_API_KEY" ] && [ "$PERPLEXITY_API_KEY" != "your_perplexity_api_key_here" ]; then
        log_info "✓ Perplexity API 金鑰已設定"
        required_keys=1
    fi
    
    if [ ! -z "$OPENAI_API_KEY" ] && [ "$OPENAI_API_KEY" != "your_openai_api_key_here" ]; then
        log_info "✓ OpenAI API 金鑰已設定"
        required_keys=1
    fi
    
    if [ $required_keys -eq 0 ]; then
        log_error "至少需要設定一個 AI API 金鑰"
        log_error "請編輯 $ENV_FILE 檔案並設定適當的 API 金鑰"
        exit 1
    fi
    
    log_info "✓ 環境變數設定完成"
}

# 建立 Docker 網路
create_network() {
    log_step "建立 Docker 網路..."
    
    if ! docker network ls | grep -q "bigdipper_mcp_network"; then
        log_info "建立 bigdipper_mcp_network 網路..."
        docker network create bigdipper_mcp_network
    else
        log_info "bigdipper_mcp_network 網路已存在"
    fi
    
    log_info "✓ Docker 網路準備完成"
}

# 拉取映像
pull_images() {
    log_step "拉取 Docker 映像..."
    
    cd "$PROJECT_DIR"
    
    if command -v docker-compose >/dev/null 2>&1; then
        docker-compose -f "$COMPOSE_FILE" pull
    else
        docker compose -f "$COMPOSE_FILE" pull
    fi
    
    log_info "✓ Docker 映像拉取完成"
}

# 建立映像
build_images() {
    log_step "建立 Docker 映像..."
    
    cd "$PROJECT_DIR"
    
    log_info "開始建立所有服務映像..."
    
    if command -v docker-compose >/dev/null 2>&1; then
        docker-compose -f "$COMPOSE_FILE" build --parallel
    else
        docker compose -f "$COMPOSE_FILE" build --parallel
    fi
    
    log_info "✓ Docker 映像建立完成"
}

# 啟動服務
start_services() {
    log_step "啟動北斗七星陣服務..."
    
    cd "$PROJECT_DIR"
    
    log_bigdipper "正在啟動七星聯合..."
    
    if command -v docker-compose >/dev/null 2>&1; then
        docker-compose -f "$COMPOSE_FILE" up -d
    else
        docker compose -f "$COMPOSE_FILE" up -d
    fi
    
    log_info "✓ 服務啟動完成"
}

# 等待服務就緒
wait_for_services() {
    log_step "等待服務就緒..."
    
    local max_wait=300  # 5分鐘
    local wait_time=0
    local interval=10
    
    cd "$PROJECT_DIR"
    
    while [ $wait_time -lt $max_wait ]; do
        local healthy_services=0
        local total_services=0
        
        if command -v docker-compose >/dev/null 2>&1; then
            local services=$(docker-compose -f "$COMPOSE_FILE" ps --services)
        else
            local services=$(docker compose -f "$COMPOSE_FILE" ps --services)
        fi
        
        for service in $services; do
            if [[ "$service" =~ ^redis- ]]; then
                continue  # 跳過 Redis 服務的健康檢查
            fi
            
            total_services=$((total_services + 1))
            
            local health_status
            if command -v docker-compose >/dev/null 2>&1; then
                health_status=$(docker-compose -f "$COMPOSE_FILE" ps -q "$service" | xargs docker inspect --format='{{.State.Health.Status}}' 2>/dev/null || echo "none")
            else
                health_status=$(docker compose -f "$COMPOSE_FILE" ps -q "$service" | xargs docker inspect --format='{{.State.Health.Status}}' 2>/dev/null || echo "none")
            fi
            
            if [ "$health_status" = "healthy" ] || [ "$health_status" = "none" ]; then
                healthy_services=$((healthy_services + 1))
                log_info "服務 $service 狀態: 就緒"
            else
                log_warn "服務 $service 狀態: $health_status"
            fi
        done
        
        if [ $healthy_services -eq $total_services ]; then
            log_info "✓ 所有服務已就緒"
            return 0
        fi
        
        log_info "等待服務就緒... ($healthy_services/$total_services) - ${wait_time}s"
        sleep $interval
        wait_time=$((wait_time + interval))
    done
    
    log_warn "等待超時，部分服務可能仍在啟動中"
    return 1
}

# 健康檢查
health_check() {
    log_step "執行健康檢查..."
    
    cd "$PROJECT_DIR"
    
    local services=("taskmaster" "perplexity" "context7" "zen-mcp" "serena" "sequential-thinking")
    local healthy_count=0
    
    for service in "${services[@]}"; do
        log_info "檢查 $service 服務..."
        
        if command -v docker-compose >/dev/null 2>&1; then
            if docker-compose -f "$COMPOSE_FILE" exec -T "$service" ./healthcheck.sh >/dev/null 2>&1; then
                log_info "✓ $service 健康檢查通過"
                healthy_count=$((healthy_count + 1))
            else
                log_warn "⚠ $service 健康檢查失敗"
            fi
        else
            if docker compose -f "$COMPOSE_FILE" exec -T "$service" ./healthcheck.sh >/dev/null 2>&1; then
                log_info "✓ $service 健康檢查通過"
                healthy_count=$((healthy_count + 1))
            else
                log_warn "⚠ $service 健康檢查失敗"
            fi
        fi
    done
    
    # 特別檢查 OpenMemory
    if curl -f -s http://localhost:8765/health >/dev/null 2>&1; then
        log_info "✓ OpenMemory 健康檢查通過"
        healthy_count=$((healthy_count + 1))
    else
        log_warn "⚠ OpenMemory 健康檢查失敗"
    fi
    
    log_info "健康檢查結果: $healthy_count/7 服務正常"
    
    if [ $healthy_count -eq 7 ]; then
        log_info "✓ 所有服務健康檢查通過"
        return 0
    else
        log_warn "部分服務健康檢查失敗，請檢查日誌"
        return 1
    fi
}

# 顯示服務狀態
show_status() {
    log_step "顯示服務狀態..."
    
    cd "$PROJECT_DIR"
    
    echo
    log_bigdipper "北斗七星陣服務狀態："
    echo
    
    if command -v docker-compose >/dev/null 2>&1; then
        docker-compose -f "$COMPOSE_FILE" ps
    else
        docker compose -f "$COMPOSE_FILE" ps
    fi
    
    echo
    log_info "服務端點："
    log_info "  🌟 TaskMaster AI:      http://localhost:${TASKMASTER_PORT:-9120}"
    log_info "  🌟 Perplexity Custom:  http://localhost:${PERPLEXITY_PORT:-8080}"
    log_info "  🌟 Context7 Cached:    http://localhost:${CONTEXT7_PORT:-9119}"
    log_info "  🌟 OpenMemory API:     http://localhost:8765"
    log_info "  🌟 OpenMemory Web UI:  http://localhost:3000"
    log_info "  🌟 Zen MCP:            http://localhost:${ZEN_PORT:-8082}"
    log_info "  🌟 Serena:             http://localhost:${SERENA_PORT:-9121}"
    log_info "  🌟 Serena Dashboard:   http://localhost:24282"
    log_info "  🌟 Sequential Thinking: http://localhost:${SEQUENTIAL_PORT:-9122}"
}

# 生成 MCP 註冊腳本
generate_mcp_script() {
    log_step "生成 MCP 註冊腳本..."
    
    local mcp_script="$PROJECT_DIR/register_bigdipper_mcp.sh"
    
    cat > "$mcp_script" << 'EOF'
#!/bin/bash
# 北斗七星陣 MCP Servers 註冊腳本

# 顏色定義
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[MCP註冊]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[MCP註冊]${NC} $1"
}

log_error() {
    echo -e "${RED}[MCP註冊]${NC} $1"
}

COMPOSE_FILE="docker-compose-bigdipper.yml"

log_info "開始註冊北斗七星陣 MCP Servers..."

# 檢查 Claude CLI 是否可用
if ! command -v claude >/dev/null 2>&1; then
    log_error "Claude CLI 未安裝，請先安裝 Claude Code CLI"
    exit 1
fi

# 檢查 Docker 服務是否運行
if ! docker-compose -f "$COMPOSE_FILE" ps | grep -q "Up"; then
    log_error "Docker 服務未運行，請先啟動服務"
    exit 1
fi

log_info "註冊 MCP Servers..."

# 天樞星 - TaskMaster AI
log_info "註冊 TaskMaster AI..."
claude mcp add taskmaster "docker-compose -f $COMPOSE_FILE exec -T taskmaster npx task-master-ai" -s user

# 天璇星 - Perplexity Custom 2.0
log_info "註冊 Perplexity Custom..."
claude mcp add perplexity "docker-compose -f $COMPOSE_FILE exec -T perplexity python server.py" -s user

# 天璣星 - Context7 Cached
log_info "註冊 Context7 Cached..."
claude mcp add context7 "npx -y @upstash/context7-mcp@latest" -s user

# 天權星 - OpenMemory
log_info "註冊 OpenMemory..."
claude mcp add openmemory "curl -X POST http://localhost:8765/mcp" -s user

# 玉衡星 - Zen MCP
log_info "註冊 Zen MCP..."
claude mcp add zen "docker-compose -f $COMPOSE_FILE exec -T zen-mcp python server.py" -s user

# 開陽星 - Serena
log_info "註冊 Serena..."
claude mcp add serena "uvx --from 'git+https://github.com/oraios/serena' serena-mcp-server" -s user

# 瑤光星 - Sequential Thinking
log_info "註冊 Sequential Thinking..."
claude mcp add sequential "npx -y @modelcontextprotocol/server-sequential-thinking" -s user

log_info "✅ 北斗七星陣 MCP Servers 註冊完成！"
log_info ""
log_info "使用以下指令查看已註冊的服務："
log_info "  claude mcp list"
log_info ""
log_info "測試服務："
log_info "  claude \"使用 TaskMaster 建立一個測試任務\""
log_info "  claude \"使用 Perplexity 搜尋最新 AI 趨勢\""
log_info "  claude \"使用 Context7 查詢 React 文檔\""
log_info "  claude \"使用 Zen MCP 進行代碼分析\""
log_info "  claude \"使用 Serena 查找專案符號\""
log_info "  claude \"使用 Sequential Thinking 進行步驟化思考\""
EOF
    
    chmod +x "$mcp_script"
    log_info "✓ MCP 註冊腳本已生成: $mcp_script"
}

# 顯示部署完成資訊
show_completion() {
    echo
    log_bigdipper "🎉 北斗七星陣部署完成！"
    echo
    log_info "後續步驟："
    log_info "1. 註冊 MCP Servers: ./register_bigdipper_mcp.sh"
    log_info "2. 查看服務日誌: docker-compose -f docker-compose-bigdipper.yml logs -f"
    log_info "3. 監控服務狀態: docker-compose -f docker-compose-bigdipper.yml ps"
    echo
    log_info "管理指令："
    log_info "  啟動服務: docker-compose -f docker-compose-bigdipper.yml up -d"
    log_info "  停止服務: docker-compose -f docker-compose-bigdipper.yml down"
    log_info "  重啟服務: docker-compose -f docker-compose-bigdipper.yml restart"
    log_info "  查看日誌: docker-compose -f docker-compose-bigdipper.yml logs -f [service]"
    echo
    log_info "需要幫助？查看文檔: ./README.md"
    echo
}

# 清理函數
cleanup() {
    if [ $? -ne 0 ]; then
        log_error "部署過程中發生錯誤"
        log_info "清理提示："
        log_info "  停止服務: docker-compose -f docker-compose-bigdipper.yml down"
        log_info "  查看日誌: docker-compose -f docker-compose-bigdipper.yml logs"
    fi
}

# 主要部署流程
main() {
    trap cleanup EXIT
    
    show_banner
    
    log_bigdipper "開始部署北斗七星陣 MCP 團隊..."
    echo
    
    check_requirements
    check_ports
    setup_environment
    create_network
    pull_images
    build_images
    start_services
    wait_for_services
    health_check
    show_status
    generate_mcp_script
    show_completion
    
    log_bigdipper "✨ 北斗七星陣已就緒，準備指引您的開發之路！"
}

# 處理命令列參數
case "${1:-}" in
    --help|-h)
        echo "北斗七星陣 MCP 團隊部署腳本"
        echo ""
        echo "用法: $0 [選項]"
        echo ""
        echo "選項:"
        echo "  --help, -h     顯示此幫助資訊"
        echo "  --check-only   僅執行檢查，不進行部署"
        echo "  --build-only   僅建立映像，不啟動服務"
        echo "  --no-pull      跳過映像拉取"
        echo ""
        exit 0
        ;;
    --check-only)
        show_banner
        check_requirements
        check_ports
        setup_environment
        log_info "✓ 檢查完成"
        exit 0
        ;;
    --build-only)
        show_banner
        check_requirements
        setup_environment
        create_network
        pull_images
        build_images
        log_info "✓ 映像建立完成"
        exit 0
        ;;
    --no-pull)
        show_banner
        log_bigdipper "開始部署北斗七星陣 MCP 團隊（跳過映像拉取）..."
        check_requirements
        check_ports
        setup_environment
        create_network
        build_images
        start_services
        wait_for_services
        health_check
        show_status
        generate_mcp_script
        show_completion
        ;;
    "")
        main
        ;;
    *)
        log_error "未知選項: $1"
        log_info "使用 --help 查看可用選項"
        exit 1
        ;;
esac