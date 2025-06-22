# Claude Task Master MCP Server 配置

Claude Task Master 是一個 AI 驅動的任務管理系統，專為軟體開發專案設計。本配置將 Task Master 整合到 Claude Code CLI 中，成為第六個核心 MCP Server。

## 🎯 核心功能

### 1. 智能任務管理
- **PRD 解析**：從產品需求文檔自動生成結構化任務
- **依賴管理**：智能識別和管理任務間的依賴關係
- **進度追蹤**：即時追蹤任務狀態和專案進度
- **優先級管理**：自動分配和調整任務優先級

### 2. AI 模型協作
- **多模型支援**：Claude、GPT、Gemini、Perplexity、Mistral 等
- **角色分工**：
  - `main`：主要任務生成和分析
  - `research`：深度研究和資訊收集
  - `fallback`：備用模型支援

### 3. 開發工作流整合
- **任務分解**：基於複雜度自動建議子任務
- **程式碼實施**：與編輯器無縫整合
- **測試策略**：為每個任務生成測試計劃
- **文檔同步**：自動更新任務文檔

## 📦 安裝配置

### 1. 環境準備

```bash
# 複製環境變數範例
cp .env.example .env

# 編輯 .env 檔案，設定 API keys
# 至少需要一個 AI 提供者的 API key
```

### 2. 註冊到 Claude Code CLI

```bash
# 使用包裝腳本註冊
claude mcp add taskmaster ~/.claude-code-taskmaster.sh
```

### 3. 驗證安裝

```bash
# 列出已安裝的 MCP servers
claude mcp list

# 應該看到：
# taskmaster: ~/.claude-code-taskmaster.sh
```

## 🚀 快速開始

### 初始化專案

```bash
# 在專案根目錄執行
task-master init

# 這將建立 .taskmaster/ 目錄結構
```

### 從 PRD 生成任務

```bash
# 解析 PRD 文檔
task-master parse-prd .taskmaster/docs/prd.txt

# 限制生成的任務數量
task-master parse-prd .taskmaster/docs/prd.txt --num-tasks=10
```

### 日常使用

```bash
# 列出所有任務
task-master list

# 顯示下一個任務
task-master next

# 顯示特定任務詳情
task-master show 1.2

# 更新任務狀態
task-master set-status --id=1.2 --status=done
```

## 🔧 進階功能

### 1. 任務複雜度分析

```bash
# 分析所有任務的複雜度
task-master analyze-complexity --research

# 查看複雜度報告
task-master complexity-report

# 基於分析結果擴展任務
task-master expand --all
```

### 2. AI 驅動的研究

```bash
# 研究特定技術主題
task-master research "JWT authentication best practices" --save-to=15

# 為特定任務進行研究
task-master research "How to implement OAuth?" --id=15,16
```

### 3. 任務重組

```bash
# 移動任務到新位置
task-master move --from=5 --to=25

# 將獨立任務轉為子任務
task-master move --from=5 --to=7.3
```

## 🔄 與其他 MCP Server 的協同

### Task Master 在六大 MCP Server 生態系統中的定位

1. **專案管理指揮官**：統籌整個開發流程
2. **與 Zen MCP**：任務實施時的深度分析和決策支援
3. **與 Perplexity**：任務相關的技術研究和趨勢分析
4. **與 Context7**：獲取任務所需的技術文檔
5. **與 OpenMemory**：儲存任務決策和實施經驗
6. **與 Serena**：任務實施時的程式碼語意分析

## 📁 專案結構

```
.taskmaster/
├── tasks.json           # 任務資料
├── config.json         # AI 模型配置
├── docs/
│   ├── prd.txt        # 產品需求文檔
│   └── tasks/         # 任務詳細文檔
└── memory/            # 任務相關記憶
```

## 🛠️ 配置選項

### AI 模型配置 (.taskmaster/config.json)

```json
{
  "models": {
    "main": {
      "provider": "anthropic",
      "modelId": "claude-3-5-sonnet",
      "maxTokens": 64000,
      "temperature": 0.2
    },
    "research": {
      "provider": "perplexity",
      "modelId": "sonar-pro",
      "maxTokens": 8700,
      "temperature": 0.1
    },
    "fallback": {
      "provider": "openai",
      "modelId": "gpt-4o",
      "maxTokens": 16000,
      "temperature": 0.2
    }
  }
}
```

## 🔐 安全注意事項

1. **API Keys 管理**：
   - 永遠不要將 API keys 提交到版本控制
   - 使用環境變數或 .env 檔案
   - 定期輪換 API keys

2. **數據隱私**：
   - 任務資料儲存在本地
   - 只有明確的研究請求才會使用外部 AI 服務

## 📚 相關資源

- [官方 GitHub](https://github.com/eyaltoledano/claude-task-master)
- [部署指南](./deployment.md)
- [整合指南](./integration.md)
- [配置詳解](./docs/CONFIGURATION.md)
- [工作流程](./docs/WORKFLOW.md)
- [協同效應分析](./docs/SYNERGY.md)

## 🤝 貢獻

本配置是 MCP Server Development 專案的一部分，歡迎提交問題和改進建議。

---

**版本**：1.0  
**更新日期**：2025-06-22  
**作者**：Claude Code with MCP Enhancement