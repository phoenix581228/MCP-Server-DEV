# MCP Server Development

這個目錄包含自製 MCP (Model Context Protocol) Server 的開發專案。

## 快速導航

- 📁 [專案結構視覺化](./PROJECT_STRUCTURE.md) - 查看完整的專案目錄結構
- 📊 [專案里程碑](./MILESTONES.md) - 開發進度和成就記錄
- 🔧 [專案導航器](./scripts/project-navigator.sh) - 互動式專案導航工具
- 🌿 [分支管理策略](./BRANCHING_STRATEGY.md) - Git 分支工作流程
- 📈 [Git 歷史報告](./GIT_HISTORY.md) - 提交歷史和統計
- 🔬 [MCP Server 整合研究報告](./RESEARCH_REPORT_MCP_SERVERS_ANALYSIS.md) - 四大 MCP Server vs 原生功能深度分析
- 🚀 [六大 MCP Server 協同生態系統研究報告](./RESEARCH_REPORT_MCP_SERVERS_2025_LATEST.md) - 最新深度研究（含 Task Master）
- 🔌 [MCP Server Port 使用指南](./PORTS.md) - 端口保留和管理規範

## 專案結構概覽

```
MCP-Server-DEV/
├── perplexity-mcp-custom/     # Perplexity MCP Server 實作
│   ├── src/                   # TypeScript 源碼
│   ├── tests/                 # 測試套件
│   └── docs/                  # 技術文檔
├── zen-mcp-config/            # Zen MCP Server 部署配置
│   ├── .env.example          # 環境變數範例
│   ├── claude_config_example.json  # Claude 配置範例
│   └── deployment.md         # 部署指南
├── openmemory-mcp-config/     # OpenMemory MCP Server 部署配置
│   ├── .env.example          # 環境變數範例
│   ├── docker-compose.yml    # Docker Compose 配置
│   ├── deployment.md         # 部署指南
│   └── troubleshooting.md    # 故障排除指南
├── serena-mcp-server/         # Serena MCP Server 整合
│   ├── docs/                  # 詳細文檔
│   ├── *.yml                  # 配置檔案範本
│   ├── install.sh             # 安裝腳本
│   ├── run-serena.sh          # 執行腳本
│   └── test-connection.sh     # 測試腳本
├── taskmaster-mcp-config/     # Task Master MCP Server 配置
│   ├── .env.example          # 環境變數範例
│   ├── deployment.md         # 部署指南
│   ├── integration.md        # 整合指南
│   └── docs/                 # 詳細文檔
└── scripts/                   # 專案管理工具
    ├── generate-tree.sh       # 生成專案結構
    ├── git-history-graph.sh   # Git 歷史視覺化
    ├── project-navigator.sh   # 互動式導航器
    ├── setup-git-hooks.sh     # Git hooks 設定
    ├── check-mcp-ports.sh     # MCP 端口保護檢查
    └── kill-mcp-ports.sh      # MCP 端口釋放工具
```

## 專案管理工具

### 1. 專案結構生成器
```bash
./scripts/generate-tree.sh
```
自動生成並更新 PROJECT_STRUCTURE.md 文件，展示完整的專案目錄結構。

### 2. Git 歷史視覺化
```bash
./scripts/git-history-graph.sh -a  # 顯示所有資訊
./scripts/git-history-graph.sh -g  # 生成報告
```
視覺化展示 Git 提交歷史和專案統計。

### 3. 專案導航器
```bash
./scripts/project-navigator.sh
```
互動式的專案導航工具，快速瀏覽和管理子專案。

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

### 2. zen-mcp-config
[Zen MCP Server](https://github.com/BeehiveInnovations/zen-mcp-server) 的部署配置和設定檔。

**包含**：
- 環境變數配置範例
- Claude 整合設定
- 部署指南
- 安全的 API 金鑰管理

**文檔**：
- [配置說明](./zen-mcp-config/README.md)
- [部署指南](./zen-mcp-config/deployment.md)

### 3. openmemory-mcp-config
[OpenMemory MCP Server](https://github.com/mem0ai/mem0) 的部署配置和設定檔。

**特點**：
- 本地優先的 AI 記憶體管理
- Docker 多服務架構
- SSE 協議支援
- 跨工具記憶體共享

**文檔**：
- [配置說明](./openmemory-mcp-config/README.md)
- [部署指南](./openmemory-mcp-config/deployment.md)
- [故障排除](./openmemory-mcp-config/troubleshooting.md)

### 4. serena-mcp-server
[Serena MCP Server](https://github.com/oraios/serena) 的整合配置，提供語意化程式碼分析功能。

**特點**：
- ✅ 完全符合 MCP 協議標準（支援 stdio 和 SSE）
- ✅ 基於 Language Server Protocol (LSP)
- ✅ 50+ 強大的程式碼分析工具
- ✅ 多語言支援（Python、TypeScript、Java、Ruby、Go、C#）

**文檔**：
- [專案說明](./serena-mcp-server/README.md)
- [安裝指南](./serena-mcp-server/docs/INSTALLATION.md)
- [配置指南](./serena-mcp-server/docs/CONFIGURATION.md)
- [工具參考](./serena-mcp-server/docs/TOOLS_REFERENCE.md)
- [整合指南](./serena-mcp-server/docs/INTEGRATION.md)

### 5. taskmaster-mcp-config
[Claude Task Master](https://github.com/eyaltoledano/claude-task-master) 的部署配置，提供 AI 驅動的任務管理系統。

**特點**：
- ✅ 智能任務規劃和管理
- ✅ 從 PRD 自動生成任務
- ✅ 多 AI 模型協作（Claude、GPT、Gemini、Perplexity）
- ✅ 任務依賴和進度追蹤

**文檔**：
- [配置說明](./taskmaster-mcp-config/README.md)
- [部署指南](./taskmaster-mcp-config/deployment.md)
- [整合指南](./taskmaster-mcp-config/integration.md)
- [詳細配置](./taskmaster-mcp-config/docs/CONFIGURATION.md)
- [工作流程](./taskmaster-mcp-config/docs/WORKFLOW.md)
- [協同效應分析](./taskmaster-mcp-config/docs/SYNERGY.md)

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