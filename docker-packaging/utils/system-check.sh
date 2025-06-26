#!/bin/bash
# 北斗七星陣系統需求檢查模組
# Big Dipper Formation - System Requirements Checker

# 顏色定義
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 日誌函數
log_info() {
    echo -e "${GREEN}[檢查]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[警告]${NC} $1"
}

log_error() {
    echo -e "${RED}[錯誤]${NC} $1"
}

log_step() {
    echo -e "${CYAN}[步驟]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[成功]${NC} $1"
}

# 檢查操作系統
check_operating_system() {
    log_step "檢查操作系統兼容性..."
    
    local os_info=""
    local supported=true
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            os_info="$NAME $VERSION"
            
            # 檢查支援的 Linux 發行版
            case "$ID" in
                ubuntu)
                    if [[ "$VERSION_ID" < "18.04" ]]; then
                        log_warn "Ubuntu 版本過舊，建議 18.04 或更新版本"
                        supported=false
                    fi
                    ;;
                debian)
                    if [[ "$VERSION_ID" < "10" ]]; then
                        log_warn "Debian 版本過舊，建議 10 或更新版本"
                        supported=false
                    fi
                    ;;
                centos|rhel)
                    if [[ "$VERSION_ID" < "7" ]]; then
                        log_warn "CentOS/RHEL 版本過舊，建議 7 或更新版本"
                        supported=false
                    fi
                    ;;
                fedora)
                    if [[ "$VERSION_ID" < "30" ]]; then
                        log_warn "Fedora 版本過舊，建議 30 或更新版本"
                        supported=false
                    fi
                    ;;
                *)
                    log_warn "未測試的 Linux 發行版: $ID"
                    ;;
            esac
        else
            os_info="Linux (未知發行版)"
            log_warn "無法確定 Linux 發行版，請確認系統兼容性"
        fi
        
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        local macos_version=$(sw_vers -productVersion)
        os_info="macOS $macos_version"
        
        # 檢查 macOS 版本
        local major_version=$(echo "$macos_version" | cut -d. -f1)
        local minor_version=$(echo "$macos_version" | cut -d. -f2)
        
        if [ "$major_version" -lt 10 ] || ([ "$major_version" -eq 10 ] && [ "$minor_version" -lt 15 ]); then
            log_warn "macOS 版本過舊，建議 10.15 (Catalina) 或更新版本"
            supported=false
        fi
        
    else
        log_error "不支援的操作系統: $OSTYPE"
        return 1
    fi
    
    log_info "操作系統: $os_info"
    
    # 檢查系統架構
    local arch=$(uname -m)
    case "$arch" in
        x86_64|amd64)
            log_info "系統架構: x86_64 ✓"
            ;;
        aarch64|arm64)
            log_info "系統架構: ARM64 ✓"
            ;;
        *)
            log_error "不支援的系統架構: $arch"
            return 1
            ;;
    esac
    
    if [ "$supported" = true ]; then
        log_success "操作系統檢查通過"
        return 0
    else
        log_warn "操作系統可能不完全支援，建議升級"
        return 2
    fi
}

# 檢查硬體需求
check_hardware_requirements() {
    log_step "檢查硬體需求..."
    
    local requirements_met=true
    local warnings=0
    
    # 檢查 CPU
    local cpu_cores
    if command -v nproc >/dev/null 2>&1; then
        cpu_cores=$(nproc)
    elif [[ "$OS" == "macos" ]]; then
        cpu_cores=$(sysctl -n hw.ncpu)
    else
        cpu_cores=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || echo "1")
    fi
    
    log_info "CPU 核心數: $cpu_cores"
    
    if [ "$cpu_cores" -ge 8 ]; then
        log_success "CPU: 優秀配置 (≥8 核心)"
    elif [ "$cpu_cores" -ge 4 ]; then
        log_info "CPU: 建議配置 (≥4 核心)"
    elif [ "$cpu_cores" -ge 2 ]; then
        log_warn "CPU: 最小配置 (≥2 核心)，可能影響效能"
        warnings=$((warnings + 1))
    else
        log_error "CPU: 不符合最小需求 (需要至少 2 核心)"
        requirements_met=false
    fi
    
    # 檢查記憶體
    local memory_gb
    if [[ "$OS" == "linux" ]]; then
        if command -v free >/dev/null 2>&1; then
            memory_gb=$(free -g | awk '/^Mem:/{print $2}')
        else
            local memory_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
            memory_gb=$((memory_kb / 1024 / 1024))
        fi
    elif [[ "$OS" == "macos" ]]; then
        local memory_bytes=$(sysctl -n hw.memsize)
        memory_gb=$((memory_bytes / 1024 / 1024 / 1024))
    fi
    
    log_info "系統記憶體: ${memory_gb}GB"
    
    if [ "$memory_gb" -ge 32 ]; then
        log_success "記憶體: 生產級配置 (≥32GB)"
    elif [ "$memory_gb" -ge 16 ]; then
        log_success "記憶體: 推薦配置 (≥16GB)"
    elif [ "$memory_gb" -ge 8 ]; then
        log_info "記憶體: 最小配置 (≥8GB)"
    elif [ "$memory_gb" -ge 4 ]; then
        log_warn "記憶體: 低於建議值 (${memory_gb}GB)，建議升級到 8GB"
        warnings=$((warnings + 1))
    else
        log_error "記憶體: 不符合最小需求 (需要至少 4GB)"
        requirements_met=false
    fi
    
    # 檢查磁碟空間
    local disk_avail_gb
    if [[ "$OS" == "linux" ]]; then
        disk_avail_gb=$(df -BG "$HOME" | awk 'NR==2{print $4}' | sed 's/G//')
    elif [[ "$OS" == "macos" ]]; then
        disk_avail_gb=$(df -g "$HOME" | awk 'NR==2{print $4}')
    fi
    
    log_info "可用磁碟空間: ${disk_avail_gb}GB"
    
    if [ "$disk_avail_gb" -ge 100 ]; then
        log_success "磁碟空間: 生產級配置 (≥100GB)"
    elif [ "$disk_avail_gb" -ge 50 ]; then
        log_success "磁碟空間: 推薦配置 (≥50GB)"
    elif [ "$disk_avail_gb" -ge 20 ]; then
        log_info "磁碟空間: 最小配置 (≥20GB)"
    elif [ "$disk_avail_gb" -ge 10 ]; then
        log_warn "磁碟空間: 低於建議值，建議清理磁碟"
        warnings=$((warnings + 1))
    else
        log_error "磁碟空間: 不符合最小需求 (需要至少 10GB)"
        requirements_met=false
    fi
    
    # 總結
    if [ "$requirements_met" = true ]; then
        if [ "$warnings" -eq 0 ]; then
            log_success "硬體需求檢查完全通過"
            return 0
        else
            log_warn "硬體需求基本滿足，但有 $warnings 個警告"
            return 2
        fi
    else
        log_error "硬體需求不滿足，無法安裝"
        return 1
    fi
}

# 檢查網路連線
check_network_connectivity() {
    log_step "檢查網路連線..."
    
    local connectivity_ok=true
    
    # 檢查基本網路連線
    if command -v ping >/dev/null 2>&1; then
        if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
            log_info "✓ 基本網路連線正常"
        else
            log_warn "網路連線異常，可能影響下載"
            connectivity_ok=false
        fi
    fi
    
    # 檢查重要服務連線
    local services=(
        "hub.docker.com:443:Docker Hub"
        "github.com:443:GitHub"
        "api.anthropic.com:443:Anthropic API"
        "api.perplexity.ai:443:Perplexity API"
    )
    
    for service in "${services[@]}"; do
        IFS=':' read -r host port name <<< "$service"
        
        if command -v nc >/dev/null 2>&1; then
            if nc -z -w5 "$host" "$port" 2>/dev/null; then
                log_info "✓ $name 連線正常"
            else
                log_warn "✗ $name 連線失敗"
                connectivity_ok=false
            fi
        elif command -v telnet >/dev/null 2>&1; then
            if timeout 5 telnet "$host" "$port" >/dev/null 2>&1; then
                log_info "✓ $name 連線正常"
            else
                log_warn "✗ $name 連線失敗"
                connectivity_ok=false
            fi
        fi
    done
    
    if [ "$connectivity_ok" = true ]; then
        log_success "網路連線檢查通過"
        return 0
    else
        log_warn "部分網路連線異常，可能影響安裝"
        return 2
    fi
}

# 檢查軟體相依性
check_software_dependencies() {
    log_step "檢查軟體相依性..."
    
    local deps_ok=true
    local missing_deps=()
    
    # 檢查必要工具
    local required_tools=("curl" "wget" "git")
    
    for tool in "${required_tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            local version=$($tool --version 2>/dev/null | head -1 || echo "已安裝")
            log_info "✓ $tool: $version"
        else
            log_warn "✗ $tool: 未安裝"
            missing_deps+=("$tool")
            deps_ok=false
        fi
    done
    
    # 檢查可選工具
    local optional_tools=("jq" "unzip" "tar" "gzip")
    local missing_optional=()
    
    for tool in "${optional_tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            log_info "✓ $tool: 已安裝"
        else
            missing_optional+=("$tool")
        fi
    done
    
    if [ ${#missing_optional[@]} -gt 0 ]; then
        log_warn "可選工具未安裝: ${missing_optional[*]}"
    fi
    
    # 檢查 Shell
    log_info "當前 Shell: $SHELL"
    if [[ "$SHELL" != *"bash"* ]]; then
        log_warn "建議使用 Bash Shell 以獲得最佳兼容性"
    fi
    
    if [ "$deps_ok" = true ]; then
        log_success "軟體相依性檢查通過"
        return 0
    else
        log_error "缺少必要工具: ${missing_deps[*]}"
        
        # 提供安裝建議
        if [[ "$OS" == "linux" ]]; then
            if command -v apt-get >/dev/null 2>&1; then
                log_info "安裝指令: sudo apt-get install ${missing_deps[*]}"
            elif command -v yum >/dev/null 2>&1; then
                log_info "安裝指令: sudo yum install ${missing_deps[*]}"
            elif command -v pacman >/dev/null 2>&1; then
                log_info "安裝指令: sudo pacman -S ${missing_deps[*]}"
            fi
        elif [[ "$OS" == "macos" ]]; then
            if command -v brew >/dev/null 2>&1; then
                log_info "安裝指令: brew install ${missing_deps[*]}"
            else
                log_info "請安裝 Homebrew: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
            fi
        fi
        
        return 1
    fi
}

# 檢查端口可用性
check_port_availability() {
    log_step "檢查端口可用性..."
    
    local ports=(8080 8082 8765 9119 9120 9121 9122 3000 6333 5432 24282)
    local conflicts=()
    local warnings=0
    
    for port in "${ports[@]}"; do
        local service_name=""
        case $port in
            8080) service_name="Perplexity Custom" ;;
            8082) service_name="Zen MCP" ;;
            8765) service_name="OpenMemory API" ;;
            9119) service_name="Context7 Cached" ;;
            9120) service_name="TaskMaster AI" ;;
            9121) service_name="Serena" ;;
            9122) service_name="Sequential Thinking" ;;
            3000) service_name="OpenMemory Web UI" ;;
            6333) service_name="Qdrant" ;;
            5432) service_name="PostgreSQL" ;;
            24282) service_name="Serena Dashboard" ;;
        esac
        
        local port_used=false
        
        # 檢查端口是否被使用
        if command -v netstat >/dev/null 2>&1; then
            if netstat -tuln 2>/dev/null | grep -q ":$port "; then
                port_used=true
            fi
        elif command -v lsof >/dev/null 2>&1; then
            if lsof -ti:$port >/dev/null 2>&1; then
                port_used=true
            fi
        elif command -v ss >/dev/null 2>&1; then
            if ss -tuln 2>/dev/null | grep -q ":$port "; then
                port_used=true
            fi
        fi
        
        if [ "$port_used" = true ]; then
            # 查看是什麼程序在使用
            local process_info=""
            if command -v lsof >/dev/null 2>&1; then
                process_info=$(lsof -ti:$port | xargs ps -p 2>/dev/null | tail -n +2 | awk '{print $4}' | head -1)
            fi
            
            if [ ! -z "$process_info" ]; then
                log_warn "✗ 端口 $port ($service_name) 被 $process_info 占用"
            else
                log_warn "✗ 端口 $port ($service_name) 已被占用"
            fi
            conflicts+=("$port")
            warnings=$((warnings + 1))
        else
            log_info "✓ 端口 $port ($service_name) 可用"
        fi
    done
    
    if [ ${#conflicts[@]} -eq 0 ]; then
        log_success "所有端口都可用"
        return 0
    else
        log_warn "發現 ${#conflicts[@]} 個端口衝突"
        echo
        log_info "解決方案："
        log_info "1. 停止占用端口的程序"
        log_info "2. 修改 .env 檔案中的端口配置"
        log_info "3. 使用自動端口分配功能"
        echo
        return 2
    fi
}

# 檢查 Docker 環境
check_docker_environment() {
    log_step "檢查 Docker 環境..."
    
    local docker_ok=true
    
    # 檢查 Docker 是否安裝
    if command -v docker >/dev/null 2>&1; then
        local docker_version=$(docker --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        log_info "✓ Docker 版本: $docker_version"
        
        # 檢查版本是否符合需求
        local min_version="20.10.0"
        if [ "$(printf '%s\n' "$min_version" "$docker_version" | sort -V | head -n1)" != "$min_version" ]; then
            log_warn "Docker 版本過舊，建議升級到 $min_version 或更新版本"
            docker_ok=false
        fi
        
        # 檢查 Docker 是否運行
        if docker info >/dev/null 2>&1; then
            log_info "✓ Docker daemon 正在運行"
            
            # 檢查 Docker 權限
            if docker ps >/dev/null 2>&1; then
                log_info "✓ Docker 權限正常"
            else
                log_warn "Docker 權限問題，可能需要 sudo 或加入 docker 群組"
                docker_ok=false
            fi
        else
            log_warn "Docker daemon 未運行"
            docker_ok=false
        fi
    else
        log_warn "Docker 未安裝"
        docker_ok=false
    fi
    
    # 檢查 Docker Compose
    local compose_ok=false
    if docker compose version >/dev/null 2>&1; then
        local compose_version=$(docker compose version --short)
        log_info "✓ Docker Compose Plugin 版本: $compose_version"
        compose_ok=true
    elif command -v docker-compose >/dev/null 2>&1; then
        local compose_version=$(docker-compose --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
        log_info "✓ Docker Compose 版本: $compose_version"
        compose_ok=true
    else
        log_warn "Docker Compose 未安裝"
    fi
    
    if [ "$docker_ok" = true ] && [ "$compose_ok" = true ]; then
        log_success "Docker 環境檢查通過"
        return 0
    else
        log_warn "Docker 環境需要設定"
        return 2
    fi
}

# 生成系統報告
generate_system_report() {
    local output_file="${1:-system-check-report.txt}"
    
    log_step "生成系統檢查報告..."
    
    cat > "$output_file" << EOF
北斗七星陣 MCP 團隊 - 系統檢查報告
=====================================
生成時間: $(date)
檢查腳本版本: 1.0.0

系統資訊:
---------
操作系統: $(uname -s) $(uname -r)
架構: $(uname -m)
主機名稱: $(hostname)

$(if [[ "$OS" == "linux" ]] && [ -f /etc/os-release ]; then
    echo "Linux 發行版資訊:"
    cat /etc/os-release
elif [[ "$OS" == "macos" ]]; then
    echo "macOS 版本: $(sw_vers -productVersion)"
    echo "建置版本: $(sw_vers -buildVersion)"
fi)

硬體資訊:
---------
CPU 核心數: $(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo "未知")
總記憶體: $(if [[ "$OS" == "linux" ]]; then free -h | grep "Mem:" | awk '{print $2}'; elif [[ "$OS" == "macos" ]]; then echo "$(($(sysctl -n hw.memsize) / 1024 / 1024 / 1024))GB"; fi)
可用磁碟空間: $(df -h "$HOME" | awk 'NR==2{print $4}')

網路資訊:
---------
IP 位址: $(hostname -I 2>/dev/null | awk '{print $1}' || ifconfig | grep "inet " | grep -v "127.0.0.1" | head -1 | awk '{print $2}')
DNS 伺服器: $(cat /etc/resolv.conf 2>/dev/null | grep "nameserver" | head -3 | awk '{print $2}' | tr '\n' ' ' || echo "未知")

已安裝軟體:
-----------
$(for cmd in docker docker-compose git curl wget jq; do
    if command -v $cmd >/dev/null 2>&1; then
        echo "$cmd: $($cmd --version 2>/dev/null | head -1 || echo '已安裝')"
    else
        echo "$cmd: 未安裝"
    fi
done)

端口狀態:
---------
$(for port in 8080 8082 8765 9119 9120 9121 9122 3000 6333 5432 24282; do
    if command -v netstat >/dev/null 2>&1; then
        if netstat -tuln 2>/dev/null | grep -q ":$port "; then
            echo "端口 $port: 已占用"
        else
            echo "端口 $port: 可用"
        fi
    elif command -v lsof >/dev/null 2>&1; then
        if lsof -ti:$port >/dev/null 2>&1; then
            echo "端口 $port: 已占用"
        else
            echo "端口 $port: 可用"
        fi
    else
        echo "端口 $port: 無法檢查"
    fi
done)

Docker 狀態:
-----------
$(if command -v docker >/dev/null 2>&1; then
    echo "Docker 版本: $(docker --version)"
    if docker info >/dev/null 2>&1; then
        echo "Docker 狀態: 運行中"
        echo "容器數量: $(docker ps -q | wc -l) 個運行中"
        echo "映像數量: $(docker images -q | wc -l) 個"
    else
        echo "Docker 狀態: 未運行"
    fi
else
    echo "Docker: 未安裝"
fi)

建議:
-----
EOF
    
    # 根據檢查結果添加建議
    {
        echo "1. 請根據上述資訊確認系統是否滿足安裝需求"
        echo "2. 如有端口衝突，請停止相關服務或修改配置"
        echo "3. 確保網路連線正常以下載必要檔案"
        echo "4. 建議在安裝前備份重要數據"
    } >> "$output_file"
    
    log_success "系統報告已保存到: $output_file"
}

# 主檢查函數
main() {
    echo -e "${CYAN}"
    cat << 'EOF'
    ╔══════════════════════════════════════════════════════════════════════╗
    ║                    北斗七星陣系統需求檢查                             ║
    ║                 Big Dipper Formation System Check                    ║
    ╚══════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo
    
    local overall_status=0
    local warnings=0
    
    # 執行各項檢查
    check_operating_system
    local os_result=$?
    if [ $os_result -eq 1 ]; then
        overall_status=1
    elif [ $os_result -eq 2 ]; then
        warnings=$((warnings + 1))
    fi
    
    echo
    
    check_hardware_requirements
    local hw_result=$?
    if [ $hw_result -eq 1 ]; then
        overall_status=1
    elif [ $hw_result -eq 2 ]; then
        warnings=$((warnings + 1))
    fi
    
    echo
    
    check_network_connectivity
    local net_result=$?
    if [ $net_result -eq 1 ]; then
        overall_status=1
    elif [ $net_result -eq 2 ]; then
        warnings=$((warnings + 1))
    fi
    
    echo
    
    check_software_dependencies
    local deps_result=$?
    if [ $deps_result -eq 1 ]; then
        overall_status=1
    elif [ $deps_result -eq 2 ]; then
        warnings=$((warnings + 1))
    fi
    
    echo
    
    check_port_availability
    local port_result=$?
    if [ $port_result -eq 1 ]; then
        overall_status=1
    elif [ $port_result -eq 2 ]; then
        warnings=$((warnings + 1))
    fi
    
    echo
    
    check_docker_environment
    local docker_result=$?
    if [ $docker_result -eq 1 ]; then
        overall_status=1
    elif [ $docker_result -eq 2 ]; then
        warnings=$((warnings + 1))
    fi
    
    echo
    
    # 生成報告
    if [[ "${1:-}" == "--report" ]]; then
        generate_system_report "${2:-system-check-report.txt}"
        echo
    fi
    
    # 總結
    echo -e "${CYAN}檢查總結:${NC}"
    echo "========"
    
    if [ $overall_status -eq 0 ]; then
        if [ $warnings -eq 0 ]; then
            log_success "✅ 系統完全符合安裝需求"
            echo -e "${GREEN}可以安全地進行北斗七星陣安裝${NC}"
        else
            log_warn "⚠️ 系統基本符合需求，但有 $warnings 個警告"
            echo -e "${YELLOW}建議解決警告後再進行安裝${NC}"
        fi
    else
        log_error "❌ 系統不符合安裝需求"
        echo -e "${RED}請解決上述問題後再嘗試安裝${NC}"
    fi
    
    echo
    
    return $overall_status
}

# 處理命令列參數
case "${1:-}" in
    --help|-h)
        echo "北斗七星陣系統需求檢查工具"
        echo ""
        echo "用法: $0 [選項]"
        echo ""
        echo "選項:"
        echo "  --help, -h           顯示此幫助資訊"
        echo "  --report [檔案]      生成詳細系統報告"
        echo "  --os                 僅檢查操作系統"
        echo "  --hardware           僅檢查硬體需求"
        echo "  --network            僅檢查網路連線"
        echo "  --software           僅檢查軟體相依性"
        echo "  --ports              僅檢查端口可用性"
        echo "  --docker             僅檢查 Docker 環境"
        echo ""
        exit 0
        ;;
    --os)
        check_operating_system
        exit $?
        ;;
    --hardware)
        check_hardware_requirements
        exit $?
        ;;
    --network)
        check_network_connectivity
        exit $?
        ;;
    --software)
        check_software_dependencies
        exit $?
        ;;
    --ports)
        check_port_availability
        exit $?
        ;;
    --docker)
        check_docker_environment
        exit $?
        ;;
    *)
        main "$@"
        exit $?
        ;;
esac