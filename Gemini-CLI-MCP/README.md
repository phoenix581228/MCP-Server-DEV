# Gemini CLI MCP Server

這是一個將 Google Gemini AI 功能封裝為 MCP (Model Context Protocol) Server 的專案，讓 Claude Code 等 MCP 客戶端可以透過標準化協議使用 Gemini 的 AI 能力。

## 🌟 功能特色

- **🤖 MCP Server**: 提供 Gemini API 功能給其他 MCP 客戶端使用
- **💬 多樣化 AI 工具**: 支援對話、文本生成、程式碼分析、圖像分析等功能
- **🐳 Docker 化部署**: 完整的容器化部署方案
- **🛠️ Gemini CLI 開發環境**: 包含完整的 Gemini CLI 開發工具
- **📚 完整文檔**: 詳細的安裝、使用和故障排除指南

## 🔧 核心 MCP 工具

| 工具名稱 | 功能描述 | 主要用途 |
|---------|---------|---------|
| `gemini_chat` | 基本對話功能 | 自然語言問答、技術諮詢 |
| `gemini_generate` | 文本生成 | 文檔撰寫、創意內容生成 |
| `gemini_analyze_code` | 程式碼分析 | 代碼審查、優化建議、錯誤診斷 |
| `gemini_vision` | 圖像分析 | 圖片內容描述、技術圖表分析 |
| `gemini_video_analysis` | 影片分析 | 影片內容理解、動作識別、場景分析 |
| `gemini_video_optimizer` | 影片優化 | 自動優化影片格式以符合模型需求 |

## 📁 目錄結構

```
Gemini-CLI-MCP/
├── src/                          # MCP Server 原始碼
│   └── gemini_mcp_server.py      # 主要伺服器實作
├── docker/                       # Docker 配置檔案
│   ├── docker-entrypoint.sh      # 容器入口腳本
│   └── healthcheck.sh            # 健康檢查腳本
├── docs/                         # 完整文檔
│   ├── INSTALLATION.md           # 安裝指南
│   └── USAGE.md                  # 使用指南
├── tests/                        # 測試檔案
│   └── test_connection.py        # 連接測試
├── gemini-cli-dev/              # Gemini CLI 開發環境
├── Dockerfile                   # Docker 映像定義
├── docker-compose.yml          # Docker Compose 配置
├── requirements.txt             # Python 依賴
└── README.md                    # 本檔案
```

## 🚀 快速開始

### 1. 環境變數設定

**使用 Google AI Studio API (推薦):**
```bash
export GOOGLE_API_KEY="your_gemini_api_key"
export GEMINI_MODEL="gemini-1.5-flash"  # 可選，預設值
```

**使用 Vertex AI:**
```bash
export GOOGLE_GENAI_USE_VERTEXAI=true
export GOOGLE_CLOUD_PROJECT="your_project_id"
export GOOGLE_CLOUD_LOCATION="us-central1"
gcloud auth application-default login
```

### 2. Docker 部署 (推薦)

```bash
# 複製環境變數範本
echo "GOOGLE_API_KEY=your_api_key_here" > .env

# 建置並啟動服務
docker-compose up -d

# 檢查狀態
docker-compose ps
docker-compose logs gemini-mcp-server
```

### 3. 本地 Python 運行

```bash
# 安裝依賴
pip install -r requirements.txt

# 運行伺服器
python src/gemini_mcp_server.py

# 測試連接
python tests/test_connection.py
```

## 🔗 MCP 客戶端整合

### Claude Code 配置

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

### 使用範例

在 Claude Code 中：

```javascript
// 基本對話
gemini_chat({
  "message": "請解釋什麼是 MCP 協議？",
  "temperature": 0.7
})

// 程式碼分析
gemini_analyze_code({
  "code": "def factorial(n): return 1 if n <= 1 else n * factorial(n-1)",
  "language": "python",
  "analysis_type": "review"
})

// 文本生成
gemini_generate({
  "prompt": "寫一份 API 文檔範例",
  "max_output_tokens": 1000
})

// 圖像分析
gemini_vision({
  "image_path": "/path/to/image.jpg",
  "question": "這張圖片在顯示什麼？"
})

// 影片分析 (新功能!)
gemini_video_analysis({
  "video_path": "/path/to/video.mp4",
  "question": "這段影片的主要內容是什麼？",
  "analysis_type": "summary",
  "auto_optimize": true,
  "target_resolution": "standard"
})

// 影片優化分析
gemini_video_optimizer({
  "video_path": "/path/to/video.mp4",
  "target_model": "gemini-2.0-flash-001",
  "analyze_only": true
})
```

### 影片分析功能詳情

**支援格式**: mp4, mov, avi, mkv, webm  
**分析類型**:
- `summary`: 影片摘要和概述
- `action`: 動作和活動分析  
- `object`: 物體和場景識別
- `text`: 影片中文字內容識別

**支援的模型**:
- `gemini-2.0-flash-001` - 最新且快速的影片分析模型
- `gemini-1.5-pro` - 強大的影片理解能力  
- `gemini-1.5-flash` - 輕量快速的影片分析

**注意事項**:
- 影片檔案會暫時上傳到 Google 伺服器進行處理
- 大型影片檔案可能需要較長的處理時間
- 處理完成後會自動清理上傳的檔案
- 系統會自動選擇最適合的模型進行影片分析

## 📖 完整文檔

- **[安裝指南](docs/INSTALLATION.md)** - 詳細的安裝和設定說明
- **[使用指南](docs/USAGE.md)** - 工具使用方法和最佳實踐

## 🧪 測試驗證

```bash
# 執行連接測試
python tests/test_connection.py

# 在 Claude Code 中驗證
# 執行 /mcp 命令查看連接狀態
```

## 🔧 Gemini CLI 開發環境

專案包含完整的 Gemini CLI 開發環境：

```bash
# 進入開發環境目錄
cd gemini-cli-dev

# 使用 Gemini CLI
gemini --version
gemini -p "Hello, Gemini!"
```

## ⚡ 進階功能

### 自定義模型

```bash
export GEMINI_MODEL="gemini-1.5-pro"
docker-compose restart
```

### 效能監控

```bash
# 查看即時日誌
docker-compose logs -f gemini-mcp-server

# 監控資源使用
docker stats gemini-mcp-server
```

### 安全配置

```bash
# 生產環境建議設定
export MCP_MAX_TOKENS=4096
export MCP_TIMEOUT=30
export LOG_LEVEL=INFO
```

## 🛠️ 故障排除

### 常見問題

1. **API 金鑰錯誤**: 檢查 `GOOGLE_API_KEY` 設定
2. **連接逾時**: 確認網路連接和防火牆設定
3. **權限問題**: 確保 Docker 權限正確設定

### 日誌檢查

```bash
# Docker 環境
docker-compose logs -f gemini-mcp-server

# 本地環境
export LOG_LEVEL=DEBUG
python src/gemini_mcp_server.py
```

## 🤝 技術支援

- 遵循全域開發規範中的標準修復流程
- 使用 Sequential Thinking 進行問題分析
- 透過 Zen MCP 進行深度技術驗證
- 利用 TaskMaster 進行任務管理

## 🔐 安全注意事項

- 永不將 API 金鑰提交到版本控制
- 使用環境變數管理敏感資訊
- 在生產環境中設置適當的資源限制
- 定期監控 API 使用量避免超額費用

## 📝 授權

MIT License

---

**注意**: 此專案需要有效的 Google API 金鑰或 Google Cloud 專案存取權限才能正常運作。請參考 [安裝指南](docs/INSTALLATION.md) 了解詳細的設定方法。