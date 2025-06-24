# OpenMemory MCP Server 一鍵安裝包

這是為 Claude Code CLI 設計的 OpenMemory MCP Server 一鍵安裝包。OpenMemory 提供持久化記憶管理功能，讓 AI 助手能夠記住跨對話的重要資訊。

## 版本資訊
- OpenMemory MCP 版本: 最新版本
- 支援平台: macOS, Linux (需要 Docker)
- 適用於: Claude Code CLI（非 Claude Desktop）
- Docker 映像: 包含完整的 OpenMemory 堆疊

## 系統架構

OpenMemory 使用以下技術堆疊：
- **MCP Server**: Node.js 基礎的 MCP 協議實現
- **API Server**: FastAPI (Python) 提供 REST API
- **向量資料庫**: Qdrant 用於語義搜尋
- **關聯式資料庫**: PostgreSQL 儲存結構化資料
- **Web UI**: Next.js 提供管理介面

## 安裝需求

1. **Docker 環境**
   - Docker Engine 20.10 或更高版本
   - Docker Compose v2.0 或更高版本
   - 至少 4GB 可用記憶體

2. **Claude Code CLI**
   - 已安裝 Claude Code CLI
   - 版本 1.0.0 或更高

3. **網路端口**
   - 8765: API Server
   - 6333: Qdrant Vector DB
   - 5432: PostgreSQL
   - 3000: Web UI (可選)

## 快速安裝

### 方法一：完整安裝（推薦）
```bash
# 1. 解壓安裝包
tar -xzf openmemory-mcp-cli-installer-*.tar.gz

# 2. 進入目錄
cd openmemory-mcp-cli-installer

# 3. 執行安裝腳本
./install.sh
```

### 方法二：Docker 快速部署
```bash
# 直接使用 docker-compose
cd docker && docker-compose up -d
```

## 功能介紹

### 核心功能

1. **記憶管理**
   - `add_memories` - 新增記憶
   - `search_memory` - 搜尋記憶
   - `list_memories` - 列出所有記憶
   - `delete_all_memories` - 刪除所有記憶

2. **智能特性**
   - 自動向量化儲存
   - 語義相似度搜尋
   - 跨對話持久化
   - 上下文感知檢索

3. **管理介面**
   - Web UI 視覺化管理
   - 記憶分類和標籤
   - 使用統計分析
   - 匯出/匯入功能

## Docker 配置

### 預設服務配置
```yaml
services:
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: openmemory
      POSTGRES_USER: openmemory
      POSTGRES_PASSWORD: openmemory123
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  qdrant:
    image: qdrant/qdrant:latest
    ports:
      - "6333:6333"
    volumes:
      - qdrant_data:/qdrant/storage

  api:
    image: openmemory/api:latest
    ports:
      - "8765:8765"
    environment:
      DATABASE_URL: postgresql://openmemory:openmemory123@postgres:5432/openmemory
      QDRANT_URL: http://qdrant:6333
    depends_on:
      - postgres
      - qdrant

  web:
    image: openmemory/web:latest
    ports:
      - "3000:3000"
    environment:
      NEXT_PUBLIC_API_URL: http://localhost:8765
    depends_on:
      - api
```

### 資料持久化
所有資料都儲存在 Docker volumes 中：
- `postgres_data`: PostgreSQL 資料
- `qdrant_data`: 向量資料庫
- 備份位置: `./backups/`

## 環境變數設定

### 必要設定
```bash
# API 設定
OPENMEMORY_API_URL=http://localhost:8765
OPENMEMORY_API_KEY=your-secure-api-key

# 資料庫設定（可選）
POSTGRES_USER=openmemory
POSTGRES_PASSWORD=openmemory123
POSTGRES_DB=openmemory

# Qdrant 設定（可選）
QDRANT_HOST=localhost
QDRANT_PORT=6333
```

## 使用範例

安裝完成後，您可以在 Claude Code CLI 中使用 OpenMemory：

```bash
# 新增記憶
claude "請記住這個專案使用 React 18 和 TypeScript 5"

# 搜尋記憶
claude "我之前告訴過你關於專案技術棧的資訊嗎？"

# 列出記憶
claude "顯示所有儲存的記憶"
```

## Web UI 使用

1. **訪問介面**
   ```
   http://localhost:3000
   ```

2. **功能區域**
   - Dashboard: 記憶統計總覽
   - Memories: 瀏覽和管理記憶
   - Search: 進階搜尋功能
   - Settings: 系統設定

3. **API 金鑰管理**
   - 在 Settings 中生成 API 金鑰
   - 用於外部應用程式整合

## 維護操作

### 備份資料
```bash
./backup.sh
```

### 還原資料
```bash
./restore.sh backup-20250124.tar.gz
```

### 更新服務
```bash
./update.sh
```

### 查看日誌
```bash
# 所有服務
docker-compose logs -f

# 特定服務
docker-compose logs -f api
```

## 故障排除

### 常見問題

1. **端口衝突**
   ```bash
   # 檢查端口使用
   ./check-ports.sh
   
   # 修改端口（編輯 .env 檔案）
   API_PORT=8766
   QDRANT_PORT=6334
   ```

2. **記憶體不足**
   - 增加 Docker 記憶體限制
   - 減少同時運行的服務
   - 使用 `--scale` 調整服務數量

3. **連接錯誤**
   - 確認所有服務都在運行
   - 檢查防火牆設定
   - 驗證環境變數

### 除錯命令

```bash
# 健康檢查
./health-check.sh

# 重置服務
./reset-services.sh

# 清理資料（謹慎使用）
./clean-data.sh
```

## 安全建議

1. **生產環境部署**
   - 更改預設密碼
   - 使用強 API 金鑰
   - 啟用 HTTPS
   - 設定防火牆規則

2. **資料保護**
   - 定期備份
   - 加密敏感資料
   - 限制網路存取
   - 監控異常活動

## 解除安裝

完整移除 OpenMemory：

```bash
./uninstall.sh
```

這將會：
- 停止並移除所有容器
- 刪除 Docker 映像
- 移除 MCP 註冊
- 保留資料卷（可選刪除）

## 授權

MIT License

## 更新日誌

### v1.0.0 (2025-01-24)
- 初始版本
- Docker 化部署
- 完整的記憶管理功能
- Web UI 整合
- 自動備份功能