<!-- MCP_AUTO_START:mcp_dev_principles -->
## 🔧 MCP Server 開發原則

此部分由 MCP Server 部署工具自動管理，包含 MCP Server 開發的核心原則和最佳實踐。

### 1. MCP 協議標準

**核心規範**：
- **協議版本**：必須支援 MCP Protocol 2024-11-05 或更新版本
- **JSON Schema**：嚴格遵循 JSON Schema draft 2020-12 標準
- **通訊模式**：
  - stdio（標準輸入/輸出）：適用於本地執行
  - SSE（Server-Sent Events）：適用於網路服務

**實作要求**：
```typescript
// 正確的 JSON Schema 定義
{
  "$schema": "http://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "query": {
      "type": "string",
      "description": "搜尋查詢"
    }
  },
  "required": ["query"],
  "additionalProperties": false
}
```

### 2. 錯誤處理標準

**必須實作的錯誤類型**：
1. **輸入驗證錯誤**：參數不符合 Schema
2. **執行錯誤**：服務執行時的錯誤
3. **超時錯誤**：操作超過時間限制
4. **資源錯誤**：資源不可用或存取被拒

**錯誤回應格式**：
```json
{
  "error": {
    "code": "INVALID_PARAMS",
    "message": "參數 'query' 是必需的",
    "data": {
      "field": "query",
      "expected": "string",
      "received": "undefined"
    }
  }
}
```

### 3. 環境變數管理

**防禦性載入策略**：
```javascript
// 強制覆蓋系統變數
require('dotenv').config({ override: true });

// 立即驗證必要變數
const requiredVars = ['API_KEY', 'SERVICE_URL'];
const missing = requiredVars.filter(key => !process.env[key]);
if (missing.length > 0) {
  throw new Error(`Missing required environment variables: ${missing.join(', ')}`);
}
```

### 4. 端口使用規範

**MCP Server 保留端口**：
| 服務 | 端口 | 用途 |
|------|------|------|
| OpenMemory API | 8765 | MCP API 服務 |
| Qdrant | 6333 | 向量資料庫 |
| PostgreSQL | 5432 | 關聯式資料庫 |
| Web UI | 3000 | 管理介面 |
| Perplexity | 8080 | HTTP/SSE 服務 |
| Xinference | 9997 | 本地 LLM API |
| LM Studio | 1234 | 模型服務 |
| Ollama | 11434 | 本地模型 |

**端口衝突處理**：
```bash
# 檢查端口前必須執行
check_mcp_ports() {
    local port=$1
    if lsof -ti:$port >/dev/null 2>&1; then
        echo "Port $port is in use"
        return 1
    fi
    return 0
}
```

### 5. Claude Code CLI 整合

**註冊決策流程**：
```
需要註冊 MCP Server?
├─ 檢查 JSON Schema 相容性
│  ├─ 相容 → 使用 -s user（全域註冊）
│  └─ 不相容 → 使用專案範圍註冊
└─ 檢查是否已註冊
   ├─ 已註冊 → 跳過
   └─ 未註冊 → 執行註冊
```

**註冊命令範例**：
```bash
# 全域註冊（需要 JSON Schema 相容）
claude mcp add perplexity "npx @org/perplexity-mcp" -s user

# 專案範圍註冊（相容性問題時使用）
claude mcp add perplexity "~/.perplexity-wrapper.sh"
```

### 6. 安全性要求

**API 金鑰管理**：
1. **禁止**：硬編碼 API 金鑰
2. **必須**：使用環境變數或安全儲存
3. **推薦**：macOS Keychain 整合

```bash
# macOS Keychain 使用範例
security add-generic-password \
  -a "mcp-server" \
  -s "PERPLEXITY_API_KEY" \
  -w "$API_KEY"

# 讀取金鑰
API_KEY=$(security find-generic-password \
  -a "mcp-server" \
  -s "PERPLEXITY_API_KEY" \
  -w)
```

### 7. 日誌記錄規範

**日誌等級**：
- **DEBUG**：詳細的調試資訊
- **INFO**：一般操作資訊
- **WARN**：警告但不影響運行
- **ERROR**：錯誤需要處理

**敏感資訊處理**：
```javascript
// 永遠不要記錄完整的 API 金鑰
logger.info(`Using API key: ${apiKey.substring(0, 4)}...`);

// 清理敏感資訊
function sanitizeLog(data) {
  const sensitive = ['password', 'apiKey', 'token'];
  return Object.keys(data).reduce((acc, key) => {
    acc[key] = sensitive.includes(key) ? '[REDACTED]' : data[key];
    return acc;
  }, {});
}
```

### 8. 測試要求

**必要的測試類型**：
1. **單元測試**：核心功能測試
2. **整合測試**：MCP 協議相容性
3. **端到端測試**：完整流程驗證

**測試覆蓋率目標**：
- 核心功能：> 90%
- 錯誤處理：> 80%
- 整體覆蓋：> 70%

### 9. 文檔標準

**必須包含的文檔**：
1. **README.md**：專案概述和快速開始
2. **API.md**：完整的 API 參考
3. **CONFIGURATION.md**：配置選項說明
4. **TROUBLESHOOTING.md**：常見問題解決

### 10. 版本管理

**語意化版本控制**：
- **主版本**：不相容的 API 變更
- **次版本**：向下相容的功能新增
- **修訂版**：向下相容的錯誤修正

```json
{
  "version": "2.0.0",
  "mcp-protocol": "2024-11-05",
  "compatibility": {
    "claude-cli": ">=1.0.0",
    "node": ">=20.0.0"
  }
}
```

### 11. 效能優化

**基本要求**：
- 回應時間：< 5 秒（一般操作）
- 記憶體使用：< 512MB（正常負載）
- 並發處理：支援多個請求

**快取策略**：
```javascript
// 實作簡單的記憶體快取
const cache = new Map();
const CACHE_TTL = 5 * 60 * 1000; // 5 分鐘

function getCached(key) {
  const item = cache.get(key);
  if (!item) return null;
  
  if (Date.now() - item.timestamp > CACHE_TTL) {
    cache.delete(key);
    return null;
  }
  
  return item.value;
}
```

### 12. 部署檢查清單

部署前必須完成：
- [ ] 所有測試通過
- [ ] 環境變數配置完整
- [ ] 端口無衝突
- [ ] JSON Schema 驗證通過
- [ ] 文檔更新完成
- [ ] 安全掃描通過
- [ ] 效能測試達標

---

*這些原則是開發高品質 MCP Server 的基礎。請在開發過程中持續參考並遵循這些指導方針。*
<!-- MCP_AUTO_END:mcp_dev_principles -->