# Perplexity MCP Server 開發可行性研究報告

**專案名稱**: perplexity-mcp-custom  
**研究日期**: 2025-06-20  
**版本**: 1.0.0

## 執行摘要

本報告評估開發自製 Perplexity MCP Server 的可行性，以解決現有實作與 MCP 協議 2025-06-18 的相容性問題。經過深入研究，我們認為此專案**高度可行**且具有重要價值。

## 一、背景與問題分析

### 1.1 現有問題
- **@jschuller/perplexity-mcp** 存在 JSON Schema 相容性問題
- 無法使用 `-g` 參數進行全域註冊
- 錯誤訊息：`tools.18.custom.input_schema: JSON schema is invalid`

### 1.2 根本原因
1. 使用了不符合 JSON Schema draft 2020-12 標準的定義
2. Zod schema 轉換可能產生不相容的結構
3. Claude API 對 schema 格式有嚴格要求

## 二、技術研究結果

### 2.1 Perplexity API 規格

#### API 端點
- **基礎 URL**: `https://api.perplexity.ai`
- **主要端點**: `/chat/completions`
- **認證方式**: Bearer Token

#### 支援的模型
1. **sonar**: 基礎模型，快速回應
2. **sonar-pro**: 專業模型（F-score: 0.858）
3. **sonar-reasoning-pro**: 支援推理輸出
4. **sonar-small-online**: 輕量級網路搜尋
5. **sonar-medium-online**: 中型網路搜尋
6. **sonar-deep-research**: 深度研究模型

#### API 特性
- 即時網路搜尋
- 引用來源（citations）
- JSON 模式輸出
- 搜尋網域過濾
- 搜尋時效性控制

### 2.2 MCP 協議 2025-06-18 要求

#### 工具定義規範
```typescript
interface Tool {
  name: string;                    // 工具唯一識別碼
  description?: string;            // 人類可讀描述
  inputSchema: {                   // 參數定義（必須符合 JSON Schema draft 2020-12）
    type: "object";
    properties?: { [key: string]: any };
    required?: string[];
    additionalProperties?: boolean;
  };
}
```

#### JSON Schema 限制
- 必須符合 draft 2020-12 標準
- 避免使用進階功能（$dynamicRef、$dynamicAnchor）
- 建議使用基本類型

## 三、技術架構設計

### 3.1 專案結構
```
perplexity-mcp-custom/
├── src/
│   ├── index.ts              # 程式入口點
│   ├── server.ts             # MCP Server 核心
│   ├── tools/
│   │   ├── search.ts         # 搜尋工具實作
│   │   ├── deep-research.ts  # 深度研究工具
│   │   └── schemas.ts        # JSON Schema 定義
│   ├── api/
│   │   ├── client.ts         # Perplexity API 客戶端
│   │   └── types.ts          # API 型別定義
│   └── utils/
│       ├── cache.ts          # 快取機制
│       └── errors.ts         # 錯誤處理
├── tests/
│   ├── unit/
│   └── integration/
├── package.json
├── tsconfig.json
├── .env.example
└── README.md
```

### 3.2 核心技術選擇
- **語言**: TypeScript 5.x
- **MCP SDK**: @modelcontextprotocol/sdk@1.13.0
- **HTTP 客戶端**: node-fetch 或原生 fetch
- **測試框架**: Vitest
- **建構工具**: tsup

### 3.3 關鍵實作策略

#### 嚴格的 Schema 定義
```typescript
export const searchToolSchema = {
  type: "object" as const,
  properties: {
    query: {
      type: "string",
      description: "搜尋查詢字串",
      minLength: 1,
      maxLength: 1000
    },
    model: {
      type: "string",
      enum: ["sonar", "sonar-pro", "sonar-deep-research"],
      default: "sonar-pro",
      description: "使用的 Perplexity 模型"
    },
    search_domain: {
      type: "string",
      description: "限制搜尋的網域（可選）"
    },
    search_recency: {
      type: "string",
      enum: ["day", "week", "month", "year"],
      description: "結果時效性過濾"
    },
    return_citations: {
      type: "boolean",
      default: true,
      description: "是否返回引用來源"
    },
    max_results: {
      type: "integer",
      minimum: 1,
      maximum: 20,
      default: 5,
      description: "最大結果數量"
    }
  },
  required: ["query"],
  additionalProperties: false
} as const;
```

## 四、功能規劃

### 4.1 核心功能（MVP）
1. **基礎網路搜尋**
   - 支援 sonar 和 sonar-pro 模型
   - 返回格式化的搜尋結果
   - 包含引用來源

2. **深度研究模式**
   - 支援 sonar-deep-research
   - 自動多輪搜尋
   - 結構化輸出

3. **錯誤處理**
   - API 錯誤優雅降級
   - 超時控制
   - 重試機制

### 4.2 進階功能
1. **智能快取**
   - LRU 快取策略
   - TTL 控制
   - 快取命中率統計

2. **並行處理**
   - 支援批量查詢
   - 並發控制
   - 結果聚合

3. **結果增強**
   - 自動摘要生成
   - 關鍵詞高亮
   - 相關性排序

4. **監控與日誌**
   - API 使用統計
   - 效能指標
   - 詳細日誌

## 五、開發計劃

### 5.1 開發階段
| 階段 | 工作內容 | 預計時間 | 交付物 |
|------|---------|----------|--------|
| 第一階段 | 基礎架構搭建 | 1天 | MCP Server 框架、專案結構 |
| 第二階段 | API 整合 | 1天 | Perplexity API 客戶端、基本搜尋 |
| 第三階段 | 工具實作 | 2天 | 搜尋工具、深度研究工具 |
| 第四階段 | 優化增強 | 2天 | 快取、錯誤處理、並行處理 |
| 第五階段 | 測試文檔 | 1天 | 單元測試、整合測試、文檔 |

### 5.2 里程碑
- **M1**: 基礎 MCP Server 可運行（第1天）
- **M2**: 簡單搜尋功能可用（第2天）
- **M3**: 完整功能實作（第4天）
- **M4**: 優化版本完成（第6天）
- **M5**: 可發布版本（第7天）

## 六、風險評估與對策

### 6.1 技術風險
| 風險 | 可能性 | 影響 | 對策 |
|------|--------|------|------|
| API 變更 | 低 | 高 | 版本鎖定、抽象層設計 |
| 效能問題 | 中 | 中 | 快取策略、並發優化 |
| Schema 相容性 | 低 | 高 | 嚴格測試、參考官方範例 |

### 6.2 非技術風險
| 風險 | 可能性 | 影響 | 對策 |
|------|--------|------|------|
| API 配額限制 | 中 | 低 | 智能快取、使用者配額管理 |
| 維護負擔 | 中 | 中 | 良好文檔、社群參與 |

## 七、成本效益分析

### 7.1 開發成本
- **人力成本**: 1人 × 7天
- **API 測試成本**: 約 $10-20
- **基礎設施**: 無（本地開發）

### 7.2 預期效益
1. **直接效益**
   - 解決相容性問題
   - 提升使用體驗
   - 支援更多功能

2. **間接效益**
   - 開源社群貢獻
   - 技術能力提升
   - 可擴展架構

### 7.3 投資回報率
- **短期**: 立即解決現有問題
- **中期**: 減少維護成本
- **長期**: 社群價值、技術積累

## 八、競爭分析

### 8.1 現有方案比較
| 方案 | 優點 | 缺點 |
|------|------|------|
| @jschuller/perplexity-mcp | 已有使用者基礎 | Schema 相容性問題 |
| 官方 Perplexity SDK | 官方支援 | 無 MCP 整合 |
| 自製方案 | 完全可控、最佳相容性 | 需要開發時間 |

### 8.2 競爭優勢
1. **技術優勢**
   - 完全符合最新 MCP 協議
   - 更好的錯誤處理
   - 進階功能支援

2. **使用者體驗**
   - 簡單的安裝流程
   - 詳細的錯誤訊息
   - 豐富的配置選項

## 九、建議與結論

### 9.1 可行性評分
- **技術可行性**: ⭐⭐⭐⭐⭐ (5/5)
- **經濟可行性**: ⭐⭐⭐⭐⭐ (5/5)
- **時間可行性**: ⭐⭐⭐⭐ (4/5)
- **維護可行性**: ⭐⭐⭐⭐ (4/5)

### 9.2 決策建議
基於以上分析，我們強烈建議**立即開始開發**自製 Perplexity MCP Server：

1. 技術路徑清晰，無重大障礙
2. 開發成本低，效益高
3. 可解決現有痛點
4. 具有長期價值

### 9.3 後續行動
1. **立即行動**
   - 建立專案結構
   - 實作基礎框架
   - 整合 API

2. **中期目標**
   - 完成核心功能
   - 發布測試版本
   - 收集使用反饋

3. **長期規劃**
   - 持續優化
   - 社群維護
   - 功能擴展

## 附錄

### A. 參考資料
- [MCP 協議規範](https://modelcontextprotocol.io/docs)
- [Perplexity API 文檔](https://docs.perplexity.ai)
- [JSON Schema 2020-12](https://json-schema.org/specification-links.html#2020-12)

### B. 技術細節
- 詳細 API 規格
- Schema 範例
- 錯誤碼對照表

### C. 專案模板
- package.json 範例
- tsconfig.json 配置
- 測試案例範本