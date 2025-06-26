# 北斗七星陣 MCP 團隊 Docker 部署指南

北斗七星陣（Big Dipper Formation）是由七位專業 MCP Server 成員組成的智能協作團隊，現已全面 Docker 化，可輕鬆部署和管理。

## 🌟 北斗七星陣成員

| 星名 | 角色 | MCP Server | 專長領域 | 端口 |
|------|------|------------|----------|------|
| 🌟 天樞星（Dubhe） | 專案管理大師 | TaskMaster AI | 任務規劃、進度追蹤、複雜度分析 | 9120 |
| 🌟 天璇星（Merak） | 研究分析專家 | Perplexity Custom 2.0 | 即時資訊搜尋、技術趨勢分析 | 8080 |
| 🌟 天璣星（Phecda） | 知識庫守護者 | Context7 Cached | 技術文檔查詢、API 規範檢索 | 9119 |
| 🌟 天權星（Megrez） | 記憶宮殿管理者 | OpenMemory | 知識儲存、經驗累積 | 8765 |
| 🌟 玉衡星（Alioth） | 多模型智能中心 | Zen MCP | 深度思考、代碼審查、多模型路由 | 8082 |
| 🌟 開陽星（Mizar） | 代碼精煉師 | Serena | 代碼重構、語言伺服器整合 | 9121 |
| 🌟 瑤光星（Alkaid） | 思維導航者 | Sequential Thinking | 序列化思考、決策分支管理 | 9122 |

## 🚀 快速部署

### 方案一：完整星陣部署（推薦）

```bash
# 1. 克隆專案
git clone https://github.com/your-org/MCP-Server-DEV.git
cd MCP-Server-DEV/docker-packaging

# 2. 設定環境變數
cp .env.bigdipper.template .env
# 編輯 .env 檔案，填入您的 API 金鑰

# 3. 建立 Docker 網路
docker network create bigdipper_mcp_network

# 4. 啟動完整星陣
docker-compose -f docker-compose-bigdipper.yml up -d

# 5. 檢查服務狀態
docker-compose -f docker-compose-bigdipper.yml ps
```

### 方案二：個別服務部署

```bash
# 進入特定服務目錄
cd taskmaster  # 或 perplexity-custom, context7, zen-mcp, serena, sequential-thinking

# 設定環境變數
cp .env.template .env
# 編輯 .env 檔案

# 啟動單一服務
docker-compose up -d
```

## 📋 部署前準備

### 1. 系統需求

**最小需求：**
- CPU: 4 核心
- 記憶體: 8GB
- 磁碟空間: 20GB
- Docker 20.10+
- Docker Compose 2.0+

**推薦配置：**
- CPU: 8 核心
- 記憶體: 16GB
- 磁碟空間: 50GB

**生產環境：**
- CPU: 16 核心
- 記憶體: 32GB
- 磁碟空間: 100GB

### 2. API 金鑰準備

至少需要以下一個 API 金鑰：

| 提供者 | 必要性 | 用途 |
|--------|--------|------|
| Anthropic Claude | 推薦 | 主要 AI 能力 |
| Perplexity AI | 必需 | 研究和即時資訊 |
| OpenAI | 可選 | 備用 AI 模型 |
| Google Gemini | 可選 | 大文件處理 |
| XAI Grok | 可選 | 創意思考 |

### 3. 端口規劃

確保以下端口未被占用：

```
北斗七星陣端口分配：
- TaskMaster AI:      9120
- Perplexity Custom:  8080
- Context7 Cached:    9119
- OpenMemory API:     8765
- OpenMemory Web UI:  3000
- Qdrant Vector DB:   6333
- PostgreSQL:         5432
- Zen MCP:            8082
- Serena:             9121
- Serena Dashboard:   24282
- Sequential Thinking: 9122
```

## 🔧 詳細配置

### 環境變數配置

複製並編輯環境變數檔案：

```bash
cp .env.bigdipper.template .env
nano .env
```

重要配置項目：

```bash
# 必填：AI API 金鑰
ANTHROPIC_API_KEY=your_claude_api_key_here
PERPLEXITY_API_KEY=your_perplexity_api_key_here

# 可選：其他 AI 提供者
OPENAI_API_KEY=your_openai_api_key_here
GOOGLE_API_KEY=your_google_api_key_here
XAI_API_KEY=your_xai_api_key_here

# 專案路徑（用於 Serena 代碼分析）
PROJECT_PATH=./workspace

# 除錯模式
DEBUG=false
```

### 服務健康檢查

```bash
# 檢查所有服務狀態
docker-compose -f docker-compose-bigdipper.yml ps

# 檢查特定服務健康狀態
docker-compose -f docker-compose-bigdipper.yml exec taskmaster ./healthcheck.sh
docker-compose -f docker-compose-bigdipper.yml exec perplexity ./healthcheck.sh
docker-compose -f docker-compose-bigdipper.yml exec context7 ./healthcheck.sh
docker-compose -f docker-compose-bigdipper.yml exec zen-mcp ./healthcheck.sh
docker-compose -f docker-compose-bigdipper.yml exec serena ./healthcheck.sh
docker-compose -f docker-compose-bigdipper.yml exec sequential-thinking ./healthcheck.sh

# 檢查 OpenMemory（特殊檢查）
curl -f http://localhost:8765/health
```

## 🔌 與 Claude Code CLI 整合

### 註冊所有 MCP Servers

```bash
# 建立註冊腳本
cat > register_bigdipper.sh << 'EOF'
#!/bin/bash

# 檢查 Docker 服務是否運行
docker-compose -f docker-compose-bigdipper.yml ps

echo "註冊北斗七星陣 MCP Servers..."

# 天樞星 - TaskMaster AI
claude mcp add taskmaster "docker-compose -f docker-compose-bigdipper.yml exec -T taskmaster npx task-master-ai" -s user

# 天璇星 - Perplexity Custom 2.0
claude mcp add perplexity "docker-compose -f docker-compose-bigdipper.yml exec -T perplexity python server.py" -s user

# 天璣星 - Context7 Cached
claude mcp add context7 "docker-compose -f docker-compose-bigdipper.yml exec -T context7 npx @upstash/context7-mcp" -s user

# 天權星 - OpenMemory
claude mcp add openmemory "curl -X POST http://localhost:8765/mcp" -s user

# 玉衡星 - Zen MCP
claude mcp add zen "docker-compose -f docker-compose-bigdipper.yml exec -T zen-mcp python server.py" -s user

# 開陽星 - Serena
claude mcp add serena "docker-compose -f docker-compose-bigdipper.yml exec -T serena uvx --from 'git+https://github.com/oraios/serena' serena-mcp-server" -s user

# 瑤光星 - Sequential Thinking
claude mcp add sequential "docker-compose -f docker-compose-bigdipper.yml exec -T sequential-thinking npx @modelcontextprotocol/server-sequential-thinking" -s user

echo "✅ 北斗七星陣註冊完成！"
echo "使用 'claude mcp list' 查看已註冊的服務"
EOF

chmod +x register_bigdipper.sh
./register_bigdipper.sh
```

### 驗證 MCP 整合

```bash
# 列出已註冊的 MCP Servers
claude mcp list

# 測試特定服務
echo "測試 TaskMaster..." && claude "使用 TaskMaster 創建一個測試任務"
echo "測試 Perplexity..." && claude "使用 Perplexity 搜尋最新的 AI 技術趨勢"
echo "測試 Context7..." && claude "使用 Context7 查詢 React 的最新文檔"
echo "測試 Zen MCP..." && claude "使用 Zen MCP 分析一段代碼"
echo "測試 Serena..." && claude "使用 Serena 查找項目中的符號"
echo "測試 Sequential..." && claude "使用 Sequential Thinking 進行步驟化思考"
```

## 📊 監控與維護

### 查看日誌

```bash
# 查看所有服務日誌
docker-compose -f docker-compose-bigdipper.yml logs -f

# 查看特定服務日誌
docker-compose -f docker-compose-bigdipper.yml logs -f taskmaster
docker-compose -f docker-compose-bigdipper.yml logs -f perplexity
docker-compose -f docker-compose-bigdipper.yml logs -f zen-mcp

# 查看錯誤日誌
docker-compose -f docker-compose-bigdipper.yml logs | grep ERROR
```

### 資源監控

```bash
# 查看容器資源使用
docker stats

# 查看磁碟使用
docker system df

# 查看網路狀態
docker network ls
docker network inspect bigdipper_mcp_network
```

### 數據備份

```bash
# 建立備份腳本
cat > backup_bigdipper.sh << 'EOF'
#!/bin/bash

BACKUP_DIR="./backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "開始備份北斗七星陣數據..."

# 備份 TaskMaster 數據
docker run --rm -v bigdipper_taskmaster_data:/data -v "$(pwd)/$BACKUP_DIR":/backup alpine tar czf /backup/taskmaster_data.tar.gz -C /data .

# 備份 Perplexity 數據
docker run --rm -v bigdipper_perplexity_data:/data -v "$(pwd)/$BACKUP_DIR":/backup alpine tar czf /backup/perplexity_data.tar.gz -C /data .

# 備份 Context7 數據
docker run --rm -v bigdipper_context7_data:/data -v "$(pwd)/$BACKUP_DIR":/backup alpine tar czf /backup/context7_data.tar.gz -C /data .

# 備份 OpenMemory 數據
docker run --rm -v bigdipper_openmemory_data:/data -v "$(pwd)/$BACKUP_DIR":/backup alpine tar czf /backup/openmemory_data.tar.gz -C /data .
docker run --rm -v bigdipper_qdrant_data:/data -v "$(pwd)/$BACKUP_DIR":/backup alpine tar czf /backup/qdrant_data.tar.gz -C /data .
docker run --rm -v bigdipper_postgres_data:/data -v "$(pwd)/$BACKUP_DIR":/backup alpine tar czf /backup/postgres_data.tar.gz -C /data .

# 備份 Zen MCP 數據
docker run --rm -v bigdipper_zen_data:/data -v "$(pwd)/$BACKUP_DIR":/backup alpine tar czf /backup/zen_data.tar.gz -C /data .

# 備份 Serena 數據
docker run --rm -v bigdipper_serena_data:/data -v "$(pwd)/$BACKUP_DIR":/backup alpine tar czf /backup/serena_data.tar.gz -C /data .

# 備份 Sequential Thinking 數據
docker run --rm -v bigdipper_sequential_data:/data -v "$(pwd)/$BACKUP_DIR":/backup alpine tar czf /backup/sequential_data.tar.gz -C /data .

echo "✅ 備份完成：$BACKUP_DIR"
EOF

chmod +x backup_bigdipper.sh
```

## 🔄 更新和升級

### 更新所有服務

```bash
# 停止所有服務
docker-compose -f docker-compose-bigdipper.yml down

# 拉取最新映像
docker-compose -f docker-compose-bigdipper.yml pull

# 重建映像
docker-compose -f docker-compose-bigdipper.yml build --no-cache

# 重新啟動服務
docker-compose -f docker-compose-bigdipper.yml up -d

# 清理舊映像
docker image prune -f
```

### 滾動更新特定服務

```bash
# 更新特定服務（零停機時間）
docker-compose -f docker-compose-bigdipper.yml up -d --no-deps taskmaster
docker-compose -f docker-compose-bigdipper.yml up -d --no-deps zen-mcp
```

## 🐛 故障排除

### 常見問題

1. **端口衝突**
   ```bash
   # 檢查端口使用情況
   netstat -tulpn | grep -E "(8080|8082|8765|9119|9120|9121|9122)"
   
   # 修改 .env 檔案中的端口配置
   ```

2. **API 金鑰錯誤**
   ```bash
   # 檢查環境變數
   docker-compose -f docker-compose-bigdipper.yml exec taskmaster env | grep API_KEY
   
   # 重新設定 .env 檔案
   ```

3. **記憶體不足**
   ```bash
   # 檢查系統記憶體
   free -h
   
   # 調整 docker-compose-bigdipper.yml 中的資源限制
   ```

4. **服務啟動失敗**
   ```bash
   # 查看特定服務日誌
   docker-compose -f docker-compose-bigdipper.yml logs service_name
   
   # 檢查健康狀態
   docker-compose -f docker-compose-bigdipper.yml exec service_name ./healthcheck.sh
   ```

### 除錯模式

```bash
# 啟用全域除錯
echo 'DEBUG=true' >> .env

# 重啟服務
docker-compose -f docker-compose-bigdipper.yml restart

# 查看除錯日誌
docker-compose -f docker-compose-bigdipper.yml logs -f | grep DEBUG
```

## 🔐 安全建議

### 生產環境安全

1. **API 金鑰管理**
   ```bash
   # 使用 Docker Secrets（生產環境）
   echo "your_api_key" | docker secret create anthropic_api_key -
   
   # 在 docker-compose 中引用
   # secrets:
   #   - anthropic_api_key
   ```

2. **網路安全**
   ```bash
   # 限制外部訪問
   # 僅暴露必要的端口
   # 使用防火牆規則
   ```

3. **容器安全**
   ```bash
   # 定期更新基礎映像
   docker-compose -f docker-compose-bigdipper.yml pull
   
   # 掃描安全漏洞
   docker scout cves bigdipper/taskmaster:latest
   ```

## 📈 效能優化

### 資源調優

```bash
# 編輯 docker-compose-bigdipper.yml
# 調整每個服務的資源限制：
# deploy:
#   resources:
#     limits:
#       memory: 2G
#       cpus: '2.0'
```

### 快取優化

```bash
# 啟用 Redis 快取持久化
# 調整 Redis 記憶體策略
# 設定適當的 TTL 值
```

## 📞 技術支援

- **GitHub Issues**: [MCP Server Issues](https://github.com/your-org/MCP-Server-DEV/issues)
- **文檔**: [北斗七星陣技術文檔](./docs/)
- **社群**: [MCP 開發者社群](https://discord.gg/mcp-community)

## 🔗 相關資源

- [MCP 協議規範](https://modelcontextprotocol.io/)
- [Claude Code CLI 文檔](https://docs.anthropic.com/claude-code)
- [Docker Compose 指南](https://docs.docker.com/compose/)
- [個別服務文檔](./):
  - [TaskMaster AI](./taskmaster/README.md)
  - [Perplexity Custom 2.0](./perplexity-custom/README.md)
  - [Context7 Cached](./context7/README.md)
  - [Zen MCP](./zen-mcp/README.md)
  - [Serena](./serena/README.md)
  - [Sequential Thinking](./sequential-thinking/README.md)

---

**北斗七星陣承諾**：以智能協作引導開發方向，如北斗指引航行，讓每個軟體專案都能在正確的道路上高效前進。🌟