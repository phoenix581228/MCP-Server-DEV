#!/bin/bash

# Generate git history visualization for MCP-Server-DEV
# This script creates visual representations of the git commit history

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_section() {
    echo -e "\n${CYAN}=== $1 ===${NC}\n"
}

# Function to show compact git log graph
show_compact_graph() {
    print_section "提交歷史圖 (Compact)"
    git log --all --decorate --oneline --graph -20
}

# Function to show detailed git log graph
show_detailed_graph() {
    print_section "提交歷史圖 (Detailed)"
    git log --all --graph --pretty=format:'%C(auto)%h%d %s %C(green)(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit -10
}

# Function to show branch structure
show_branch_structure() {
    print_section "分支結構"
    echo "當前分支："
    git branch --show-current
    echo ""
    echo "所有分支："
    git branch -a
}

# Function to show recent activity
show_recent_activity() {
    print_section "最近活動"
    echo "最近的提交："
    git log --oneline -5
    echo ""
    echo "檔案變更統計："
    git diff --stat HEAD~2..HEAD 2>/dev/null || echo "（少於 2 個提交）"
}

# Function to show project statistics
show_statistics() {
    print_section "專案統計"
    
    # Count commits
    commit_count=$(git rev-list --all --count)
    echo "總提交數: $commit_count"
    
    # Show contributors
    echo ""
    echo "貢獻者："
    git shortlog -sn --all
    
    # File count
    echo ""
    file_count=$(git ls-tree -r HEAD --name-only | wc -l)
    echo "版本控制中的檔案數: $file_count"
    
    # Language statistics (simple version)
    echo ""
    echo "檔案類型分布："
    git ls-tree -r HEAD --name-only | grep -E '\.(ts|js|py|md|json)$' | sed 's/.*\.//' | sort | uniq -c | sort -rn
}

# Function to generate commit history report
generate_history_report() {
    local output_file="GIT_HISTORY.md"
    
    print_info "生成提交歷史報告..."
    
    cat > "$output_file" << 'EOF'
# Git 提交歷史報告

此報告展示 MCP Server Development 專案的 Git 歷史記錄。

## 專案概覽

EOF
    
    # Add basic info
    echo "- **當前分支**: $(git branch --show-current)" >> "$output_file"
    echo "- **總提交數**: $(git rev-list --all --count)" >> "$output_file"
    echo "- **最後更新**: $(git log -1 --format=%cd --date=format:'%Y-%m-%d %H:%M:%S')" >> "$output_file"
    echo "" >> "$output_file"
    
    # Add commit graph
    echo "## 提交歷史圖" >> "$output_file"
    echo "" >> "$output_file"
    echo '```' >> "$output_file"
    git log --all --decorate --oneline --graph -20 >> "$output_file"
    echo '```' >> "$output_file"
    echo "" >> "$output_file"
    
    # Add recent commits
    echo "## 最近的提交" >> "$output_file"
    echo "" >> "$output_file"
    git log --pretty=format:"- **%h** - %s _(by %an, %ar)_" -10 >> "$output_file"
    echo "" >> "$output_file"
    echo "" >> "$output_file"
    
    # Add file changes
    echo "## 重要檔案變更" >> "$output_file"
    echo "" >> "$output_file"
    echo "### 最近變更的檔案" >> "$output_file"
    echo '```' >> "$output_file"
    git diff --name-status HEAD~2..HEAD 2>/dev/null >> "$output_file" || echo "（少於 2 個提交）" >> "$output_file"
    echo '```' >> "$output_file"
    echo "" >> "$output_file"
    
    # Add statistics
    echo "## 專案統計" >> "$output_file"
    echo "" >> "$output_file"
    echo "### 檔案類型分布" >> "$output_file"
    echo "" >> "$output_file"
    echo "| 檔案類型 | 數量 |" >> "$output_file"
    echo "|---------|------|" >> "$output_file"
    git ls-tree -r HEAD --name-only | grep -E '\.(ts|js|py|md|json)$' | sed 's/.*\.//' | sort | uniq -c | sort -rn | awk '{print "| ." $2 " | " $1 " |"}' >> "$output_file"
    echo "" >> "$output_file"
    
    # Add footer
    echo "---" >> "$output_file"
    echo "" >> "$output_file"
    echo "_報告生成時間: $(date '+%Y-%m-%d %H:%M:%S')_" >> "$output_file"
    
    print_success "歷史報告已生成: $output_file"
}

# Function to show usage
show_usage() {
    cat << EOF
使用方法: $0 [選項]

選項:
    -c, --compact     顯示精簡的提交圖
    -d, --detailed    顯示詳細的提交圖
    -b, --branches    顯示分支結構
    -r, --recent      顯示最近活動
    -s, --stats       顯示專案統計
    -g, --generate    生成完整的歷史報告 (GIT_HISTORY.md)
    -a, --all         顯示所有資訊
    -h, --help        顯示此幫助訊息

範例:
    $0 -c             # 只顯示精簡提交圖
    $0 -a             # 顯示所有資訊
    $0 -g             # 生成 Markdown 報告
EOF
}

# Main execution
main() {
    # Default to showing all if no arguments
    if [[ $# -eq 0 ]]; then
        show_compact_graph
        show_branch_structure
        show_recent_activity
        exit 0
    fi
    
    # Process arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -c|--compact)
                show_compact_graph
                ;;
            -d|--detailed)
                show_detailed_graph
                ;;
            -b|--branches)
                show_branch_structure
                ;;
            -r|--recent)
                show_recent_activity
                ;;
            -s|--stats)
                show_statistics
                ;;
            -g|--generate)
                generate_history_report
                ;;
            -a|--all)
                show_compact_graph
                show_detailed_graph
                show_branch_structure
                show_recent_activity
                show_statistics
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                echo "未知選項: $1"
                show_usage
                exit 1
                ;;
        esac
        shift
    done
}

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}錯誤：不在 Git 倉庫中${NC}"
    exit 1
fi

# Run main function
main "$@"