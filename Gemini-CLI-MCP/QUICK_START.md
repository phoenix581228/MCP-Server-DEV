# Gemini MCP Server 快速開始指南

## 🚀 3 分鐘快速部署

### 步驟 1: 設置 API 金鑰

```bash
# 方法 1: 環境變數
export GOOGLE_API_KEY="your_gemini_api_key"

# 方法 2: 修改 .env 檔案
echo "GOOGLE_API_KEY=your_api_key_here" > .env
```

### 步驟 2: 安裝依賴

```bash
pip install -r requirements.txt
```

### 步驟 3: 測試功能

```bash
python tests/test_full_functionality.py
```

如果看到 "🎊 所有測試都通過了！Gemini MCP Server 準備就緒！"，表示安裝成功！

## 🔗 與 Claude Code 整合

### 方法 1: 本地 Python 運行

在您的專案中建立或編輯 `.mcp.json`：

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

### 方法 2: Docker 運行 (推薦)

```bash
# 建置 Docker 映像
docker build -t gemini-mcp-server .

# 在 .mcp.json 中配置
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

## 🛠️ 在 Claude Code 中使用

啟動 Claude Code 後，執行 `/mcp` 命令檢查連接狀態。

### 基本對話

```javascript
gemini_chat({
  "message": "請解釋 React 的核心概念",
  "temperature": 0.7
})
```

### 程式碼分析

```javascript
gemini_analyze_code({
  "code": "function fibonacci(n) { return n <= 1 ? n : fibonacci(n-1) + fibonacci(n-2); }",
  "language": "javascript",
  "analysis_type": "optimize"
})
```

### 文本生成

```javascript
gemini_generate({
  "prompt": "寫一份 API 文檔的範本",
  "max_output_tokens": 1000
})
```

### 影片分析

```javascript
gemini_video_analysis({
  "video_path": "/path/to/your/video.mp4",
  "question": "這段影片在做什麼？",
  "analysis_type": "summary"
})
```

## 🔧 常見問題

### Q: API 金鑰錯誤
A: 確認在 [Google AI Studio](https://makersuite.google.com/app/apikey) 取得正確的 API 金鑰

### Q: 連接失敗
A: 檢查 Python 環境和依賴安裝：`python tests/test_connection.py`

### Q: Docker 權限問題
A: 確保 Docker daemon 運行且用戶有適當權限

## 📊 功能矩陣

| 功能 | 狀態 | 說明 |
|------|------|------|
| 基本對話 | ✅ | 支援系統指令和溫度控制 |
| 文本生成 | ✅ | 可控制長度和創意度 |
| 程式碼分析 | ✅ | 支援多種分析類型 |
| 圖像分析 | ✅ | 需要本地圖片檔案 |
| 影片分析 | ✅ | 支援 mp4, mov, avi, mkv, webm 格式 |
| Docker 部署 | ✅ | 完整容器化方案 |
| 錯誤處理 | ✅ | 完善的異常處理機制 |

## 🎯 進階配置

### 切換模型

```bash
# 針對一般用途 (對話、程式碼分析、文本生成)
export GEMINI_MODEL="gemini-1.5-flash"

# 針對複雜任務 (包含高品質影片分析)
export GEMINI_MODEL="gemini-1.5-pro"

# 針對最新功能支援 (推薦用於影片分析)
export GEMINI_MODEL="gemini-2.0-flash-001"
```

### 調整日誌級別

```bash
export LOG_LEVEL="DEBUG"
```

### 使用 Vertex AI

```bash
export GOOGLE_GENAI_USE_VERTEXAI=true
export GOOGLE_CLOUD_PROJECT="your-project"
```

---

**🎉 恭喜！** 您已成功部署 Gemini MCP Server。現在可以在 Claude Code 中享受 Gemini AI 的強大功能了！