#!/bin/bash

# 構建 Zen MCP 安裝包
# 版本: 1.0.0

set -e

# 顏色定義
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== 構建 Zen MCP 安裝包 ===${NC}"

# 1. 創建發布目錄
echo -e "${GREEN}[1/3] 準備發布檔案...${NC}"
RELEASE_DIR="zen-mcp-cli-installer"
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
echo -e "${GREEN}[2/3] 創建快速安裝腳本...${NC}"

cat > "$RELEASE_DIR/quick-install.sh" << 'EOF'
#!/bin/bash
# Zen MCP 快速安裝腳本

echo "開始快速安裝 Zen MCP Server..."

# 檢查 Node.js
if ! command -v node &> /dev/null; then
    echo "錯誤：請先安裝 Node.js"
    exit 1
fi

# 檢查 Claude CLI
if ! command -v claude &> /dev/null; then
    echo "錯誤：請先安裝 Claude Code CLI"
    echo "執行：npm install -g @anthropic-ai/claude-cli"
    exit 1
fi

# 直接註冊 Zen MCP
echo "註冊 Zen MCP 到 Claude Code CLI..."
claude mcp add zen "npx -y @gptscript-ai/zen-mcp@latest"

echo "✅ 安裝完成！"
echo ""
echo "使用範例："
echo "  claude '使用 Zen 分析這個程式碼'"
echo ""
echo "如需完整安裝（含環境檢查），請執行 ./install.sh"
EOF

chmod +x "$RELEASE_DIR/quick-install.sh"

# 3. 創建配置範本
echo -e "${GREEN}[3/3] 創建配置範本...${NC}"

cat > "$RELEASE_DIR/zen-config-template.sh" << 'EOF'
#!/bin/bash
# Zen MCP 配置範本
# 複製此檔案到 ~/.claude-code-zen.sh 並修改

# 預設模型設定
export ZEN_DEFAULT_MODEL="pro"  # 可選: flash, pro, o3, o3-mini, grok

# 思考模式深度
export ZEN_THINKING_MODE="high"  # 可選: minimal, low, medium, high, max

# API 金鑰（如果需要）
# export ANTHROPIC_API_KEY="your-anthropic-key"
# export OPENAI_API_KEY="your-openai-key"

# 網路搜尋功能
export ZEN_USE_WEBSEARCH="true"  # 啟用網路搜尋增強功能

# 溫度設定（0.0-1.0）
export ZEN_TEMPERATURE="0.7"

# 執行 Zen MCP
exec npx -y @gptscript-ai/zen-mcp@latest "$@"
EOF

# 創建壓縮包
TAR_NAME="zen-mcp-cli-installer-$(date +%Y%m%d).tar.gz"
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
echo "功能特色："
echo "  • 自動檢測虛擬環境"
echo "  • 支援多種 AI 模型"
echo "  • 包含完整工具集"
echo "  • 適用於 Claude Code CLI"