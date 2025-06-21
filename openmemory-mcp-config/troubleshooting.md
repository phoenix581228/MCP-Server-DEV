# OpenMemory MCP Server 故障排除指南

本指南幫助您解決部署和使用 OpenMemory MCP Server 時可能遇到的常見問題。

## 目錄

1. [安裝問題](#安裝問題)
2. [連線問題](#連線問題)
3. [資料庫問題](#資料庫問題)
4. [記憶體問題](#記憶體問題)
5. [效能問題](#效能問題)
6. [Docker 相關問題](#docker-相關問題)
7. [日誌和偵錯](#日誌和偵錯)

## 安裝問題

### 問題：Docker Compose 版本過舊

**症狀**：
```
ERROR: Version in "./docker-compose.yml" is unsupported.
```

**解決方案**：
```bash
# 更新 Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

### 問題：無法拉取 Docker 映像

**症狀**：
```
ERROR: pull access denied for mem0/openmemory-mcp
```

**解決方案**：
```bash
# 手動構建映像
cd openmemory
docker-compose build --no-cache
```

### 問題：埠號已被佔用

**症狀**：
```
ERROR: bind: address already in use
```

**解決方案**：
```bash
# 檢查埠號使用情況
sudo lsof -i :8765
sudo lsof -i :6333
sudo lsof -i :5432
sudo lsof -i :3000

# 停止佔用的服務或更改埠號配置
```

## 連線問題

### 問題：MCP 客戶端無法連線

**症狀**：
- Claude/Cursor 顯示連線錯誤
- SSE 連線超時

**解決方案**：

1. 檢查服務狀態：
```bash
docker-compose ps
curl http://localhost:8765/health
```

2. 確認 SSE 端點：
```bash
# 測試 SSE 連線
curl -N http://localhost:8765/mcp/sse/test/$(whoami)
```

3. 檢查防火牆設定：
```bash
# macOS
sudo pfctl -s rules | grep 8765

# Linux
sudo iptables -L | grep 8765
```

### 問題：CORS 錯誤

**症狀**：
```
Access to XMLHttpRequest has been blocked by CORS policy
```

**解決方案**：

在 `.env` 中更新 CORS 設定：
```env
CORS_ORIGINS=["http://localhost:3000", "http://localhost:8765"]
CORS_ALLOW_CREDENTIALS=true
```

## 資料庫問題

### 問題：Qdrant 連線失敗

**症狀**：
```
ConnectionError: Failed to connect to Qdrant at mem0_store:6333
```

**解決方案**：

1. 確認 Qdrant 服務正在運行：
```bash
docker-compose logs mem0_store
docker exec -it openmemory_qdrant curl http://localhost:6333/health
```

2. 重啟 Qdrant：
```bash
docker-compose restart mem0_store
```

### 問題：PostgreSQL 初始化失敗

**症狀**：
```
FATAL: database "openmemory" does not exist
```

**解決方案**：

1. 手動創建資料庫：
```bash
docker exec -it openmemory_postgres psql -U openmemory_user -c "CREATE DATABASE openmemory;"
```

2. 重置資料庫：
```bash
docker-compose down -v
docker-compose up -d
```

### 問題：資料遺失（Volume 掛載問題）

**症狀**：
- 重啟後所有記憶體消失
- 資料庫為空

**解決方案**：

確認 volume 正確掛載：
```yaml
volumes:
  - qdrant_storage:/qdrant/storage  # 注意路徑
  # 不要使用 ./mem0_storage:/qdrant/storage
```

## 記憶體問題

### 問題：記憶體無法儲存

**症狀**：
```
Error: Failed to add memory
```

**解決方案**：

1. 檢查 OpenAI API 金鑰：
```bash
# 驗證 API 金鑰
curl https://api.openai.com/v1/models \
  -H "Authorization: Bearer $OPENAI_API_KEY"
```

2. 檢查記憶體格式：
```json
{
  "content": "記憶體內容",
  "user_id": "username",
  "metadata": {
    "category": "work"
  }
}
```

### 問題：搜尋結果為空

**症狀**：
- 搜尋總是返回空結果
- 向量索引未建立

**解決方案**：

1. 重建向量索引：
```bash
docker exec -it openmemory_api python -c "
from mem0 import Memory
m = Memory()
m.rebuild_index()
"
```

2. 檢查嵌入生成：
```bash
docker-compose logs openmemory-mcp | grep embedding
```

## 效能問題

### 問題：回應速度緩慢

**症狀**：
- API 回應時間超過 5 秒
- UI 載入緩慢

**解決方案**：

1. 增加 Docker 資源限制：
```yaml
services:
  openmemory-mcp:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 4G
```

2. 優化資料庫查詢：
```bash
# 檢查慢查詢
docker exec -it openmemory_postgres psql -U openmemory_user -c "
SELECT query, mean_exec_time 
FROM pg_stat_statements 
ORDER BY mean_exec_time DESC 
LIMIT 10;"
```

### 問題：記憶體使用過高

**症狀**：
- Docker 容器佔用大量記憶體
- 系統變慢

**解決方案**：

1. 限制記憶體使用：
```env
MAX_MEMORY_SIZE_MB=50
MEMORY_RETENTION_DAYS=30
```

2. 清理舊記憶體：
```bash
curl -X DELETE "http://localhost:8765/api/v1/memories/cleanup?days=30"
```

## Docker 相關問題

### 問題：容器自動重啟

**症狀**：
```
STATUS: Restarting (1) 5 seconds ago
```

**解決方案**：

查看容器日誌：
```bash
docker-compose logs --tail=100 openmemory-mcp
```

常見原因：
- 環境變數缺失
- 依賴服務未就緒
- 記憶體不足

### 問題：無法存取容器

**症狀**：
```
Error response from daemon: Container is not running
```

**解決方案**：

1. 檢查容器狀態：
```bash
docker ps -a | grep openmemory
```

2. 啟動停止的容器：
```bash
docker-compose start
```

## 日誌和偵錯

### 啟用詳細日誌

在 `.env` 中設定：
```env
LOG_LEVEL=DEBUG
DEBUG=true
```

### 查看各服務日誌

```bash
# API 服務日誌
docker-compose logs -f openmemory-mcp

# 資料庫日誌
docker-compose logs -f postgres
docker-compose logs -f mem0_store

# UI 日誌
docker-compose logs -f openmemory-ui
```

### 進入容器偵錯

```bash
# 進入 API 容器
docker exec -it openmemory_api /bin/bash

# Python 互動式偵錯
docker exec -it openmemory_api python
>>> from main import app
>>> # 進行偵錯
```

### 測試 MCP 協議

```bash
# 初始化連線
echo '{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0.0"}},"id":1}' | \
curl -X POST http://localhost:8765/mcp/messages -H "Content-Type: application/json" -d @-

# 列出可用工具
echo '{"jsonrpc":"2.0","method":"tools/list","id":2}' | \
curl -X POST http://localhost:8765/mcp/messages -H "Content-Type: application/json" -d @-
```

## 常用診斷命令

### 系統資源檢查
```bash
# Docker 資源使用
docker stats

# 磁碟空間
df -h
docker system df
```

### 網路診斷
```bash
# 檢查網路連通性
docker network ls
docker network inspect openmemory_network

# 測試服務間連線
docker exec -it openmemory_api ping mem0_store
```

### 資料庫診斷
```bash
# PostgreSQL 連線測試
docker exec -it openmemory_postgres pg_isready

# Qdrant 集合檢查
curl http://localhost:6333/collections
```

## 獲取協助

如果以上方案無法解決您的問題：

1. 收集診斷資訊：
```bash
docker-compose logs > diagnostic_logs.txt
docker-compose ps >> diagnostic_logs.txt
docker version >> diagnostic_logs.txt
```

2. 查看[官方 GitHub Issues](https://github.com/mem0ai/mem0/issues)

3. 在[討論區](https://github.com/mem0ai/mem0/discussions)發問

4. 提供以下資訊：
   - 作業系統和版本
   - Docker 和 Docker Compose 版本
   - 完整的錯誤訊息
   - 相關的日誌輸出