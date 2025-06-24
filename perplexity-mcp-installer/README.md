# Perplexity Custom MCP Server for Claude Code CLI 一鍵安裝包

## 🚨 重要提醒

**本安裝包專為 Claude Code CLI 設計，禁止用於 Claude Desktop！**

## 📋 系統需求

- Python 3.8+ （需在虛擬環境中）
- Node.js 14+
- npm 6+
- Claude Code CLI 已安裝
- macOS/Linux 系統

## 🚀 快速開始

### 1. 下載安裝包

```bash
git clone <repository-url>
cd perplexity-mcp-installer
```

### 2. 賦予執行權限

```bash
chmod +x install.sh uninstall.sh
```

### 3. 執行安裝

```bash
./install.sh
```

安裝腳本會自動：
- ✅ 檢查虛擬環境
- ✅ 驗證 Python/pip 版本
- ✅ 檢查 Claude Code CLI
- ✅ 安裝 Python 套件
- ✅ 創建包裝腳本
- ✅ 註冊到 Claude Code CLI

## 🔑 API Key 設定

### 獲取 API Key
1. 訪問 https://www.perplexity.ai/settings/api
2. 創建新的 API Key
3. 複製 Key

### 設定方式

#### 方式一：安裝時設定
安裝腳本會提示輸入 API Key

#### 方式二：手動設定
```bash
export PERPLEXITY_API_KEY='your-api-key-here'
```

#### 方式三：永久設定
添加到 `~/.zshrc` 或 `~/.bashrc`：
```bash
echo "export PERPLEXITY_API_KEY='your-api-key-here'" >> ~/.zshrc
source ~/.zshrc
```

## 🎯 使用方法

### 基本使用
```bash
claude "搜尋最新的 React 19 特性"
```

### 切換模型
```bash
# 快速模式
export PERPLEXITY_MODEL='sonar'

# 專業模式（預設）
export PERPLEXITY_MODEL='sonar-pro'

# 深度研究模式
export PERPLEXITY_MODEL='sonar-deep-research'
```

### 查看已安裝的 MCP Servers
```bash
claude mcp list
```

## 🔧 故障排除

### 問題：找不到虛擬環境

**解決方案**：
1. 確認已激活虛擬環境：
   ```bash
   source /path/to/venv/bin/activate
   ```

2. 或使用共用虛擬環境：
   ```bash
   source ~/projects/bin/activate
   ```

### 問題：API Key 錯誤

**解決方案**：
1. 檢查環境變數：
   ```bash
   echo $PERPLEXITY_API_KEY
   ```

2. 重新設定：
   ```bash
   export PERPLEXITY_API_KEY='correct-key'
   ```

### 問題：JSON Schema 錯誤

**解決方案**：
如果全域註冊失敗，安裝腳本會自動退回到專案範圍註冊。

### 問題：找不到 Claude 命令

**解決方案**：
安裝 Claude Code CLI：
```bash
npm install -g @anthropic-ai/claude-cli
```

## 📦 安裝內容

安裝包會創建以下文件：
- `~/.claude-code-perplexity.sh` - MCP Server 包裝腳本
- Python 套件 `perplexity-mcp-custom` 安裝到虛擬環境

## 🗑️ 卸載

```bash
./uninstall.sh
```

卸載腳本會：
- 從 Claude Code CLI 移除註冊
- 刪除包裝腳本
- 卸載 Python 套件
- 提示清理環境變數

## 📝 環境檢查功能

安裝腳本包含完整的環境檢查：

1. **虛擬環境檢測**
   - 檢查 `$VIRTUAL_ENV`
   - 搜尋 `venv/` 和 `.venv/`
   - 檢查共用環境 `~/projects`

2. **Python 環境驗證**
   - 使用虛擬環境中的 python3/pip3
   - 驗證版本相容性

3. **依賴檢查**
   - Node.js/npm
   - Claude Code CLI
   - Git（可選）

## 🔒 安全注意事項

1. **API Key 安全**
   - 不要將 API Key 提交到版本控制
   - 使用環境變數而非硬編碼
   - 定期更換 API Key

2. **虛擬環境隔離**
   - 始終在虛擬環境中安裝
   - 避免污染系統 Python

## 📄 授權

MIT License

## 🤝 貢獻

歡迎提交 Issue 和 Pull Request！

## 📞 支援

如遇到問題，請：
1. 查看故障排除章節
2. 提交 Issue 到專案倉庫
3. 提供詳細的錯誤訊息和環境資訊