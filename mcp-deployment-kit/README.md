# MCP Server 一鍵部署包

這是一個專為 Claude Code 設計的 MCP Server 自動部署工具，支援 macOS 15.5。

## 🚀 功能特點

- **一鍵部署**：自動安裝和配置五個 MCP Server
- **Claude Code 優化**：專為 Claude Code 執行環境設計
- **智能錯誤處理**：自動檢測和解決常見問題
- **安全管理**：使用 macOS Keychain 管理 API 金鑰
- **模組化設計**：易於擴展和維護

## 📦 包含的 MCP Servers

1. **perplexity-mcp-custom** - 增強版 Perplexity 搜尋服務
2. **zen-mcp-server** - 多模型 AI 協作平台
3. **openmemory-mcp-config** - AI 記憶體管理系統
4. **serena-mcp-server** - 語意化程式碼分析工具
5. **taskmaster-mcp-config** - AI 驅動的任務管理系統

## 🛠️ 系統需求

- macOS 15.5 或更高版本
- Claude Code CLI
- 網路連線（用於下載依賴）

## 📋 快速開始

### 給 Claude Code 的指令：

1. 閱讀 `CLAUDE_INSTRUCTIONS.md` 了解執行細節
2. 使用 TodoWrite 建立執行計劃
3. 執行 `./install-with-claude.sh` 開始安裝

### 手動執行：

```bash
# 1. 克隆或下載此部署包
cd mcp-deployment-kit

# 2. 給予執行權限
chmod +x install-with-claude.sh

# 3. 執行安裝
./install-with-claude.sh
```

## 📁 目錄結構

```
mcp-deployment-kit/
├── README.md                    # 本文件
├── CLAUDE_INSTRUCTIONS.md       # Claude Code 專用指南
├── install-with-claude.sh       # 主安裝腳本
├── claude-tasks/                # Claude 任務定義
│   ├── 01-environment-check.md  # 環境檢查
│   ├── 02-install-dependencies.md # 依賴安裝
│   ├── 03-deploy-services.md    # 服務部署
│   ├── 04-register-mcp.md       # MCP 註冊
│   └── 05-verify-installation.md # 安裝驗證
├── lib/                         # 核心功能庫
├── services/                    # 各 MCP Server 配置
├── templates/                   # 模板文件
└── verification/                # 驗證工具
```

## 🔒 安全性

- 所有 API 金鑰使用 macOS Keychain 安全儲存
- 敏感資訊不會記錄在日誌中
- 支援環境變數覆蓋

## 🐛 故障排除

遇到問題時，請：

1. 查看 `install.log` 了解詳細錯誤
2. 執行 `./verification/test-claude-integration.sh` 進行診斷
3. 參考 `templates/claude_context/troubleshooting.md`

## 📄 授權

MIT License

## 🤝 貢獻

歡迎提交 Issue 和 Pull Request！

---

*本部署包由 MCP Server Development 專案維護*