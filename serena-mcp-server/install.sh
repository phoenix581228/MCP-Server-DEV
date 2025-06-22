#!/bin/bash
# Serena MCP Server 安裝腳本

set -e

echo "==================================="
echo "Serena MCP Server 安裝程式"
echo "==================================="

# 檢查作業系統
OS=$(uname -s)
echo "偵測到作業系統: $OS"

# 檢查 Python
echo ""
echo "檢查 Python 版本..."
if command -v python3 >/dev/null 2>&1; then
    PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
    echo "✓ Python $PYTHON_VERSION 已安裝"
else
    echo "✗ Python 3 未安裝"
    echo "請先安裝 Python 3.9 或更高版本"
    exit 1
fi

# 安裝 uv
echo ""
echo "檢查 uv 套件管理器..."
if command -v uv >/dev/null 2>&1; then
    echo "✓ uv 已安裝"
else
    echo "安裝 uv..."
    if [ "$OS" = "Darwin" ] || [ "$OS" = "Linux" ]; then
        curl -LsSf https://astral.sh/uv/install.sh | sh
    else
        echo "Windows 用戶請執行："
        echo "powershell -ExecutionPolicy ByPass -c \"irm https://astral.sh/uv/install.ps1 | iex\""
        exit 1
    fi
    
    # 添加到 PATH
    export PATH="$HOME/.local/bin:$PATH"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc 2>/dev/null || true
fi

# 檢查 Language Servers
echo ""
echo "檢查 Language Server 支援..."

# Python LSP
if command -v pylsp >/dev/null 2>&1; then
    echo "✓ Python Language Server 已安裝"
else
    echo "○ Python Language Server 未安裝"
    echo "  建議安裝: pip install python-lsp-server"
fi

# TypeScript LSP
if command -v typescript-language-server >/dev/null 2>&1; then
    echo "✓ TypeScript Language Server 已安裝"
else
    echo "○ TypeScript Language Server 未安裝"
    echo "  建議安裝: npm install -g typescript-language-server"
fi

# 創建配置目錄
echo ""
echo "創建配置目錄..."
mkdir -p ~/.serena/contexts
mkdir -p ~/.serena/modes
mkdir -p ~/.serena/cache
mkdir -p ~/.serena/memory

# 複製配置範本
echo ""
echo "安裝配置範本..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/serena_config.template.yml" ]; then
    cp "$SCRIPT_DIR/serena_config.template.yml" ~/.serena/serena_config.template.yml
    echo "✓ 已安裝全域配置範本到 ~/.serena/serena_config.template.yml"
fi

if [ -f "$SCRIPT_DIR/project.template.yml" ]; then
    cp "$SCRIPT_DIR/project.template.yml" ~/.serena/project.template.yml
    echo "✓ 已安裝專案配置範本到 ~/.serena/project.template.yml"
fi

# 創建包裝腳本
echo ""
echo "創建執行包裝腳本..."
cat > ~/.serena/run-serena.sh << 'EOF'
#!/bin/bash
# Serena MCP Server 執行包裝腳本

# 設定預設值
SERENA_PROJECT=${1:-$(pwd)}
SERENA_CONTEXT=${SERENA_CONTEXT:-ide-assistant}
SERENA_MODE=${SERENA_MODE:-}
SERENA_LOG_LEVEL=${SERENA_LOG_LEVEL:-INFO}

# 檢查專案配置
if [ ! -f "$SERENA_PROJECT/.serena/project.yml" ]; then
    echo "提示：專案配置不存在於 $SERENA_PROJECT/.serena/project.yml" >&2
    echo "      將使用預設設定執行" >&2
fi

# 構建參數
ARGS=(
    "--from" "git+https://github.com/oraios/serena"
    "serena-mcp-server"
    "--context" "$SERENA_CONTEXT"
    "--project" "$SERENA_PROJECT"
)

# 添加模式（如果指定）
if [ -n "$SERENA_MODE" ]; then
    ARGS+=("--mode" "$SERENA_MODE")
fi

# 執行 Serena
exec uvx "${ARGS[@]}"
EOF

chmod +x ~/.serena/run-serena.sh
echo "✓ 已創建執行腳本 ~/.serena/run-serena.sh"

# 測試安裝
echo ""
echo "測試 Serena 安裝..."
if uvx --from git+https://github.com/oraios/serena serena-mcp-server --help >/dev/null 2>&1; then
    echo "✓ Serena 可以正常執行"
else
    echo "✗ Serena 執行失敗，請檢查錯誤訊息"
    exit 1
fi

# 顯示下一步指示
echo ""
echo "==================================="
echo "安裝完成！"
echo "==================================="
echo ""
echo "下一步："
echo ""
echo "1. 註冊到 Claude Code CLI："
echo "   claude mcp add serena -- ~/.serena/run-serena.sh \$(pwd)"
echo ""
echo "2. 為您的專案創建配置："
echo "   mkdir -p .serena"
echo "   cp ~/.serena/project.template.yml .serena/project.yml"
echo "   # 編輯 .serena/project.yml 以符合您的專案"
echo ""
echo "3. 可選：索引您的專案以提升效能："
echo "   uvx --from git+https://github.com/oraios/serena index-project"
echo ""
echo "更多資訊請參考文檔：$SCRIPT_DIR/README.md"