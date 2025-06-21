# MCP Server Development

這個目錄包含自製 MCP (Model Context Protocol) Server 的開發專案。

## 專案列表

### 1. perplexity-mcp-custom
完全符合 MCP 協議 2025-06-18 標準的 Perplexity MCP Server，解決現有實作的相容性問題。

**特點**：
- ✅ 完全符合 JSON Schema draft 2020-12
- ✅ 支援全域註冊（-g 參數）
- ✅ 優秀的錯誤處理
- ✅ 豐富的進階功能

**文檔**：
- [可行性研究報告](./perplexity-mcp-custom/docs/FEASIBILITY_STUDY.md)
- [開發計劃](./perplexity-mcp-custom/docs/DEVELOPMENT_PLAN.md)
- [技術規格書](./perplexity-mcp-custom/docs/TECHNICAL_SPEC.md)

## 開發標準

所有 MCP Server 開發都應遵循以下標準：

### 1. 協議相容性
- 必須完全符合 MCP 協議規範
- 支援最新版本（2025-06-18）
- 保持向下相容性

### 2. JSON Schema
- 嚴格遵循 JSON Schema draft 2020-12
- 避免使用不相容的擴展
- 完整的 Schema 驗證

### 3. 程式碼品質
- TypeScript 優先
- 完整的型別定義
- 單元測試覆蓋率 > 80%

### 4. 文檔要求
- 清晰的 README
- API 文檔
- 使用範例
- 故障排除指南

## 開發工具

### 必需工具
- Node.js 20+
- TypeScript 5+
- @modelcontextprotocol/sdk

### 建議工具
- Vitest (測試)
- tsup (建構)
- Prettier (格式化)
- ESLint (程式碼檢查)

## 貢獻指南

1. 每個 MCP Server 獨立一個資料夾
2. 遵循既定的資料夾結構
3. 提供完整的文檔
4. 通過所有測試
5. 符合程式碼規範

## 授權

除非另有說明，所有專案採用 MIT 授權。