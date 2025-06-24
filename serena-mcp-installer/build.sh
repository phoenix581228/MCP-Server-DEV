#!/bin/bash

# 構建 Serena MCP 安裝包
# 版本: 1.0.0

set -e

# 顏色定義
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== 構建 Serena MCP 安裝包 ===${NC}"

# 1. 創建發布目錄
echo -e "${GREEN}[1/4] 準備發布檔案...${NC}"
RELEASE_DIR="serena-mcp-cli-installer"
rm -rf "$RELEASE_DIR"
mkdir -p "$RELEASE_DIR"

# 複製必要文件
cp install.sh "$RELEASE_DIR/"
cp uninstall.sh "$RELEASE_DIR/"
cp test-mcp.sh "$RELEASE_DIR/"
cp README.md "$RELEASE_DIR/"

# 設定執行權限
chmod +x "$RELEASE_DIR"/*.sh

# 2. 創建快速安裝腳本
echo -e "${GREEN}[2/4] 創建快速安裝腳本...${NC}"

cat > "$RELEASE_DIR/quick-install.sh" << 'EOF'
#!/bin/bash
# Serena MCP 快速安裝腳本

echo "開始快速安裝 Serena MCP Server..."

# 檢查基本需求
if ! command -v python3 &> /dev/null; then
    echo "錯誤：請先安裝 Python 3"
    exit 1
fi

if ! command -v claude &> /dev/null; then
    echo "錯誤：請先安裝 Claude Code CLI"
    echo "執行：npm install -g @anthropic-ai/claude-cli"
    exit 1
fi

# 安裝 Serena
echo "安裝 Serena Python 套件..."
pip3 install --upgrade serena-mcp

# 創建簡單包裝腳本
cat > "$HOME/.claude-code-serena.sh" << 'WRAPPER'
#!/bin/bash
export SERENA_PROJECT_ROOT="${SERENA_PROJECT_ROOT:-$HOME/projects}"
export SERENA_DEFAULT_MODE="${SERENA_DEFAULT_MODE:-editing}"
exec python3 -m serena "$@"
WRAPPER

chmod +x "$HOME/.claude-code-serena.sh"

# 註冊到 Claude
echo "註冊 Serena MCP 到 Claude Code CLI..."
claude mcp add serena "$HOME/.claude-code-serena.sh"

echo "✅ 安裝完成！"
echo ""
echo "使用範例："
echo "  claude '使用 Serena 讀取 README.md'"
echo ""
echo "如需完整安裝（含環境檢查），請執行 ./install.sh"
EOF

chmod +x "$RELEASE_DIR/quick-install.sh"

# 3. 創建專案初始化腳本
echo -e "${GREEN}[3/4] 創建專案初始化腳本...${NC}"

cat > "$RELEASE_DIR/init-project.sh" << 'EOF'
#!/bin/bash
# Serena 專案初始化腳本

echo "初始化 Serena 專案配置..."

# 創建 .serena 目錄結構
mkdir -p .serena/memories
mkdir -p .serena/cache

# 創建預設配置
cat > .serena/config.json << 'CONFIG'
{
  "project_name": "$(basename $(pwd))",
  "modes": ["editing", "interactive"],
  "language_server": "auto",
  "ignored_patterns": [
    "*.log",
    "*.pyc",
    "__pycache__/",
    "node_modules/",
    ".git/",
    "dist/",
    "build/",
    ".venv/",
    "venv/"
  ],
  "memory_settings": {
    "auto_save": true,
    "max_memories": 100
  },
  "shell_commands": {
    "allowed": [
      "git status",
      "git diff",
      "git log",
      "npm test",
      "npm run",
      "python -m pytest",
      "ls",
      "pwd",
      "which"
    ],
    "forbidden": [
      "rm -rf /",
      "sudo rm -rf",
      "format",
      "fdisk"
    ]
  }
}
CONFIG

# 創建初始記憶
cat > .serena/memories/project-setup.md << 'MEMORY'
# 專案設定記憶

## 專案資訊
- 專案名稱: $(basename $(pwd))
- 初始化時間: $(date)
- 工作目錄: $(pwd)

## 技術棧
（請更新此部分）
- 程式語言: 
- 框架: 
- 測試工具: 
- 建置工具: 

## 開發慣例
（請更新此部分）
- 程式碼風格: 
- 分支策略: 
- 提交訊息格式: 

## 常用命令
（請更新此部分）
- 開發: 
- 測試: 
- 建置: 
- 部署: 
MEMORY

echo "✅ Serena 專案初始化完成！"
echo ""
echo "已創建："
echo "  • .serena/config.json - 專案配置"
echo "  • .serena/memories/ - 記憶儲存目錄"
echo "  • .serena/memories/project-setup.md - 初始記憶"
echo ""
echo "下一步："
echo "1. 編輯 .serena/config.json 自訂配置"
echo "2. 更新 .serena/memories/project-setup.md"
echo "3. 在 Claude 中使用: claude '使用 Serena 啟動專案'"
EOF

chmod +x "$RELEASE_DIR/init-project.sh"

# 4. 創建配置範本
echo -e "${GREEN}[4/4] 創建配置範本...${NC}"

mkdir -p "$RELEASE_DIR/templates"

# TypeScript/React 專案範本
cat > "$RELEASE_DIR/templates/typescript-react.json" << 'EOF'
{
  "project_name": "typescript-react-app",
  "modes": ["editing", "interactive"],
  "language_server": "typescript",
  "ignored_patterns": [
    "*.log",
    "node_modules/",
    ".git/",
    "dist/",
    "build/",
    "coverage/",
    ".next/",
    ".cache/",
    "*.test.ts",
    "*.test.tsx"
  ],
  "file_associations": {
    "*.tsx": "typescriptreact",
    "*.ts": "typescript",
    "*.jsx": "javascriptreact",
    "*.js": "javascript"
  },
  "memory_settings": {
    "auto_save": true,
    "max_memories": 100
  }
}
EOF

# Python/Django 專案範本
cat > "$RELEASE_DIR/templates/python-django.json" << 'EOF'
{
  "project_name": "django-app",
  "modes": ["editing", "interactive"],
  "language_server": "pylsp",
  "ignored_patterns": [
    "*.pyc",
    "__pycache__/",
    ".git/",
    "venv/",
    ".venv/",
    "*.sqlite3",
    "media/",
    "staticfiles/",
    ".coverage",
    "htmlcov/"
  ],
  "file_associations": {
    "*.py": "python",
    "*.pyi": "python"
  },
  "memory_settings": {
    "auto_save": true,
    "max_memories": 100
  }
}
EOF

# 創建壓縮包
TAR_NAME="serena-mcp-cli-installer-$(date +%Y%m%d).tar.gz"
tar -czf "$TAR_NAME" "$RELEASE_DIR"

echo ""
echo -e "${GREEN}✅ 構建完成！${NC}"
echo ""
echo "生成的檔案："
echo "  - $TAR_NAME (完整安裝包)"
echo "  - $RELEASE_DIR/ (解壓後目錄)"
echo ""
echo "安裝方式："
echo ""
echo "方法一：完整安裝（推薦）"
echo "  1. 解壓: tar -xzf $TAR_NAME"
echo "  2. 進入目錄: cd $RELEASE_DIR"
echo "  3. 執行安裝: ./install.sh"
echo ""
echo "方法二：快速安裝"
echo "  1. 解壓: tar -xzf $TAR_NAME"
echo "  2. 進入目錄: cd $RELEASE_DIR"
echo "  3. 執行: ./quick-install.sh"
echo ""
echo "專案初始化："
echo "  在專案目錄執行: ./init-project.sh"
echo ""
echo "功能特色："
echo "  • 完整的檔案和符號操作"
echo "  • 專案記憶系統"
echo "  • 多語言服務器支援"
echo "  • 智能程式碼編輯"
echo "  • 適用於 Claude Code CLI"