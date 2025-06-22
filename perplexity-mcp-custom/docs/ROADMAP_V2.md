# Perplexity MCP Custom Server 2.0 開發路線圖

## 概述

本文件描述了 Perplexity MCP Custom Server 從目前的 1.x 版本（基於 stdio + HTTP Bridge）升級到 2.0 版本（原生 Streamable HTTP）的開發計劃。

## 背景

### MCP 協議演進

Model Context Protocol (MCP) 在 2025-06-18 版本中正式支援 **Streamable HTTP Transport**：

```
Protocol Revision: 2025-06-18

Streamable HTTP Transport:
  - Server Operation: Independent process, handles multiple client connections
  - Methods: Uses HTTP POST and GET requests  
  - Streaming: Server can optionally use Server-Sent Events (SSE) for streaming
  - MCP Endpoint: Server MUST provide a single HTTP endpoint supporting both methods
```

### 現有架構限制

目前的 1.x 版本架構：

```
瀏覽器 <---> HTTP Bridge <---> MCP Server
       HTTP/SSE          stdio
```

問題：
1. 需要額外的 HTTP Bridge 層
2. 增加了系統複雜度
3. 可能的性能開銷
4. 維護兩個獨立的進程

## V2.0 目標架構

### 原生 Streamable HTTP 實作

```
瀏覽器 <---> MCP Server
       HTTP/SSE
```

優勢：
1. 簡化架構，移除中間層
2. 提升性能
3. 符合最新 MCP 規範
4. 單一進程管理

## 實施計劃

### 第一階段：研究與設計（2週）

1. **深入研究 MCP Streamable HTTP 規範**
   - 請求/響應格式
   - SSE 流式傳輸細節
   - 會話管理（Mcp-Session-Id）
   - 錯誤處理機制

2. **設計新架構**
   - HTTP 伺服器選型（Express.js / Fastify / 原生 Node.js）
   - Transport 層抽象設計
   - 向後兼容策略

3. **技術驗證（POC）**
   - 實作最小可行的 Streamable HTTP Transport
   - 測試與現有客戶端的兼容性

### 第二階段：核心開發（4週）

1. **實作 HTTPServerTransport**
   ```typescript
   class HTTPServerTransport implements Transport {
     constructor(options: HTTPServerOptions) {
       // 初始化 HTTP 伺服器
     }
     
     async handlePost(req: Request, res: Response) {
       // 處理 JSON-RPC 請求
     }
     
     async handleGet(req: Request, res: Response) {
       // 建立 SSE 連接
     }
   }
   ```

2. **整合現有功能**
   - 遷移所有工具定義
   - 保持 API 兼容性
   - 整合快取機制

3. **實作進階功能**
   - 會話管理
   - 多客戶端支援
   - 流式響應優化

### 第三階段：測試與優化（2週）

1. **全面測試**
   - 單元測試覆蓋率 > 90%
   - 整合測試
   - 性能基準測試
   - 與 Claude Code CLI 的兼容性測試

2. **性能優化**
   - 連接池管理
   - 請求批處理
   - 記憶體使用優化

3. **文檔更新**
   - API 文檔
   - 遷移指南
   - 部署說明

### 第四階段：漸進式發布（2週）

1. **Alpha 版本**
   - 內部測試
   - 收集反饋

2. **Beta 版本**
   - 公開測試
   - 向後兼容模式

3. **正式發布**
   - 2.0.0 版本發布
   - 廢棄 HTTP Bridge

## 技術細節

### 關鍵實作要點

1. **單一端點處理**
   ```typescript
   app.all('/mcp', async (req, res) => {
     if (req.method === 'POST') {
       // 處理 JSON-RPC 請求
     } else if (req.method === 'GET') {
       // 建立 SSE 流
     }
   });
   ```

2. **協議版本協商**
   ```typescript
   // 支援 MCP-Protocol-Version header
   const protocolVersion = req.headers['mcp-protocol-version'] || '2025-06-18';
   ```

3. **雙模式支援（過渡期）**
   ```typescript
   // 同時支援 stdio 和 HTTP
   const transport = options.mode === 'stdio' 
     ? new StdioServerTransport()
     : new HTTPServerTransport(options);
   ```

## 風險與緩解

### 技術風險

1. **兼容性風險**
   - 緩解：提供雙模式運行選項
   - 充分的兼容性測試

2. **性能風險**
   - 緩解：基準測試對比
   - 漸進式優化

### 業務風險

1. **用戶遷移**
   - 緩解：詳細的遷移文檔
   - 向後兼容期至少 6 個月

## 成功指標

1. **技術指標**
   - 響應時間降低 20%
   - 資源使用降低 30%
   - 零停機遷移

2. **用戶指標**
   - 90% 用戶順利遷移
   - 用戶滿意度提升
   - 問題報告減少

## 時間表

- **2024 Q1**: 研究與設計
- **2024 Q2**: 核心開發
- **2024 Q3**: 測試與優化
- **2024 Q4**: 正式發布

## 結論

Perplexity MCP Custom Server 2.0 將帶來更簡潔的架構、更好的性能和更符合標準的實作。這次升級是必要的技術演進，將為未來的功能擴展打下堅實基礎。