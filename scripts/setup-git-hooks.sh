#!/bin/bash

# Setup Git hooks for MCP-Server-DEV
# This script installs Git hooks to maintain project structure consistency

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Project root
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOKS_DIR="$PROJECT_ROOT/.git/hooks"

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Create pre-commit hook
create_pre_commit_hook() {
    print_info "創建 pre-commit hook..."
    
    cat > "$HOOKS_DIR/pre-commit" << 'EOF'
#!/bin/bash
# Pre-commit hook for MCP-Server-DEV
# Updates project structure documentation before commit

# Colors
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${YELLOW}[PRE-COMMIT]${NC} 檢查專案結構變更..."

# Check if any structural changes were made
STRUCTURE_CHANGED=0

# Check for new/deleted files
if git diff --cached --name-status | grep -E '^[AD]'; then
    STRUCTURE_CHANGED=1
fi

# Check for new directories
if git diff --cached --name-only | grep -E '/' | sort -u | while read -r file; do
    dir=$(dirname "$file")
    if [[ ! -d "$dir" ]]; then
        echo "New directory detected: $dir"
        return 0
    fi
done; then
    STRUCTURE_CHANGED=1
fi

if [[ $STRUCTURE_CHANGED -eq 1 ]]; then
    echo -e "${YELLOW}[PRE-COMMIT]${NC} 偵測到結構變更，更新專案結構文檔..."
    
    # Run the structure generation script
    if [[ -x "./scripts/generate-tree.sh" ]]; then
        ./scripts/generate-tree.sh > /dev/null 2>&1
        
        # Add the updated structure file to the commit
        git add PROJECT_STRUCTURE.md
        echo -e "${GREEN}[PRE-COMMIT]${NC} 專案結構文檔已更新並加入提交"
    else
        echo -e "${YELLOW}[PRE-COMMIT]${NC} 找不到 generate-tree.sh，跳過結構更新"
    fi
fi

# Run tests if available
if [[ -f "package.json" ]] && grep -q '"test"' package.json; then
    echo -e "${YELLOW}[PRE-COMMIT]${NC} 執行測試..."
    # Uncomment to enable automatic testing
    # npm test
fi

exit 0
EOF
    
    chmod +x "$HOOKS_DIR/pre-commit"
    print_success "pre-commit hook 已創建"
}

# Create post-commit hook
create_post_commit_hook() {
    print_info "創建 post-commit hook..."
    
    cat > "$HOOKS_DIR/post-commit" << 'EOF'
#!/bin/bash
# Post-commit hook for MCP-Server-DEV
# Updates git history documentation after commit

# Colors
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}[POST-COMMIT]${NC} 更新 Git 歷史文檔..."

# Update git history if script exists
if [[ -x "./scripts/git-history-graph.sh" ]]; then
    ./scripts/git-history-graph.sh -g > /dev/null 2>&1
    echo -e "${GREEN}[POST-COMMIT]${NC} Git 歷史文檔已更新"
fi

# Show commit summary
echo -e "${GREEN}[POST-COMMIT]${NC} 提交成功！"
git log --oneline -1
EOF
    
    chmod +x "$HOOKS_DIR/post-commit"
    print_success "post-commit hook 已創建"
}

# Create commit-msg hook
create_commit_msg_hook() {
    print_info "創建 commit-msg hook..."
    
    cat > "$HOOKS_DIR/commit-msg" << 'EOF'
#!/bin/bash
# Commit message hook for MCP-Server-DEV
# Validates commit message format

# Read the commit message
COMMIT_MSG_FILE=$1
COMMIT_MSG=$(cat "$COMMIT_MSG_FILE")

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check commit message format
# Expected format: type: description
# Types: feat, fix, docs, style, refactor, test, chore
PATTERN="^(feat|fix|docs|style|refactor|test|chore)(\(.+\))?: .{1,100}$"

if ! echo "$COMMIT_MSG" | grep -qE "$PATTERN"; then
    echo -e "${RED}[COMMIT-MSG]${NC} 無效的提交訊息格式！"
    echo -e "${YELLOW}正確格式：type: description${NC}"
    echo -e "${YELLOW}類型：feat, fix, docs, style, refactor, test, chore${NC}"
    echo -e "${YELLOW}範例：feat: 新增專案結構生成工具${NC}"
    exit 1
fi

exit 0
EOF
    
    chmod +x "$HOOKS_DIR/commit-msg"
    print_success "commit-msg hook 已創建"
}

# Function to remove hooks
remove_hooks() {
    print_info "移除現有的 Git hooks..."
    
    for hook in pre-commit post-commit commit-msg; do
        if [[ -f "$HOOKS_DIR/$hook" ]]; then
            rm "$HOOKS_DIR/$hook"
            print_info "已移除 $hook"
        fi
    done
}

# Show usage
show_usage() {
    cat << EOF
使用方法: $0 [選項]

選項:
    install     安裝所有 Git hooks (預設)
    remove      移除所有 Git hooks
    help        顯示此幫助訊息

Git Hooks 功能：
    pre-commit  - 提交前自動更新專案結構文檔
    post-commit - 提交後更新 Git 歷史文檔
    commit-msg  - 驗證提交訊息格式

提交訊息格式：
    type: description
    
    類型:
    - feat: 新功能
    - fix: 修復錯誤
    - docs: 文檔更新
    - style: 程式碼格式調整
    - refactor: 重構
    - test: 測試相關
    - chore: 其他雜項

範例:
    git commit -m "feat: 新增專案導航工具"
    git commit -m "docs: 更新 README 文件"
    git commit -m "fix: 修復結構生成錯誤"
EOF
}

# Main function
main() {
    # Check if we're in a git repository
    if [[ ! -d "$PROJECT_ROOT/.git" ]]; then
        print_error "不在 Git 倉庫中！"
        exit 1
    fi
    
    # Create hooks directory if it doesn't exist
    mkdir -p "$HOOKS_DIR"
    
    # Parse arguments
    case "${1:-install}" in
        install)
            print_info "安裝 Git hooks..."
            create_pre_commit_hook
            create_post_commit_hook
            create_commit_msg_hook
            print_success "Git hooks 安裝完成！"
            echo ""
            echo "提示："
            echo "1. pre-commit hook 會在提交前自動更新專案結構"
            echo "2. post-commit hook 會在提交後更新 Git 歷史"
            echo "3. commit-msg hook 會驗證提交訊息格式"
            echo ""
            echo "使用 '$0 remove' 來移除 hooks"
            ;;
        remove)
            remove_hooks
            print_success "Git hooks 已移除"
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            print_error "未知選項: $1"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"