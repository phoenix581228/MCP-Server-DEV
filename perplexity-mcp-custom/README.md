# Perplexity MCP Custom Server

這是一個完全符合 MCP (Model Context Protocol) 標準的 Perplexity 搜尋伺服器實作。解決了現有 Perplexity MCP 實作的 JSON Schema 相容性問題，並提供更豐富的功能。

## ✨ 特點

- ✅ **完全符合 JSON Schema draft 2020-12 標準** - 不會出現 schema 驗證錯誤
- ✅ **支援 Claude Code CLI 全域註冊** - 可使用 `-g` 參數安全註冊
- ✅ **內建 LRU 快取機制** - 提升效能，減少 API 呼叫
- ✅ **完整的錯誤處理** - 友善的錯誤訊息
- ✅ **TypeScript 實作** - 型別安全，易於維護
- ✅ **支援所有 Perplexity 模型** - sonar、sonar-pro、sonar-deep-research
- ✅ **深度研究工具** - 專門的深度研究功能
- 🆕 **支援 HTTP/SSE Transport** - 原生支援 WebUI，無需 MCP Bridge
- 🆕 **雙模式運行** - stdio (桌面) 和 HTTP (WebUI) 模式

## 🚀 快速開始

### 安裝

#### 方法一：npm 安裝（推薦）

```bash
npm install -g @tzuchi/perplexity-mcp-custom
```

#### 方法二：從原始碼安裝

```bash
git clone https://github.com/tzuchi/perplexity-mcp-custom
cd perplexity-mcp-custom
npm install
npm run build
npm link
```

### 設定

#### 1. 設定環境變數

建立 `.env` 檔案或設定環境變數：

```bash
# 必需
PERPLEXITY_API_KEY=your_api_key_here

# 選用
PERPLEXITY_BASE_URL=https://api.perplexity.ai
PERPLEXITY_MODEL=sonar-pro
DEBUG=true
```

#### 2. 註冊到 Claude Code CLI

##### 專案範圍註冊（建議先測試）
```bash
claude mcp add perplexity "npx @tzuchi/perplexity-mcp-custom"
```

##### 全域註冊（經測試可安全使用）
```bash
claude mcp add perplexity "npx @tzuchi/perplexity-mcp-custom" -g
```

## 🌐 HTTP/SSE Transport 模式

### 啟動 HTTP 模式

```bash
# 預設 port 3000
perplexity-mcp --http

# 指定 port
perplexity-mcp --http --port 8080

# 使用環境變數
MCP_TRANSPORT=http MCP_PORT=8080 perplexity-mcp
```

### HTTP 端點

- `POST /mcp` - JSON-RPC 請求
- `GET /mcp` - SSE 串流連接  
- `DELETE /mcp` - 終止 session
- `GET /health` - 健康檢查

### 安全配置

```bash
# CORS 設定
PERPLEXITY_CORS_ORIGINS=http://localhost:5173,https://myapp.com

# Bearer Token 認證
PERPLEXITY_BEARER_TOKEN=your-secret-token

# Rate Limiting (每分鐘最大請求數)
PERPLEXITY_RATE_LIMIT=60
```

詳細說明請參考 [HTTP Transport 文件](docs/HTTP_TRANSPORT.md)。

## 📖 使用方式

### 可用工具

#### 1. `perplexity_search_web`
執行網路搜尋，獲取最新資訊。

**參數：**
- `query` (必需): 搜尋查詢字串
- `model` (選用): 使用的模型 (sonar/sonar-pro/sonar-deep-research)
- `options` (選用):
  - `search_domain`: 限定搜尋的網域
  - `search_recency`: 搜尋時間範圍 (day/week/month/year)
  - `return_citations`: 是否返回引用來源（預設：true）
  - `return_images`: 是否返回圖片（預設：false）
  - `return_related_questions`: 是否返回相關問題（預設：false）

#### 2. `perplexity_deep_research`
對特定主題進行深度研究。

**參數：**
- `topic` (必需): 研究主題
- `depth` (選用): 研究深度 (quick/standard/comprehensive)
- `focus_areas` (選用): 重點研究領域陣列

### 使用範例

#### 在 Claude Code 中使用

```bash
# 基本搜尋
claude "搜尋最新的 MCP 協議規範"

# 指定工具
claude "搜尋最新的 MCP 協議規範" --allowedTools mcp__perplexity__perplexity_search_web

# 深度研究
claude "深度研究 Model Context Protocol 的架構和實作" --allowedTools mcp__perplexity__perplexity_deep_research
```

#### 程式化使用

```javascript
// 搜尋範例
const searchResult = await callTool('perplexity_search_web', {
  query: 'Model Context Protocol 最新規範',
  model: 'sonar-pro',
  options: {
    search_recency: 'month',
    return_citations: true
  }
});

// 深度研究範例
const researchResult = await callTool('perplexity_deep_research', {
  topic: 'AI 安全性研究',
  depth: 'comprehensive',
  focus_areas: ['對齊問題', '安全部署', '風險評估']
});
```

## 🛠️ 開發

### 建構專案
```bash
npm run build
```

### 執行測試
```bash
npm test
```

### 開發模式
```bash
npm run dev
```

### 程式碼品質
```bash
npm run lint
npm run format
npm run typecheck
```

## 📁 專案結構

```
src/
├── server/       # MCP Server 實作
├── api/          # Perplexity API 客戶端
├── tools/        # 工具定義和 Schema
├── types/        # TypeScript 型別定義
└── utils/        # 工具函式（快取等）
```

## 🧪 測試

專案包含完整的測試套件：

```bash
# 執行所有測試
npm test

# 測試覆蓋率
npm run test:coverage

# 監視模式
npm run test:watch
```

## 🔧 故障排除

### 常見問題

1. **API Key 錯誤**
   ```
   Error: PERPLEXITY_API_KEY is required
   ```
   解決：確保已設定 PERPLEXITY_API_KEY 環境變數

2. **JSON Schema 錯誤**
   此版本已完全解決 schema 相容性問題，不應出現相關錯誤

3. **連線問題**
   確保網路連線正常，可存取 api.perplexity.ai

### Debug 模式

設定 `DEBUG=true` 可查看詳細的請求和回應記錄：

```bash
DEBUG=true claude mcp list
```

## 🤝 貢獻

歡迎提交 Issue 和 Pull Request！

### 開發流程

1. Fork 專案
2. 建立功能分支 (`git checkout -b feature/amazing-feature`)
3. 提交變更 (`git commit -m 'Add amazing feature'`)
4. 推送分支 (`git push origin feature/amazing-feature`)
5. 開啟 Pull Request

## 📄 授權

MIT License - 詳見 [LICENSE](LICENSE) 檔案

## 🙏 致謝

- [Model Context Protocol](https://modelcontextprotocol.io/) - 協議規範
- [Perplexity AI](https://www.perplexity.ai/) - API 服務
- 慈濟開發團隊 - 專案支援

## 📋 V2.0 開發計劃

我們正在開發 Perplexity MCP Custom Server 2.0，將帶來重大架構改進：

### 主要變更
- **原生 Streamable HTTP 支援** - 移除 HTTP Bridge 需求
- **簡化架構** - 單一進程，更高效能
- **完全符合最新 MCP 規範** - 支援 2025-06-18 協議版本

### 相關文件
- [開發路線圖](docs/ROADMAP_V2.md) - 詳細的開發計劃和時程
- [架構設計](docs/ARCHITECTURE_V2.md) - V2.0 的技術架構
- [技術規格](docs/TECHNICAL_SPEC_V2.md) - 實作細節和程式碼範例

### 遷移指南
V2.0 將提供完整的向後兼容性和漸進式遷移路徑。詳細資訊請參考上述文件。

---

🤖 使用 Claude Code 開發