# Zen MCP Server 一鍵安裝包

這是為 Claude Code CLI 設計的 Zen MCP Server 一鍵安裝包。Zen MCP 提供深度分析、程式碼審查、除錯、測試生成等強大功能。

## 版本資訊
- Zen MCP 版本: 最新版本
- 支援平台: macOS, Linux
- 適用於: Claude Code CLI（非 Claude Desktop）

## 安裝需求

1. **Python 環境**
   - Python 3.8 或更高版本
   - 虛擬環境（建議）

2. **Claude Code CLI**
   - 已安裝 Claude Code CLI
   - 版本 1.0.0 或更高

3. **API 金鑰（可選）**
   - 某些功能可能需要額外的 API 金鑰
   - 安裝時會提供詳細說明

## 快速安裝

### 方法一：線上安裝（推薦）
```bash
# 1. 解壓安裝包
tar -xzf zen-mcp-cli-installer-*.tar.gz

# 2. 進入目錄
cd zen-mcp-cli-installer

# 3. 執行安裝腳本
./install.sh
```

### 方法二：離線安裝
如果您的環境無法連接網路，可以使用離線安裝：
```bash
./install-offline.sh
```

## 功能介紹

Zen MCP 提供以下強大工具：

### 1. 深度分析 (thinkdeep)
- 多階段工作流程進行複雜問題分析
- 系統性假設測試
- 專家驗證
- 適用於：架構決策、複雜錯誤、性能挑戰、安全分析

### 2. 程式碼審查 (codereview)
- 逐步程式碼審查與專家分析
- 安全審計
- 性能分析
- 架構評估
- 程式碼品質評估

### 3. 除錯分析 (debug)
- 系統性自我調查
- 根本原因分析
- 適用於：複雜錯誤、神秘錯誤、性能問題、競態條件

### 4. 測試生成 (testgen)
- 創建全面的測試套件
- 邊緣案例覆蓋
- 框架特定測試
- 支援測試模式

### 5. 重構分析 (refactor)
- 程式碼異味檢測
- 分解規劃
- 現代化機會
- 組織改進

### 6. 程式碼追蹤 (tracer)
- 方法執行流分析
- 依賴映射
- 呼叫鏈追蹤
- 結構關係分析

### 7. 通用聊天 (chat)
- AI 模型作為思考夥伴
- 協作腦力激盪
- 驗證方法
- 探索替代方案

### 8. 多模型共識 (consensus)
- 從多個 AI 模型收集不同觀點
- 驗證可行性評估
- 全面觀點

## 模型支援

Zen MCP 支援多種 AI 模型：

- **flash**: 超快速（1M 上下文）- 快速分析、簡單查詢
- **pro**: 深度推理 + 思考模式（1M 上下文）- 複雜問題、架構、深度分析
- **o3**: 強大推理（200K 上下文）- 邏輯問題、程式碼生成
- **o3-mini**: 快速 O3 變體（200K 上下文）- 平衡性能/速度
- **o3-pro**: 專業級推理（200K 上下文）- 極複雜問題
- **grok**: GROK-3（131K 上下文）- X.AI 的進階推理模型

## 配置說明

### 環境變數設定
安裝後，您可能需要設定以下環境變數：

```bash
# 基本配置（可選）
export ZEN_DEFAULT_MODEL="pro"
export ZEN_THINKING_MODE="high"

# API 金鑰（如果需要）
export ANTHROPIC_API_KEY="your-key"
export OPENAI_API_KEY="your-key"
```

### 模型選擇建議
- 簡單查詢：使用 `flash`
- 標準開發：使用 `pro`（預設）
- 複雜分析：使用 `o3` 或 `grok`
- 極限挑戰：使用 `o3-pro`（注意成本）

## 使用範例

安裝完成後，您可以在 Claude Code CLI 中使用 Zen MCP：

```bash
# 深度分析
claude "使用 Zen 深度分析這個效能問題"

# 程式碼審查
claude "請用 Zen 審查 src/api.js 的程式碼"

# 除錯
claude "用 Zen debug 找出為什麼登入功能失敗"

# 測試生成
claude "使用 Zen 為 UserService 類別生成測試"
```

## 解除安裝

如需解除安裝 Zen MCP Server：

```bash
./uninstall.sh
```

或手動執行：
```bash
claude mcp remove zen
```

## 故障排除

### 常見問題

1. **安裝失敗**
   - 確認 Python 版本：`python3 --version`
   - 檢查虛擬環境：`which python3`
   - 查看安裝日誌：`cat install.log`

2. **MCP 註冊失敗**
   - 確認 Claude Code CLI 已安裝
   - 檢查現有 MCP：`claude mcp list`
   - 重新註冊：`claude mcp add zen "npx -y @gptscript-ai/zen-mcp"`

3. **工具無法使用**
   - 檢查 MCP 狀態：`ps aux | grep zen-mcp`
   - 查看錯誤日誌：`tail -f /tmp/zen-mcp.log`

### 獲取幫助

- NPM 套件: https://www.npmjs.com/package/zen-mcp-server-199bio
- GitHub: https://github.com/199-biotechnologies/mcp-zen-plus

## 授權

MIT License

## 更新日誌

### v1.0.0 (2025-01-24)
- 初始版本
- 支援 Claude Code CLI
- 自動虛擬環境檢測
- 完整工具集整合