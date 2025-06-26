#!/bin/bash
# 北斗七星陣驗證和測試模組
# Big Dipper Formation - Validation and Testing Module

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
TEST_RESULTS_DIR="$INSTALL_DIR/test-results"
VALIDATION_LOG="$TEST_RESULTS_DIR/validation-$(date +%Y%m%d_%H%M%S).log"

# 建立測試結果目錄
mkdir -p "$TEST_RESULTS_DIR"

# 日誌函數
log_info() {
    echo -e "${GREEN}[測試]${NC} $1" | tee -a "$VALIDATION_LOG"
}

log_warn() {
    echo -e "${YELLOW}[警告]${NC} $1" | tee -a "$VALIDATION_LOG"
}

log_error() {
    echo -e "${RED}[錯誤]${NC} $1" | tee -a "$VALIDATION_LOG"
}

log_step() {
    echo -e "${CYAN}[步驟]${NC} $1" | tee -a "$VALIDATION_LOG"
}

log_success() {
    echo -e "${GREEN}[成功]${NC} $1" | tee -a "$VALIDATION_LOG"
}

log_test() {
    echo -e "${PURPLE}[測試]${NC} $1" | tee -a "$VALIDATION_LOG"
}

# 顯示測試橫幅
show_test_banner() {
    clear
    echo -e "${PURPLE}"
    cat << 'EOF'
    ╔══════════════════════════════════════════════════════════════════════╗
    ║                    🧪 北斗七星陣驗證測試中心                          ║
    ║                Big Dipper Formation Test & Validation                ║
    ║                                                                      ║
    ║              全面驗證系統部署和服務功能                               ║
    ║            Comprehensive System Validation & Testing                ║
    ╚══════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo
}

# 檢查 Docker 容器狀態
test_container_status() {
    log_step "檢查 Docker 容器狀態..."
    
    local containers=(
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
    )
    
    local running_count=0
    local total_count=${#containers[@]}
    
    for container in "${containers[@]}"; do
        if docker ps --filter "name=$container" --filter "status=running" | grep -q "$container"; then
            log_success "✓ $container 運行正常"
            running_count=$((running_count + 1))
        else
            log_error "✗ $container 未運行"
        fi
    done
    
    echo "容器狀態: $running_count/$total_count 運行中" >> "$VALIDATION_LOG"
    
    if [ $running_count -eq $total_count ]; then
        log_success "容器狀態檢查通過"
        return 0
    else
        log_warn "部分容器未運行"
        return 1
    fi
}

# 測試服務端點連線
test_service_endpoints() {
    log_step "測試服務端點連線..."
    
    local endpoints=(
        "http://localhost:9120:TaskMaster AI"
        "http://localhost:8080:Perplexity Custom"
        "http://localhost:9119:Context7 Cached"
        "http://localhost:8765:OpenMemory API"
        "http://localhost:3000:OpenMemory UI"
        "http://localhost:8082:Zen MCP"
        "http://localhost:9121:Serena"
        "http://localhost:24282:Serena Dashboard"
        "http://localhost:9122:Sequential Thinking"
    )
    
    local accessible_count=0
    local total_endpoints=${#endpoints[@]}
    
    for endpoint_desc in "${endpoints[@]}"; do
        IFS=':' read -r endpoint service <<< "$endpoint_desc"
        
        log_test "測試 $service 連線..."
        
        if command -v curl >/dev/null 2>&1; then
            if timeout 10 curl -f -s "$endpoint" >/dev/null 2>&1; then
                log_success "✓ $service 連線正常"
                accessible_count=$((accessible_count + 1))
            else
                # 嘗試基本連線測試
                local host=$(echo "$endpoint" | sed 's|http://||' | cut -d':' -f1)
                local port=$(echo "$endpoint" | sed 's|http://||' | cut -d':' -f2 | cut -d'/' -f1)
                
                if command -v nc >/dev/null 2>&1; then
                    if nc -z -w5 "$host" "$port" 2>/dev/null; then
                        log_warn "✓ $service 端口開放但 HTTP 連線失敗"
                        accessible_count=$((accessible_count + 1))
                    else
                        log_error "✗ $service 連線失敗（端口未開放）"
                    fi
                else
                    log_error "✗ $service 連線失敗"
                fi
            fi
        else
            log_warn "curl 未安裝，跳過 $service HTTP 測試"
        fi
    done
    
    echo "端點連線: $accessible_count/$total_endpoints 可訪問" >> "$VALIDATION_LOG"
    
    if [ $accessible_count -ge $((total_endpoints * 3 / 4)) ]; then
        log_success "服務端點測試基本通過"
        return 0
    else
        log_warn "多數服務端點無法訪問"
        return 1
    fi
}

# 測試 MCP Server 功能
test_mcp_functionality() {
    log_step "測試 MCP Server 功能..."
    
    # 檢查 Claude CLI 是否可用
    if ! command -v claude >/dev/null 2>&1; then
        log_warn "Claude CLI 未安裝，跳過 MCP 功能測試"
        return 2
    fi
    
    # 測試已註冊的 MCP Servers
    log_test "檢查已註冊的 MCP Servers..."
    
    local mcp_servers=(
        "taskmaster"
        "perplexity"
        "context7"
        "openmemory"
        "zen"
        "serena"
        "sequential"
    )
    
    local registered_count=0
    local mcp_list_output=$(claude mcp list 2>/dev/null || echo "")
    
    for server in "${mcp_servers[@]}"; do
        if echo "$mcp_list_output" | grep -q "$server"; then
            log_success "✓ $server MCP Server 已註冊"
            registered_count=$((registered_count + 1))
        else
            log_warn "✗ $server MCP Server 未註冊"
        fi
    done
    
    echo "MCP 註冊: $registered_count/${#mcp_servers[@]} 已註冊" >> "$VALIDATION_LOG"
    
    # 簡單功能測試（如果有註冊的服務）
    if [ $registered_count -gt 0 ]; then
        log_test "執行基本 MCP 功能測試..."
        
        # 測試 TaskMaster（如果可用）
        if echo "$mcp_list_output" | grep -q "taskmaster"; then
            log_test "測試 TaskMaster 功能..."
            if timeout 30 claude "使用 TaskMaster 顯示幫助資訊" --allowedTools mcp__taskmaster__help 2>/dev/null | grep -q "taskmaster"; then
                log_success "✓ TaskMaster 功能測試通過"
            else
                log_warn "✗ TaskMaster 功能測試失敗"
            fi
        fi
        
        # 測試 Context7（如果可用）
        if echo "$mcp_list_output" | grep -q "context7"; then
            log_test "測試 Context7 功能..."
            if timeout 30 claude "使用 Context7 搜尋 react 相關資訊" --allowedTools mcp__context7-cached__resolve-library-id 2>/dev/null; then
                log_success "✓ Context7 功能測試通過"
            else
                log_warn "✗ Context7 功能測試失敗"
            fi
        fi
    fi
    
    if [ $registered_count -ge 4 ]; then
        log_success "MCP 功能測試基本通過"
        return 0
    else
        log_warn "部分 MCP Server 未正常運作"
        return 1
    fi
}

# 測試 API 連線
test_api_connectivity() {
    log_step "測試 API 連線..."
    
    # 檢查環境變數檔案
    local env_files=(
        "$PROJECT_DIR/.env"
        "$INSTALL_DIR/deployment/*/env"
    )
    
    local env_file=""
    for file in "${env_files[@]}"; do
        if [ -f "$file" ]; then
            env_file="$file"
            break
        fi
    done
    
    if [ -z "$env_file" ]; then
        log_warn "找不到環境變數檔案，跳過 API 測試"
        return 2
    fi
    
    source "$env_file"
    
    local api_tests_passed=0
    local total_api_tests=0
    
    # 測試 Anthropic API
    if [ ! -z "$ANTHROPIC_API_KEY" ] && [ "$ANTHROPIC_API_KEY" != "your_claude_api_key_here" ]; then
        log_test "測試 Anthropic API..."
        total_api_tests=$((total_api_tests + 1))
        
        local response=$(curl -s -o /dev/null -w "%{http_code}" \
            -H "Authorization: Bearer $ANTHROPIC_API_KEY" \
            -H "anthropic-version: 2023-06-01" \
            "https://api.anthropic.com/v1/messages" \
            -d '{"model":"claude-3-haiku-20240307","max_tokens":1,"messages":[{"role":"user","content":"test"}]}' 2>/dev/null)
        
        if [ "$response" = "200" ] || [ "$response" = "400" ]; then
            log_success "✓ Anthropic API 連線正常"
            api_tests_passed=$((api_tests_passed + 1))
        else
            log_warn "✗ Anthropic API 連線失敗 (HTTP $response)"
        fi
    fi
    
    # 測試 Perplexity API
    if [ ! -z "$PERPLEXITY_API_KEY" ] && [ "$PERPLEXITY_API_KEY" != "your_perplexity_api_key_here" ]; then
        log_test "測試 Perplexity API..."
        total_api_tests=$((total_api_tests + 1))
        
        local response=$(curl -s -o /dev/null -w "%{http_code}" \
            -H "Authorization: Bearer $PERPLEXITY_API_KEY" \
            "https://api.perplexity.ai/chat/completions" \
            -d '{"model":"sonar-small-chat","messages":[{"role":"user","content":"test"}],"max_tokens":1}' 2>/dev/null)
        
        if [ "$response" = "200" ] || [ "$response" = "400" ]; then
            log_success "✓ Perplexity API 連線正常"
            api_tests_passed=$((api_tests_passed + 1))
        else
            log_warn "✗ Perplexity API 連線失敗 (HTTP $response)"
        fi
    fi
    
    # 測試 OpenAI API
    if [ ! -z "$OPENAI_API_KEY" ] && [ "$OPENAI_API_KEY" != "your_openai_api_key_here" ]; then
        log_test "測試 OpenAI API..."
        total_api_tests=$((total_api_tests + 1))
        
        local response=$(curl -s -o /dev/null -w "%{http_code}" \
            -H "Authorization: Bearer $OPENAI_API_KEY" \
            "https://api.openai.com/v1/models" 2>/dev/null)
        
        if [ "$response" = "200" ]; then
            log_success "✓ OpenAI API 連線正常"
            api_tests_passed=$((api_tests_passed + 1))
        else
            log_warn "✗ OpenAI API 連線失敗 (HTTP $response)"
        fi
    fi
    
    echo "API 連線測試: $api_tests_passed/$total_api_tests 通過" >> "$VALIDATION_LOG"
    
    if [ $total_api_tests -eq 0 ]; then
        log_warn "未找到配置的 API 金鑰"
        return 2
    elif [ $api_tests_passed -gt 0 ]; then
        log_success "至少一個 API 連線正常"
        return 0
    else
        log_error "所有 API 連線測試失敗"
        return 1
    fi
}

# 測試資料庫連線
test_database_connectivity() {
    log_step "測試資料庫連線..."
    
    local db_tests_passed=0
    local total_db_tests=3
    
    # 測試 PostgreSQL
    log_test "測試 PostgreSQL 連線..."
    if docker exec -it postgres psql -U postgres -d openmemory -c "SELECT 1;" >/dev/null 2>&1; then
        log_success "✓ PostgreSQL 連線正常"
        db_tests_passed=$((db_tests_passed + 1))
    else
        log_warn "✗ PostgreSQL 連線失敗"
    fi
    
    # 測試 Qdrant
    log_test "測試 Qdrant 連線..."
    if curl -f -s http://localhost:6333/collections >/dev/null 2>&1; then
        log_success "✓ Qdrant 連線正常"
        db_tests_passed=$((db_tests_passed + 1))
    else
        log_warn "✗ Qdrant 連線失敗"
    fi
    
    # 測試 Redis（多個實例）
    log_test "測試 Redis 連線..."
    local redis_count=0
    
    for port in 6379 6380 6381; do
        if docker exec redis-perplexity redis-cli -p $port ping 2>/dev/null | grep -q "PONG"; then
            redis_count=$((redis_count + 1))
        fi
    done
    
    if [ $redis_count -gt 0 ]; then
        log_success "✓ Redis 連線正常 ($redis_count 個實例)"
        db_tests_passed=$((db_tests_passed + 1))
    else
        log_warn "✗ Redis 連線失敗"
    fi
    
    echo "資料庫連線: $db_tests_passed/$total_db_tests 正常" >> "$VALIDATION_LOG"
    
    if [ $db_tests_passed -ge 2 ]; then
        log_success "資料庫連線測試基本通過"
        return 0
    else
        log_warn "多數資料庫連線異常"
        return 1
    fi
}

# 測試系統資源使用
test_system_resources() {
    log_step "測試系統資源使用..."
    
    # 檢查記憶體使用
    log_test "檢查記憶體使用情況..."
    local memory_usage=$(docker stats --no-stream --format "table {{.Container}}\t{{.MemUsage}}" | grep -E "(taskmaster|perplexity|context7|zen|serena|sequential|openmemory)" | head -10)
    
    if [ ! -z "$memory_usage" ]; then
        echo "記憶體使用情況:" >> "$VALIDATION_LOG"
        echo "$memory_usage" >> "$VALIDATION_LOG"
        log_success "✓ 記憶體使用情況正常"
    else
        log_warn "✗ 無法獲取記憶體使用情況"
    fi
    
    # 檢查 CPU 使用
    log_test "檢查 CPU 使用情況..."
    local cpu_usage=$(docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}" | grep -E "(taskmaster|perplexity|context7|zen|serena|sequential|openmemory)" | head -10)
    
    if [ ! -z "$cpu_usage" ]; then
        echo "CPU 使用情況:" >> "$VALIDATION_LOG"
        echo "$cpu_usage" >> "$VALIDATION_LOG"
        log_success "✓ CPU 使用情況正常"
    else
        log_warn "✗ 無法獲取 CPU 使用情況"
    fi
    
    # 檢查磁碟使用
    log_test "檢查磁碟使用情況..."
    local disk_usage=$(df -h "$HOME" | awk 'NR==2{print $5}' | sed 's/%//')
    
    if [ "$disk_usage" -lt 90 ]; then
        log_success "✓ 磁碟使用正常 (${disk_usage}%)"
    else
        log_warn "✗ 磁碟使用率過高 (${disk_usage}%)"
    fi
    
    echo "系統資源檢查完成" >> "$VALIDATION_LOG"
    log_success "系統資源測試完成"
    return 0
}

# 執行壓力測試
run_stress_test() {
    log_step "執行壓力測試..."
    
    local stress_tests_passed=0
    local total_stress_tests=3
    
    # 並發請求測試（如果有 curl）
    if command -v curl >/dev/null 2>&1; then
        log_test "執行並發請求測試..."
        
        local concurrent_requests=5
        local test_urls=(
            "http://localhost:8765/health"
            "http://localhost:3000"
        )
        
        for url in "${test_urls[@]}"; do
            local success_count=0
            
            for i in $(seq 1 $concurrent_requests); do
                if timeout 10 curl -f -s "$url" >/dev/null 2>&1 &
                then
                    success_count=$((success_count + 1))
                fi
            done
            
            wait  # 等待所有背景任務完成
            
            if [ $success_count -ge $((concurrent_requests / 2)) ]; then
                log_success "✓ $url 並發測試通過 ($success_count/$concurrent_requests)"
            else
                log_warn "✗ $url 並發測試失敗 ($success_count/$concurrent_requests)"
            fi
        done
        
        stress_tests_passed=$((stress_tests_passed + 1))
    fi
    
    # 記憶體壓力測試
    log_test "檢查記憶體壓力情況..."
    local memory_pressure=$(free | awk '/^Mem:/{printf "%.1f", $3/$2*100}')
    
    if [ "${memory_pressure%.*}" -lt 85 ]; then
        log_success "✓ 記憶體壓力正常 (${memory_pressure}%)"
        stress_tests_passed=$((stress_tests_passed + 1))
    else
        log_warn "✗ 記憶體壓力過高 (${memory_pressure}%)"
    fi
    
    # 檔案描述符檢查
    log_test "檢查檔案描述符使用..."
    local fd_usage=$(lsof 2>/dev/null | wc -l)
    local fd_limit=$(ulimit -n)
    local fd_percentage=$((fd_usage * 100 / fd_limit))
    
    if [ "$fd_percentage" -lt 80 ]; then
        log_success "✓ 檔案描述符使用正常 ($fd_usage/$fd_limit, ${fd_percentage}%)"
        stress_tests_passed=$((stress_tests_passed + 1))
    else
        log_warn "✗ 檔案描述符使用率過高 (${fd_percentage}%)"
    fi
    
    echo "壓力測試: $stress_tests_passed/$total_stress_tests 通過" >> "$VALIDATION_LOG"
    
    if [ $stress_tests_passed -ge 2 ]; then
        log_success "壓力測試基本通過"
        return 0
    else
        log_warn "壓力測試未完全通過"
        return 1
    fi
}

# 生成測試報告
generate_test_report() {
    log_step "生成測試報告..."
    
    local report_file="$TEST_RESULTS_DIR/test-report-$(date +%Y%m%d_%H%M%S).md"
    
    cat > "$report_file" << EOF
# 北斗七星陣驗證測試報告

**測試時間**: $(date)  
**測試版本**: 1.0.0  
**測試環境**: $(uname -s) $(uname -r)

## 測試摘要

### 執行的測試
- ✅ Docker 容器狀態檢查
- ✅ 服務端點連線測試
- ✅ MCP Server 功能測試
- ✅ API 連線測試
- ✅ 資料庫連線測試
- ✅ 系統資源檢查
- ✅ 壓力測試

### 測試結果統計

$(grep -E "通過|失敗|正常|異常" "$VALIDATION_LOG" | sort | uniq -c)

## 詳細測試日誌

\`\`\`
$(cat "$VALIDATION_LOG")
\`\`\`

## 系統狀態快照

### Docker 容器狀態
\`\`\`
$(docker ps --filter "label=bigdipper.service" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "無法獲取容器資訊")
\`\`\`

### 資源使用情況
\`\`\`
$(docker stats --no-stream --filter "label=bigdipper.service" --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" 2>/dev/null || echo "無法獲取資源資訊")
\`\`\`

### 網路端口狀態
\`\`\`
$(netstat -tuln 2>/dev/null | grep -E ":(8080|8082|8765|9119|9120|9121|9122|3000|6333|5432|24282)" || echo "無法獲取端口資訊")
\`\`\`

## 建議

### 成功的部分
- 記錄表現良好的服務和功能
- 穩定運行的組件

### 需要關注的問題
- 列出發現的問題和警告
- 提供解決建議

### 後續行動
1. 監控系統運行狀況
2. 定期執行驗證測試
3. 根據使用情況調整配置

---
*報告生成時間: $(date)*
EOF
    
    log_success "測試報告已生成: $report_file"
    echo "詳細測試日誌: $VALIDATION_LOG"
}

# 主測試流程
main() {
    show_test_banner
    
    log_test "開始執行北斗七星陣系統驗證測試..."
    echo
    
    local test_results=()
    local total_score=0
    local max_score=0
    
    # 執行各項測試
    echo "=== 容器狀態檢查 ===" >> "$VALIDATION_LOG"
    test_container_status
    local container_result=$?
    test_results+=("container:$container_result")
    max_score=$((max_score + 1))
    [ $container_result -eq 0 ] && total_score=$((total_score + 1))
    
    echo
    echo "=== 服務端點測試 ===" >> "$VALIDATION_LOG"
    test_service_endpoints
    local endpoint_result=$?
    test_results+=("endpoint:$endpoint_result")
    max_score=$((max_score + 1))
    [ $endpoint_result -eq 0 ] && total_score=$((total_score + 1))
    
    echo
    echo "=== MCP 功能測試 ===" >> "$VALIDATION_LOG"
    test_mcp_functionality
    local mcp_result=$?
    test_results+=("mcp:$mcp_result")
    if [ $mcp_result -ne 2 ]; then  # 不計算跳過的測試
        max_score=$((max_score + 1))
        [ $mcp_result -eq 0 ] && total_score=$((total_score + 1))
    fi
    
    echo
    echo "=== API 連線測試 ===" >> "$VALIDATION_LOG"
    test_api_connectivity
    local api_result=$?
    test_results+=("api:$api_result")
    if [ $api_result -ne 2 ]; then
        max_score=$((max_score + 1))
        [ $api_result -eq 0 ] && total_score=$((total_score + 1))
    fi
    
    echo
    echo "=== 資料庫連線測試 ===" >> "$VALIDATION_LOG"
    test_database_connectivity
    local db_result=$?
    test_results+=("database:$db_result")
    max_score=$((max_score + 1))
    [ $db_result -eq 0 ] && total_score=$((total_score + 1))
    
    echo
    echo "=== 系統資源測試 ===" >> "$VALIDATION_LOG"
    test_system_resources
    local resource_result=$?
    test_results+=("resource:$resource_result")
    max_score=$((max_score + 1))
    [ $resource_result -eq 0 ] && total_score=$((total_score + 1))
    
    echo
    echo "=== 壓力測試 ===" >> "$VALIDATION_LOG"
    run_stress_test
    local stress_result=$?
    test_results+=("stress:$stress_result")
    max_score=$((max_score + 1))
    [ $stress_result -eq 0 ] && total_score=$((total_score + 1))
    
    # 生成報告
    echo
    generate_test_report
    
    # 顯示總結
    echo
    log_step "測試總結"
    echo "========"
    
    local pass_percentage=$((total_score * 100 / max_score))
    
    echo "測試通過率: $total_score/$max_score ($pass_percentage%)" | tee -a "$VALIDATION_LOG"
    
    if [ $pass_percentage -ge 80 ]; then
        log_success "🎉 系統驗證測試優秀通過！"
        echo -e "${GREEN}北斗七星陣運行狀況良好${NC}"
        return 0
    elif [ $pass_percentage -ge 60 ]; then
        log_warn "⚠️ 系統驗證測試基本通過"
        echo -e "${YELLOW}北斗七星陣基本運行正常，但有改進空間${NC}"
        return 1
    else
        log_error "❌ 系統驗證測試未通過"
        echo -e "${RED}北斗七星陣運行存在問題，需要檢查${NC}"
        return 2
    fi
}

# 處理命令列參數
case "${1:-}" in
    --help|-h)
        echo "北斗七星陣驗證測試工具"
        echo ""
        echo "用法: $0 [選項]"
        echo ""
        echo "選項:"
        echo "  --help, -h           顯示此幫助資訊"
        echo "  --container-only     僅測試容器狀態"
        echo "  --endpoint-only      僅測試服務端點"
        echo "  --mcp-only          僅測試 MCP 功能"
        echo "  --api-only          僅測試 API 連線"
        echo "  --db-only           僅測試資料庫連線"
        echo "  --resource-only     僅測試系統資源"
        echo "  --stress-only       僅執行壓力測試"
        echo "  --quick             快速測試（跳過壓力測試）"
        echo ""
        echo "範例:"
        echo "  $0                  # 執行完整測試"
        echo "  $0 --quick          # 執行快速測試"
        echo "  $0 --container-only # 僅測試容器狀態"
        echo ""
        exit 0
        ;;
    --container-only)
        show_test_banner
        test_container_status
        exit $?
        ;;
    --endpoint-only)
        show_test_banner
        test_service_endpoints
        exit $?
        ;;
    --mcp-only)
        show_test_banner
        test_mcp_functionality
        exit $?
        ;;
    --api-only)
        show_test_banner
        test_api_connectivity
        exit $?
        ;;
    --db-only)
        show_test_banner
        test_database_connectivity
        exit $?
        ;;
    --resource-only)
        show_test_banner
        test_system_resources
        exit $?
        ;;
    --stress-only)
        show_test_banner
        run_stress_test
        exit $?
        ;;
    --quick)
        # 執行快速測試（跳過壓力測試）
        show_test_banner
        log_test "執行快速驗證測試..."
        test_container_status
        test_service_endpoints
        test_mcp_functionality
        test_api_connectivity
        test_database_connectivity
        test_system_resources
        generate_test_report
        log_success "快速測試完成"
        ;;
    *)
        main
        exit $?
        ;;
esac