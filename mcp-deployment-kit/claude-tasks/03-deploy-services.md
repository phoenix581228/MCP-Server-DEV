# 任務 3：部署 MCP Services

## 📋 任務概述
部署五個 MCP Server 到目標系統。

## 🎯 目標
- 安裝每個 MCP Server 的必要文件
- 配置環境變數和 API 金鑰  
- 建立包裝腳本（如需要）
- 確保服務可以正常啟動

## 🔧 Claude Code 執行步驟

### 1. Perplexity MCP Custom 部署

#### 檢查現有安裝
```bash
# 檢查是否已安裝
if claude mcp list | grep -q "perplexity"; then
    echo "⚠️  Perplexity MCP 已存在"
    # 詢問是否要重新安裝
fi
```

#### 創建包裝腳本
```bash
# 創建 Perplexity 包裝腳本
cat > ~/.claude-code-perplexity.sh << 'EOF'
#!/bin/bash
# Perplexity MCP 包裝腳本

# 從 Keychain 讀取 API 金鑰
export PERPLEXITY_API_KEY=$(security find-generic-password \
    -a "mcp-deployment" \
    -s "PERPLEXITY_API_KEY" \
    -w 2>/dev/null)

if [ -z "$PERPLEXITY_API_KEY" ]; then
    echo "錯誤：未找到 Perplexity API 金鑰" >&2
    echo "請先設定 API 金鑰：" >&2
    echo "security add-generic-password -a 'mcp-deployment' -s 'PERPLEXITY_API_KEY' -w 'your-key'" >&2
    exit 1
fi

# 執行 Perplexity MCP
exec npx -y @jschuller/perplexity-mcp@latest
EOF

chmod +x ~/.claude-code-perplexity.sh
```

### 2. Zen MCP Server 部署

#### 克隆或下載 Zen MCP
```bash
# 創建 MCP 目錄
mkdir -p ~/mcp-servers
cd ~/mcp-servers

# 克隆 Zen MCP Server
if [ ! -d "zen-mcp-server" ]; then
    git clone https://github.com/BeehiveInnovations/zen-mcp-server.git
    cd zen-mcp-server
    
    # 安裝依賴
    pip3 install -r requirements.txt
fi
```

#### 配置 Zen MCP
```bash
# 創建配置文件
cat > ~/mcp-servers/zen-mcp-server/.env << EOF
# Zen MCP Server 配置
OPENAI_API_KEY=$(security find-generic-password -a "mcp-deployment" -s "OPENAI_API_KEY" -w 2>/dev/null)
ANTHROPIC_API_KEY=$(security find-generic-password -a "mcp-deployment" -s "ANTHROPIC_API_KEY" -w 2>/dev/null)
EOF
```

### 3. OpenMemory MCP 部署

#### Docker Compose 設置
```bash
# 創建 OpenMemory 目錄
mkdir -p ~/mcp-servers/openmemory
cd ~/mcp-servers/openmemory

# 創建 docker-compose.yml
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_USER: openmemory
      POSTGRES_PASSWORD: openmemory123
      POSTGRES_DB: openmemory
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  qdrant:
    image: qdrant/qdrant
    ports:
      - "6333:6333"
    volumes:
      - qdrant_data:/qdrant/storage

  openmemory:
    image: openmemory/server:latest
    depends_on:
      - postgres
      - qdrant
    environment:
      DATABASE_URL: postgresql://openmemory:openmemory123@postgres:5432/openmemory
      QDRANT_URL: http://qdrant:6333
      API_PORT: 8765
    ports:
      - "8765:8765"
      - "3000:3000"

volumes:
  postgres_data:
  qdrant_data:
EOF
```

#### 啟動檢查
```bash
# 檢查 Docker 是否運行
if ! docker info >/dev/null 2>&1; then
    echo "❌ Docker 未運行，請啟動 Docker Desktop"
    open -a Docker
    echo "等待 Docker 啟動..."
    sleep 10
fi

# 啟動服務
docker-compose up -d
```

### 4. Serena MCP Server 部署

```bash
# Serena 安裝
cd ~/mcp-servers
if [ ! -d "serena" ]; then
    git clone https://github.com/oraios/serena.git
    cd serena
    
    # Python 環境設置
    python3 -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt
fi

# 創建執行腳本
cat > ~/mcp-servers/serena/run-serena.sh << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
source venv/bin/activate
exec python -m serena.mcp_server
EOF

chmod +x ~/mcp-servers/serena/run-serena.sh
```

### 5. Task Master MCP 部署

```bash
# Task Master 配置
mkdir -p ~/mcp-servers/taskmaster
cd ~/mcp-servers/taskmaster

# 創建配置文件
cat > .env << EOF
# Task Master 配置
OPENAI_API_KEY=$(security find-generic-password -a "mcp-deployment" -s "OPENAI_API_KEY" -w 2>/dev/null)
ANTHROPIC_API_KEY=$(security find-generic-password -a "mcp-deployment" -s "ANTHROPIC_API_KEY" -w 2>/dev/null)
PERPLEXITY_API_KEY=$(security find-generic-password -a "mcp-deployment" -s "PERPLEXITY_API_KEY" -w 2>/dev/null)
EOF

# 安裝 Task Master（假設使用 npm 包）
npm install -g @eyaltoledano/claude-task-master
```

## 🔑 API 金鑰設置

### 使用 macOS Keychain
```bash
# 設置 API 金鑰的輔助函數
set_api_key() {
    local service_name=$1
    local key_name=$2
    
    echo "請輸入 $key_name："
    read -s api_key
    echo
    
    security add-generic-password \
        -a "mcp-deployment" \
        -s "$key_name" \
        -w "$api_key" \
        -U
    
    echo "✅ $key_name 已安全儲存"
}

# 收集所需的 API 金鑰
echo "🔑 設置 API 金鑰..."
set_api_key "Perplexity" "PERPLEXITY_API_KEY"
set_api_key "OpenAI" "OPENAI_API_KEY"
set_api_key "Anthropic" "ANTHROPIC_API_KEY"
```

## 🌳 決策樹

### 服務部署失敗處理
```
部署失敗?
├─ 網路問題 → 重試或使用代理
├─ 權限問題 → 修復文件權限
├─ 依賴衝突 → 使用虛擬環境隔離
└─ 配置錯誤 → 檢查環境變數

Docker 服務啟動失敗?
├─ 端口被占用 → 停止衝突服務或更改端口
├─ 資源不足 → 檢查磁碟空間和記憶體
└─ 網路問題 → 檢查 Docker 網路設定
```

## 📊 部署驗證

每個服務部署後進行驗證：

### Perplexity
```bash
echo '{"jsonrpc":"2.0","method":"initialize","id":1}' | ~/.claude-code-perplexity.sh
```

### OpenMemory
```bash
curl -X GET http://localhost:8765/health
```

### Zen MCP
```bash
cd ~/mcp-servers/zen-mcp-server
python -m server --test
```

## ✅ 完成標準

- 所有服務文件已下載/克隆
- 環境變數和 API 金鑰已配置
- 包裝腳本已創建（如需要）
- 基本連接測試通過
- 無錯誤日誌

## 💡 給 Claude 的提醒

1. 每個服務部署後立即測試
2. 記錄所有安裝路徑
3. 保存配置文件的備份
4. 不要在日誌中顯示 API 金鑰
5. 遇到錯誤時提供詳細的錯誤信息