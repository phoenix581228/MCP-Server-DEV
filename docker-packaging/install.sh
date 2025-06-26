#!/bin/bash
# 北斗七星陣 MCP 團隊一鍵安裝包
# Big Dipper Formation - One-Click Installation Package
# 版本: 1.0.0
# 作者: Claude Code + 北斗七星陣團隊

set -e

# 顏色定義
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# 全域變數
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$HOME/.bigdipper"
LOG_FILE="$INSTALL_DIR/install.log"
CONFIG_FILE="$INSTALL_DIR/config.yaml"
TEMP_DIR="/tmp/bigdipper_install_$$"

# 建立日誌目錄
mkdir -p "$INSTALL_DIR"
mkdir -p "$TEMP_DIR"

# 日誌函數
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_info() {
    echo -e "${GREEN}[安裝]${NC} $1" | tee -a "$LOG_FILE"
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

log_bigdipper() {
    echo -e "${BLUE}[北斗七星陣]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[成功]${NC} $1" | tee -a "$LOG_FILE"
}

# 顯示安裝橫幅
show_banner() {
    clear
    echo -e "${CYAN}"
    cat << 'EOF'
    ╔══════════════════════════════════════════════════════════════════════╗
    ║                        北斗七星陣 MCP 團隊                           ║
    ║                   Big Dipper Formation                               ║
    ║                      一鍵安裝包 v1.0.0                              ║
    ║                                                                      ║
    ║  🌟 天樞星 TaskMaster    🌟 天璇星 Perplexity                      ║
    ║  🌟 天璣星 Context7      🌟 天權星 OpenMemory                      ║
    ║  🌟 玉衡星 Zen MCP       🌟 開陽星 Serena                          ║
    ║  🌟 瑤光星 Sequential Thinking                                     ║
    ║                                                                      ║
    ║              智能協作，引導開發方向                                   ║
    ║           One-Click Installation & Configuration                     ║
    ╚══════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo
}

# 檢查操作系統
check_os() {
    log_step "檢查操作系統..."
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        if command -v apt-get >/dev/null 2>&1; then
            DISTRO="ubuntu"
        elif command -v yum >/dev/null 2>&1; then
            DISTRO="centos"
        elif command -v pacman >/dev/null 2>&1; then
            DISTRO="arch"
        else
            DISTRO="unknown"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        DISTRO="macos"
    else
        log_error "不支援的操作系統: $OSTYPE"
        exit 1
    fi
    
    log_info "操作系統: $OS ($DISTRO)"
    
    # 檢查架構
    ARCH=$(uname -m)
    case $ARCH in
        x86_64) ARCH="amd64" ;;
        aarch64|arm64) ARCH="arm64" ;;
        *) 
            log_error "不支援的架構: $ARCH"
            exit 1
            ;;
    esac
    
    log_info "系統架構: $ARCH"
}

# 檢查系統需求
check_system_requirements() {
    log_step "檢查系統需求..."
    
    local requirements_met=true
    
    # 檢查 CPU 核心數
    local cpu_cores=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo "1")
    log_info "CPU 核心數: $cpu_cores"
    if [ "$cpu_cores" -lt 4 ]; then
        log_warn "建議至少 4 個 CPU 核心，當前: $cpu_cores"
    fi
    
    # 檢查記憶體
    if [[ "$OS" == "linux" ]]; then
        local memory_gb=$(free -g | awk '/^Mem:/{print $2}')
    elif [[ "$OS" == "macos" ]]; then
        local memory_bytes=$(sysctl -n hw.memsize)
        local memory_gb=$((memory_bytes / 1024 / 1024 / 1024))
    fi
    
    log_info "系統記憶體: ${memory_gb}GB"
    if [ "$memory_gb" -lt 8 ]; then
        log_warn "建議至少 8GB 記憶體，當前: ${memory_gb}GB"
        requirements_met=false
    fi
    
    # 檢查磁碟空間
    local disk_avail
    if [[ "$OS" == "linux" ]]; then
        disk_avail=$(df -BG "$HOME" | awk 'NR==2{print $4}' | sed 's/G//')
    elif [[ "$OS" == "macos" ]]; then
        disk_avail=$(df -g "$HOME" | awk 'NR==2{print $4}')
    fi
    
    log_info "可用磁碟空間: ${disk_avail}GB"
    if [ "$disk_avail" -lt 20 ]; then
        log_warn "建議至少 20GB 可用空間，當前: ${disk_avail}GB"
        requirements_met=false
    fi
    
    if [ "$requirements_met" = false ]; then
        read -p "系統資源可能不足，是否繼續安裝？(y/N): " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "安裝已取消"
            exit 0
        fi
    fi
    
    log_success "系統需求檢查完成"
}

# 安裝 Docker
install_docker() {
    log_step "檢查並安裝 Docker..."
    
    if command -v docker >/dev/null 2>&1; then
        local docker_version=$(docker --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        log_info "Docker 已安裝，版本: $docker_version"
        
        # 檢查版本是否符合需求
        local min_version="20.10.0"
        if [ "$(printf '%s\n' "$min_version" "$docker_version" | sort -V | head -n1)" != "$min_version" ]; then
            log_warn "Docker 版本過舊，建議升級到 $min_version 或更新版本"
        fi
    else
        log_info "Docker 未安裝，開始自動安裝..."
        
        if [[ "$OS" == "linux" ]]; then
            if [[ "$DISTRO" == "ubuntu" ]]; then
                # Ubuntu/Debian 安裝
                sudo apt-get update
                sudo apt-get install -y ca-certificates curl gnupg lsb-release
                
                # 添加 Docker 官方 GPG 金鑰
                sudo mkdir -p /etc/apt/keyrings
                curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
                
                # 添加儲存庫
                echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
                
                # 安裝 Docker
                sudo apt-get update
                sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
                
            elif [[ "$DISTRO" == "centos" ]]; then
                # CentOS/RHEL 安裝
                sudo yum install -y yum-utils
                sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
                sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
                sudo systemctl start docker
                sudo systemctl enable docker
            fi
            
            # 將使用者加入 docker 群組
            sudo usermod -aG docker $USER
            log_warn "已將使用者加入 docker 群組，請重新登入或執行: newgrp docker"
            
        elif [[ "$OS" == "macos" ]]; then
            if command -v brew >/dev/null 2>&1; then
                log_info "使用 Homebrew 安裝 Docker..."
                brew install --cask docker
                log_info "請啟動 Docker Desktop 應用程式"
            else
                log_error "請手動安裝 Docker Desktop for Mac: https://docs.docker.com/desktop/mac/install/"
                exit 1
            fi
        fi
        
        log_success "Docker 安裝完成"
    fi
    
    # 檢查 Docker 是否運行
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker daemon 未運行，請啟動 Docker"
        if [[ "$OS" == "linux" ]]; then
            log_info "嘗試啟動 Docker 服務..."
            sudo systemctl start docker
            sleep 5
            if ! docker info >/dev/null 2>&1; then
                log_error "無法啟動 Docker 服務"
                exit 1
            fi
        else
            log_error "請手動啟動 Docker Desktop"
            exit 1
        fi
    fi
}

# 安裝 Docker Compose
install_docker_compose() {
    log_step "檢查並安裝 Docker Compose..."
    
    # 檢查是否有 Docker Compose Plugin
    if docker compose version >/dev/null 2>&1; then
        local compose_version=$(docker compose version --short)
        log_info "Docker Compose Plugin 已安裝，版本: $compose_version"
        return 0
    fi
    
    # 檢查傳統 docker-compose
    if command -v docker-compose >/dev/null 2>&1; then
        local compose_version=$(docker-compose --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
        log_info "Docker Compose 已安裝，版本: $compose_version"
        return 0
    fi
    
    log_info "Docker Compose 未安裝，開始自動安裝..."
    
    if [[ "$OS" == "linux" ]]; then
        # 下載最新版本的 Docker Compose
        local compose_version=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
        log_info "下載 Docker Compose $compose_version..."
        
        sudo curl -L "https://github.com/docker/compose/releases/download/$compose_version/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        
    elif [[ "$OS" == "macos" ]]; then
        if command -v brew >/dev/null 2>&1; then
            brew install docker-compose
        else
            log_error "請手動安裝 Docker Compose"
            exit 1
        fi
    fi
    
    log_success "Docker Compose 安裝完成"
}

# 安裝必要工具
install_dependencies() {
    log_step "安裝相依套件..."
    
    local packages=()
    
    if [[ "$OS" == "linux" ]]; then
        if [[ "$DISTRO" == "ubuntu" ]]; then
            # 檢查並安裝必要套件
            local required_packages=("curl" "wget" "git" "unzip" "jq" "netstat")
            for package in "${required_packages[@]}"; do
                if ! command -v "$package" >/dev/null 2>&1; then
                    case "$package" in
                        "netstat") packages+=("net-tools") ;;
                        *) packages+=("$package") ;;
                    esac
                fi
            done
            
            if [ ${#packages[@]} -gt 0 ]; then
                log_info "安裝套件: ${packages[*]}"
                sudo apt-get update
                sudo apt-get install -y "${packages[@]}"
            fi
            
        elif [[ "$DISTRO" == "centos" ]]; then
            local required_packages=("curl" "wget" "git" "unzip" "jq" "netstat")
            for package in "${required_packages[@]}"; do
                if ! command -v "$package" >/dev/null 2>&1; then
                    case "$package" in
                        "netstat") packages+=("net-tools") ;;
                        *) packages+=("$package") ;;
                    esac
                fi
            done
            
            if [ ${#packages[@]} -gt 0 ]; then
                log_info "安裝套件: ${packages[*]}"
                sudo yum install -y "${packages[@]}"
            fi
        fi
        
    elif [[ "$OS" == "macos" ]]; then
        # macOS 通常已經有必要工具，檢查 jq
        if ! command -v jq >/dev/null 2>&1; then
            if command -v brew >/dev/null 2>&1; then
                brew install jq
            else
                log_warn "建議安裝 Homebrew 以管理套件"
            fi
        fi
    fi
    
    log_success "相依套件安裝完成"
}

# 安裝 Claude CLI
install_claude_cli() {
    log_step "檢查並安裝 Claude CLI..."
    
    if command -v claude >/dev/null 2>&1; then
        log_info "Claude CLI 已安裝"
        return 0
    fi
    
    log_info "Claude CLI 未安裝，開始自動安裝..."
    
    if [[ "$OS" == "macos" ]]; then
        if command -v brew >/dev/null 2>&1; then
            brew install anthropics/claude/claude
        else
            log_error "請手動安裝 Claude CLI: https://docs.anthropic.com/claude-code"
            exit 1
        fi
    elif [[ "$OS" == "linux" ]]; then
        # Linux 安裝方法
        curl -fsSL https://claude.ai/install.sh | sh
    fi
    
    log_success "Claude CLI 安裝完成"
}

# 下載北斗七星陣檔案
download_bigdipper() {
    log_step "下載北斗七星陣檔案..."
    
    local bigdipper_dir="$INSTALL_DIR/bigdipper"
    mkdir -p "$bigdipper_dir"
    
    # 如果當前目錄已經包含 Docker 檔案，則複製
    if [ -f "$SCRIPT_DIR/docker-compose-bigdipper.yml" ]; then
        log_info "從本地複製檔案..."
        cp -r "$SCRIPT_DIR"/* "$bigdipper_dir/"
    else
        log_info "從遠端下載檔案..."
        # 這裡可以從 GitHub 或其他地方下載
        git clone https://github.com/your-org/MCP-Server-DEV.git "$TEMP_DIR/MCP-Server-DEV"
        cp -r "$TEMP_DIR/MCP-Server-DEV/docker-packaging"/* "$bigdipper_dir/"
    fi
    
    # 設定執行權限
    chmod +x "$bigdipper_dir"/scripts/*.sh
    chmod +x "$bigdipper_dir"/*.sh
    
    log_success "北斗七星陣檔案準備完成"
}

# 配置環境變數
configure_environment() {
    log_step "配置環境變數..."
    
    local bigdipper_dir="$INSTALL_DIR/bigdipper"
    local env_file="$bigdipper_dir/.env"
    local env_template="$bigdipper_dir/.env.bigdipper.template"
    
    if [ ! -f "$env_file" ] && [ -f "$env_template" ]; then
        cp "$env_template" "$env_file"
        log_info "建立環境配置檔案: $env_file"
        
        echo
        log_warn "請設定您的 API 金鑰以啟用 AI 功能："
        echo
        
        # 互動式設定 API 金鑰
        setup_api_keys "$env_file"
    fi
    
    log_success "環境變數配置完成"
}

# 設定 API 金鑰
setup_api_keys() {
    local env_file="$1"
    
    echo -e "${YELLOW}API 金鑰設定精靈${NC}"
    echo "請輸入您的 API 金鑰（按 Enter 跳過可選項）："
    echo
    
    # Anthropic Claude API（必需）
    echo -e "${GREEN}1. Anthropic Claude API（推薦 - 主要 AI 功能）${NC}"
    read -p "請輸入 Anthropic API 金鑰: " -r anthropic_key
    if [ ! -z "$anthropic_key" ]; then
        sed -i.bak "s/your_claude_api_key_here/$anthropic_key/" "$env_file"
        log_info "✓ Anthropic API 金鑰已設定"
    fi
    
    echo
    
    # Perplexity API（必需）
    echo -e "${GREEN}2. Perplexity AI API（必需 - 研究功能）${NC}"
    read -p "請輸入 Perplexity API 金鑰: " -r perplexity_key
    if [ ! -z "$perplexity_key" ]; then
        sed -i.bak "s/your_perplexity_api_key_here/$perplexity_key/" "$env_file"
        log_info "✓ Perplexity API 金鑰已設定"
    fi
    
    echo
    
    # 可選 API 金鑰
    echo -e "${CYAN}可選 API 金鑰（可稍後設定）：${NC}"
    
    echo "3. OpenAI API（可選）"
    read -p "請輸入 OpenAI API 金鑰（可選）: " -r openai_key
    if [ ! -z "$openai_key" ]; then
        sed -i.bak "s/your_openai_api_key_here/$openai_key/" "$env_file"
        log_info "✓ OpenAI API 金鑰已設定"
    fi
    
    echo "4. Google Gemini API（可選）"
    read -p "請輸入 Google API 金鑰（可選）: " -r google_key
    if [ ! -z "$google_key" ]; then
        sed -i.bak "s/your_google_api_key_here/$google_key/" "$env_file"
        log_info "✓ Google API 金鑰已設定"
    fi
    
    # 清理備份檔案
    rm -f "$env_file.bak"
    
    echo
    log_info "API 金鑰設定完成"
    log_info "您可稍後編輯 $env_file 來修改設定"
}

# 檢查端口衝突
check_ports() {
    log_step "檢查端口衝突..."
    
    local ports=(8080 8082 8765 9119 9120 9121 9122 3000 6333 5432 24282)
    local conflicts=()
    
    for port in "${ports[@]}"; do
        if command -v netstat >/dev/null 2>&1; then
            if netstat -tuln 2>/dev/null | grep -q ":$port "; then
                conflicts+=("$port")
            fi
        elif command -v lsof >/dev/null 2>&1; then
            if lsof -ti:$port >/dev/null 2>&1; then
                conflicts+=("$port")
            fi
        fi
    done
    
    if [ ${#conflicts[@]} -gt 0 ]; then
        log_warn "發現端口衝突: ${conflicts[*]}"
        echo
        log_info "衝突的端口將在環境配置中自動調整"
        echo "或者您可以："
        echo "1. 停止使用這些端口的服務"
        echo "2. 手動編輯 .env 檔案調整端口"
        echo
        read -p "是否繼續安裝？(y/N): " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "安裝已取消"
            exit 0
        fi
    else
        log_success "端口檢查通過，無衝突"
    fi
}

# 部署北斗七星陣
deploy_bigdipper() {
    log_step "部署北斗七星陣服務..."
    
    local bigdipper_dir="$INSTALL_DIR/bigdipper"
    cd "$bigdipper_dir"
    
    # 建立 Docker 網路
    log_info "建立 Docker 網路..."
    if ! docker network ls | grep -q "bigdipper_mcp_network"; then
        docker network create bigdipper_mcp_network
    fi
    
    # 拉取基礎映像
    log_info "拉取基礎映像..."
    docker pull node:20-alpine
    docker pull python:3.11-slim
    docker pull redis:7-alpine
    docker pull postgres:15-alpine
    docker pull qdrant/qdrant:latest
    
    # 建立服務映像
    log_info "建立服務映像..."
    if command -v docker-compose >/dev/null 2>&1; then
        docker-compose -f docker-compose-bigdipper.yml build --parallel
    else
        docker compose -f docker-compose-bigdipper.yml build --parallel
    fi
    
    # 啟動服務
    log_info "啟動北斗七星陣服務..."
    if command -v docker-compose >/dev/null 2>&1; then
        docker-compose -f docker-compose-bigdipper.yml up -d
    else
        docker compose -f docker-compose-bigdipper.yml up -d
    fi
    
    log_success "北斗七星陣部署完成"
}

# 等待服務就緒
wait_for_services() {
    log_step "等待服務就緒..."
    
    local bigdipper_dir="$INSTALL_DIR/bigdipper"
    cd "$bigdipper_dir"
    
    local max_wait=300  # 5分鐘
    local wait_time=0
    local interval=10
    
    while [ $wait_time -lt $max_wait ]; do
        local healthy_services=0
        local total_services=0
        
        # 檢查基本服務是否啟動
        if docker ps | grep -q "taskmaster_mcp_server"; then
            healthy_services=$((healthy_services + 1))
        fi
        total_services=$((total_services + 1))
        
        if docker ps | grep -q "perplexity_mcp_server"; then
            healthy_services=$((healthy_services + 1))
        fi
        total_services=$((total_services + 1))
        
        if docker ps | grep -q "context7_mcp_server"; then
            healthy_services=$((healthy_services + 1))
        fi
        total_services=$((total_services + 1))
        
        if docker ps | grep -q "zen_mcp_server"; then
            healthy_services=$((healthy_services + 1))
        fi
        total_services=$((total_services + 1))
        
        if [ $healthy_services -eq $total_services ]; then
            log_success "所有服務已啟動"
            return 0
        fi
        
        log_info "等待服務啟動... ($healthy_services/$total_services) - ${wait_time}s"
        sleep $interval
        wait_time=$((wait_time + interval))
    done
    
    log_warn "部分服務可能仍在啟動中，請檢查狀態"
    return 1
}

# 註冊 MCP Servers
register_mcp_servers() {
    log_step "註冊 MCP Servers 到 Claude CLI..."
    
    local bigdipper_dir="$INSTALL_DIR/bigdipper"
    
    if [ -f "$bigdipper_dir/register_bigdipper_mcp.sh" ]; then
        log_info "執行 MCP 註冊腳本..."
        cd "$bigdipper_dir"
        chmod +x register_bigdipper_mcp.sh
        ./register_bigdipper_mcp.sh
        log_success "MCP Servers 註冊完成"
    else
        log_warn "MCP 註冊腳本不存在，請手動註冊"
    fi
}

# 建立桌面快捷方式
create_shortcuts() {
    log_step "建立桌面快捷方式..."
    
    local bigdipper_dir="$INSTALL_DIR/bigdipper"
    
    # 建立控制腳本
    cat > "$INSTALL_DIR/bigdipper-control.sh" << 'EOF'
#!/bin/bash
# 北斗七星陣控制面板

BIGDIPPER_DIR="$HOME/.bigdipper/bigdipper"

case "$1" in
    start)
        echo "啟動北斗七星陣..."
        cd "$BIGDIPPER_DIR" && ./scripts/manage.sh start
        ;;
    stop)
        echo "停止北斗七星陣..."
        cd "$BIGDIPPER_DIR" && ./scripts/manage.sh stop
        ;;
    status)
        echo "檢查北斗七星陣狀態..."
        cd "$BIGDIPPER_DIR" && ./scripts/manage.sh status
        ;;
    logs)
        echo "顯示北斗七星陣日誌..."
        cd "$BIGDIPPER_DIR" && ./scripts/manage.sh logs
        ;;
    restart)
        echo "重啟北斗七星陣..."
        cd "$BIGDIPPER_DIR" && ./scripts/manage.sh restart
        ;;
    dashboard)
        echo "開啟監控面板..."
        cd "$BIGDIPPER_DIR" && ./scripts/manage.sh monitor
        ;;
    *)
        echo "北斗七星陣控制面板"
        echo "用法: $0 {start|stop|restart|status|logs|dashboard}"
        echo ""
        echo "可用指令："
        echo "  start     - 啟動所有服務"
        echo "  stop      - 停止所有服務"
        echo "  restart   - 重啟所有服務"
        echo "  status    - 查看服務狀態"
        echo "  logs      - 查看服務日誌"
        echo "  dashboard - 開啟監控面板"
        ;;
esac
EOF
    
    chmod +x "$INSTALL_DIR/bigdipper-control.sh"
    
    # 建立 symlink 到 /usr/local/bin
    if [ -w "/usr/local/bin" ] || sudo -n true 2>/dev/null; then
        if command -v sudo >/dev/null 2>&1; then
            sudo ln -sf "$INSTALL_DIR/bigdipper-control.sh" /usr/local/bin/bigdipper
            log_info "✓ 建立全域指令: bigdipper"
        fi
    fi
    
    # macOS 建立桌面捷徑
    if [[ "$OS" == "macos" ]]; then
        local desktop_app="$HOME/Desktop/北斗七星陣.app"
        mkdir -p "$desktop_app/Contents/MacOS"
        
        cat > "$desktop_app/Contents/MacOS/bigdipper" << EOF
#!/bin/bash
osascript -e 'tell app "Terminal" to do script "cd $bigdipper_dir && ./scripts/manage.sh monitor"'
EOF
        chmod +x "$desktop_app/Contents/MacOS/bigdipper"
        
        cat > "$desktop_app/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>bigdipper</string>
    <key>CFBundleName</key>
    <string>北斗七星陣</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
</dict>
</plist>
EOF
    fi
    
    log_success "快捷方式建立完成"
}

# 執行最終驗證
final_verification() {
    log_step "執行最終驗證..."
    
    local bigdipper_dir="$INSTALL_DIR/bigdipper"
    cd "$bigdipper_dir"
    
    # 檢查容器狀態
    local running_containers=$(docker ps --filter "label=bigdipper.service" --format "{{.Names}}" | wc -l)
    log_info "運行中的北斗七星陣服務: $running_containers"
    
    # 檢查 MCP 註冊
    if command -v claude >/dev/null 2>&1; then
        local mcp_count=$(claude mcp list 2>/dev/null | grep -E "(taskmaster|perplexity|context7|zen|serena|sequential)" | wc -l)
        log_info "已註冊的 MCP Servers: $mcp_count"
    fi
    
    # 健康檢查
    log_info "執行健康檢查..."
    if [ -f "$bigdipper_dir/scripts/manage.sh" ]; then
        "$bigdipper_dir/scripts/manage.sh" health >/dev/null 2>&1 || true
    fi
    
    log_success "最終驗證完成"
}

# 顯示安裝完成資訊
show_completion() {
    clear
    echo -e "${GREEN}"
    cat << 'EOF'
    ╔════════════════════════════════════════════════════════════════════════╗
    ║                          🎉 安裝完成！                                 ║
    ║                    北斗七星陣已成功部署                                 ║
    ╚════════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    log_bigdipper "北斗七星陣 MCP 團隊安裝完成！"
    echo
    
    echo -e "${CYAN}🌟 服務端點：${NC}"
    echo "  TaskMaster AI:      http://localhost:9120"
    echo "  Perplexity Custom:  http://localhost:8080"  
    echo "  Context7 Cached:    http://localhost:9119"
    echo "  OpenMemory API:     http://localhost:8765"
    echo "  OpenMemory Web UI:  http://localhost:3000"
    echo "  Zen MCP:            http://localhost:8082"
    echo "  Serena:             http://localhost:9121"
    echo "  Serena Dashboard:   http://localhost:24282"
    echo "  Sequential Thinking: http://localhost:9122"
    echo
    
    echo -e "${CYAN}🚀 快速指令：${NC}"
    if command -v bigdipper >/dev/null 2>&1; then
        echo "  bigdipper status    # 查看服務狀態"
        echo "  bigdipper logs      # 查看日誌"
        echo "  bigdipper restart   # 重啟服務"
        echo "  bigdipper dashboard # 監控面板"
    else
        echo "  $INSTALL_DIR/bigdipper-control.sh status"
        echo "  $INSTALL_DIR/bigdipper-control.sh logs"
        echo "  $INSTALL_DIR/bigdipper-control.sh restart"
    fi
    echo
    
    echo -e "${CYAN}📚 使用說明：${NC}"
    echo "  1. 檢查服務狀態: docker ps"
    echo "  2. 查看 MCP 註冊: claude mcp list"
    echo "  3. 測試功能: claude \"使用 TaskMaster 建立測試任務\""
    echo "  4. 監控服務: $INSTALL_DIR/bigdipper/scripts/manage.sh monitor"
    echo
    
    echo -e "${CYAN}📁 重要檔案位置：${NC}"
    echo "  安裝目錄: $INSTALL_DIR"
    echo "  配置檔案: $INSTALL_DIR/bigdipper/.env"
    echo "  日誌檔案: $INSTALL_DIR/install.log"
    echo "  控制腳本: $INSTALL_DIR/bigdipper/scripts/manage.sh"
    echo
    
    echo -e "${YELLOW}💡 提示：${NC}"
    echo "  • 首次使用請確認所有 API 金鑰已正確設定"
    echo "  • 如需修改配置，請編輯 .env 檔案後重啟服務"
    echo "  • 遇到問題請查看日誌檔案或訪問專案文檔"
    echo
    
    echo -e "${GREEN}✨ 北斗七星陣已就緒，準備指引您的開發之路！${NC}"
    echo
}

# 清理函數
cleanup() {
    if [ $? -ne 0 ]; then
        log_error "安裝過程中發生錯誤"
        echo
        log_info "清理提示："
        log_info "1. 查看日誌: $LOG_FILE"
        log_info "2. 清理容器: docker-compose -f $INSTALL_DIR/bigdipper/docker-compose-bigdipper.yml down"
        log_info "3. 重新執行安裝"
        echo
    fi
    
    # 清理臨時檔案
    rm -rf "$TEMP_DIR"
}

# 解除安裝函數
uninstall() {
    echo -e "${RED}解除安裝北斗七星陣${NC}"
    echo
    
    read -p "確定要完全移除北斗七星陣嗎？這將刪除所有數據！(y/N): " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "解除安裝已取消"
        exit 0
    fi
    
    log_info "開始解除安裝..."
    
    # 停止並移除容器
    if [ -f "$INSTALL_DIR/bigdipper/docker-compose-bigdipper.yml" ]; then
        cd "$INSTALL_DIR/bigdipper"
        docker-compose -f docker-compose-bigdipper.yml down -v
    fi
    
    # 移除映像
    docker images --filter "reference=bigdipper/*" -q | xargs -r docker rmi -f
    
    # 移除 MCP 註冊
    if command -v claude >/dev/null 2>&1; then
        claude mcp remove taskmaster -s user 2>/dev/null || true
        claude mcp remove perplexity -s user 2>/dev/null || true
        claude mcp remove context7 -s user 2>/dev/null || true
        claude mcp remove openmemory -s user 2>/dev/null || true
        claude mcp remove zen -s user 2>/dev/null || true
        claude mcp remove serena -s user 2>/dev/null || true
        claude mcp remove sequential -s user 2>/dev/null || true
    fi
    
    # 移除檔案
    rm -rf "$INSTALL_DIR"
    sudo rm -f /usr/local/bin/bigdipper 2>/dev/null || true
    rm -rf "$HOME/Desktop/北斗七星陣.app" 2>/dev/null || true
    
    log_success "北斗七星陣已完全移除"
}

# 主函數
main() {
    trap cleanup EXIT
    
    # 處理命令列參數
    case "${1:-}" in
        --uninstall)
            uninstall
            exit 0
            ;;
        --help|-h)
            echo "北斗七星陣 MCP 團隊一鍵安裝包"
            echo ""
            echo "用法: $0 [選項]"
            echo ""
            echo "選項:"
            echo "  --help, -h      顯示此幫助資訊"
            echo "  --uninstall     解除安裝北斗七星陣"
            echo "  --skip-docker   跳過 Docker 安裝檢查"
            echo "  --skip-api      跳過 API 金鑰設定"
            echo "  --quiet         靜默安裝模式"
            echo ""
            exit 0
            ;;
    esac
    
    show_banner
    
    log_bigdipper "開始安裝北斗七星陣 MCP 團隊..."
    echo
    
    # 執行安裝步驟
    check_os
    check_system_requirements
    
    if [[ "${1:-}" != "--skip-docker" ]]; then
        install_docker
        install_docker_compose
    fi
    
    install_dependencies
    install_claude_cli
    download_bigdipper
    
    if [[ "${1:-}" != "--skip-api" ]]; then
        configure_environment
    fi
    
    check_ports
    deploy_bigdipper
    wait_for_services
    register_mcp_servers
    create_shortcuts
    final_verification
    
    show_completion
    
    log_bigdipper "✨ 北斗七星陣安裝完成！"
}

# 執行主函數
main "$@"