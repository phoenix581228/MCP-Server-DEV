# Gemini MCP Server 安裝指南

## 系統需求

- Python 3.11+
- Docker (可選，用於容器化部署)
- Google API 金鑰或 Google Cloud 專案存取權限

## 環境變數設定

### 使用 Google AI Studio API (推薦)

```bash
export GOOGLE_API_KEY="your_gemini_api_key"
export GEMINI_MODEL="gemini-1.5-flash"  # 可選，預設值
```

### 使用 Vertex AI

```bash
export GOOGLE_GENAI_USE_VERTEXAI=true
export GOOGLE_CLOUD_PROJECT="your_project_id"
export GOOGLE_CLOUD_LOCATION="us-central1"

# 設置 Google Cloud 認證
gcloud auth application-default login
```

## 安裝方式

### 方式一：Docker 部署 (推薦)

1. **建置映像檔**
```bash
cd Gemini-CLI-MCP
docker build -t gemini-mcp-server .
```

2. **使用 Docker Compose 運行**
```bash
# 設置環境變數
echo "GOOGLE_API_KEY=your_api_key_here" > .env

# 啟動服務
docker-compose up -d
```

3. **檢查狀態**
```bash
docker-compose ps
docker-compose logs gemini-mcp-server
```

### 方式二：本地 Python 安裝

1. **安裝依賴**
```bash
pip install -r requirements.txt
```

2. **運行伺服器**
```bash
python src/gemini_mcp_server.py
```

3. **測試連接**
```bash
python tests/test_connection.py
```

## MCP 客戶端配置

### Claude Code 整合

在專案的 `.mcp.json` 中添加：

```json
{
  "mcpServers": {
    "gemini-mcp": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm",
        "-e", "GOOGLE_API_KEY",
        "gemini-mcp-server:latest"
      ],
      "env": {
        "GOOGLE_API_KEY": "$GOOGLE_API_KEY"
      }
    }
  }
}
```

### 使用 npx 安裝的版本

```json
{
  "mcpServers": {
    "gemini-mcp": {
      "command": "python",
      "args": ["/path/to/Gemini-CLI-MCP/src/gemini_mcp_server.py"],
      "env": {
        "GOOGLE_API_KEY": "$GOOGLE_API_KEY"
      }
    }
  }
}
```

## 驗證安裝

1. **測試 MCP 連接**
```bash
python tests/test_connection.py
```

2. **在 Claude Code 中測試**
```bash
# 在 Claude Code 中執行
/mcp
```

應該看到 `gemini-mcp` 伺服器已連接並列出可用工具。

## 故障排除

### 常見問題

1. **API 金鑰錯誤**
   - 檢查 `GOOGLE_API_KEY` 是否正確設置
   - 確認 API 金鑰有 Gemini API 存取權限

2. **Docker 權限問題**
   - 確保 Docker daemon 正在運行
   - 檢查用戶是否在 docker 群組中

3. **模組導入錯誤**
   - 確認所有依賴已正確安裝
   - 檢查 Python 版本是否符合需求

4. **連接逾時**
   - 檢查網路連接
   - 確認防火牆設定

### 日誌檢查

```bash
# Docker 日誌
docker-compose logs -f gemini-mcp-server

# 本地運行日誌
export LOG_LEVEL=DEBUG
python src/gemini_mcp_server.py
```

## 進階配置

### 自定義模型

```bash
export GEMINI_MODEL="gemini-1.5-pro"
```

### 效能調優

```bash
# 設置資源限制
export MCP_MAX_TOKENS=4096
export MCP_TIMEOUT=30
```

## 安全注意事項

1. **API 金鑰保護**
   - 不要將 API 金鑰提交到版本控制
   - 使用環境變數或安全的秘密管理

2. **網路安全**
   - 在生產環境中限制容器網路存取
   - 使用適當的防火牆規則

3. **資源限制**
   - 設置適當的記憶體和 CPU 限制
   - 監控 API 使用量以避免超額費用