#!/bin/bash

# Claude Code MCP 整合測試腳本
# 全面測試 MCP Server 部署和整合狀態

set -euo pipefail

# 顏色定義
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# 測試結果統計
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
WARNINGS=0

# 測試結果記錄
test_result() {
    local test_name=$1
    local status=$2
    local message=${3:-""}
    
    ((TOTAL_TESTS++))
    
    case $status in
        "pass")
            ((PASSED_TESTS++))
            echo -e "${GREEN}✅ $test_name${NC}"
            ;;
        "fail")
            ((FAILED_TESTS++))
            echo -e "${RED}❌ $test_name${NC}"
            ;;
        "warn")
            ((WARNINGS++))
            echo -e "${YELLOW}⚠️  $test_name${NC}"
            ;;
    esac
    
    if [ -n "$message" ]; then
        echo "   $message"
    fi
}

# 環境測試
test_environment() {
    echo -e "\n${BLUE}=== 環境測試 ===${NC}"
    
    # macOS 版本
    local os_version=$(sw_vers -productVersion)
    if [[ "$os_version" =~ ^1[5-9]\. ]]; then
        test_result "macOS 版本 ($os_version)" "pass"
    else
        test_result "macOS 版本 ($os_version)" "warn" "建議使用 macOS 15.5 或更高版本"
    fi
    
    # Node.js
    if command -v node >/dev/null 2>&1; then
        local node_version=$(node --version)
        test_result "Node.js ($node_version)" "pass"
    else
        test_result "Node.js" "fail" "未安裝"
    fi
    
    # Python
    if command -v python3 >/dev/null 2>&1; then
        local python_version=$(python3 --version | awk '{print $2}')
        test_result "Python ($python_version)" "pass"
    else
        test_result "Python" "fail" "未安裝"
    fi
    
    # Docker
    if command -v docker >/dev/null 2>&1; then
        if docker info >/dev/null 2>&1; then
            test_result "Docker" "pass" "運行中"
        else
            test_result "Docker" "warn" "已安裝但未運行"
        fi
    else
        test_result "Docker" "fail" "未安裝"
    fi
    
    # Claude CLI
    if command -v claude >/dev/null 2>&1; then
        test_result "Claude CLI" "pass"
    else
        test_result "Claude CLI" "fail" "未安裝"
    fi
}

# MCP Server 測試
test_mcp_servers() {
    echo -e "\n${BLUE}=== MCP Server 測試 ===${NC}"
    
    # Perplexity
    if [ -f "$HOME/.claude-code-perplexity.sh" ]; then
        if timeout 5 bash -c 'echo "{\"jsonrpc\":\"2.0\",\"method\":\"initialize\",\"id\":1}" | '"$HOME/.claude-code-perplexity.sh" >/dev/null 2>&1; then
            test_result "Perplexity MCP" "pass"
        else
            test_result "Perplexity MCP" "fail" "初始化失敗"
        fi
    else
        test_result "Perplexity MCP" "fail" "包裝腳本未找到"
    fi
    
    # OpenMemory
    if curl -s -f http://localhost:8765/health >/dev/null 2>&1; then
        test_result "OpenMemory API" "pass"
    else
        test_result "OpenMemory API" "fail" "服務未響應"
    fi
    
    # Qdrant
    if curl -s -f http://localhost:6333/health >/dev/null 2>&1; then
        test_result "Qdrant Vector DB" "pass"
    else
        test_result "Qdrant Vector DB" "warn" "服務未響應"
    fi
    
    # PostgreSQL
    if nc -z localhost 5432 2>/dev/null; then
        test_result "PostgreSQL" "pass"
    else
        test_result "PostgreSQL" "warn" "端口未開放"
    fi
}

# Claude CLI 整合測試
test_claude_integration() {
    echo -e "\n${BLUE}=== Claude CLI 整合測試 ===${NC}"
    
    # 獲取註冊列表
    if ! command -v claude >/dev/null 2>&1; then
        test_result "Claude CLI 整合" "fail" "Claude CLI 未安裝"
        return
    fi
    
    local mcp_list=$(claude mcp list 2>/dev/null || echo "")
    
    # 測試各服務註冊狀態
    local services=("perplexity" "zen" "serena" "taskmaster")
    for service in "${services[@]}"; do
        if echo "$mcp_list" | grep -q "$service"; then
            test_result "$service 註冊" "pass"
        else
            test_result "$service 註冊" "fail" "未在 Claude CLI 中註冊"
        fi
    done
    
    # OpenMemory 特殊說明
    test_result "OpenMemory" "warn" "使用 SSE 協議，需通過 HTTP API 訪問"
}

# CLAUDE.md 測試
test_claude_md() {
    echo -e "\n${BLUE}=== CLAUDE.md 配置測試 ===${NC}"
    
    local claude_md="$HOME/.claude/CLAUDE.md"
    
    if [ -f "$claude_md" ]; then
        test_result "CLAUDE.md 文件" "pass"
        
        # 檢查 MCP 開發原則
        if grep -q "MCP Server 開發原則" "$claude_md"; then
            test_result "MCP 開發原則" "pass"
        else
            test_result "MCP 開發原則" "fail" "未找到 MCP 開發原則部分"
        fi
        
        # 檢查端口保護
        if grep -q "check_mcp_ports" "$claude_md"; then
            test_result "端口保護函數" "pass"
        else
            test_result "端口保護函數" "fail" "未找到端口保護函數"
        fi
    else
        test_result "CLAUDE.md 文件" "fail" "文件不存在"
    fi
}

# 端口測試
test_ports() {
    echo -e "\n${BLUE}=== 端口使用測試 ===${NC}"
    
    local ports=(8765 6333 5432 3000 8080 9997 1234 11434)
    local names=("OpenMemory" "Qdrant" "PostgreSQL" "WebUI" "Perplexity" "Xinference" "LMStudio" "Ollama")
    
    for i in "${!ports[@]}"; do
        local port=${ports[$i]}
        local name=${names[$i]}
        
        if lsof -ti:$port >/dev/null 2>&1; then
            local process=$(lsof -ti:$port | xargs ps -p 2>/dev/null | tail -n 1 | awk '{print $4}')
            test_result "Port $port ($name)" "pass" "使用中: $process"
        else
            test_result "Port $port ($name)" "warn" "未使用"
        fi
    done
}

# API 金鑰測試
test_api_keys() {
    echo -e "\n${BLUE}=== API 金鑰配置測試 ===${NC}"
    
    # 測試 Keychain 中的金鑰
    local keys=("PERPLEXITY_API_KEY" "OPENAI_API_KEY" "ANTHROPIC_API_KEY")
    
    for key in "${keys[@]}"; do
        if security find-generic-password -a "mcp-deployment" -s "$key" >/dev/null 2>&1; then
            test_result "$key" "pass" "已在 Keychain 中配置"
        else
            test_result "$key" "warn" "未在 Keychain 中找到"
        fi
    done
}

# 生成測試報告
generate_report() {
    local report_file="test_report_$(date +%Y%m%d_%H%M%S).md"
    
    cat > "$report_file" << EOF
# MCP Server 整合測試報告

生成時間: $(date)
測試系統: $(hostname)

## 測試摘要

- 總測試數: $TOTAL_TESTS
- 通過: $PASSED_TESTS
- 失敗: $FAILED_TESTS
- 警告: $WARNINGS
- 成功率: $(( PASSED_TESTS * 100 / TOTAL_TESTS ))%

## 測試結果

### 環境測試
$(test_environment 2>&1)

### MCP Server 測試
$(test_mcp_servers 2>&1)

### Claude CLI 整合
$(test_claude_integration 2>&1)

### CLAUDE.md 配置
$(test_claude_md 2>&1)

### 端口使用
$(test_ports 2>&1)

### API 金鑰
$(test_api_keys 2>&1)

## 建議

$(generate_recommendations)

---
*測試報告完成*
EOF
    
    echo -e "\n${GREEN}✅ 測試報告已生成: $report_file${NC}"
}

# 生成建議
generate_recommendations() {
    if [ $FAILED_TESTS -eq 0 ]; then
        echo "✅ 所有測試通過！MCP Server 部署成功。"
    else
        echo "### 需要處理的問題："
        
        if ! command -v claude >/dev/null 2>&1; then
            echo "1. 安裝 Claude Code CLI"
        fi
        
        if ! docker info >/dev/null 2>&1; then
            echo "2. 啟動 Docker Desktop"
        fi
        
        if [ $FAILED_TESTS -gt 0 ]; then
            echo "3. 檢查失敗的測試項目並根據錯誤信息進行修復"
        fi
    fi
}

# 主函數
main() {
    echo -e "${PURPLE}╔══════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║   MCP Server 整合測試工具 v1.0.0    ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════╝${NC}"
    
    # 執行測試
    test_environment
    test_mcp_servers
    test_claude_integration
    test_claude_md
    test_ports
    test_api_keys
    
    # 顯示摘要
    echo -e "\n${BLUE}=== 測試摘要 ===${NC}"
    echo -e "總測試數: $TOTAL_TESTS"
    echo -e "${GREEN}通過: $PASSED_TESTS${NC}"
    echo -e "${RED}失敗: $FAILED_TESTS${NC}"
    echo -e "${YELLOW}警告: $WARNINGS${NC}"
    
    local success_rate=$(( PASSED_TESTS * 100 / TOTAL_TESTS ))
    echo -e "成功率: $success_rate%"
    
    # 生成報告
    read -p "是否生成詳細測試報告？(y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        generate_report
    fi
    
    # 返回狀態
    if [ $FAILED_TESTS -eq 0 ]; then
        echo -e "\n${GREEN}✅ 所有關鍵測試通過！${NC}"
        exit 0
    else
        echo -e "\n${RED}❌ 有 $FAILED_TESTS 個測試失敗${NC}"
        exit 1
    fi
}

# 執行主函數
main "$@"