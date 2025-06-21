# Perplexity MCP Custom Server - Pro 搜尋功能指南

## 更新內容

已成功增加所有 5 個 Perplexity 模型的支援，並新增了專門的 Pro 搜尋工具。

## 可用的工具

### 1. perplexity_search_web
通用搜尋工具，支援所有 5 個模型：
- `sonar` - 基礎模型，快速回應
- `sonar-pro` - 專業模型，平衡速度與品質
- `sonar-reasoning` - 推理模型，適合邏輯分析
- `sonar-reasoning-pro` - 進階推理模型，最佳邏輯分析能力
- `sonar-deep-research` - 深度研究模型，最詳盡但較慢

### 2. perplexity_pro_search
專門的 Pro 搜尋工具，預設啟用所有進階功能：
- 預設使用 `sonar-pro` 模型
- 自動返回引用來源、圖片和相關問題
- 支援 `sonar-pro` 和 `sonar-reasoning-pro`

### 3. perplexity_deep_research
深度研究工具，使用 `sonar-deep-research` 模型：
- 支援設定研究深度（quick, standard, comprehensive）
- 可指定重點研究領域

## 使用範例

### 基本搜尋（使用不同模型）
```bash
# 使用基礎模型
claude "查詢天氣預報" --allowedTools mcp__perplexity-custom__perplexity_search_web

# 使用 Pro 模型（在工具參數中指定）
claude "分析量子計算的商業應用" --allowedTools mcp__perplexity-custom__perplexity_search_web
```

### Pro 搜尋（優化體驗）
```bash
# 使用專門的 Pro 搜尋工具
claude "研究最新的 AI 安全技術發展" --allowedTools mcp__perplexity-custom__perplexity_pro_search
```

### 推理分析
```bash
# 使用推理模型進行邏輯分析
claude "分析氣候變遷對全球經濟的影響鏈" --allowedTools mcp__perplexity-custom__perplexity_search_web
# Claude 會自動選擇適合的推理模型
```

### 深度研究
```bash
# 進行全面深度研究
claude "深入研究 CRISPR 基因編輯技術的最新進展和倫理問題" --allowedTools mcp__perplexity-custom__perplexity_deep_research
```

## 模型選擇建議

1. **快速查詢**：使用 `sonar`
   - 簡單事實查詢
   - 即時資訊需求
   - 對準確度要求不高

2. **一般搜尋**：使用 `sonar-pro`（預設）
   - 大部分搜尋需求
   - 平衡速度與品質
   - 綜合性查詢

3. **邏輯推理**：使用 `sonar-reasoning` 或 `sonar-reasoning-pro`
   - 因果關係分析
   - 邏輯推導
   - 複雜問題解決

4. **深度研究**：使用 `sonar-deep-research`
   - 學術研究
   - 詳盡報告
   - 多角度分析

## 技術細節

### 環境變數配置
```bash
PERPLEXITY_API_KEY="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"
PERPLEXITY_MODEL="sonar-pro"  # 預設模型
DEBUG="false"
```

### 快取機制
- 所有搜尋結果都會快取 1 小時
- 相同查詢會返回快取結果以提升效能
- 快取鍵值包含模型名稱，不同模型的結果分開快取

### JSON Schema 相容性
所有工具都符合 JSON Schema draft 2020-12 標準，可安全註冊到全域範圍。

## 註冊狀態

MCP Server 已成功註冊到使用者範圍（user scope）：
- 名稱：`perplexity-custom`
- 範圍：所有專案可用
- 類型：stdio
- 路徑：`/Users/chih-hungtseng/.claude-code-perplexity-custom.sh`

## 更新日誌

- 2025-06-21：增加所有 5 個 Perplexity 模型支援
- 2025-06-21：新增專門的 Pro 搜尋工具
- 2025-06-21：實施環境變數驗證機制
- 2025-06-21：優化快取策略