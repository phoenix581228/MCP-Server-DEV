#!/bin/bash

# 構建 OpenMemory MCP 安裝包
# 版本: 1.0.0

set -e

# 顏色定義
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}=== 構建 OpenMemory MCP 安裝包 ===${NC}"

# 1. 創建發布目錄
echo -e "${GREEN}[1/5] 準備發布檔案...${NC}"
RELEASE_DIR="openmemory-mcp-cli-installer"
rm -rf "$RELEASE_DIR"
mkdir -p "$RELEASE_DIR"

# 複製必要文件
cp install.sh "$RELEASE_DIR/"
cp uninstall.sh "$RELEASE_DIR/"
cp test-mcp.sh "$RELEASE_DIR/"
cp README.md "$RELEASE_DIR/"

# 設定執行權限
chmod +x "$RELEASE_DIR"/*.sh

# 2. 準備 Docker 映像
echo -e "${GREEN}[2/5] 準備 Docker 映像構建檔案...${NC}"

# 創建 docker 目錄結構
mkdir -p "$RELEASE_DIR/docker-images/api"
mkdir -p "$RELEASE_DIR/docker-images/web"
mkdir -p "$RELEASE_DIR/docker-images/mcp"

# API Dockerfile 和相關檔案
cat > "$RELEASE_DIR/docker-images/api/Dockerfile" << 'EOF'
FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y \
    gcc \
    postgresql-client \
    curl \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

RUN useradd -m -u 1000 openmemory && chown -R openmemory:openmemory /app
USER openmemory

EXPOSE 8765

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8765"]
EOF

# Web Dockerfile
cat > "$RELEASE_DIR/docker-images/web/Dockerfile" << 'EOF'
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .
RUN npm run build

RUN adduser -D -u 1000 openmemory && chown -R openmemory:openmemory /app
USER openmemory

EXPOSE 3000

CMD ["npm", "start"]
EOF

# MCP Bridge Dockerfile
cat > "$RELEASE_DIR/docker-images/mcp/Dockerfile" << 'EOF'
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

RUN adduser -D -u 1000 openmemory && chown -R openmemory:openmemory /app
USER openmemory

CMD ["node", "index.js"]
EOF

# 3. 創建快速安裝腳本
echo -e "${GREEN}[3/5] 創建快速安裝腳本...${NC}"

cat > "$RELEASE_DIR/quick-install.sh" << 'EOF'
#!/bin/bash
# OpenMemory MCP 快速安裝腳本

echo "開始快速安裝 OpenMemory MCP Server..."

# 檢查 Docker
if ! command -v docker &> /dev/null; then
    echo "錯誤：請先安裝 Docker"
    exit 1
fi

# 檢查 Claude CLI
if ! command -v claude &> /dev/null; then
    echo "錯誤：請先安裝 Claude Code CLI"
    exit 1
fi

# 執行完整安裝
./install.sh

echo "✅ 快速安裝完成！"
EOF

chmod +x "$RELEASE_DIR/quick-install.sh"

# 4. 創建 Docker 構建腳本
echo -e "${GREEN}[4/5] 創建 Docker 映像構建腳本...${NC}"

cat > "$RELEASE_DIR/build-images.sh" << 'EOF'
#!/bin/bash
# 構建 OpenMemory Docker 映像

echo "構建 Docker 映像..."

# 檢查是否在線
if curl -s --head https://hub.docker.com &>/dev/null; then
    echo "在線模式：嘗試拉取官方映像..."
    
    # 嘗試拉取官方映像
    docker pull openmemory/api:latest 2>/dev/null || BUILD_API=true
    docker pull openmemory/web:latest 2>/dev/null || BUILD_WEB=true
    docker pull openmemory/mcp:latest 2>/dev/null || BUILD_MCP=true
else
    echo "離線模式：本地構建所有映像..."
    BUILD_API=true
    BUILD_WEB=true
    BUILD_MCP=true
fi

# 構建需要的映像
if [ "$BUILD_API" = true ]; then
    echo "構建 API 映像..."
    docker build -t openmemory/api:latest ./docker/api
fi

if [ "$BUILD_WEB" = true ]; then
    echo "構建 Web 映像..."
    docker build -t openmemory/web:latest ./docker/web
fi

if [ "$BUILD_MCP" = true ]; then
    echo "構建 MCP 映像..."
    docker build -t openmemory/mcp:latest ./docker/mcp
fi

echo "✅ Docker 映像準備完成"
EOF

chmod +x "$RELEASE_DIR/build-images.sh"

# 5. 創建離線映像導出腳本
echo -e "${GREEN}[5/5] 創建映像導出/導入腳本...${NC}"

cat > "$RELEASE_DIR/export-images.sh" << 'EOF'
#!/bin/bash
# 導出 Docker 映像供離線使用

echo "導出 Docker 映像..."

mkdir -p docker-images-export

# 導出基礎映像
docker save postgres:15-alpine -o docker-images-export/postgres.tar
docker save qdrant/qdrant:latest -o docker-images-export/qdrant.tar

# 導出 OpenMemory 映像（如果存在）
if docker images | grep -q "openmemory/api"; then
    docker save openmemory/api:latest -o docker-images-export/openmemory-api.tar
fi

if docker images | grep -q "openmemory/web"; then
    docker save openmemory/web:latest -o docker-images-export/openmemory-web.tar
fi

if docker images | grep -q "openmemory/mcp"; then
    docker save openmemory/mcp:latest -o docker-images-export/openmemory-mcp.tar
fi

# 創建導入腳本
cat > docker-images-export/import-images.sh << 'IMPORT'
#!/bin/bash
echo "導入 Docker 映像..."

for image in *.tar; do
    if [ -f "$image" ]; then
        echo "導入 $image..."
        docker load -i "$image"
    fi
done

echo "✅ 映像導入完成"
IMPORT

chmod +x docker-images-export/import-images.sh

# 打包
tar -czf docker-images-export.tar.gz docker-images-export/

echo "✅ Docker 映像已導出到 docker-images-export.tar.gz"
echo "在目標機器上解壓並執行 import-images.sh 來導入映像"
EOF

chmod +x "$RELEASE_DIR/export-images.sh"

# 創建額外的管理腳本
cat > "$RELEASE_DIR/manage-openmemory.sh" << 'EOF'
#!/bin/bash
# OpenMemory 管理腳本

case "$1" in
    start)
        echo "啟動 OpenMemory..."
        cd docker && docker-compose up -d
        ;;
    stop)
        echo "停止 OpenMemory..."
        cd docker && docker-compose down
        ;;
    restart)
        echo "重啟 OpenMemory..."
        cd docker && docker-compose restart
        ;;
    logs)
        cd docker && docker-compose logs -f
        ;;
    status)
        cd docker && docker-compose ps
        ;;
    backup)
        ./backup.sh
        ;;
    *)
        echo "用法: $0 {start|stop|restart|logs|status|backup}"
        exit 1
        ;;
esac
EOF

chmod +x "$RELEASE_DIR/manage-openmemory.sh"

# 創建壓縮包
TAR_NAME="openmemory-mcp-cli-installer-$(date +%Y%m%d).tar.gz"
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
echo "  執行: ./quick-install.sh"
echo ""
echo "離線部署："
echo "  1. 在有網路的機器上執行 ./export-images.sh"
echo "  2. 將 docker-images-export.tar.gz 複製到目標機器"
echo "  3. 解壓並執行 import-images.sh"
echo ""
echo "功能特色："
echo "  • 完整的 Docker 化部署"
echo "  • 持久化記憶管理"
echo "  • Web UI 管理介面"
echo "  • 自動備份功能"
echo "  • 支援離線安裝"
echo ""
echo -e "${YELLOW}注意事項：${NC}"
echo "  • 需要 Docker 和 Docker Compose"
echo "  • 占用端口：8765, 6333, 5432, 3000"
echo "  • 建議至少 4GB 記憶體"