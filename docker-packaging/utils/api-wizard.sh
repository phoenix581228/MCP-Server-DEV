#!/bin/bash
# 北斗七星陣 API 金鑰配置精靈
# Big Dipper Formation - API Key Configuration Wizard

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
ENV_FILE=""
INTERACTIVE_MODE=true
BACKUP_CREATED=false

# 日誌函數
log_info() {
    echo -e "${GREEN}[配置]${NC} $1"
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

log_wizard() {
    echo -e "${PURPLE}[精靈]${NC} $1"
}

# 顯示精靈橫幅
show_wizard_banner() {
    clear
    echo -e "${PURPLE}"
    cat << 'EOF'
    ╔══════════════════════════════════════════════════════════════════════╗
    ║                    🧙 北斗七星陣 API 配置精靈                        ║
    ║                  Big Dipper Formation API Wizard                    ║
    ║                                                                      ║
    ║              智能引導您完成 API 金鑰設定                              ║
    ║            Intelligent API Key Configuration Guide                  ║
    ╚══════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo
}

# API 提供者資訊資料庫
declare -A API_PROVIDERS
API_PROVIDERS=(
    ["anthropic"]="Anthropic Claude API|https://console.anthropic.com|推薦|主要 AI 功能，TaskMaster、Zen MCP 等服務核心|必需"
    ["perplexity"]="Perplexity AI API|https://www.perplexity.ai/settings/api|必需|研究分析、即時資訊搜尋|必需"
    ["openai"]="OpenAI API|https://platform.openai.com/api-keys|可選|備用 AI 模型、Zen MCP 多模型支援|可選"
    ["google"]="Google Gemini API|https://aistudio.google.com/app/apikey|可選|大文件處理、Zen MCP 增強功能|可選"
    ["xai"]="XAI Grok API|https://console.x.ai|可選|創意思考、Zen MCP 高級功能|可選"
    ["openrouter"]="OpenRouter API|https://openrouter.ai/keys|可選|多模型聚合服務|可選"
)

# 解析 API 提供者資訊
get_provider_info() {
    local provider="$1"
    local field="$2"
    
    if [[ -n "${API_PROVIDERS[$provider]}" ]]; then
        local info="${API_PROVIDERS[$provider]}"
        IFS='|' read -r name url priority description requirement <<< "$info"
        
        case "$field" in
            "name") echo "$name" ;;
            "url") echo "$url" ;;
            "priority") echo "$priority" ;;
            "description") echo "$description" ;;
            "requirement") echo "$requirement" ;;
            *) echo "$info" ;;
        esac
    fi
}

# 檢查環境檔案
check_env_file() {
    log_step "檢查環境配置檔案..."
    
    if [ -z "$ENV_FILE" ]; then
        # 自動尋找 .env 檔案
        local possible_paths=(
            "$(pwd)/.env"
            "$(dirname "$SCRIPT_DIR")/.env"
            "$HOME/.bigdipper/bigdipper/.env"
        )
        
        for path in "${possible_paths[@]}"; do
            if [ -f "$path" ]; then
                ENV_FILE="$path"
                log_info "找到環境檔案: $ENV_FILE"
                break
            fi
        done
        
        if [ -z "$ENV_FILE" ]; then
            # 尋找範本檔案
            local template_paths=(
                "$(pwd)/.env.bigdipper.template"
                "$(dirname "$SCRIPT_DIR")/.env.bigdipper.template"
                "$HOME/.bigdipper/bigdipper/.env.bigdipper.template"
            )
            
            for template in "${template_paths[@]}"; do
                if [ -f "$template" ]; then
                    ENV_FILE="$(dirname "$template")/.env"
                    log_info "從範本建立環境檔案: $ENV_FILE"
                    cp "$template" "$ENV_FILE"
                    break
                fi
            done
        fi
        
        if [ -z "$ENV_FILE" ]; then
            log_error "找不到環境檔案或範本"
            exit 1
        fi
    fi
    
    if [ ! -f "$ENV_FILE" ]; then
        log_error "環境檔案不存在: $ENV_FILE"
        exit 1
    fi
    
    log_success "環境檔案準備完成: $ENV_FILE"
}

# 備份環境檔案
backup_env_file() {
    if [ "$BACKUP_CREATED" = false ]; then
        local backup_file="${ENV_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$ENV_FILE" "$backup_file"
        log_info "已備份環境檔案到: $backup_file"
        BACKUP_CREATED=true
    fi
}

# 檢查當前 API 金鑰狀態
check_current_api_keys() {
    log_step "檢查當前 API 金鑰狀態..."
    
    local configured_count=0
    local total_providers=${#API_PROVIDERS[@]}
    
    echo
    echo -e "${BOLD}當前 API 金鑰狀態：${NC}"
    echo "=========================="
    
    for provider in "${!API_PROVIDERS[@]}"; do
        local name=$(get_provider_info "$provider" "name")
        local requirement=$(get_provider_info "$provider" "requirement")
        local priority=$(get_provider_info "$provider" "priority")
        
        # 讀取當前值
        local current_value=""
        case "$provider" in
            "anthropic") current_value=$(grep "^ANTHROPIC_API_KEY=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '"' | tr -d "'") ;;
            "perplexity") current_value=$(grep "^PERPLEXITY_API_KEY=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '"' | tr -d "'") ;;
            "openai") current_value=$(grep "^OPENAI_API_KEY=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '"' | tr -d "'") ;;
            "google") current_value=$(grep "^GOOGLE_API_KEY=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '"' | tr -d "'") ;;
            "xai") current_value=$(grep "^XAI_API_KEY=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '"' | tr -d "'") ;;
            "openrouter") current_value=$(grep "^OPENROUTER_API_KEY=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '"' | tr -d "'") ;;
        esac
        
        # 檢查是否已配置
        local status_icon="❌"
        local status_text="未設定"
        local status_color="$RED"
        
        if [ ! -z "$current_value" ] && [ "$current_value" != "your_${provider}_api_key_here" ] && [ "$current_value" != "your_api_key_here" ]; then
            status_icon="✅"
            status_text="已設定"
            status_color="$GREEN"
            configured_count=$((configured_count + 1))
        fi
        
        # 顯示狀態
        local priority_badge=""
        case "$priority" in
            "推薦") priority_badge="${GREEN}[推薦]${NC}" ;;
            "必需") priority_badge="${RED}[必需]${NC}" ;;
            "可選") priority_badge="${YELLOW}[可選]${NC}" ;;
        esac
        
        echo -e "$status_icon ${status_color}$name${NC} $priority_badge"
        
        if [ ! -z "$current_value" ] && [ "$current_value" != "your_${provider}_api_key_here" ] && [ "$current_value" != "your_api_key_here" ]; then
            # 顯示部分金鑰（隱藏敏感部分）
            local masked_key="${current_value:0:8}...${current_value: -4}"
            echo -e "  金鑰: $masked_key"
        fi
        
        echo
    done
    
    echo "=========================="
    log_info "已配置: $configured_count/$total_providers 個 API 金鑰"
    echo
}

# 顯示 API 提供者詳細資訊
show_provider_details() {
    local provider="$1"
    
    local name=$(get_provider_info "$provider" "name")
    local url=$(get_provider_info "$provider" "url")
    local priority=$(get_provider_info "$provider" "priority")
    local description=$(get_provider_info "$provider" "description")
    local requirement=$(get_provider_info "$provider" "requirement")
    
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}🔑 $name${NC}"
    echo
    echo -e "📋 ${BOLD}用途：${NC}$description"
    echo -e "🎯 ${BOLD}重要性：${NC}$priority ($requirement)"
    echo -e "🌐 ${BOLD}申請網址：${NC}$url"
    echo
    
    # 提供使用建議
    case "$provider" in
        "anthropic")
            echo -e "${YELLOW}💡 重要提示：${NC}"
            echo "• Claude API 是北斗七星陣的核心，提供主要 AI 功能"
            echo "• 建議申請 Claude 3.5 Sonnet 或更高版本"
            echo "• 用於 TaskMaster、Zen MCP、Serena 等多個服務"
            ;;
        "perplexity")
            echo -e "${YELLOW}💡 重要提示：${NC}"
            echo "• Perplexity AI 提供即時網路搜尋和研究功能"
            echo "• 支援多種模型：sonar、sonar-pro、sonar-deep-research"
            echo "• 用於技術趨勢分析和最新資訊查詢"
            ;;
        "openai")
            echo -e "${YELLOW}💡 重要提示：${NC}"
            echo "• OpenAI API 作為備用 AI 模型"
            echo "• 支援 GPT-4、GPT-3.5 等模型"
            echo "• 可與 Zen MCP 整合提供多模型選擇"
            ;;
        "google")
            echo -e "${YELLOW}💡 重要提示：${NC}"
            echo "• Google Gemini API 擅長處理大型文件"
            echo "• 支援 100 萬 token 上下文"
            echo "• 適合代碼庫分析和文檔處理"
            ;;
        "xai")
            echo -e "${YELLOW}💡 重要提示：${NC}"
            echo "• XAI Grok 提供創意思考能力"
            echo "• 適合複雜推理和創新解決方案"
            echo "• 與 Zen MCP 整合提供高級 AI 功能"
            ;;
        "openrouter")
            echo -e "${YELLOW}💡 重要提示：${NC}"
            echo "• OpenRouter 提供多模型聚合服務"
            echo "• 一個 API 金鑰訪問多種 AI 模型"
            echo "• 適合需要多樣化 AI 能力的場景"
            ;;
    esac
    
    echo
}

# 驗證 API 金鑰格式
validate_api_key() {
    local provider="$1"
    local key="$2"
    
    if [ -z "$key" ]; then
        return 1
    fi
    
    # 基本格式檢查
    case "$provider" in
        "anthropic")
            # Claude API 金鑰通常以 sk-ant- 開頭
            if [[ "$key" =~ ^sk-ant-[a-zA-Z0-9_-]+$ ]]; then
                return 0
            else
                log_warn "Anthropic API 金鑰格式可能不正確（應以 sk-ant- 開頭）"
                return 2
            fi
            ;;
        "perplexity")
            # Perplexity API 金鑰格式
            if [[ "$key" =~ ^pplx-[a-zA-Z0-9]+$ ]]; then
                return 0
            else
                log_warn "Perplexity API 金鑰格式可能不正確（應以 pplx- 開頭）"
                return 2
            fi
            ;;
        "openai")
            # OpenAI API 金鑰通常以 sk- 開頭
            if [[ "$key" =~ ^sk-[a-zA-Z0-9]+$ ]]; then
                return 0
            else
                log_warn "OpenAI API 金鑰格式可能不正確（應以 sk- 開頭）"
                return 2
            fi
            ;;
        "google")
            # Google API 金鑰是隨機字串
            if [[ ${#key} -ge 20 ]]; then
                return 0
            else
                log_warn "Google API 金鑰長度可能不正確"
                return 2
            fi
            ;;
        "xai")
            # XAI API 金鑰格式
            if [[ "$key" =~ ^xai-[a-zA-Z0-9]+$ ]]; then
                return 0
            else
                log_warn "XAI API 金鑰格式可能不正確（應以 xai- 開頭）"
                return 2
            fi
            ;;
        "openrouter")
            # OpenRouter API 金鑰格式
            if [[ "$key" =~ ^sk-or-[a-zA-Z0-9_-]+$ ]]; then
                return 0
            else
                log_warn "OpenRouter API 金鑰格式可能不正確（應以 sk-or- 開頭）"
                return 2
            fi
            ;;
        *)
            # 通用檢查：至少 20 個字符
            if [[ ${#key} -ge 20 ]]; then
                return 0
            else
                log_warn "API 金鑰長度可能不正確"
                return 2
            fi
            ;;
    esac
}

# 測試 API 金鑰
test_api_key() {
    local provider="$1"
    local key="$2"
    
    log_info "測試 $provider API 金鑰..."
    
    case "$provider" in
        "anthropic")
            # 測試 Anthropic API
            local response=$(curl -s -o /dev/null -w "%{http_code}" \
                -H "Authorization: Bearer $key" \
                -H "anthropic-version: 2023-06-01" \
                "https://api.anthropic.com/v1/messages" \
                -d '{"model":"claude-3-haiku-20240307","max_tokens":1,"messages":[{"role":"user","content":"test"}]}' 2>/dev/null)
            
            if [ "$response" = "200" ] || [ "$response" = "400" ]; then
                log_success "Anthropic API 金鑰有效"
                return 0
            else
                log_error "Anthropic API 金鑰測試失敗 (HTTP $response)"
                return 1
            fi
            ;;
        "perplexity")
            # 測試 Perplexity API
            local response=$(curl -s -o /dev/null -w "%{http_code}" \
                -H "Authorization: Bearer $key" \
                "https://api.perplexity.ai/chat/completions" \
                -d '{"model":"sonar-small-chat","messages":[{"role":"user","content":"test"}],"max_tokens":1}' 2>/dev/null)
            
            if [ "$response" = "200" ] || [ "$response" = "400" ]; then
                log_success "Perplexity API 金鑰有效"
                return 0
            else
                log_error "Perplexity API 金鑰測試失敗 (HTTP $response)"
                return 1
            fi
            ;;
        "openai")
            # 測試 OpenAI API
            local response=$(curl -s -o /dev/null -w "%{http_code}" \
                -H "Authorization: Bearer $key" \
                "https://api.openai.com/v1/models" 2>/dev/null)
            
            if [ "$response" = "200" ]; then
                log_success "OpenAI API 金鑰有效"
                return 0
            else
                log_error "OpenAI API 金鑰測試失敗 (HTTP $response)"
                return 1
            fi
            ;;
        *)
            log_warn "暫不支援 $provider API 金鑰測試，僅進行格式驗證"
            return 0
            ;;
    esac
}

# 設定單個 API 金鑰
configure_api_key() {
    local provider="$1"
    local skip_test="$2"
    
    local name=$(get_provider_info "$provider" "name")
    local url=$(get_provider_info "$provider" "url")
    local priority=$(get_provider_info "$provider" "priority")
    
    echo
    show_provider_details "$provider"
    
    # 讀取當前值
    local current_value=""
    local env_var_name=""
    case "$provider" in
        "anthropic") 
            env_var_name="ANTHROPIC_API_KEY"
            current_value=$(grep "^ANTHROPIC_API_KEY=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '"' | tr -d "'")
            ;;
        "perplexity") 
            env_var_name="PERPLEXITY_API_KEY"
            current_value=$(grep "^PERPLEXITY_API_KEY=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '"' | tr -d "'")
            ;;
        "openai") 
            env_var_name="OPENAI_API_KEY"
            current_value=$(grep "^OPENAI_API_KEY=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '"' | tr -d "'")
            ;;
        "google") 
            env_var_name="GOOGLE_API_KEY"
            current_value=$(grep "^GOOGLE_API_KEY=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '"' | tr -d "'")
            ;;
        "xai") 
            env_var_name="XAI_API_KEY"
            current_value=$(grep "^XAI_API_KEY=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '"' | tr -d "'")
            ;;
        "openrouter") 
            env_var_name="OPENROUTER_API_KEY"
            current_value=$(grep "^OPENROUTER_API_KEY=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '"' | tr -d "'")
            ;;
    esac
    
    # 顯示當前狀態
    if [ ! -z "$current_value" ] && [ "$current_value" != "your_${provider}_api_key_here" ] && [ "$current_value" != "your_api_key_here" ]; then
        local masked_key="${current_value:0:8}...${current_value: -4}"
        echo -e "${GREEN}當前已設定金鑰：${NC}$masked_key"
        echo
        
        if [ "$priority" != "必需" ]; then
            read -p "是否要更新此金鑰？(y/N): " -r
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                log_info "跳過 $name 配置"
                return 0
            fi
        fi
    fi
    
    # 提示用戶輸入
    echo -e "${BOLD}請輸入您的 $name：${NC}"
    echo "（按 Enter 跳過，輸入 'open' 開啟申請網頁）"
    echo
    
    local new_key=""
    while true; do
        read -p "API 金鑰: " -r new_key
        
        if [ -z "$new_key" ]; then
            if [ "$priority" = "必需" ]; then
                log_warn "這是必需的 API 金鑰，建議設定"
                read -p "確定要跳過嗎？(y/N): " -r
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    log_info "跳過 $name 配置"
                    return 0
                fi
                continue
            else
                log_info "跳過 $name 配置"
                return 0
            fi
        elif [ "$new_key" = "open" ]; then
            log_info "開啟 $name 申請網頁..."
            if command -v open >/dev/null 2>&1; then
                open "$url"
            elif command -v xdg-open >/dev/null 2>&1; then
                xdg-open "$url"
            else
                echo "請手動開啟: $url"
            fi
            continue
        else
            break
        fi
    done
    
    # 驗證金鑰格式
    validate_api_key "$provider" "$new_key"
    local validation_result=$?
    
    if [ $validation_result -eq 1 ]; then
        log_error "API 金鑰格式無效"
        return 1
    elif [ $validation_result -eq 2 ]; then
        read -p "格式警告，是否繼續？(y/N): " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi
    
    # 測試 API 金鑰（可選）
    if [ "$skip_test" != "true" ] && [ "$priority" = "必需" ]; then
        echo
        read -p "是否測試 API 金鑰有效性？(Y/n): " -r
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            if ! test_api_key "$provider" "$new_key"; then
                read -p "API 測試失敗，是否仍要保存？(y/N): " -r
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    return 1
                fi
            fi
        fi
    fi
    
    # 保存到環境檔案
    backup_env_file
    
    # 更新環境檔案
    if grep -q "^$env_var_name=" "$ENV_FILE"; then
        # 更新現有行
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s|^$env_var_name=.*|$env_var_name=$new_key|" "$ENV_FILE"
        else
            sed -i "s|^$env_var_name=.*|$env_var_name=$new_key|" "$ENV_FILE"
        fi
    else
        # 添加新行
        echo "$env_var_name=$new_key" >> "$ENV_FILE"
    fi
    
    log_success "$name API 金鑰已保存"
    return 0
}

# 互動式配置嚮導
interactive_wizard() {
    show_wizard_banner
    
    log_wizard "歡迎使用北斗七星陣 API 配置精靈！"
    echo
    log_info "此精靈將引導您完成所有 API 金鑰的配置"
    log_info "您可以隨時按 Ctrl+C 退出"
    echo
    
    read -p "按 Enter 開始配置，或輸入 'q' 退出: " -r
    if [[ $REPLY = "q" ]]; then
        exit 0
    fi
    
    # 檢查當前狀態
    check_current_api_keys
    
    # 配置順序：必需 -> 推薦 -> 可選
    local providers_ordered=("anthropic" "perplexity" "openai" "google" "xai" "openrouter")
    
    for provider in "${providers_ordered[@]}"; do
        local priority=$(get_provider_info "$provider" "priority")
        local name=$(get_provider_info "$provider" "name")
        
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${BOLD}配置 $name${NC}"
        echo
        
        configure_api_key "$provider"
        
        echo
        read -p "按 Enter 繼續下一個 API，或輸入 'q' 完成配置: " -r
        if [[ $REPLY = "q" ]]; then
            break
        fi
    done
    
    # 顯示配置總結
    echo
    log_step "配置完成！正在生成總結..."
    check_current_api_keys
    
    echo -e "${GREEN}✨ API 配置精靈完成！${NC}"
    echo
    echo -e "${CYAN}後續步驟：${NC}"
    echo "1. 執行安裝腳本部署北斗七星陣"
    echo "2. 使用管理腳本啟動和監控服務"
    echo "3. 在 Claude CLI 中註冊 MCP Servers"
    echo
}

# 快速配置模式
quick_setup() {
    log_step "快速配置模式 - 僅配置必需 API"
    
    local required_providers=("anthropic" "perplexity")
    
    for provider in "${required_providers[@]}"; do
        local name=$(get_provider_info "$provider" "name")
        echo
        echo -e "${BOLD}配置 $name（必需）${NC}"
        configure_api_key "$provider" "true"
    done
    
    log_success "必需 API 配置完成"
}

# 驗證模式
validate_mode() {
    log_step "驗證現有 API 金鑰..."
    
    local all_valid=true
    
    for provider in "${!API_PROVIDERS[@]}"; do
        local name=$(get_provider_info "$provider" "name")
        local priority=$(get_provider_info "$provider" "priority")
        
        # 讀取當前值
        local current_value=""
        case "$provider" in
            "anthropic") current_value=$(grep "^ANTHROPIC_API_KEY=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '"' | tr -d "'") ;;
            "perplexity") current_value=$(grep "^PERPLEXITY_API_KEY=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '"' | tr -d "'") ;;
            "openai") current_value=$(grep "^OPENAI_API_KEY=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '"' | tr -d "'") ;;
            "google") current_value=$(grep "^GOOGLE_API_KEY=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '"' | tr -d "'") ;;
            "xai") current_value=$(grep "^XAI_API_KEY=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '"' | tr -d "'") ;;
            "openrouter") current_value=$(grep "^OPENROUTER_API_KEY=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '"' | tr -d "'") ;;
        esac
        
        if [ ! -z "$current_value" ] && [ "$current_value" != "your_${provider}_api_key_here" ] && [ "$current_value" != "your_api_key_here" ]; then
            echo -n "驗證 $name... "
            
            validate_api_key "$provider" "$current_value"
            local validation_result=$?
            
            if [ $validation_result -eq 0 ]; then
                echo -e "${GREEN}✓ 格式正確${NC}"
                
                # 可選：測試 API
                if [ "$priority" = "必需" ]; then
                    echo -n "測試連線... "
                    if test_api_key "$provider" "$current_value"; then
                        echo -e "${GREEN}✓ 連線正常${NC}"
                    else
                        echo -e "${RED}✗ 連線失敗${NC}"
                        all_valid=false
                    fi
                fi
            else
                echo -e "${YELLOW}⚠ 格式警告${NC}"
                all_valid=false
            fi
        elif [ "$priority" = "必需" ]; then
            echo -e "${RED}✗ $name 未設定（必需）${NC}"
            all_valid=false
        else
            echo -e "${YELLOW}- $name 未設定（可選）${NC}"
        fi
    done
    
    echo
    if [ "$all_valid" = true ]; then
        log_success "所有 API 金鑰驗證通過"
        exit 0
    else
        log_error "部分 API 金鑰存在問題"
        exit 1
    fi
}

# 主函數
main() {
    # 處理命令列參數
    case "${1:-}" in
        --help|-h)
            echo "北斗七星陣 API 配置精靈"
            echo ""
            echo "用法: $0 [選項] [環境檔案]"
            echo ""
            echo "選項:"
            echo "  --help, -h          顯示此幫助資訊"
            echo "  --quick             快速配置模式（僅必需 API）"
            echo "  --validate          驗證現有 API 金鑰"
            echo "  --status            顯示當前配置狀態"
            echo "  --provider <name>   配置特定提供者"
            echo "  --no-test           跳過 API 測試"
            echo ""
            echo "環境檔案:"
            echo "  指定要配置的 .env 檔案路徑"
            echo "  預設會自動尋找環境檔案"
            echo ""
            echo "範例:"
            echo "  $0                     # 互動式配置嚮導"
            echo "  $0 --quick             # 快速配置必需 API"
            echo "  $0 --provider anthropic # 僅配置 Anthropic API"
            echo "  $0 --validate          # 驗證現有配置"
            echo ""
            exit 0
            ;;
        --quick)
            INTERACTIVE_MODE=false
            ;;
        --validate)
            INTERACTIVE_MODE=false
            ;;
        --status)
            INTERACTIVE_MODE=false
            ;;
        --provider)
            if [ -z "$2" ]; then
                log_error "請指定提供者名稱"
                exit 1
            fi
            INTERACTIVE_MODE=false
            ;;
        --no-test)
            # 在配置函數中處理
            ;;
    esac
    
    # 設定環境檔案
    if [ ! -z "$2" ] && [ -f "$2" ]; then
        ENV_FILE="$2"
    elif [ ! -z "$1" ] && [ -f "$1" ] && [[ "$1" != --* ]]; then
        ENV_FILE="$1"
    fi
    
    check_env_file
    
    # 執行相應操作
    case "${1:-}" in
        --quick)
            quick_setup
            ;;
        --validate)
            validate_mode
            ;;
        --status)
            check_current_api_keys
            ;;
        --provider)
            configure_api_key "$2"
            ;;
        *)
            if [ "$INTERACTIVE_MODE" = true ]; then
                interactive_wizard
            else
                quick_setup
            fi
            ;;
    esac
}

# 執行主函數
main "$@"