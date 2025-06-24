# 網頁應用配置 Perplexity Custom MCP Server v2 (SSE) 完整指南

## 概述

本指南說明如何在網頁應用中透過 Server-Sent Events (SSE) 連接到 Perplexity Custom MCP Server v2。

## 系統架構

```
網頁應用 (localhost:5173)
    ↓ HTTP + SSE
Perplexity MCP v2 (localhost:3001)
    ↓ API 調用
Perplexity API (api.perplexity.ai)
```

## 1. 啟動 Perplexity MCP Server v2

### 方式一：直接啟動（開發環境）

```bash
cd /Users/chih-hungtseng/projects/MCP-Server-DEV/perplexity-mcp-custom

# 設定環境變數
export PERPLEXITY_API_KEY="your-api-key"
export PERPLEXITY_MODEL="sonar-pro"

# 啟動 HTTP 模式
node dist/index.js --http --port 3001
```

### 方式二：使用包裝腳本（生產環境）

創建啟動腳本 `start-perplexity-http.sh`：

```bash
#!/bin/bash

# 設定環境變數
export PERPLEXITY_API_KEY="your-api-key"
export PERPLEXITY_MODEL="sonar-pro"

# 啟動 HTTP 服務
cd /path/to/perplexity-mcp-custom
node dist/index.js --http --port 3001
```

## 2. 網頁端 MCP Manager 配置

### MCPManager.js 配置

```javascript
const MCP_SERVER_CONFIGS = {
  [MCPServerType.PERPLEXITY]: {
    name: 'Perplexity MCP',
    url: 'http://localhost:3001/mcp',  // HTTP 端點
    transportType: 'sse',              // 使用 SSE
    priority: 1,
    capabilities: ['search', 'research']
  }
};
```

## 3. UnifiedMCPClient 實作重點

### 3.1 SSE 連接處理

```javascript
class UnifiedMCPClient {
  constructor(serverUrl, serverName, transportType = 'sse') {
    this.serverUrl = serverUrl;
    this.serverName = serverName;
    this.transportType = transportType;
    this.sessionId = this._generateSessionId();
  }

  async _connectSSE() {
    // Perplexity v2 使用 HTTP POST 而非持久 SSE 連接
    // 每個請求都是獨立的 HTTP POST
    this.logger.debug('Perplexity v2 使用 HTTP POST 模式');
    return Promise.resolve();
  }

  async _sendRequest(method, params) {
    const request = {
      jsonrpc: '2.0',
      method: method,
      params: params || {},
      id: this._generateRequestId()
    };

    const response = await fetch(this.serverUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json, text/event-stream',
        'MCP-Session-Id': this.sessionId
      },
      body: JSON.stringify(request)
    });

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    // 處理 SSE 響應
    if (response.headers.get('content-type')?.includes('text/event-stream')) {
      return this._parseSSEResponse(response);
    }

    // 處理 JSON 響應
    return response.json();
  }

  async _parseSSEResponse(response) {
    const reader = response.body.getReader();
    const decoder = new TextDecoder();
    let buffer = '';

    while (true) {
      const { done, value } = await reader.read();
      if (done) break;

      buffer += decoder.decode(value, { stream: true });
      const lines = buffer.split('\n');
      
      for (let i = 0; i < lines.length - 1; i++) {
        const line = lines[i].trim();
        if (line.startsWith('data: ')) {
          const data = line.slice(6);
          if (data === '[DONE]') {
            return;
          }
          try {
            const parsed = JSON.parse(data);
            if (parsed.result) {
              return parsed;
            }
          } catch (e) {
            console.error('解析 SSE 數據失敗:', e);
          }
        }
      }
      
      buffer = lines[lines.length - 1];
    }
  }
}
```

### 3.2 初始化流程

```javascript
async connect() {
  try {
    // 1. 初始化連接
    const initResponse = await this._sendRequest('initialize', {
      protocolVersion: '2024-11-05',
      capabilities: {},
      clientInfo: {
        name: 'WebUI-Client',
        version: '1.0.0'
      }
    });

    // 2. 獲取工具列表
    const toolsResponse = await this._sendRequest('tools/list', {});
    this.availableTools = toolsResponse.result?.tools || [];

    this.connectionState = ConnectionState.CONNECTED;
    return true;
  } catch (error) {
    console.error('連接失敗:', error);
    throw error;
  }
}
```

## 4. CORS 配置

Perplexity MCP v2 已內建 CORS 支援：

```javascript
// 服務器端已配置
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Accept, MCP-Session-Id',
  'Access-Control-Max-Age': '86400'
};
```

## 5. 完整測試範例

### 5.1 健康檢查

```javascript
async function testHealth() {
  const response = await fetch('http://localhost:3001/health');
  const data = await response.json();
  console.log('健康檢查:', data);
  // 預期: { status: 'ok', version: '2.0.0' }
}
```

### 5.2 MCP 初始化測試

```javascript
async function testMCPInitialize() {
  const response = await fetch('http://localhost:3001/mcp', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json, text/event-stream',
      'MCP-Session-Id': 'test-session-123'
    },
    body: JSON.stringify({
      jsonrpc: '2.0',
      method: 'initialize',
      params: {
        protocolVersion: '2024-11-05',
        capabilities: {},
        clientInfo: {
          name: 'test-client',
          version: '1.0.0'
        }
      },
      id: 1
    })
  });

  const reader = response.body.getReader();
  const decoder = new TextDecoder();
  
  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    
    const chunk = decoder.decode(value);
    console.log('收到:', chunk);
  }
}
```

### 5.3 搜尋測試

```javascript
async function testSearch(query) {
  const client = new UnifiedMCPClient('http://localhost:3001/mcp', 'Perplexity', 'sse');
  await client.connect();
  
  const result = await client.callTool('perplexity_search_web', {
    query: query
  });
  
  console.log('搜尋結果:', result);
}
```

## 6. 常見錯誤及解決方案

### 6.1 CORS 錯誤

如果遇到 CORS 錯誤，請確認：
1. Perplexity MCP v2 使用 `--http` 參數啟動
2. 端口正確（3001）
3. 沒有其他服務占用該端口

### 6.2 Session ID 錯誤

確保使用正確的標頭名稱：
- ✅ 正確: `MCP-Session-Id`（小寫 'd'）
- ❌ 錯誤: `MCP-Session-ID`（大寫 'D'）

### 6.3 SSE 解析錯誤

SSE 格式範例：
```
data: {"jsonrpc":"2.0","id":1,"result":{"protocolVersion":"2024-11-05"}}

data: [DONE]
```

## 7. 完整配置檢查清單

- [ ] Perplexity API Key 已設定
- [ ] Perplexity MCP v2 在 3001 端口運行
- [ ] 使用 `--http` 參數啟動
- [ ] MCPManager.js 配置正確的 URL 和 transportType
- [ ] UnifiedMCPClient 支援 SSE 解析
- [ ] 正確的協議版本 (2024-11-05)
- [ ] 正確的 Session ID 標頭

## 8. 調試工具

### curl 測試命令

```bash
# 健康檢查
curl http://localhost:3001/health

# MCP 初始化（會返回 SSE）
curl -X POST http://localhost:3001/mcp \
  -H "Content-Type: application/json" \
  -H "Accept: text/event-stream" \
  -H "MCP-Session-Id: test-123" \
  -d '{
    "jsonrpc": "2.0",
    "method": "initialize",
    "params": {
      "protocolVersion": "2024-11-05",
      "capabilities": {},
      "clientInfo": {
        "name": "curl-test",
        "version": "1.0.0"
      }
    },
    "id": 1
  }'
```

### 瀏覽器開發工具

1. 打開 Network 標籤
2. 篩選 "mcp" 請求
3. 檢查請求標頭和響應
4. 查看 EventStream 標籤（針對 SSE）

## 9. 生產環境建議

1. **使用 PM2 管理進程**
   ```bash
   pm2 start dist/index.js --name perplexity-mcp -- --http --port 3001
   ```

2. **配置環境變數檔案**
   ```bash
   # .env.production
   PERPLEXITY_API_KEY=your-production-key
   PERPLEXITY_MODEL=sonar-pro
   HTTP_PORT=3001
   ```

3. **監控和日誌**
   ```bash
   pm2 logs perplexity-mcp
   pm2 monit
   ```

## 10. 參考資源

- [MCP 協議規範](https://modelcontextprotocol.io/specification)
- [Perplexity API 文檔](https://docs.perplexity.ai)
- [SSE 規範](https://html.spec.whatwg.org/multipage/server-sent-events.html)

---

**注意**: 本指南針對 Perplexity Custom MCP Server v2，使用 HTTP + SSE 模式，適用於網頁應用整合。