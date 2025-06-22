# HTTP Transport 模式使用指南

## 概述

Perplexity MCP Server 現在支援兩種 transport 模式：
- **stdio** (預設): 適用於桌面應用程式
- **http**: 適用於 WebUI，支援 SSE (Server-Sent Events) 串流

## 為什麼使用 HTTP 模式？

1. **無需 MCP Bridge**: WebUI 可以直接連接，不需要額外的轉換層
2. **原生 SSE 支援**: 支援即時串流回應
3. **Session 管理**: 內建 session 支援，可處理多個並發連接
4. **更好的擴展性**: 可以輕鬆部署到雲端環境

## 啟動方式

### 命令行參數

```bash
# 預設 HTTP 模式 (port 3000)
npm start -- --http

# 指定連接埠
npm start -- --http --port 8080

# 指定主機
npm start -- --http --port 8080 --host localhost
```

### 環境變數

```bash
# 使用環境變數
MCP_TRANSPORT=http MCP_PORT=8080 npm start
```

## HTTP 端點

啟動後，server 會提供以下端點：

- `POST /mcp` - JSON-RPC 請求
- `GET /mcp` - SSE 串流連接
- `DELETE /mcp` - 終止 session
- `GET /health` - 健康檢查

## 使用範例

### 1. 初始化連接

```javascript
const response = await fetch('http://localhost:3000/mcp', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    jsonrpc: '2.0',
    method: 'initialize',
    params: {
      protocolVersion: '2024-11-05',
      capabilities: {},
      clientInfo: {
        name: 'my-client',
        version: '1.0.0'
      }
    },
    id: 1
  })
});

const result = await response.json();
const sessionId = response.headers.get('MCP-Session-Id');
```

### 2. 建立 SSE 連接

```javascript
const eventSource = new EventSource(`http://localhost:3000/mcp`, {
  headers: {
    'MCP-Session-Id': sessionId
  }
});

eventSource.onmessage = (event) => {
  const data = JSON.parse(event.data);
  console.log('Received:', data);
};
```

### 3. 呼叫工具

```javascript
const response = await fetch('http://localhost:3000/mcp', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'MCP-Session-Id': sessionId
  },
  body: JSON.stringify({
    jsonrpc: '2.0',
    method: 'tools/call',
    params: {
      name: 'perplexity_search_web',
      arguments: {
        query: 'Your search query'
      }
    },
    id: 2
  })
});
```

## 安全配置

### CORS 設定

```bash
# 設定允許的來源
PERPLEXITY_CORS_ORIGINS=http://localhost:5173,https://myapp.com npm start -- --http
```

### Bearer Token 認證

```bash
# 啟用認證
PERPLEXITY_BEARER_TOKEN=your-secret-token npm start -- --http
```

客戶端需要包含認證標頭：
```javascript
headers: {
  'Authorization': 'Bearer your-secret-token'
}
```

### Rate Limiting

```bash
# 設定每分鐘最大請求數
PERPLEXITY_RATE_LIMIT=60 npm start -- --http
```

## 與 stdio 模式的差異

| 特性 | stdio | http |
|------|-------|------|
| 連接方式 | 標準輸入/輸出 | HTTP/SSE |
| 適用場景 | 桌面應用 | WebUI |
| Session 管理 | 單一連接 | 多 session |
| 部署 | 本地執行 | 可遠端部署 |
| 安全性 | 進程隔離 | 需要 CORS/Auth |

## 故障排除

### 連接埠已被佔用

```bash
# 檢查連接埠
lsof -i :3000

# 使用其他連接埠
npm start -- --http --port 8080
```

### CORS 錯誤

確保設定正確的 CORS 來源：
```bash
PERPLEXITY_CORS_ORIGINS=http://localhost:5173 npm start -- --http
```

### Session 遺失

- 確保每個請求都包含 `MCP-Session-Id` 標頭
- Session ID 在初始化時由 server 返回
- 不要在多個客戶端間共享 session ID

## 生產環境部署建議

1. **使用 HTTPS**: 在生產環境中使用反向代理（如 nginx）提供 HTTPS
2. **啟用認證**: 設定 `PERPLEXITY_BEARER_TOKEN`
3. **限制 CORS**: 只允許特定的來源
4. **設定 Rate Limiting**: 防止濫用
5. **監控**: 記錄所有請求和錯誤

## 測試

使用提供的測試腳本：
```bash
./test-http.sh
```

或手動測試：
```bash
# 健康檢查
curl http://localhost:3000/health
```