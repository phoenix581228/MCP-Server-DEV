# Zen MCP Server 部署指南

這個目錄包含部署 Zen MCP Server 所需的配置文件和指南。

## 部署步驟

### 1. 克隆 Zen MCP Server

```bash
git clone https://github.com/BeehiveInnovations/zen-mcp-server.git
cd zen-mcp-server
```

### 2. 配置環境變數

1. 複製環境變數範例：
   ```bash
   cp ../zen-mcp-config/.env.example .env
   ```

2. 編輯 `.env` 文件，填入您的 API 金鑰：
   ```bash
   nano .env
   ```

### 3. 執行設定腳本

```bash
./run-server.sh
```

這個腳本會：
- 設定 Python 虛擬環境
- 安裝所有依賴
- 配置 MCP 與 Claude
- 驗證 API 金鑰

### 4. 驗證安裝

檢查 MCP 配置：
```bash
./run-server.sh -c
```

查看日誌：
```bash
tail -f logs/mcp_server.log
```

## 配置選項

### API 提供者選擇

您可以選擇以下其中一種配置方式：

1. **原生 API（推薦）**
   - Gemini API
   - OpenAI API
   - X.AI API

2. **OpenRouter**
   - 透過單一 API 存取多個模型

3. **自訂端點**
   - Ollama
   - vLLM
   - LM Studio

### 重要設定

- `DEFAULT_MODEL`: 設為 `auto` 讓 Claude 自動選擇最佳模型
- `DEFAULT_THINKING_MODE_THINKDEEP`: 建議設為 `high` 以獲得最佳分析品質
- `LOG_LEVEL`: 開發時使用 `DEBUG`，生產環境使用 `INFO`

## 模型限制

如需限制可用模型（成本控制），可設定：
- `OPENAI_ALLOWED_MODELS`
- `GOOGLE_ALLOWED_MODELS`
- `XAI_ALLOWED_MODELS`

範例：
```env
OPENAI_ALLOWED_MODELS=o3-mini,o4-mini
GOOGLE_ALLOWED_MODELS=flash
```

## 故障排除

如遇到問題，請參考：
- [官方故障排除指南](https://github.com/BeehiveInnovations/zen-mcp-server/blob/main/docs/troubleshooting.md)
- 檢查日誌：`logs/mcp_server.log`
- 確認 API 金鑰正確且有效

## 更新

更新到最新版本：
```bash
cd zen-mcp-server
git pull
./run-server.sh
```

## 注意事項

- **永遠不要**將包含實際 API 金鑰的 `.env` 文件提交到版本控制
- 定期檢查並更新 API 金鑰
- 監控 API 使用量以避免意外費用