# 任務 2：安裝系統依賴

## 📋 任務概述
根據環境檢查結果，安裝缺失的系統依賴。

## 🎯 目標
- 安裝或更新必要的開發工具
- 配置正確的環境變數
- 確保所有依賴版本符合要求

## 🔧 Claude Code 執行步驟

### 1. Homebrew 安裝（如需要）
```bash
# 檢查並安裝 Homebrew
if ! command -v brew >/dev/null 2>&1; then
    echo "📦 安裝 Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # 配置 PATH (Apple Silicon)
    if [[ $(uname -m) == "arm64" ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
fi
```

### 2. Node.js 安裝/更新
```bash
# 使用 nvm 管理 Node.js
if ! command -v nvm >/dev/null 2>&1; then
    echo "📦 安裝 nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
    
    # 載入 nvm
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
fi

# 安裝 Node.js 20
nvm install 20
nvm use 20
nvm alias default 20

# 驗證安裝
node --version
npm --version
```

### 3. Python 更新（如需要）
```bash
# 使用 Homebrew 安裝 Python 3.12
if ! python3 -c "import sys; exit(0 if sys.version_info >= (3, 9) else 1)" 2>/dev/null; then
    echo "📦 更新 Python..."
    brew install python@3.12
    
    # 建立符號連結
    brew link python@3.12
    
    # 更新 pip
    python3 -m pip install --upgrade pip
fi

# 安裝必要的 Python 套件
python3 -m pip install --user pipx
python3 -m pipx ensurepath
```

### 4. Docker Desktop 安裝檢查
```bash
# Docker 需要手動安裝
if ! command -v docker >/dev/null 2>&1; then
    echo "❌ Docker Desktop 需要手動安裝"
    echo "請訪問: https://www.docker.com/products/docker-desktop/"
    echo ""
    echo "安裝步驟："
    echo "1. 下載 Docker Desktop for Mac"
    echo "2. 打開下載的 .dmg 文件"
    echo "3. 拖動 Docker 到 Applications"
    echo "4. 啟動 Docker Desktop"
    echo ""
    read -p "Docker 安裝完成後按 Enter 繼續..."
    
    # 再次檢查
    if docker info >/dev/null 2>&1; then
        echo "✅ Docker 已成功安裝並運行"
    else
        echo "⚠️  Docker 似乎未正常運行，請檢查"
    fi
fi
```

### 5. 其他必要工具
```bash
# Git（通常已預裝）
if ! command -v git >/dev/null 2>&1; then
    brew install git
fi

# jq（JSON 處理工具）
if ! command -v jq >/dev/null 2>&1; then
    echo "📦 安裝 jq..."
    brew install jq
fi

# wget（某些腳本可能需要）
if ! command -v wget >/dev/null 2>&1; then
    echo "📦 安裝 wget..."
    brew install wget
fi
```

### 6. 全域 npm 套件
```bash
# 安裝常用的全域套件
echo "📦 安裝全域 npm 套件..."

# npm 套件管理工具
npm install -g npm-check-updates

# TypeScript（某些 MCP Server 可能需要）
npm install -g typescript

# PM2（進程管理，可選）
npm install -g pm2
```

## 🌳 決策樹

### 安裝失敗處理
```
Homebrew 安裝失敗?
├─ 網路問題 → 使用中國鏡像
│   └─ /bin/bash -c "$(curl -fsSL https://gitee.com/cunkai/HomebrewCN/raw/master/Homebrew.sh)"
├─ 權限問題 → 修復目錄權限
│   └─ sudo chown -R $(whoami) /usr/local/*
└─ 其他錯誤 → 查看官方故障排除

Node.js 安裝失敗?
├─ nvm 未正確載入 → 手動 source 配置
│   └─ source ~/.nvm/nvm.sh
├─ 下載超時 → 使用淘寶鏡像
│   └─ NVM_NODEJS_ORG_MIRROR=https://npmmirror.com/mirrors/node nvm install 20
└─ 權限問題 → 檢查 ~/.nvm 目錄

Docker 啟動失敗?
├─ 資源不足 → 檢查磁碟空間
├─ 權限問題 → 將用戶加入 docker 群組
└─ 系統相容性 → 確認 macOS 版本
```

## 📊 進度追蹤

在安裝過程中更新進度：
```bash
# 範例輸出
[TASK:install-homebrew] Status: completed
[TASK:install-nodejs] Status: in_progress
[TASK:install-python] Status: pending
[TASK:install-docker] Status: pending
```

## 🚨 錯誤處理

### 常見問題解決

1. **SSL 證書錯誤**
   ```bash
   # 暫時忽略（不推薦用於生產環境）
   export NODE_TLS_REJECT_UNAUTHORIZED=0
   # 或更新證書
   brew install ca-certificates
   ```

2. **npm 權限錯誤**
   ```bash
   # 修復 npm 全域目錄權限
   mkdir ~/.npm-global
   npm config set prefix '~/.npm-global'
   echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.zshrc
   source ~/.zshrc
   ```

3. **Python pip 警告**
   ```bash
   # 使用虛擬環境避免系統 Python 衝突
   python3 -m venv ~/mcp-venv
   source ~/mcp-venv/bin/activate
   ```

## 📝 環境變數配置

創建或更新 shell 配置文件：
```bash
# 檢測使用的 shell
SHELL_RC="$HOME/.zshrc"
if [ "$SHELL" = "/bin/bash" ]; then
    SHELL_RC="$HOME/.bashrc"
fi

# 添加必要的環境變數
cat >> "$SHELL_RC" << 'EOF'

# MCP Server Development Environment
export MCP_DEV_HOME="$HOME/mcp-deployment-kit"
export NODE_OPTIONS="--max-old-space-size=4096"

# Homebrew (Apple Silicon)
if [[ $(uname -m) == "arm64" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Python
export PATH="$HOME/Library/Python/3.12/bin:$PATH"

EOF

# 重新載入配置
source "$SHELL_RC"
```

## ✅ 完成標準

- ✅ Homebrew 已安裝並可用
- ✅ Node.js 20+ 已安裝
- ✅ Python 3.9+ 已安裝
- ✅ Docker Desktop 已安裝（或用戶確認跳過）
- ✅ 必要的輔助工具已安裝
- ✅ 環境變數已正確配置

## 📋 驗證安裝

執行驗證腳本：
```bash
echo "=== 依賴安裝驗證 ==="
echo "Homebrew: $(brew --version | head -1)"
echo "Node.js: $(node --version)"
echo "npm: $(npm --version)"
echo "Python: $(python3 --version)"
echo "Docker: $(docker --version 2>/dev/null || echo 'Not installed')"
echo "Git: $(git --version)"
echo "jq: $(jq --version)"
```

## 💡 給 Claude 的提醒

1. 安裝過程可能需要較長時間，保持耐心
2. 某些步驟可能需要用戶輸入密碼
3. 網路問題是最常見的失敗原因
4. 記錄所有安裝的版本號
5. 保存安裝日誌到 `dependencies-install.log`