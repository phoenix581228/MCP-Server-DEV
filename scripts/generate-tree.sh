#!/bin/bash

# Generate project tree structure for MCP-Server-DEV
# This script creates a visual representation of the project structure
# using git ls-tree and formats it for documentation

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
OUTPUT_FILE="PROJECT_STRUCTURE.md"
TEMP_FILE=".tree_temp.txt"

# Directories to exclude from tree
EXCLUDE_DIRS=(
    "node_modules"
    "__pycache__"
    ".git"
    "dist"
    "build"
    ".egg-info"
    "venv"
    ".venv"
    ".zen_venv"
    "logs"
    "coverage"
    ".pytest_cache"
)

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

# Function to check if a path should be excluded
should_exclude() {
    local path="$1"
    for exclude in "${EXCLUDE_DIRS[@]}"; do
        if [[ "$path" == *"/$exclude/"* ]] || [[ "$path" == *"/$exclude" ]]; then
            return 0
        fi
    done
    return 1
}

# Function to generate tree using git ls-tree
generate_git_tree() {
    print_info "Generating project tree using git ls-tree..."
    
    # Get all files tracked by git
    git ls-tree -r --name-only HEAD | while read -r file; do
        # Skip excluded paths
        if should_exclude "$file"; then
            continue
        fi
        
        # Count the depth (number of slashes)
        depth=$(echo "$file" | tr -cd '/' | wc -c)
        
        # Create indentation
        indent=""
        for ((i=0; i<depth; i++)); do
            indent="${indent}  "
        done
        
        # Get just the filename
        filename=$(basename "$file")
        
        # Check if it's a directory by looking ahead
        dirname=$(dirname "$file")
        if [[ "$dirname" != "." ]]; then
            # Print directory structure
            echo "${indent}├── ${filename}"
        else
            echo "├── ${filename}"
        fi
    done | sort -u > "$TEMP_FILE"
}

# Function to generate enhanced tree with file counts
generate_enhanced_tree() {
    print_info "Generating enhanced project structure..."
    
    cat > "$OUTPUT_FILE" << 'EOF'
# MCP Server Development - 專案結構

此文件展示 MCP Server Development 專案的完整目錄結構。

## 專案概覽

```
MCP-Server-DEV/
├── README.md                    # 專案主文檔
├── MILESTONES.md               # 專案里程碑記錄
├── PROJECT_STRUCTURE.md        # 本文件
├── scripts/                    # 工具腳本
│   └── generate-tree.sh       # 生成專案結構的腳本
├── perplexity-mcp-custom/     # Perplexity MCP Server 實作
└── zen-mcp-server/            # Zen MCP Server (多模型 AI 協作)
```

## 詳細結構

### 根目錄
```
EOF

    # Add basic structure
    tree -L 2 -I 'node_modules|__pycache__|.git|dist|build|*.egg-info|venv|.venv|.zen_venv|logs|coverage|.pytest_cache' . >> "$OUTPUT_FILE" 2>/dev/null || {
        print_warning "tree command not found, using basic listing"
        ls -la | grep -E '^d' | awk '{print "├── " $9}' | grep -v '^\.' >> "$OUTPUT_FILE"
        ls -la | grep -E '^-' | awk '{print "├── " $9}' >> "$OUTPUT_FILE"
    }

    echo '```' >> "$OUTPUT_FILE"
    
    # Add detailed structure for each subproject
    for subproject in "perplexity-mcp-custom" "zen-mcp-server"; do
        if [[ -d "$subproject" ]]; then
            cat >> "$OUTPUT_FILE" << EOF

### $subproject 詳細結構

\`\`\`
EOF
            cd "$subproject"
            tree -L 3 -I 'node_modules|__pycache__|.git|dist|build|*.egg-info|venv|.venv|.zen_venv|logs|coverage|.pytest_cache' . >> "../$OUTPUT_FILE" 2>/dev/null || {
                find . -type f -o -type d | grep -v -E '(node_modules|__pycache__|\.git|dist|build|\.egg-info|venv|\.venv|\.zen_venv|logs|coverage|\.pytest_cache)' | sort >> "../$OUTPUT_FILE"
            }
            cd ..
            echo '```' >> "$OUTPUT_FILE"
            
            # Add file statistics
            echo "" >> "$OUTPUT_FILE"
            echo "#### 統計資訊" >> "$OUTPUT_FILE"
            
            # Count files by type
            ts_files=$(find "$subproject" -name "*.ts" -not -path "*/node_modules/*" 2>/dev/null | wc -l)
            js_files=$(find "$subproject" -name "*.js" -not -path "*/node_modules/*" 2>/dev/null | wc -l)
            py_files=$(find "$subproject" -name "*.py" -not -path "*/__pycache__/*" -not -path "*/venv/*" 2>/dev/null | wc -l)
            md_files=$(find "$subproject" -name "*.md" 2>/dev/null | wc -l)
            
            echo "- TypeScript 檔案: $ts_files" >> "$OUTPUT_FILE"
            echo "- JavaScript 檔案: $js_files" >> "$OUTPUT_FILE"
            echo "- Python 檔案: $py_files" >> "$OUTPUT_FILE"
            echo "- Markdown 文檔: $md_files" >> "$OUTPUT_FILE"
        fi
    done
    
    # Add footer
    cat >> "$OUTPUT_FILE" << 'EOF'

## 關鍵目錄說明

### perplexity-mcp-custom/
Perplexity AI 的 MCP Server 實作，提供：
- 完整的 Perplexity API 整合
- JSON Schema 2020-12 相容性
- 豐富的測試腳本和文檔

### zen-mcp-server/
多模型 AI 協作的 MCP Server，特點：
- 支援多個 AI 提供者（Gemini、OpenAI、Ollama 等）
- 豐富的開發工具（debug、analyze、refactor 等）
- 完整的測試框架和模擬器

## 維護說明

此文件由 `scripts/generate-tree.sh` 自動生成。要更新結構：

```bash
./scripts/generate-tree.sh
```

最後更新時間：$(date '+%Y-%m-%d %H:%M:%S')
EOF
    
    # Clean up
    rm -f "$TEMP_FILE"
}

# Function to create a visual graph of project dependencies
generate_dependency_graph() {
    print_info "Analyzing project dependencies..."
    
    cat >> "$OUTPUT_FILE" << 'EOF'

## 專案依賴關係

### perplexity-mcp-custom 依賴
- @modelcontextprotocol/sdk (MCP 核心)
- dotenv (環境變數管理)
- zod (資料驗證)

### zen-mcp-server 依賴
主要 Python 套件：
- Python 3.9+ 
- MCP SDK
- 各種 AI 提供者的客戶端庫

詳細依賴請查看各專案的 package.json 或 requirements.txt。
EOF
}

# Main execution
main() {
    print_info "Starting project structure generation..."
    
    # Check if we're in the right directory
    if [[ ! -f "README.md" ]] || [[ ! -d "perplexity-mcp-custom" ]]; then
        print_warning "Please run this script from the MCP-Server-DEV root directory"
        exit 1
    fi
    
    # Generate the structure
    generate_enhanced_tree
    generate_dependency_graph
    
    print_success "Project structure generated successfully!"
    print_info "Output saved to: $OUTPUT_FILE"
    
    # Show a preview
    echo ""
    echo "Preview of generated structure:"
    echo "==============================="
    head -n 20 "$OUTPUT_FILE"
    echo "..."
    echo ""
    print_info "Full structure saved to $OUTPUT_FILE"
}

# Run main function
main