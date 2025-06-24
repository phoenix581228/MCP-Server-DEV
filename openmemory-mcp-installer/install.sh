#!/bin/bash

# OpenMemory MCP Server 安裝腳本
# 適用於 Claude Code CLI（非 Claude Desktop）
# 版本: 1.0.0

set -e

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 輸出函數
info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Banner
echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════╗"
echo "║         OpenMemory MCP Server 安裝程式           ║"
echo "║         for Claude Code CLI                      ║"
echo "║         版本 1.0.0                               ║"
echo "╚══════════════════════════════════════════════════╝"
echo -e "${NC}"

# 檢查作業系統
check_os() {
    info "檢查作業系統..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        success "偵測到 macOS"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        success "偵測到 Linux"
    else
        error "不支援的作業系統: $OSTYPE"
        exit 1
    fi
}

# 檢查 Docker
check_docker() {
    info "檢查 Docker 環境..."
    
    # 檢查 Docker
    if ! command -v docker &> /dev/null; then
        error "找不到 Docker，請先安裝 Docker"
        echo "請訪問 https://docs.docker.com/get-docker/"
        exit 1
    fi
    
    # 檢查 Docker 是否運行
    if ! docker info &> /dev/null; then
        error "Docker 未運行，請啟動 Docker"
        exit 1
    fi
    
    DOCKER_VERSION=$(docker --version | awk '{print $3}' | sed 's/,$//')
    success "Docker 版本: $DOCKER_VERSION"
    
    # 檢查 Docker Compose
    if command -v docker-compose &> /dev/null; then
        COMPOSE_VERSION=$(docker-compose --version | awk '{print $3}' | sed 's/,$//')
        COMPOSE_CMD="docker-compose"
    elif docker compose version &> /dev/null; then
        COMPOSE_VERSION=$(docker compose version | awk '{print $4}')
        COMPOSE_CMD="docker compose"
    else
        error "找不到 Docker Compose"
        exit 1
    fi
    
    success "Docker Compose 版本: $COMPOSE_VERSION"
}

# 檢查必要端口
check_ports() {
    info "檢查必要端口..."
    
    PORTS=(8765 6333 5432 3000)
    PORT_NAMES=("API Server" "Qdrant" "PostgreSQL" "Web UI")
    BLOCKED_PORTS=()
    
    for i in "${!PORTS[@]}"; do
        port=${PORTS[$i]}
        name=${PORT_NAMES[$i]}
        
        if lsof -ti:$port &>/dev/null; then
            warning "端口 $port ($name) 已被占用"
            BLOCKED_PORTS+=($port)
        else
            success "端口 $port ($name) 可用"
        fi
    done
    
    if [ ${#BLOCKED_PORTS[@]} -gt 0 ]; then
        echo ""
        warning "發現端口衝突！"
        echo "以下端口已被占用: ${BLOCKED_PORTS[*]}"
        echo ""
        echo "您可以："
        echo "1) 停止占用端口的服務"
        echo "2) 修改 OpenMemory 的端口配置"
        echo ""
        echo -n "是否繼續安裝？[y/N] "
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            info "取消安裝"
            exit 0
        fi
    fi
}

# 檢查 Node.js 和 npm
check_node() {
    info "檢查 Node.js 環境..."
    
    if ! command -v node &> /dev/null; then
        error "找不到 Node.js，請先安裝 Node.js"
        exit 1
    fi
    
    if ! command -v npm &> /dev/null; then
        error "找不到 npm，請先安裝 npm"
        exit 1
    fi
    
    NODE_VERSION=$(node --version)
    NPM_VERSION=$(npm --version)
    success "Node.js 版本: $NODE_VERSION"
    success "npm 版本: $NPM_VERSION"
}

# 檢查 Claude Code CLI
check_claude_cli() {
    info "檢查 Claude Code CLI..."
    
    if ! command -v claude &> /dev/null; then
        error "找不到 Claude Code CLI"
        echo "請先安裝 Claude Code CLI："
        echo "  npm install -g @anthropic-ai/claude-cli"
        exit 1
    fi
    
    success "Claude Code CLI 已安裝"
}

# 檢查現有的 MCP 註冊
check_existing_mcp() {
    info "檢查現有的 OpenMemory MCP 註冊..."
    
    if claude mcp list 2>/dev/null | grep -q "openmemory"; then
        warning "發現已註冊的 OpenMemory MCP"
        echo -n "是否要重新安裝？[y/N] "
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            info "取消安裝"
            exit 0
        fi
        
        info "移除現有的 OpenMemory MCP..."
        claude mcp remove openmemory 2>/dev/null || true
        success "已移除舊版本"
    fi
}

# 準備 Docker 環境
prepare_docker_env() {
    info "準備 Docker 環境..."
    
    # 創建必要目錄
    mkdir -p docker/volumes/postgres
    mkdir -p docker/volumes/qdrant
    mkdir -p docker/backups
    mkdir -p docker/configs
    mkdir -p docker/web
    mkdir -p docker/api
    mkdir -p docker/mcp
    
    # 創建 .env 檔案
    if [ ! -f "docker/.env" ]; then
        cat > docker/.env << 'EOF'
# OpenMemory 環境設定

# API 設定
API_PORT=8765
API_HOST=0.0.0.0

# PostgreSQL 設定
POSTGRES_USER=openmemory
POSTGRES_PASSWORD=openmemory123
POSTGRES_DB=openmemory
POSTGRES_PORT=5432

# Qdrant 設定
QDRANT_PORT=6333
QDRANT_HOST=localhost

# Web UI 設定
WEB_PORT=3000
NEXT_PUBLIC_API_URL=http://localhost:8765

# 安全設定
OPENMEMORY_API_KEY=your-secure-api-key-here

# 記憶體限制
POSTGRES_MEMORY_LIMIT=1g
QDRANT_MEMORY_LIMIT=2g
API_MEMORY_LIMIT=1g
WEB_MEMORY_LIMIT=512m
EOF
        success "創建環境設定檔"
    else
        info "使用現有環境設定"
    fi
}

# 創建 Docker Compose 檔案
create_docker_compose() {
    info "創建 Docker Compose 配置..."
    
    cat > docker/docker-compose.yml << 'EOF'
services:
  postgres:
    image: postgres:15-alpine
    container_name: openmemory-postgres
    restart: unless-stopped
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
    ports:
      - "${POSTGRES_PORT}:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init-db.sql:/docker-entrypoint-initdb.d/init.sql
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER}"]
      interval: 10s
      timeout: 5s
      retries: 5
    deploy:
      resources:
        limits:
          memory: ${POSTGRES_MEMORY_LIMIT}

  qdrant:
    image: qdrant/qdrant:latest
    container_name: openmemory-qdrant
    restart: unless-stopped
    ports:
      - "${QDRANT_PORT}:6333"
    volumes:
      - qdrant_data:/qdrant/storage
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:6333/health"]
      interval: 10s
      timeout: 5s
      retries: 5
    deploy:
      resources:
        limits:
          memory: ${QDRANT_MEMORY_LIMIT}

  api:
    build:
      context: ./api
      dockerfile: Dockerfile
    image: openmemory/api:latest
    container_name: openmemory-api
    restart: unless-stopped
    ports:
      - "${API_PORT}:8765"
    environment:
      DATABASE_URL: postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/${POSTGRES_DB}
      QDRANT_URL: http://qdrant:6333
      API_KEY: ${OPENMEMORY_API_KEY}
      HOST: ${API_HOST}
      PORT: 8765
    depends_on:
      postgres:
        condition: service_healthy
      qdrant:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8765/health"]
      interval: 10s
      timeout: 5s
      retries: 5
    deploy:
      resources:
        limits:
          memory: ${API_MEMORY_LIMIT}

  web:
    build:
      context: ./web
      dockerfile: Dockerfile
    image: openmemory/web:latest
    container_name: openmemory-web
    restart: unless-stopped
    ports:
      - "${WEB_PORT}:3000"
    environment:
      NEXT_PUBLIC_API_URL: ${NEXT_PUBLIC_API_URL}
    depends_on:
      api:
        condition: service_healthy
    deploy:
      resources:
        limits:
          memory: ${WEB_MEMORY_LIMIT}

  mcp-bridge:
    build:
      context: ./mcp
      dockerfile: Dockerfile
    image: openmemory/mcp:latest
    container_name: openmemory-mcp
    restart: unless-stopped
    environment:
      OPENMEMORY_API_URL: http://api:8765
      OPENMEMORY_API_KEY: ${OPENMEMORY_API_KEY}
    depends_on:
      api:
        condition: service_healthy
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro

volumes:
  postgres_data:
    driver: local
  qdrant_data:
    driver: local

networks:
  default:
    name: openmemory-network
EOF
    
    success "Docker Compose 配置已創建"
}

# 創建初始化 SQL
create_init_sql() {
    cat > docker/init-db.sql << 'EOF'
-- OpenMemory 資料庫初始化腳本

-- 創建 memories 表
CREATE TABLE IF NOT EXISTS memories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    content TEXT NOT NULL,
    embedding_id VARCHAR(255),
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    user_id VARCHAR(255),
    tags TEXT[]
);

-- 創建索引
CREATE INDEX IF NOT EXISTS idx_memories_created_at ON memories(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_memories_user_id ON memories(user_id);
CREATE INDEX IF NOT EXISTS idx_memories_tags ON memories USING GIN(tags);
CREATE INDEX IF NOT EXISTS idx_memories_metadata ON memories USING GIN(metadata);

-- 創建更新時間觸發器
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_memories_updated_at BEFORE UPDATE
    ON memories FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
EOF
}

# 構建 Docker 映像
build_docker_images() {
    info "構建 Docker 映像..."
    
    # 創建 API Dockerfile
    cat > docker/api/Dockerfile << 'EOF'
FROM python:3.11-slim

WORKDIR /app

# 安裝系統依賴
RUN apt-get update && apt-get install -y \
    gcc \
    postgresql-client \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 安裝 Python 依賴
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 複製應用程式
COPY . .

# 創建非 root 用戶
RUN useradd -m -u 1000 openmemory && chown -R openmemory:openmemory /app
USER openmemory

EXPOSE 8765

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8765"]
EOF

    # 創建 API requirements.txt
    cat > docker/api/requirements.txt << 'EOF'
fastapi==0.109.0
uvicorn[standard]==0.27.0
pydantic==2.5.3
sqlalchemy==2.0.25
psycopg2-binary==2.9.9
qdrant-client==1.7.0
python-dotenv==1.0.0
httpx==0.26.0
python-multipart==0.0.6
EOF

    # 創建 API 主程式
    cat > docker/api/main.py << 'EOF'
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
import os
import uuid
from datetime import datetime

app = FastAPI(title="OpenMemory API", version="1.0.0")

# CORS 設定
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class Memory(BaseModel):
    content: str
    metadata: Optional[dict] = {}
    tags: Optional[List[str]] = []

class MemoryResponse(BaseModel):
    id: str
    content: str
    metadata: dict
    tags: List[str]
    created_at: datetime
    updated_at: datetime

@app.get("/health")
async def health():
    return {"status": "healthy", "service": "openmemory-api"}

@app.post("/memories", response_model=MemoryResponse)
async def add_memory(memory: Memory):
    # TODO: 實際實現記憶儲存
    return MemoryResponse(
        id=str(uuid.uuid4()),
        content=memory.content,
        metadata=memory.metadata,
        tags=memory.tags,
        created_at=datetime.now(),
        updated_at=datetime.now()
    )

@app.get("/memories", response_model=List[MemoryResponse])
async def list_memories(limit: int = 100):
    # TODO: 實際實現記憶列表
    return []

@app.get("/memories/search", response_model=List[MemoryResponse])
async def search_memories(query: str, limit: int = 10):
    # TODO: 實際實現記憶搜尋
    return []

@app.delete("/memories")
async def delete_all_memories():
    # TODO: 實際實現記憶刪除
    return {"message": "All memories deleted"}
EOF

    # 創建 MCP Bridge
    cat > docker/mcp/Dockerfile << 'EOF'
FROM node:18-alpine

WORKDIR /app

# 安裝依賴
COPY package.json .
RUN npm install

# 複製程式碼
COPY . .

# 創建非 root 用戶
RUN adduser -D -u 1000 openmemory && chown -R openmemory:openmemory /app
USER openmemory

CMD ["node", "index.js"]
EOF

    # 創建 MCP package.json
    cat > docker/mcp/package.json << 'EOF'
{
  "name": "openmemory-mcp",
  "version": "1.0.0",
  "description": "OpenMemory MCP Bridge",
  "main": "index.js",
  "dependencies": {
    "axios": "^1.6.0",
    "dotenv": "^16.0.0"
  }
}
EOF

    # 創建 MCP 主程式
    cat > docker/mcp/index.js << 'EOF'
const axios = require('axios');
const readline = require('readline');

const API_URL = process.env.OPENMEMORY_API_URL || 'http://localhost:8765';
const API_KEY = process.env.OPENMEMORY_API_KEY;

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
  terminal: false
});

const api = axios.create({
  baseURL: API_URL,
  headers: {
    'Authorization': `Bearer ${API_KEY}`,
    'Content-Type': 'application/json'
  }
});

// MCP 協議處理
rl.on('line', async (line) => {
  try {
    const request = JSON.parse(line);
    const response = await handleRequest(request);
    if (response) {
      console.log(JSON.stringify(response));
    }
  } catch (error) {
    console.error(JSON.stringify({
      jsonrpc: "2.0",
      error: {
        code: -32603,
        message: error.message
      }
    }));
  }
});

async function handleRequest(request) {
  const { method, params, id } = request;
  
  switch (method) {
    case 'initialize':
      return {
        jsonrpc: "2.0",
        id,
        result: {
          protocolVersion: "2024-11-05",
          capabilities: {
            tools: { listChanged: false }
          },
          serverInfo: {
            name: "openmemory-mcp",
            version: "1.0.0"
          }
        }
      };
      
    case 'tools/list':
      return {
        jsonrpc: "2.0",
        id,
        result: {
          tools: [
            {
              name: "add_memories",
              description: "Add a new memory",
              inputSchema: {
                type: "object",
                properties: {
                  text: { type: "string" }
                },
                required: ["text"]
              }
            },
            {
              name: "search_memory",
              description: "Search through memories",
              inputSchema: {
                type: "object",
                properties: {
                  query: { type: "string" }
                },
                required: ["query"]
              }
            },
            {
              name: "list_memories",
              description: "List all memories",
              inputSchema: {
                type: "object",
                properties: {}
              }
            },
            {
              name: "delete_all_memories",
              description: "Delete all memories",
              inputSchema: {
                type: "object",
                properties: {}
              }
            }
          ]
        }
      };
      
    case 'tools/call':
      return await handleToolCall(params, id);
      
    default:
      return null;
  }
}

async function handleToolCall(params, id) {
  const { name, arguments: args } = params;
  
  try {
    let result;
    
    switch (name) {
      case 'add_memories':
        const response = await api.post('/memories', {
          content: args.text,
          metadata: {},
          tags: []
        });
        result = `Memory added successfully: ${response.data.id}`;
        break;
        
      case 'search_memory':
        const searchRes = await api.get('/memories/search', {
          params: { query: args.query }
        });
        result = JSON.stringify(searchRes.data, null, 2);
        break;
        
      case 'list_memories':
        const listRes = await api.get('/memories');
        result = JSON.stringify(listRes.data, null, 2);
        break;
        
      case 'delete_all_memories':
        await api.delete('/memories');
        result = "All memories deleted successfully";
        break;
        
      default:
        throw new Error(`Unknown tool: ${name}`);
    }
    
    return {
      jsonrpc: "2.0",
      id,
      result: {
        content: [
          {
            type: "text",
            text: result
          }
        ]
      }
    };
  } catch (error) {
    return {
      jsonrpc: "2.0",
      id,
      error: {
        code: -32603,
        message: error.message
      }
    };
  }
}
EOF

    # 創建 Web UI
    cat > docker/web/Dockerfile << 'EOF'
FROM node:18-alpine AS builder

WORKDIR /app

# 複製 package.json
COPY package.json package-lock.json* ./
RUN npm ci

# 複製源碼
COPY . .

# 構建應用
RUN npm run build

# 生產階段
FROM node:18-alpine AS runner

WORKDIR /app

ENV NODE_ENV production

# 創建非 root 用戶
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nextjs -u 1001

# 複製構建結果
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000

ENV PORT 3000

CMD ["node", "server.js"]
EOF

    # 創建 Web package.json
    cat > docker/web/package.json << 'EOF'
{
  "name": "openmemory-web",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint"
  },
  "dependencies": {
    "@radix-ui/react-dialog": "^1.0.5",
    "@radix-ui/react-dropdown-menu": "^2.0.6",
    "@radix-ui/react-label": "^2.0.2",
    "@radix-ui/react-slot": "^1.0.2",
    "axios": "^1.6.0",
    "class-variance-authority": "^0.7.0",
    "clsx": "^2.0.0",
    "lucide-react": "^0.294.0",
    "next": "14.0.4",
    "react": "^18",
    "react-dom": "^18",
    "tailwind-merge": "^2.1.0",
    "tailwindcss-animate": "^1.0.7"
  },
  "devDependencies": {
    "@types/node": "^20",
    "@types/react": "^18",
    "@types/react-dom": "^18",
    "autoprefixer": "^10.0.1",
    "eslint": "^8",
    "eslint-config-next": "14.0.4",
    "postcss": "^8",
    "tailwindcss": "^3.3.0",
    "typescript": "^5"
  }
}
EOF

    # 創建基本的 Next.js 配置
    cat > docker/web/next.config.js << 'EOF'
/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone',
  reactStrictMode: true,
  publicRuntimeConfig: {
    apiUrl: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8765'
  }
}

module.exports = nextConfig
EOF

    # 創建基本的頁面檔案
    mkdir -p docker/web/pages
    cat > docker/web/pages/index.js << 'EOF'
import { useState, useEffect } from 'react'
import axios from 'axios'

export default function Home() {
  const [memories, setMemories] = useState([])
  const [newMemory, setNewMemory] = useState('')
  const [loading, setLoading] = useState(false)

  const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8765'

  useEffect(() => {
    fetchMemories()
  }, [])

  const fetchMemories = async () => {
    try {
      const response = await axios.get(`${apiUrl}/memories`)
      setMemories(response.data)
    } catch (error) {
      console.error('Failed to fetch memories:', error)
    }
  }

  const addMemory = async (e) => {
    e.preventDefault()
    if (!newMemory.trim()) return

    setLoading(true)
    try {
      await axios.post(`${apiUrl}/memories`, { content: newMemory })
      setNewMemory('')
      await fetchMemories()
    } catch (error) {
      console.error('Failed to add memory:', error)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="container mx-auto p-4">
      <h1 className="text-3xl font-bold mb-8">OpenMemory</h1>
      
      <form onSubmit={addMemory} className="mb-8">
        <div className="flex gap-2">
          <input
            type="text"
            value={newMemory}
            onChange={(e) => setNewMemory(e.target.value)}
            placeholder="Add a new memory..."
            className="flex-1 p-2 border rounded"
            disabled={loading}
          />
          <button
            type="submit"
            disabled={loading || !newMemory.trim()}
            className="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600 disabled:opacity-50"
          >
            Add Memory
          </button>
        </div>
      </form>

      <div className="space-y-4">
        {memories.map((memory) => (
          <div key={memory.id} className="p-4 border rounded">
            <p>{memory.content}</p>
            <p className="text-sm text-gray-500 mt-2">
              {new Date(memory.created_at).toLocaleString()}
            </p>
          </div>
        ))}
      </div>
    </div>
  )
}
EOF

    # 創建 _app.js
    cat > docker/web/pages/_app.js << 'EOF'
import '../styles/globals.css'

function MyApp({ Component, pageProps }) {
  return <Component {...pageProps} />
}

export default MyApp
EOF

    # 創建基本樣式
    mkdir -p docker/web/styles
    cat > docker/web/styles/globals.css << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

html,
body {
  padding: 0;
  margin: 0;
  font-family: -apple-system, BlinkMacSystemFont, Segoe UI, Roboto, Oxygen,
    Ubuntu, Cantarell, Fira Sans, Droid Sans, Helvetica Neue, sans-serif;
}

a {
  color: inherit;
  text-decoration: none;
}

* {
  box-sizing: border-box;
}
EOF

    # 創建 postcss 配置
    cat > docker/web/postcss.config.js << 'EOF'
module.exports = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
}
EOF

    # 創建 tailwind 配置
    cat > docker/web/tailwind.config.js << 'EOF'
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './pages/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
    './app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
EOF

    success "Docker 映像配置已準備完成"
}

# 啟動 Docker 服務
start_docker_services() {
    info "啟動 Docker 服務..."
    
    cd docker
    
    # 構建映像
    info "構建 Docker 映像（首次可能需要幾分鐘）..."
    $COMPOSE_CMD build
    
    # 啟動服務
    info "啟動服務..."
    $COMPOSE_CMD up -d
    
    # 等待服務啟動
    info "等待服務啟動..."
    sleep 10
    
    # 檢查服務狀態
    info "檢查服務狀態..."
    $COMPOSE_CMD ps
    
    cd ..
    success "Docker 服務已啟動"
}

# 創建包裝腳本
create_wrapper_script() {
    info "創建 MCP 包裝腳本..."
    
    WRAPPER_PATH="$HOME/.claude-code-openmemory.sh"
    
    cat > "$WRAPPER_PATH" << 'EOF'
#!/bin/bash
# OpenMemory MCP Server 包裝腳本
# 自動生成，請勿手動編輯

# 設定環境變數
export OPENMEMORY_API_URL="${OPENMEMORY_API_URL:-http://localhost:8765}"
export OPENMEMORY_API_KEY="${OPENMEMORY_API_KEY:-your-secure-api-key-here}"

# 執行 MCP Bridge
exec docker exec -i openmemory-mcp node index.js "$@"
EOF
    
    chmod +x "$WRAPPER_PATH"
    success "包裝腳本已創建: $WRAPPER_PATH"
}

# 註冊到 Claude Code CLI
register_to_claude() {
    info "註冊 OpenMemory MCP 到 Claude Code CLI..."
    
    MCP_COMMAND="$HOME/.claude-code-openmemory.sh"
    
    # 詢問註冊範圍
    echo ""
    echo "請選擇註冊範圍："
    echo "1) 專案範圍（僅在當前專案可用）"
    echo "2) 使用者範圍（在所有專案可用）"
    echo -n "請選擇 [1/2] (預設: 2): "
    read -r scope_choice
    
    case "$scope_choice" in
        1)
            info "註冊到專案範圍..."
            claude mcp add openmemory "$MCP_COMMAND"
            success "成功註冊到專案範圍"
            ;;
        *)
            info "註冊到使用者範圍..."
            if claude mcp add openmemory "$MCP_COMMAND" -s user; then
                success "成功註冊到使用者範圍"
            else
                warning "使用者範圍註冊失敗，嘗試專案範圍..."
                claude mcp add openmemory "$MCP_COMMAND"
                success "成功註冊到專案範圍"
            fi
            ;;
    esac
}

# 創建管理腳本
create_management_scripts() {
    info "創建管理腳本..."
    
    # 健康檢查腳本
    cat > health-check.sh << 'EOF'
#!/bin/bash
echo "檢查 OpenMemory 服務健康狀態..."

# API 健康檢查
echo -n "API Server: "
curl -s http://localhost:8765/health | jq -r '.status' || echo "不健康"

# Qdrant 健康檢查
echo -n "Qdrant: "
curl -s http://localhost:6333/health | jq -r '.status' || echo "不健康"

# PostgreSQL 健康檢查
echo -n "PostgreSQL: "
docker exec openmemory-postgres pg_isready -U openmemory &>/dev/null && echo "健康" || echo "不健康"

# Web UI 檢查
echo -n "Web UI: "
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 | grep -q "200" && echo "健康" || echo "不健康"
EOF
    chmod +x health-check.sh
    
    # 備份腳本
    cat > backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="docker/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/openmemory_backup_$TIMESTAMP.tar.gz"

echo "備份 OpenMemory 資料..."
mkdir -p $BACKUP_DIR

# 備份 PostgreSQL
docker exec openmemory-postgres pg_dumpall -U openmemory > "$BACKUP_DIR/postgres_$TIMESTAMP.sql"

# 備份 Qdrant
docker run --rm -v openmemory_qdrant_data:/data -v $(pwd)/$BACKUP_DIR:/backup alpine tar czf /backup/qdrant_$TIMESTAMP.tar.gz -C /data .

# 創建綜合備份
tar -czf "$BACKUP_FILE" -C "$BACKUP_DIR" "postgres_$TIMESTAMP.sql" "qdrant_$TIMESTAMP.tar.gz"

# 清理臨時檔案
rm -f "$BACKUP_DIR/postgres_$TIMESTAMP.sql" "$BACKUP_DIR/qdrant_$TIMESTAMP.tar.gz"

echo "備份完成: $BACKUP_FILE"
EOF
    chmod +x backup.sh
    
    # 檢查端口腳本
    cat > check-ports.sh << 'EOF'
#!/bin/bash
echo "檢查 OpenMemory 使用的端口..."

PORTS=(8765 6333 5432 3000)
NAMES=("API Server" "Qdrant" "PostgreSQL" "Web UI")

for i in "${!PORTS[@]}"; do
    port=${PORTS[$i]}
    name=${NAMES[$i]}
    
    if lsof -ti:$port &>/dev/null; then
        echo "✗ 端口 $port ($name) 被占用"
        lsof -ti:$port | xargs ps -p | tail -n 1
    else
        echo "✓ 端口 $port ($name) 可用"
    fi
done
EOF
    chmod +x check-ports.sh
    
    success "管理腳本已創建"
}

# 測試安裝
test_installation() {
    info "測試 OpenMemory MCP 安裝..."
    
    # 檢查註冊
    if claude mcp list | grep -q "openmemory"; then
        success "OpenMemory MCP 已成功註冊"
    else
        error "OpenMemory MCP 註冊失敗"
        return 1
    fi
    
    # 測試 API
    if curl -s http://localhost:8765/health | grep -q "healthy"; then
        success "API Server 運行正常"
    else
        warning "API Server 可能需要更多時間啟動"
    fi
    
    return 0
}

# 顯示使用說明
show_usage() {
    echo ""
    echo -e "${GREEN}══════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✨ OpenMemory MCP Server 安裝成功！${NC}"
    echo -e "${GREEN}══════════════════════════════════════════════════${NC}"
    echo ""
    echo "服務狀態："
    echo "  • API Server: http://localhost:8765"
    echo "  • Qdrant: http://localhost:6333"
    echo "  • PostgreSQL: localhost:5432"
    echo "  • Web UI: http://localhost:3000"
    echo ""
    echo "可用的工具："
    echo "  • add_memories - 新增記憶"
    echo "  • search_memory - 搜尋記憶"
    echo "  • list_memories - 列出所有記憶"
    echo "  • delete_all_memories - 刪除所有記憶"
    echo ""
    echo "使用範例："
    echo "  claude '請記住這個專案使用 React 18'"
    echo "  claude '搜尋關於專案技術棧的記憶'"
    echo "  claude '列出所有儲存的記憶'"
    echo ""
    echo "管理命令："
    echo "  ./health-check.sh - 檢查服務健康狀態"
    echo "  ./backup.sh - 備份資料"
    echo "  ./check-ports.sh - 檢查端口使用"
    echo ""
    echo "Docker 命令："
    echo "  cd docker && docker-compose ps - 查看服務狀態"
    echo "  cd docker && docker-compose logs -f - 查看日誌"
    echo "  cd docker && docker-compose down - 停止服務"
    echo ""
    echo "Web UI："
    echo "  訪問 http://localhost:3000 管理記憶"
    echo ""
    echo "配置檔案："
    echo "  docker/.env - 環境變數設定"
    echo "  $HOME/.claude-code-openmemory.sh - MCP 包裝腳本"
}

# 主要安裝流程
main() {
    # 執行檢查
    check_os
    check_docker
    check_ports
    check_node
    check_claude_cli
    check_existing_mcp
    
    # 準備環境
    prepare_docker_env
    create_docker_compose
    create_init_sql
    build_docker_images
    
    # 啟動服務
    start_docker_services
    
    # 設定 MCP
    create_wrapper_script
    register_to_claude
    create_management_scripts
    
    # 測試安裝
    test_installation
    
    # 顯示完成訊息
    show_usage
    
    # 寫入安裝日誌
    cat > install.log << EOF
OpenMemory MCP Server 安裝日誌
時間: $(date)
作業系統: $OS
Docker: $DOCKER_VERSION
Docker Compose: $COMPOSE_VERSION
Node.js: $NODE_VERSION
npm: $NPM_VERSION
安裝狀態: 成功
EOF
    
    success "安裝日誌已保存到 install.log"
}

# 錯誤處理
trap 'error "安裝過程中發生錯誤"; exit 1' ERR

# 執行主程式
main