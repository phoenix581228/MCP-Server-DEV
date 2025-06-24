# Zen MCP 安裝錯誤修正指南

## 問題描述

原始安裝腳本中使用的套件 `@gptscript-ai/zen-mcp` 在 NPM 官方註冊表中不存在，導致安裝失敗。

### 錯誤訊息
```
404 Not Found - '@gptscript-ai/zen-mcp@latest' is not in this registry
```

## 解決方案

### 正確的套件名稱
- ❌ 錯誤：`@gptscript-ai/zen-mcp`
- ✅ 正確：`zen-mcp-server-199bio`

### 套件資訊
- NPM 頁面：https://www.npmjs.com/package/zen-mcp-server-199bio
- 版本：2.2.0
- 作者：199bio
- 授權：Apache-2.0

## 修正步驟

### 1. 更新已安裝的 Zen MCP

如果您已經安裝了舊版本，請先移除：
```bash
claude mcp remove zen
```

### 2. 手動註冊正確的套件

```bash
# 註冊到專案範圍
claude mcp add zen "npx -y zen-mcp-server-199bio@latest"

# 或註冊到使用者範圍（全域）
claude mcp add zen "npx -y zen-mcp-server-199bio@latest" -s user
```

### 3. 使用包裝腳本（可選）

如果需要設定環境變數，創建包裝腳本：

```bash
cat > ~/.claude-code-zen.sh << 'EOF'
#!/bin/bash
# Zen MCP Server 包裝腳本

# 設定環境變數
export ZEN_DEFAULT_MODEL="${ZEN_DEFAULT_MODEL:-pro}"
export ZEN_THINKING_MODE="${ZEN_THINKING_MODE:-high}"

# 執行 Zen MCP Server
exec npx -y zen-mcp-server-199bio@latest "$@"
EOF

chmod +x ~/.claude-code-zen.sh
```

然後註冊包裝腳本：
```bash
claude mcp add zen ~/.claude-code-zen.sh
```

## 驗證安裝

### 1. 檢查註冊
```bash
claude mcp list
```

### 2. 測試初始化
```bash
echo '{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2024-11-05"},"id":1}' | npx -y zen-mcp-server-199bio@latest
```

### 3. 在 Claude 中使用
```bash
claude "使用 Zen 分析這個程式碼"
```

## 更新的安裝包

所有安裝腳本已更新為使用正確的套件名稱：
- `install.sh` - 完整安裝腳本
- `quick-install.sh` - 快速安裝腳本
- `test-mcp.sh` - 測試腳本
- `zen-config-template.sh` - 配置範本

## 注意事項

1. `zen-mcp-server-199bio` 是由 199bio 維護的版本
2. 功能與原始的 Zen MCP 相同
3. 支援所有 Zen MCP 的工具和功能
4. 可能需要額外的 API 金鑰設定（取決於使用的模型）

## 相關連結

- NPM 套件頁面：https://www.npmjs.com/package/zen-mcp-server-199bio
- GitHub 儲存庫：https://github.com/199-biotechnologies/mcp-zen-plus