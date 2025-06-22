# Serena MCP Server

Serena 是一個強大的編碼代理工具包，透過 Model Context Protocol (MCP) 提供語意化程式碼檢索和編輯功能。與其他依賴純文字分析的 MCP 伺服器不同，Serena 基於 Language Server Protocol (LSP) 提供深度的程式碼理解能力。

## 主要特點

- **語意化程式碼分析**：基於 LSP 的符號理解，而非純文字搜尋
- **多語言支援**：
  - 直接支援：Python、Java、TypeScript
  - 間接支援：Ruby、Go、C#
- **豐富的工具集**：50+ 個工具，涵蓋程式碼導航、重構、記憶管理等
- **免費開源**：無需 API Key 或訂閱費用
- **多種部署方式**：本地安裝、Docker、uvx 直接執行

## 快速開始

### 方法一：使用 uvx（推薦）

最簡單的方式，無需本地安裝：

```bash
# 直接執行 Serena MCP Server
uvx --from git+https://github.com/oraios/serena serena-mcp-server

# 註冊到 Claude Code CLI
claude mcp add serena -- uvx --from git+https://github.com/oraios/serena serena-mcp-server --context ide-assistant --project $(pwd)
```

### 方法二：Docker 部署

使用 Docker 獲得隔離的執行環境：

```bash
# 執行 Serena Docker 容器
docker run --rm -i --network host \
  -v /path/to/your/projects:/workspaces/projects \
  ghcr.io/oraios/serena:latest \
  serena-mcp-server --transport stdio

# 註冊到 Claude Code CLI
claude mcp add serena -- docker run --rm -i --network host \
  -v "$(pwd):/workspace" \
  ghcr.io/oraios/serena:latest \
  serena-mcp-server --transport stdio
```

### 方法三：本地安裝

詳細安裝步驟請參考 [docs/INSTALLATION.md](docs/INSTALLATION.md)

## 核心功能

### 程式碼導航與搜尋
- `find_symbol` - 全域或區域搜尋符號
- `get_symbols_overview` - 獲取檔案或目錄的頂層符號概覽
- `find_referencing_symbols` - 尋找引用特定符號的位置
- `search_for_pattern` - 在專案中搜尋模式

### 程式碼編輯與重構
- `replace_symbol_body` - 替換符號的完整定義
- `insert_before_symbol` / `insert_after_symbol` - 在符號前後插入內容
- `replace_lines` - 替換指定行範圍的內容
- `delete_lines` - 刪除指定行範圍

### 專案管理
- `activate_project` - 啟動專案
- `onboarding` - 執行專案初始化（識別結構、測試、建置等）
- `check_onboarding_performed` - 檢查是否已完成初始化

### 記憶管理
- `write_memory` - 儲存命名記憶供未來參考
- `read_memory` - 讀取特定記憶
- `list_memories` - 列出所有記憶
- `delete_memory` - 刪除記憶

### 思考工具
- `think_about_collected_information` - 評估收集資訊的完整性
- `think_about_task_adherence` - 確認是否仍在正確的任務軌道上
- `think_about_whether_you_are_done` - 判斷任務是否真正完成

## 配置

### 基本配置

1. 複製配置模板：
```bash
cp serena_config.template.yml serena_config.yml
```

2. 為專案建立配置：
```bash
mkdir -p /path/to/your/project/.serena
cp project.template.yml /path/to/your/project/.serena/project.yml
```

### Claude Code CLI 整合

在 Claude Code CLI 中註冊 Serena：

```bash
# 使用 IDE 助手上下文（推薦）
claude mcp add serena -- [serena-mcp-server-command] --context ide-assistant --project $(pwd)

# 基本註冊
claude mcp add serena -- [serena-mcp-server-command]
```

詳細配置說明請參考 [docs/CONFIGURATION.md](docs/CONFIGURATION.md)

## 使用範例

### 搜尋符號
```
使用 find_symbol 工具搜尋名為 "UserService" 的類別
```

### 重構程式碼
```
使用 replace_symbol_body 工具更新 login 方法的實作
```

### 專案分析
```
使用 get_symbols_overview 工具分析 src 目錄的結構
```

## 進階功能

### 上下文和模式

Serena 支援不同的操作上下文和模式：

- **上下文**（Context）：影響初始系統提示和可用工具
  - `ide-assistant`：IDE 整合優化
  - 自訂上下文：根據需求定義

- **模式**（Mode）：動態調整行為
  - `planning`：規劃模式
  - `no-onboarding`：跳過自動初始化
  - 自訂模式：擴展功能

### 索引專案

為大型專案建立索引以提升效能：

```bash
# 使用 uvx
uvx --from git+https://github.com/oraios/serena index-project

# 使用本地安裝
uv run --directory /path/to/serena index-project
```

## 故障排除

### 常見問題

1. **Language Server 未啟動**
   - 確保專案包含支援的語言檔案
   - 檢查 `.serena/project.yml` 中的語言設定

2. **符號搜尋無結果**
   - 執行 `restart_language_server` 工具
   - 確認檔案已儲存且語法正確

3. **Docker 權限問題**
   - 確保掛載的目錄有正確的讀寫權限
   - 使用絕對路徑而非相對路徑

詳細故障排除請參考 [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)

## 相關資源

- [官方 GitHub](https://github.com/oraios/serena)
- [工具參考文檔](docs/TOOLS_REFERENCE.md)
- [整合指南](docs/INTEGRATION.md)
- [MCP 協議規範](https://modelcontextprotocol.io/)

## 授權

Serena 是開源軟體，詳細授權資訊請參考官方倉庫。

---

此文檔是 MCP Server Development 專案的一部分，專注於整合和使用 Serena MCP Server。