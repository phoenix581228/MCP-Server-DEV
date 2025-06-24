# Serena MCP 安裝錯誤修正指南

## 問題描述

原始安裝腳本嘗試使用 `pip install serena-mcp`，但這個套件在 PyPI 上不存在，導致安裝失敗。

### 錯誤訊息
```
ERROR: Could not find a version that satisfies the requirement serena-mcp (from versions: none)
ERROR: No matching distribution found for serena-mcp
```

## 解決方案

### 正確的安裝方式
Serena MCP 不是透過 pip 安裝的，而是需要透過 uvx 從 GitHub 執行：

- ❌ 錯誤：`pip install serena-mcp`
- ✅ 正確：`uvx --from git+https://github.com/oraios/serena serena-mcp-server`

### 專案資訊
- GitHub 儲存庫：https://github.com/oraios/serena
- 執行工具：uvx (uv 的一部分)
- 協議：Model Context Protocol (MCP)

## 修正內容

### 1. 安裝腳本更新

移除了 Python pip 安裝，改為：
1. 檢查並安裝 uv/uvx
2. 創建包裝腳本使用 uvx 執行
3. 註冊包裝腳本到 Claude Code CLI

### 2. 新的依賴

現在需要安裝 uv (Rust 編寫的快速 Python 套件管理器)：
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

### 3. 包裝腳本內容

```bash
#!/bin/bash
# 確保 uv 在 PATH 中
export PATH="$HOME/.cargo/bin:$PATH"

# 執行 Serena MCP Server
exec uvx --from git+https://github.com/oraios/serena serena-mcp-server \
    --context ide-assistant \
    --project "$PROJECT_DIR" \
    "$@"
```

## 手動安裝步驟

如果自動安裝失敗，可以手動執行：

### 1. 安裝 uv
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
export PATH="$HOME/.cargo/bin:$PATH"
```

### 2. 註冊到 Claude Code CLI

直接使用 uvx 命令：
```bash
# 專案範圍
claude mcp add serena -- uvx --from git+https://github.com/oraios/serena serena-mcp-server --context ide-assistant --project $(pwd)

# 或使用包裝腳本
claude mcp add serena ~/.claude-code-serena.sh
```

## 驗證安裝

### 1. 檢查註冊
```bash
claude mcp list
```

### 2. 測試初始化
```bash
echo '{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2024-11-05"},"id":1}' | uvx --from git+https://github.com/oraios/serena serena-mcp-server --context ide-assistant --project .
```

## 注意事項

1. 首次執行時，uvx 會下載 Serena，可能需要一些時間
2. 需要網路連接來下載和執行
3. 每次執行都會檢查更新，確保使用最新版本
4. 專案路徑參數 (`--project`) 是必需的

## 相關連結

- Serena GitHub：https://github.com/oraios/serena
- uv 文檔：https://github.com/astral-sh/uv
- MCP 協議：https://modelcontextprotocol.io/

## 關鍵教訓

這個問題提醒我們：
1. 不是所有 MCP Server 都發布到 PyPI
2. 許多工具選擇直接從 GitHub 執行以保持最新
3. uvx 提供了便捷的方式來執行 Python 工具而無需安裝
4. 始終檢查官方文檔的安裝說明