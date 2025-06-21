# OpenMemory MCP Server 部署指南

本指南詳細說明如何部署和配置 OpenMemory MCP Server。

## 目錄

1. [系統需求](#系統需求)
2. [快速安裝](#快速安裝)
3. [手動安裝](#手動安裝)
4. [配置說明](#配置說明)
5. [服務驗證](#服務驗證)
6. [客戶端連線](#客戶端連線)
7. [維護與更新](#維護與更新)

## 系統需求

### 硬體需求
- CPU: 2 核心或以上
- 記憶體: 4GB RAM（建議 8GB）
- 儲存空間: 10GB 可用空間
- 網路: 本地網路存取

### 軟體需求
- Docker 24.0 或更高版本
- Docker Compose 2.20 或更高版本
- Python 3.9+（用於客戶端工具）
- Node.js 18+（用於 UI 開發）
- Git

### API 金鑰需求
- OpenAI API Key（必需，用於向量嵌入）

## 快速安裝

### 方法一：使用官方安裝腳本

```bash
# 下載並執行安裝腳本
curl -sL https://raw.githubusercontent.com/mem0ai/mem0/main/openmemory/run.sh | bash
```

### 方法二：使用我們的配置

```bash
# 1. 克隆 OpenMemory 倉庫
git clone https://github.com/mem0ai/mem0.git
cd mem0/openmemory

# 2. 複製我們的配置
cp /path/to/MCP-Server-DEV/openmemory-mcp-config/.env.example .env
cp /path/to/MCP-Server-DEV/openmemory-mcp-config/docker-compose.yml .

# 3. 編輯環境變數
nano .env

# 4. 啟動服務
docker-compose up -d
```

## 手動安裝

### 步驟 1：準備環境

```bash
# 創建專案目錄
mkdir -p ~/openmemory-mcp
cd ~/openmemory-mcp

# 克隆倉庫
git clone https://github.com/mem0ai/mem0.git .
cd openmemory
```

### 步驟 2：配置環境變數

創建並編輯 `.env` 文件：

```bash
# API 目錄配置
cat > api/.env << EOF
OPENAI_API_KEY=your_actual_openai_api_key
USER_ID=$(whoami)
SECRET_KEY=$(openssl rand -hex 32)
EOF

# UI 目錄配置
cat > ui/.env << EOF
NEXT_PUBLIC_API_URL=http://localhost:8765
NEXT_PUBLIC_USER_ID=$(whoami)
EOF
```

### 步驟 3：構建並啟動服務

```bash
# 構建 Docker 映像
make build

# 啟動所有服務
make up

# 或者使用 docker-compose
docker-compose build
docker-compose up -d
```

## 配置說明

### 環境變數詳解

| 變數名稱 | 說明 | 預設值 | 必需 |
|---------|------|--------|------|
| OPENAI_API_KEY | OpenAI API 金鑰 | 無 | ✓ |
| USER_ID | 使用者識別碼 | 系統使用者名稱 | ✓ |
| SECRET_KEY | JWT 加密金鑰 | 隨機生成 | ✓ |
| API_HOST | API 服務主機 | 0.0.0.0 | ✗ |
| API_PORT | API 服務埠號 | 8765 | ✗ |
| LOG_LEVEL | 日誌等級 | INFO | ✗ |

### 服務埠號配置

| 服務 | 埠號 | 說明 |
|------|------|------|
| MCP API | 8765 | MCP 協議端點和 REST API |
| Qdrant | 6333 | 向量資料庫 |
| PostgreSQL | 5432 | 關聯式資料庫 |
| UI Dashboard | 3000 | Web 管理介面 |

## 服務驗證

### 1. 檢查容器狀態

```bash
# 查看所有容器狀態
docker-compose ps

# 預期輸出：所有服務都應該是 "Up" 狀態
```

### 2. 測試 API 健康狀態

```bash
# 檢查 API 服務
curl http://localhost:8765/health

# 檢查 API 文檔
open http://localhost:8765/docs
```

### 3. 測試記憶體功能

```bash
# 新增測試記憶體
curl -X POST http://localhost:8765/api/v1/memories \
  -H "Content-Type: application/json" \
  -d '{
    "content": "這是一個測試記憶",
    "user_id": "'$(whoami)'",
    "metadata": {"category": "test"}
  }'

# 搜尋記憶體
curl "http://localhost:8765/api/v1/memories/search?query=測試&user_id=$(whoami)"
```

### 4. 存取 UI 介面

```bash
# 開啟瀏覽器
open http://localhost:3000
```

## 客戶端連線

### Claude Desktop 配置

1. 使用 npx 工具安裝：
```bash
npx install-mcp i "http://localhost:8765/mcp/claude/sse/$(whoami)" --client claude
```

2. 手動配置：
編輯 Claude Desktop 配置文件：
```json
{
  "mcpServers": {
    "openmemory": {
      "transport": "sse",
      "url": "http://localhost:8765/mcp/sse/claude/your_username"
    }
  }
}
```

### Claude Code CLI 配置

```bash
# 新增 MCP 伺服器
claude mcp add openmemory \
  --transport sse \
  "http://localhost:8765/mcp/sse/claude/$(whoami)"
```

### Cursor 配置

```bash
# 使用 npx 安裝
npx install-mcp i "http://localhost:8765/mcp/cursor/sse/$(whoami)" --client cursor
```

## 維護與更新

### 備份資料

```bash
# 備份 Docker volumes
docker run --rm \
  -v openmemory_qdrant_storage:/source \
  -v $(pwd)/backup:/backup \
  alpine tar -czf /backup/qdrant_backup_$(date +%Y%m%d).tar.gz -C /source .

docker run --rm \
  -v openmemory_postgres_data:/source \
  -v $(pwd)/backup:/backup \
  alpine tar -czf /backup/postgres_backup_$(date +%Y%m%d).tar.gz -C /source .
```

### 更新服務

```bash
# 停止服務
docker-compose down

# 拉取最新映像
docker-compose pull

# 重建並啟動
docker-compose up -d --build
```

### 查看日誌

```bash
# 查看所有服務日誌
docker-compose logs -f

# 查看特定服務日誌
docker-compose logs -f openmemory-mcp
```

### 清理資源

```bash
# 停止並移除容器
docker-compose down

# 移除 volumes（警告：這會刪除所有資料）
docker-compose down -v

# 清理未使用的資源
docker system prune -af
```

## 安全建議

1. **API 金鑰管理**
   - 永不將實際的 API 金鑰提交到版本控制
   - 使用環境變數或金鑰管理服務
   - 定期輪換金鑰

2. **網路安全**
   - 預設僅允許本地連線
   - 如需遠端存取，使用 VPN 或 SSH 通道
   - 啟用 HTTPS/TLS 加密

3. **資料保護**
   - 定期備份重要資料
   - 加密敏感記憶體內容
   - 實施存取控制策略

4. **監控與審計**
   - 啟用詳細日誌記錄
   - 監控異常存取模式
   - 定期審查存取日誌

## 下一步

- 閱讀[故障排除指南](./troubleshooting.md)了解常見問題解決方案
- 查看[官方文檔](https://docs.mem0.ai/openmemory)了解進階功能
- 加入[社群討論](https://github.com/mem0ai/mem0/discussions)獲取支援