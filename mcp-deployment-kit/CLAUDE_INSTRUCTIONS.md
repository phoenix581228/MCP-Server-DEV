# Claude Code 執行指南

## 🤖 給 Claude Code 的重要指示

親愛的 Claude，這份文件專門為你準備。請仔細閱讀並遵循這些指示，以確保 MCP Server 部署成功。

## 📋 執行前準備

1. **理解任務範圍**
   - 你將要部署 5 個 MCP Server 到一個新的 macOS 系統
   - 這些服務將整合到 Claude Code CLI 中
   - 你需要更新目標系統的 CLAUDE.md 文件

2. **建立執行計劃**
   請使用 TodoWrite 工具建立以下任務：
   ```
   1. 環境檢查與評估
   2. 安裝系統依賴
   3. 部署 MCP Servers
   4. 配置 Claude CLI 整合
   5. 驗證安裝結果
   ```

3. **讀取所有任務文件**
   在開始前，請閱讀 `claude-tasks/` 目錄下的所有文件：
   - 01-environment-check.md
   - 02-install-dependencies.md
   - 03-deploy-services.md
   - 04-register-mcp.md
   - 05-verify-installation.md

## 🚀 執行步驟

### 步驟 1：環境評估
```bash
# 使用 Bash 工具執行
./install-with-claude.sh --check-only
```

這會檢查：
- macOS 版本
- 必要工具（Homebrew、Node.js、Python、Docker）
- 現有 MCP 配置
- 端口可用性

### 步驟 2：智能決策

根據環境檢查結果，你需要做出以下決策：

1. **依賴缺失處理**
   - 如果缺少 Homebrew → 安裝它
   - 如果 Node.js < v20 → 使用 nvm 更新
   - 如果 Python < 3.9 → 使用 pyenv 更新

2. **端口衝突解決**
   - 檢測到衝突時，記錄占用的服務
   - 詢問用戶是否要停止衝突服務
   - 或建議使用替代端口

3. **現有配置處理**
   - 如果發現已安裝的 MCP Server
   - 詢問是否要覆蓋或跳過

### 步驟 3：執行安裝

```bash
# 主安裝命令
./install-with-claude.sh --install
```

安裝過程中，請：
- 實時更新 TodoWrite 任務狀態
- 記錄每個步驟的結果到 install.log
- 遇到錯誤時立即處理

### 步驟 4：API 金鑰配置

當腳本提示輸入 API 金鑰時：
1. 提醒用戶準備所需的 API 金鑰
2. 使用安全的方式讀取（不顯示在螢幕上）
3. 儲存到 macOS Keychain

需要的 API 金鑰：
- PERPLEXITY_API_KEY
- OPENAI_API_KEY（用於 Zen）
- ANTHROPIC_API_KEY（用於 Zen）
- 其他服務特定的金鑰

### 步驟 5：更新 CLAUDE.md

自動將 MCP 開發原則加入目標系統的 `~/.claude/CLAUDE.md`：
```bash
./lib/claude_md_updater.sh
```

## 🛠️ 錯誤處理策略

### 1. 常見錯誤及解決方案

**端口被占用**
```bash
# 錯誤：Port 3000 already in use
# 解決：
lsof -ti:3000 | xargs kill -9
# 或使用替代端口
export MCP_OPENMEMORY_PORT=3001
```

**依賴版本不符**
```bash
# 錯誤：Node.js version too old
# 解決：
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
nvm install 20
nvm use 20
```

**Docker 未啟動**
```bash
# 錯誤：Cannot connect to Docker daemon
# 解決：
open -a Docker
# 等待 Docker 啟動後重試
```

### 2. 智能錯誤恢復

當遇到未預期的錯誤時：
1. 使用 WebSearch 搜尋錯誤訊息
2. 查看 `templates/claude_context/troubleshooting.md`
3. 嘗試相關的替代方案
4. 記錄解決方案供未來參考

## 📊 進度追蹤

請在執行過程中保持進度更新：

```bash
# 腳本會自動輸出格式化的進度
[TASK:environment-check] Status: completed
[TASK:install-homebrew] Status: in_progress
[TASK:deploy-perplexity] Status: pending
```

## 🔍 驗證檢查

安裝完成後，執行完整驗證：

```bash
# 自動驗證
./verification/test-claude-integration.sh

# 手動檢查
claude mcp list
```

預期結果：
- 5 個 MCP Server 全部顯示為 "registered"
- 所有服務回應正常
- 無端口衝突警告

## 💡 特殊指令

### 使用 Task 工具
當需要搜尋複雜資訊時（如查找特定錯誤的解決方案），使用 Task 工具：
```
Task: 搜尋 "MCP Server JSON Schema compatibility error" 的解決方案
```

### 保持上下文
定期保存執行上下文：
```bash
./lib/save_claude_context.sh
```

### 生成報告
安裝完成後，生成詳細報告：
```bash
./lib/generate_installation_report.sh > installation_report.md
```

## ⚠️ 重要提醒

1. **不要跳過任何檢查步驟**
2. **遇到問題時先嘗試自行解決**
3. **保持詳細的日誌記錄**
4. **敏感資訊絕不記錄在日誌中**
5. **完成後驗證每個服務的功能**

## 🎯 成功標準

安裝成功的標誌：
- ✅ 所有 5 個 MCP Server 成功註冊
- ✅ `claude mcp list` 顯示所有服務
- ✅ 測試命令回應正常
- ✅ CLAUDE.md 包含 MCP 開發原則
- ✅ 無錯誤日誌

祝你執行順利！如有任何疑問，請參考任務文件或使用 WebSearch 尋找答案。

---

*記住：你是在幫助用戶在新電腦上快速恢復完整的 MCP 開發環境。細心、耐心、智能是成功的關鍵。*