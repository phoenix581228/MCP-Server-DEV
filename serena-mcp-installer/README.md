# Serena MCP Server 一鍵安裝包

這是為 Claude Code CLI 設計的 Serena MCP Server 一鍵安裝包。Serena 是專為程式碼編輯和專案管理設計的 MCP 服務器，提供強大的程式碼操作和專案管理功能。

## 版本資訊
- Serena MCP 版本: 最新版本
- 支援平台: macOS, Linux
- 適用於: Claude Code CLI（非 Claude Desktop）

## 安裝需求

1. **Python 環境**
   - Python 3.8 或更高版本
   - 虛擬環境（建議）

2. **Claude Code CLI**
   - 已安裝 Claude Code CLI
   - 版本 1.0.0 或更高

3. **Git**
   - 需要 Git 來管理專案版本控制

4. **uv (Python 套件管理器)**
   - Serena 透過 uvx 執行
   - 安裝腳本會自動安裝 uv

## 快速安裝

### 方法一：線上安裝（推薦）
```bash
# 1. 解壓安裝包
tar -xzf serena-mcp-cli-installer-*.tar.gz

# 2. 進入目錄
cd serena-mcp-cli-installer

# 3. 執行安裝腳本
./install.sh
```

### 方法二：快速安裝
```bash
./quick-install.sh
```

## 功能介紹

Serena MCP 提供以下核心功能：

### 1. 檔案操作
- **read_file** - 讀取檔案內容
- **create_text_file** - 創建新檔案
- **list_dir** - 列出目錄內容
- **find_file** - 搜尋檔案

### 2. 符號操作（程式碼編輯）
- **get_symbols_overview** - 獲取程式碼符號概覽
- **find_symbol** - 查找特定符號
- **find_referencing_symbols** - 查找引用符號
- **replace_symbol_body** - 替換符號內容
- **insert_after_symbol** - 在符號後插入
- **insert_before_symbol** - 在符號前插入

### 3. 文字操作
- **replace_regex** - 正則表達式替換
- **delete_lines** - 刪除行
- **replace_lines** - 替換行
- **insert_at_line** - 在指定行插入

### 4. 專案管理
- **activate_project** - 啟動專案
- **remove_project** - 移除專案
- **switch_modes** - 切換工作模式
- **get_current_config** - 獲取當前配置

### 5. 記憶體管理
- **write_memory** - 寫入專案記憶
- **read_memory** - 讀取專案記憶
- **list_memories** - 列出所有記憶
- **delete_memory** - 刪除記憶

### 6. 智能輔助
- **think_about_collected_information** - 分析收集的資訊
- **think_about_task_adherence** - 檢查任務遵循性
- **think_about_whether_you_are_done** - 判斷任務完成度
- **summarize_changes** - 總結變更

### 7. 其他功能
- **search_for_pattern** - 搜尋模式
- **execute_shell_command** - 執行 shell 命令
- **restart_language_server** - 重啟語言服務器
- **initial_instructions** - 獲取初始指令
- **onboarding** - 專案導覽
- **prepare_for_new_conversation** - 準備新對話

## 專案配置

Serena 使用專案導向的工作方式：

### 1. 註冊專案
```bash
# 在專案目錄中
serena register-project "my-project" .
```

### 2. 啟動專案
```bash
serena activate "my-project"
```

### 3. 專案記憶
Serena 會在專案目錄中創建 `.serena/memories/` 資料夾來儲存專案相關的記憶和配置。

## 工作模式

Serena 支援多種工作模式：
- **editing** - 編輯模式（預設）
- **interactive** - 互動模式
- **planning** - 規劃模式
- **one-shot** - 單次執行模式

切換模式：
```bash
# 在 Claude 中使用
serena switch_modes ["editing", "interactive"]
```

## 配置說明

### 環境變數
```bash
# Serena 專案根目錄（可選）
export SERENA_PROJECT_ROOT="/path/to/projects"

# 預設工作模式
export SERENA_DEFAULT_MODE="editing"

# 除錯模式
export SERENA_DEBUG="false"
```

### 專案配置檔
每個專案可以有自己的 `.serena/config.json` 檔案：
```json
{
  "project_name": "my-project",
  "modes": ["editing", "interactive"],
  "language_server": "auto",
  "ignored_patterns": ["*.log", "node_modules/"]
}
```

## 使用範例

安裝完成後，您可以在 Claude Code CLI 中使用 Serena：

```bash
# 啟動專案
claude "使用 Serena 啟動 my-project 專案"

# 程式碼編輯
claude "用 Serena 將 calculateTotal 函數重構為更清晰的版本"

# 搜尋和替換
claude "使用 Serena 將所有的 'oldAPI' 替換為 'newAPI'"

# 專案記憶
claude "請 Serena 記住這個專案使用 TypeScript 和 React"
```

## 語言服務器支援

Serena 內建對多種語言服務器的支援：
- TypeScript/JavaScript
- Python
- Java
- C/C++
- Go
- Rust

語言服務器會自動根據專案類型啟動。

## 解除安裝

如需解除安裝 Serena MCP Server：

```bash
./uninstall.sh
```

或手動執行：
```bash
claude mcp remove serena
```

## 故障排除

### 常見問題

1. **語言服務器錯誤**
   - 使用 `restart_language_server` 工具
   - 檢查專案依賴是否已安裝
   - 確認檔案路徑正確

2. **專案啟動失敗**
   - 確認專案已註冊
   - 檢查專案路徑是否正確
   - 查看 `.serena/` 目錄權限

3. **記憶體無法保存**
   - 檢查 `.serena/memories/` 目錄是否存在
   - 確認有寫入權限
   - 檢查磁碟空間

4. **uv/uvx 相關問題**
   - 確認 uv 已安裝：`command -v uv`
   - 重新安裝 uv：`curl -LsSf https://astral.sh/uv/install.sh | sh`
   - 確保 PATH 包含：`export PATH="$HOME/.cargo/bin:$PATH"`

### 最佳實踐

1. **專案組織**
   - 每個專案都應該有清晰的結構
   - 使用 `.gitignore` 排除不需要的檔案
   - 定期清理專案記憶

2. **程式碼編輯**
   - 優先使用符號操作而非文字操作
   - 在修改前先讀取檔案
   - 使用 `think_about_` 工具來驗證操作

3. **記憶管理**
   - 為重要的專案決策創建記憶
   - 使用有意義的記憶名稱
   - 定期審查和更新記憶

## 授權

MIT License

## 更新日誌

### v1.0.0 (2025-01-24)
- 初始版本
- 支援 Claude Code CLI
- 完整的檔案和符號操作
- 專案記憶系統
- 多語言服務器支援
- 使用 uvx 從 GitHub 直接執行

## 技術資訊

- GitHub 專案：https://github.com/oraios/serena
- 執行方式：uvx --from git+https://github.com/oraios/serena serena-mcp-server
- MCP 協議版本：2024-11-05