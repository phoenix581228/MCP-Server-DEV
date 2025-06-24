#!/bin/bash

# 構建 Perplexity MCP 安裝包
# 版本: 1.0.0

set -e

# 顏色定義
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== 構建 Perplexity MCP 安裝包 ===${NC}"

# 1. 構建 Python 套件
echo -e "${GREEN}[1/3] 構建 Python 套件...${NC}"
cd perplexity-mcp-custom
python3 -m pip install --upgrade build
python3 -m build
cd ..

# 2. 創建發布目錄
echo -e "${GREEN}[2/3] 準備發布檔案...${NC}"
RELEASE_DIR="perplexity-mcp-cli-installer"
rm -rf "$RELEASE_DIR"
mkdir -p "$RELEASE_DIR"

# 複製必要文件
cp install.sh "$RELEASE_DIR/"
cp uninstall.sh "$RELEASE_DIR/"
cp README.md "$RELEASE_DIR/"

# 複製 Python 套件
mkdir -p "$RELEASE_DIR/packages"
cp perplexity-mcp-custom/dist/*.whl "$RELEASE_DIR/packages/" 2>/dev/null || true
cp perplexity-mcp-custom/dist/*.tar.gz "$RELEASE_DIR/packages/" 2>/dev/null || true

# 3. 創建離線安裝版本
echo -e "${GREEN}[3/3] 創建安裝包...${NC}"

# 創建離線安裝腳本
cat > "$RELEASE_DIR/install-offline.sh" << 'EOF'
#!/bin/bash
# 離線安裝腳本
set -e

echo "開始離線安裝 Perplexity MCP Server..."

# 安裝本地 Python 套件
if [ -d "packages" ]; then
    pip install packages/*.whl || pip install packages/*.tar.gz
fi

# 執行主安裝腳本
./install.sh

echo "離線安裝完成！"
EOF

chmod +x "$RELEASE_DIR/install-offline.sh"

# 創建壓縮包
TAR_NAME="perplexity-mcp-cli-installer-$(date +%Y%m%d).tar.gz"
tar -czf "$TAR_NAME" "$RELEASE_DIR"

echo ""
echo -e "${GREEN}✅ 構建完成！${NC}"
echo ""
echo "生成的檔案："
echo "  - $TAR_NAME (完整安裝包)"
echo "  - $RELEASE_DIR/ (解壓後目錄)"
echo ""
echo "使用方法："
echo "  1. 解壓: tar -xzf $TAR_NAME"
echo "  2. 進入目錄: cd $RELEASE_DIR"
echo "  3. 執行安裝: ./install.sh"
echo ""
echo "離線安裝："
echo "  使用 ./install-offline.sh 進行離線安裝"