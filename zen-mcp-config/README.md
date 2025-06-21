# Zen MCP Server 配置

這個目錄包含部署和配置 [Zen MCP Server](https://github.com/BeehiveInnovations/zen-mcp-server) 所需的文件。

## 目錄結構

```
zen-mcp-config/
├── README.md                # 本文件
├── .env.example            # 環境變數配置範例
├── claude_config_example.json  # Claude 配置範例
└── deployment.md           # 完整部署指南
```

## 快速開始

1. **取得 Zen MCP Server**
   ```bash
   git clone https://github.com/BeehiveInnovations/zen-mcp-server.git
   ```

2. **配置環境變數**
   ```bash
   cp zen-mcp-config/.env.example zen-mcp-server/.env
   # 編輯 .env 填入您的 API 金鑰
   ```

3. **安裝並執行**
   ```bash
   cd zen-mcp-server
   ./run-server.sh
   ```

## 文件說明

### .env.example
環境變數配置範例，包含：
- API 金鑰設定（Gemini、OpenAI、X.AI）
- 模型選擇和限制
- 日誌等級設定
- 對話超時設定

### claude_config_example.json
Claude Desktop 的 MCP 配置範例。實際配置請執行：
```bash
./run-server.sh -c
```

### deployment.md
詳細的部署指南，包含：
- 步驟說明
- 配置選項
- 故障排除
- 更新方法

## 重要提醒

⚠️ **安全注意事項**：
- 永遠不要將實際的 API 金鑰提交到版本控制
- 使用 `.env` 文件管理敏感資訊
- 定期更新和輪換 API 金鑰

## 相關連結

- [Zen MCP Server 官方倉庫](https://github.com/BeehiveInnovations/zen-mcp-server)
- [MCP 協議文檔](https://modelcontextprotocol.com)
- [Claude Code CLI](https://claude.ai/code)