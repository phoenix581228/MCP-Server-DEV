#!/bin/bash

# Project Navigator for MCP-Server-DEV
# Interactive navigation tool for MCP Server Development projects

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

# Project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Function to print menu header
print_header() {
    clear
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}                       MCP Server Development - 專案導航器                          ${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Function to show project info
show_project_info() {
    local project_path="$1"
    local project_name="$2"
    
    echo -e "${BLUE}專案資訊 - $project_name${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if [[ -f "$project_path/package.json" ]]; then
        # Node.js project
        echo "類型: Node.js/TypeScript 專案"
        if command -v jq &> /dev/null; then
            version=$(jq -r '.version // "N/A"' "$project_path/package.json")
            description=$(jq -r '.description // "N/A"' "$project_path/package.json")
            echo "版本: $version"
            echo "描述: $description"
        fi
    elif [[ -f "$project_path/pyproject.toml" ]] || [[ -f "$project_path/setup.py" ]]; then
        # Python project
        echo "類型: Python 專案"
        if [[ -f "$project_path/pyproject.toml" ]]; then
            echo "設定檔: pyproject.toml"
        fi
    fi
    
    # Count files
    echo ""
    echo "檔案統計:"
    echo "- TypeScript: $(find "$project_path" -name "*.ts" -not -path "*/node_modules/*" 2>/dev/null | wc -l)"
    echo "- JavaScript: $(find "$project_path" -name "*.js" -not -path "*/node_modules/*" 2>/dev/null | wc -l)"
    echo "- Python: $(find "$project_path" -name "*.py" -not -path "*/__pycache__/*" 2>/dev/null | wc -l)"
    echo "- Markdown: $(find "$project_path" -name "*.md" 2>/dev/null | wc -l)"
    
    echo ""
}

# Function to show available actions
show_actions() {
    local project_path="$1"
    
    echo -e "${GREEN}可用操作:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "1) 開啟專案目錄 (cd)"
    echo "2) 查看 README"
    echo "3) 查看專案結構"
    echo "4) 查看最近提交"
    echo "5) 執行測試"
    echo "6) 查看文檔"
    echo "0) 返回主選單"
    echo ""
}

# Function to handle project actions
handle_project_actions() {
    local project_path="$1"
    local project_name="$2"
    
    while true; do
        print_header
        show_project_info "$project_path" "$project_name"
        show_actions "$project_path"
        
        read -p "請選擇操作 (0-6): " action
        
        case $action in
            1)
                echo ""
                echo -e "${GREEN}切換到專案目錄:${NC}"
                echo "cd $project_path"
                echo ""
                echo -e "${YELLOW}提示: 請在新的終端視窗中執行上述命令${NC}"
                read -p "按 Enter 繼續..."
                ;;
            2)
                if [[ -f "$project_path/README.md" ]]; then
                    less "$project_path/README.md"
                else
                    echo -e "${RED}找不到 README.md${NC}"
                    read -p "按 Enter 繼續..."
                fi
                ;;
            3)
                echo ""
                echo -e "${BLUE}專案結構:${NC}"
                tree -L 3 -I 'node_modules|__pycache__|.git|dist|build' "$project_path" 2>/dev/null || ls -la "$project_path"
                read -p "按 Enter 繼續..."
                ;;
            4)
                echo ""
                echo -e "${BLUE}最近的提交:${NC}"
                cd "$project_path" && git log --oneline -10 && cd "$PROJECT_ROOT"
                read -p "按 Enter 繼續..."
                ;;
            5)
                echo ""
                echo -e "${BLUE}測試命令:${NC}"
                if [[ -f "$project_path/package.json" ]]; then
                    echo "npm test"
                elif [[ -f "$project_path/pytest.ini" ]]; then
                    echo "pytest"
                else
                    echo "沒有找到測試配置"
                fi
                read -p "按 Enter 繼續..."
                ;;
            6)
                if [[ -d "$project_path/docs" ]]; then
                    echo ""
                    echo -e "${BLUE}可用文檔:${NC}"
                    ls -1 "$project_path/docs/"
                    read -p "按 Enter 繼續..."
                else
                    echo -e "${RED}找不到 docs 目錄${NC}"
                    read -p "按 Enter 繼續..."
                fi
                ;;
            0)
                return
                ;;
            *)
                echo -e "${RED}無效選擇${NC}"
                sleep 1
                ;;
        esac
    done
}

# Function to show main menu
show_main_menu() {
    echo -e "${GREEN}請選擇要導航的專案:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "1) Perplexity MCP Custom Server"
    echo "   └─ 自製的 Perplexity AI 整合 MCP Server"
    echo ""
    echo "2) Zen MCP Server"
    echo "   └─ 多模型 AI 協作的 MCP Server"
    echo ""
    echo "3) 專案總覽"
    echo "   └─ 查看所有專案的概要資訊"
    echo ""
    echo "4) Git 歷史視覺化"
    echo "   └─ 查看專案的提交歷史圖"
    echo ""
    echo "5) 更新專案結構文檔"
    echo "   └─ 重新生成 PROJECT_STRUCTURE.md"
    echo ""
    echo "0) 退出"
    echo ""
}

# Function to show project overview
show_overview() {
    print_header
    echo -e "${BLUE}專案總覽${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Show each project's basic info
    for project in "perplexity-mcp-custom" "zen-mcp-server"; do
        if [[ -d "$PROJECT_ROOT/$project" ]]; then
            echo -e "${GREEN}$project${NC}"
            cd "$PROJECT_ROOT/$project"
            
            # Get last commit
            last_commit=$(git log -1 --format="%h - %s (%ar)" 2>/dev/null || echo "No commits")
            echo "最後提交: $last_commit"
            
            # Count files
            file_count=$(find . -type f -not -path '*/\.*' -not -path '*/node_modules/*' -not -path '*/__pycache__/*' | wc -l)
            echo "檔案數量: $file_count"
            
            echo ""
            cd "$PROJECT_ROOT"
        fi
    done
    
    read -p "按 Enter 返回主選單..."
}

# Main menu loop
main_menu() {
    while true; do
        print_header
        show_main_menu
        
        read -p "請選擇 (0-5): " choice
        
        case $choice in
            1)
                if [[ -d "$PROJECT_ROOT/perplexity-mcp-custom" ]]; then
                    handle_project_actions "$PROJECT_ROOT/perplexity-mcp-custom" "Perplexity MCP Custom"
                else
                    echo -e "${RED}找不到 perplexity-mcp-custom 專案${NC}"
                    sleep 2
                fi
                ;;
            2)
                if [[ -d "$PROJECT_ROOT/zen-mcp-server" ]]; then
                    handle_project_actions "$PROJECT_ROOT/zen-mcp-server" "Zen MCP Server"
                else
                    echo -e "${RED}找不到 zen-mcp-server 專案${NC}"
                    sleep 2
                fi
                ;;
            3)
                show_overview
                ;;
            4)
                "$PROJECT_ROOT/scripts/git-history-graph.sh" -a
                read -p "按 Enter 繼續..."
                ;;
            5)
                echo -e "${BLUE}更新專案結構...${NC}"
                "$PROJECT_ROOT/scripts/generate-tree.sh"
                read -p "按 Enter 繼續..."
                ;;
            0)
                echo -e "${GREEN}感謝使用專案導航器！${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}無效選擇${NC}"
                sleep 1
                ;;
        esac
    done
}

# Check if we're in the right directory
if [[ ! -f "$PROJECT_ROOT/README.md" ]]; then
    echo -e "${RED}錯誤: 無法找到專案根目錄${NC}"
    echo "請確保腳本位於 MCP-Server-DEV/scripts/ 目錄中"
    exit 1
fi

# Start the navigator
main_menu