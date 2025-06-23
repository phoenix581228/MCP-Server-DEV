# 任務 1：環境檢查

## 📋 任務概述
確保目標系統符合 MCP Server 部署的所有要求。

## 🎯 目標
- 驗證 macOS 版本相容性
- 檢查必要的開發工具
- 評估現有 MCP 配置
- 確認端口可用性

## 🔧 Claude Code 執行步驟

### 1. 作業系統檢查
```bash
# 檢查 macOS 版本
sw_vers -productVersion
```
**預期結果**：15.5 或更高版本
**失敗處理**：警告用戶並詢問是否繼續

### 2. 開發工具檢查

#### Homebrew
```bash
# 檢查 Homebrew
if command -v brew >/dev/null 2>&1; then
    echo "✅ Homebrew 已安裝: $(brew --version | head -1)"
else
    echo "❌ Homebrew 未安裝"
    echo "需要安裝 Homebrew"
fi
```

#### Node.js
```bash
# 檢查 Node.js
if command -v node >/dev/null 2>&1; then
    NODE_VERSION=$(node --version)
    echo "✅ Node.js 已安裝: $NODE_VERSION"
    
    # 檢查版本是否 >= 20
    MAJOR_VERSION=$(echo $NODE_VERSION | cut -d. -f1 | sed 's/v//')
    if [ $MAJOR_VERSION -lt 20 ]; then
        echo "⚠️  Node.js 版本過舊，需要 v20 或更高"
    fi
else
    echo "❌ Node.js 未安裝"
fi
```

#### Python
```bash
# 檢查 Python
if command -v python3 >/dev/null 2>&1; then
    PYTHON_VERSION=$(python3 --version)
    echo "✅ Python 已安裝: $PYTHON_VERSION"
    
    # 檢查版本是否 >= 3.9
    MINOR_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.minor}")')
    if [ $MINOR_VERSION -lt 9 ]; then
        echo "⚠️  Python 版本過舊，需要 3.9 或更高"
    fi
else
    echo "❌ Python 未安裝"
fi
```

#### Docker
```bash
# 檢查 Docker
if command -v docker >/dev/null 2>&1; then
    if docker info >/dev/null 2>&1; then
        echo "✅ Docker 已安裝並運行中: $(docker --version)"
    else
        echo "⚠️  Docker 已安裝但未運行"
        echo "請啟動 Docker Desktop"
    fi
else
    echo "❌ Docker 未安裝"
fi
```

### 3. Claude Code CLI 檢查
```bash
# 檢查 Claude CLI
if command -v claude >/dev/null 2>&1; then
    echo "✅ Claude Code CLI 已安裝"
    
    # 檢查現有 MCP 配置
    echo "📋 現有 MCP Servers："
    claude mcp list 2>/dev/null || echo "無法獲取 MCP 列表"
else
    echo "❌ Claude Code CLI 未安裝"
    echo "請先安裝 Claude Code CLI"
fi
```

### 4. 端口可用性檢查
```bash
# MCP 保留端口
MCP_PORTS=(8765 6333 5432 3000 8080 9997 1234 11434)

echo "🔍 檢查 MCP 端口可用性..."
for port in "${MCP_PORTS[@]}"; do
    if lsof -ti:$port >/dev/null 2>&1; then
        PROCESS=$(lsof -ti:$port | xargs ps -p 2>/dev/null | tail -n 1 | awk '{print $4}')
        echo "⚠️  Port $port 被占用 by: $PROCESS"
    else
        echo "✅ Port $port 可用"
    fi
done
```

### 5. 目錄權限檢查
```bash
# 檢查關鍵目錄的寫入權限
DIRS_TO_CHECK=(
    "$HOME/.claude"
    "$HOME/.config"
    "/usr/local/bin"
)

for dir in "${DIRS_TO_CHECK[@]}"; do
    if [ -w "$dir" ] 2>/dev/null; then
        echo "✅ 可寫入: $dir"
    else
        echo "⚠️  無法寫入: $dir"
    fi
done
```

## 🌳 決策樹

### 依賴缺失處理
```
缺少 Homebrew?
├─ 是 → 執行 Homebrew 安裝
│   └─ /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
└─ 否 → 繼續下一項檢查

Node.js < v20?
├─ 是 → 使用 nvm 安裝 Node.js 20
│   ├─ 安裝 nvm (如果未安裝)
│   └─ nvm install 20 && nvm use 20
└─ 否 → 繼續下一項檢查

Python < 3.9?
├─ 是 → 使用 pyenv 或 Homebrew 更新
│   └─ brew install python@3.12
└─ 否 → 繼續下一項檢查

缺少 Docker?
├─ 是 → 提示手動安裝 Docker Desktop
│   └─ 提供下載連結
└─ 否 → 檢查是否運行中
```

### 端口衝突處理
```
發現端口衝突?
├─ 是 → 識別占用的程序
│   ├─ MCP 相關程序 → 詢問是否重啟
│   └─ 非 MCP 程序 → 詢問是否停止或使用替代端口
└─ 否 → 繼續安裝
```

## 🚨 錯誤處理

### 常見錯誤及解決方案

1. **Homebrew 安裝失敗**
   - 錯誤：`Failed to connect to raw.githubusercontent.com`
   - 解決：檢查網路連線，使用鏡像源

2. **權限不足**
   - 錯誤：`Permission denied`
   - 解決：使用 sudo（謹慎）或修改目錄權限

3. **Docker 連線失敗**
   - 錯誤：`Cannot connect to the Docker daemon`
   - 解決：
     ```bash
     # macOS: 啟動 Docker Desktop
     open -a Docker
     # 等待 30 秒後重試
     ```

## 📊 輸出格式

環境檢查完成後，生成摘要報告：

```
=== 環境檢查報告 ===
作業系統: macOS 15.5 ✅
Homebrew: 4.2.7 ✅
Node.js: v20.11.0 ✅
Python: 3.12.1 ✅
Docker: 25.0.2 ✅
Claude CLI: 已安裝 ✅

端口狀態:
- 8765 (OpenMemory API): 可用 ✅
- 6333 (Qdrant): 可用 ✅
- 5432 (PostgreSQL): 被占用 ⚠️
- 3000 (Web UI): 可用 ✅
- 8080 (Perplexity): 可用 ✅
- 9997 (Xinference): 可用 ✅
- 1234 (LM Studio): 可用 ✅
- 11434 (Ollama): 可用 ✅

總體狀態: 準備就緒（有 1 個警告）
```

## ✅ 完成標準

- 所有必要工具已安裝或有安裝計劃
- 端口衝突已識別並有解決方案
- 生成完整的環境報告
- 用戶已確認繼續安裝

## 📝 給 Claude 的提醒

1. 保持輸出清晰易讀
2. 遇到問題時提供具體解決步驟
3. 不要假設用戶的技術水平
4. 重要決定前總是詢問確認
5. 將檢查結果保存到 `environment-check.log`