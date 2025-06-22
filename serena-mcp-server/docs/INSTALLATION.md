# Serena MCP Server 安裝指南

本文檔提供 Serena MCP Server 的詳細安裝說明，涵蓋多種安裝方式。

## 系統需求

### 基本需求
- **作業系統**：Linux、macOS、Windows (WSL)
- **Python**：3.9 或更高版本（本地安裝時需要）
- **網路**：能夠存取 GitHub 和 Docker Hub

### 語言支援需求
根據您要分析的程式語言，需要安裝對應的 Language Server：

| 語言 | Language Server | 安裝方式 |
|------|----------------|----------|
| Python | Pylsp | `pip install python-lsp-server` |
| Java | Eclipse JDT.LS | 自動下載 |
| TypeScript | TypeScript Language Server | `npm install -g typescript-language-server` |
| Ruby | Solargraph | `gem install solargraph` |
| Go | gopls | `go install golang.org/x/tools/gopls@latest` |
| C# | OmniSharp | 自動下載 |

## 安裝方式

### 方法一：使用 uvx（最簡單）

uvx 允許您直接從 GitHub 執行 Serena，無需本地安裝。

#### 1. 安裝 uv

```bash
# macOS/Linux
curl -LsSf https://astral.sh/uv/install.sh | sh

# Windows
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
```

#### 2. 執行 Serena

```bash
# 直接執行最新版本
uvx --from git+https://github.com/oraios/serena serena-mcp-server

# Windows 用戶使用
uvx --from git+https://github.com/oraios/serena serena-mcp-server.exe
```

### 方法二：Docker 安裝

Docker 提供了隔離的執行環境，適合生產環境使用。

#### 1. 安裝 Docker

請參考 [Docker 官方安裝指南](https://docs.docker.com/get-docker/)

#### 2. 拉取 Serena 映像

```bash
docker pull ghcr.io/oraios/serena:latest
```

#### 3. 執行容器

```bash
docker run --rm -i \
  --network host \
  -v "$(pwd):/workspace" \
  ghcr.io/oraios/serena:latest \
  serena-mcp-server --transport stdio
```

### 方法三：本地安裝

適合需要修改或擴展 Serena 功能的開發者。

#### 1. 克隆倉庫

```bash
git clone https://github.com/oraios/serena
cd serena
```

#### 2. 安裝 uv（如果尚未安裝）

參考方法一的步驟 1

#### 3. 設置虛擬環境

```bash
# 創建虛擬環境
uv venv

# 啟動虛擬環境
# Linux/macOS
source .venv/bin/activate

# Windows
.venv\Scripts\activate
```

#### 4. 安裝依賴

```bash
# 安裝所有額外功能
uv pip install --all-extras -r pyproject.toml -e .

# 或者選擇性安裝
uv pip install -e ".[agno,anthropic]"
```

#### 5. 驗證安裝

```bash
uv run serena-mcp-server --help
```

## 配置初始化

### 1. 創建主配置檔案

```bash
# 複製配置模板
cp serena_config.template.yml serena_config.yml

# 編輯配置（可選）
nano serena_config.yml
```

### 2. 創建專案配置

每個專案需要自己的配置檔案：

```bash
# 在專案根目錄創建 .serena 目錄
mkdir -p /path/to/your/project/.serena

# 複製專案配置模板
cp /path/to/serena/myproject.template.yml /path/to/your/project/.serena/project.yml

# 編輯專案配置
nano /path/to/your/project/.serena/project.yml
```

專案配置範例：

```yaml
# project.yml
name: "my-project"
language: "python"  # 或 java, typescript 等
description: "My awesome project"
```

## 整合到 Claude Code CLI

### 基本整合

```bash
# 使用 uvx
claude mcp add serena -- uvx --from git+https://github.com/oraios/serena serena-mcp-server

# 使用 Docker
claude mcp add serena -- docker run --rm -i --network host -v "$(pwd):/workspace" ghcr.io/oraios/serena:latest serena-mcp-server --transport stdio

# 使用本地安裝
claude mcp add serena -- /path/to/uv run --directory /path/to/serena serena-mcp-server
```

### 進階整合（推薦）

使用 IDE 助手上下文和專案路徑：

```bash
claude mcp add serena -- [serena-command] --context ide-assistant --project $(pwd)
```

## 索引專案（可選但推薦）

對於大型專案，建立索引可以顯著提升效能：

```bash
# 在專案目錄執行
uvx --from git+https://github.com/oraios/serena index-project

# 或使用本地安裝
uv run --directory /path/to/serena index-project
```

## 驗證安裝

### 1. 測試 MCP 連線

```bash
# 列出已註冊的 MCP 服務
claude mcp list

# 應該看到 serena 在列表中
```

### 2. 測試基本功能

在 Claude 中測試：

```
請使用 get_current_config 工具查看 Serena 的當前配置
```

### 3. 測試專案功能

```
請使用 get_active_project 工具查看當前啟用的專案
```

## 常見問題

### 1. uv 命令找不到

確保將 uv 添加到 PATH：

```bash
# 添加到 ~/.bashrc 或 ~/.zshrc
export PATH="$HOME/.local/bin:$PATH"
```

### 2. Docker 權限錯誤

確保當前用戶在 docker 群組中：

```bash
sudo usermod -aG docker $USER
# 登出後重新登入
```

### 3. Language Server 啟動失敗

檢查對應的 Language Server 是否已安裝：

```bash
# Python
which pylsp

# TypeScript
which typescript-language-server

# 如果未安裝，參考系統需求章節安裝
```

## 下一步

- 閱讀 [配置指南](CONFIGURATION.md) 了解詳細配置選項
- 查看 [工具參考](TOOLS_REFERENCE.md) 了解所有可用工具
- 參考 [整合指南](INTEGRATION.md) 深入了解 Claude 整合

---

如有問題，請參考 [故障排除指南](TROUBLESHOOTING.md) 或訪問 [Serena GitHub Issues](https://github.com/oraios/serena/issues)。