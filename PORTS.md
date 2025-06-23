# MCP Server 專案 Port 使用指南

本文件記錄 MCP Server 專案所使用的所有端口，以避免端口衝突並確保服務正常運行。

## 🔒 MCP Server 保留端口總覽

以下端口已被 MCP Server 專案保留，請勿在其他專案中使用：

### OpenMemory MCP Server
| 服務 | Port | 說明 |
|------|------|------|
| MCP API Server | **8765** | FastAPI 後端，提供 MCP 協議端點和 REST API |
| Qdrant Vector DB | **6333** | 向量資料庫，用於語義搜尋 |
| PostgreSQL | **5432** | 關聯式資料庫，儲存記憶體元資料 |
| Web UI Dashboard | **3000** | Next.js 前端管理介面 |

### Perplexity MCP Custom Server
| 服務 | Port | 說明 |
|------|------|------|
| HTTP/SSE Mode | **8080** | 預設 HTTP 模式端口（避免與 OpenMemory 衝突） |
| Alternative Port | **3000** | 可選端口（但建議避免，因為會與 OpenMemory UI 衝突） |

### 其他 MCP 相關服務
| 服務 | Port | 說明 |
|------|------|------|
| Xinference API | **9997** | Local LLM 整合服務 |
| LM Studio API | **1234** | LM Studio 模型服務 |
| Ollama API | **11434** | Ollama 本地模型服務 |

## 🛡️ Port 衝突檢查

### 快速檢查所有 MCP 端口

```bash
# 檢查所有 MCP 保留端口
MCP_PORTS=(8765 6333 5432 3000 8080 9997 1234 11434)
echo "=== Checking MCP Server Reserved Ports ==="
for port in "${MCP_PORTS[@]}"; do
    if lsof -ti:$port >/dev/null 2>&1; then
        echo "⚠️  Port $port is in use!"
        lsof -ti:$port | xargs ps -p | tail -n 1
    else
        echo "✅ Port $port is available"
    fi
done
```

### 檢查特定服務端口

```bash
# OpenMemory 端口檢查
check_openmemory_ports() {
    local ports=(8765 6333 5432 3000)
    echo "=== OpenMemory Port Check ==="
    for port in "${ports[@]}"; do
        lsof -ti:$port >/dev/null 2>&1 && echo "Port $port: USED" || echo "Port $port: FREE"
    done
}

# Perplexity 端口檢查
check_perplexity_port() {
    lsof -ti:8080 >/dev/null 2>&1 && echo "Port 8080: USED" || echo "Port 8080: FREE"
}
```

## 🔧 Port 衝突解決方案

### 1. 識別占用程序

```bash
# 查看特定端口的占用程序
lsof -i :PORT_NUMBER

# 查看程序詳細資訊
ps -p $(lsof -ti:PORT_NUMBER)
```

### 2. 釋放端口

```bash
# 終止占用端口的程序
kill $(lsof -ti:PORT_NUMBER)

# 強制終止（謹慎使用）
kill -9 $(lsof -ti:PORT_NUMBER)
```

### 3. 更改服務端口

如果 MCP 保留端口被其他重要服務占用，建議：

1. **其他專案**：更改為非保留端口
   - 推薦使用：3001, 4000, 4200, 5000, 5173, 8000
   - 避免使用：MCP 保留端口列表中的任何端口

2. **Perplexity HTTP 模式**：可配置其他端口
   ```bash
   perplexity-mcp --http --port 8081
   ```

## 📋 開發最佳實踐

### 1. 啟動服務前檢查

```bash
# 在啟動任何 MCP 服務前執行
./check_mcp_ports.sh
```

### 2. 專案端口分配建議

| 專案類型 | 建議端口範圍 |
|----------|-------------|
| React/Vue 開發 | 3001, 4000-4999 |
| Node.js API | 5001-5999 |
| Python 服務 | 8001-8079, 8081-8999 |
| 測試服務 | 9000-9996, 9998-9999 |

### 3. Docker 網路隔離

使用 Docker 時，建議使用專用網路來隔離 MCP 服務：

```yaml
# docker-compose.yml
networks:
  mcp-network:
    name: mcp-network
    driver: bridge
```

## 🚨 重要提醒

1. **OpenMemory 優先權**：由於 OpenMemory 使用多個端口且為 Docker 服務，具有最高優先權
2. **端口 3000 衝突**：這是最常見的衝突端口，建議其他專案避免使用
3. **PostgreSQL 5432**：系統級服務端口，請確保不與系統 PostgreSQL 衝突

## 📝 更新記錄

- 2025-06-22：初始版本，記錄所有 MCP Server 使用的端口
- 端口保護已整合到全域 CLAUDE.md 配置中

---

**注意**：此文件是 MCP Server 專案的官方端口使用指南，請在開發任何相關專案時參考此文件。