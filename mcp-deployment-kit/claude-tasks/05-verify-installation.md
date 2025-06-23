# 任務 5：驗證安裝

## 📋 任務概述
全面驗證 MCP Server 部署是否成功。

## 🎯 目標
- 測試每個 MCP Server 的基本功能
- 確認 Claude CLI 整合正常
- 驗證 CLAUDE.md 更新
- 生成完整的安裝報告

## 🔧 Claude Code 執行步驟

### 1. 服務健康檢查

#### Perplexity MCP 測試
```bash
echo "🧪 測試 Perplexity MCP..."
if [ -f "$HOME/.claude-code-perplexity.sh" ]; then
    # 發送初始化請求
    echo '{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0.0"}},"id":1}' | \
    timeout 10 "$HOME/.claude-code-perplexity.sh" > perplexity_test.json 2>&1
    
    if grep -q "result" perplexity_test.json; then
        echo "✅ Perplexity MCP 回應正常"
    else
        echo "❌ Perplexity MCP 測試失敗"
        cat perplexity_test.json
    fi
else
    echo "⚠️  Perplexity 包裝腳本未找到"
fi
```

#### OpenMemory 健康檢查
```bash
echo "🧪 測試 OpenMemory..."
if curl -s -X GET http://localhost:8765/health > /dev/null 2>&1; then
    echo "✅ OpenMemory API 服務運行中"
    
    # 檢查相關服務
    if curl -s http://localhost:6333/health > /dev/null 2>&1; then
        echo "✅ Qdrant 向量資料庫運行中"
    else
        echo "❌ Qdrant 未響應"
    fi
    
    if nc -z localhost 5432 2>/dev/null; then
        echo "✅ PostgreSQL 資料庫運行中"
    else
        echo "❌ PostgreSQL 未響應"
    fi
else
    echo "❌ OpenMemory API 未響應"
    
    # 檢查 Docker 容器狀態
    echo "檢查 Docker 容器..."
    docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "(openmemory|qdrant|postgres)"
fi
```

#### Zen MCP 測試
```bash
echo "🧪 測試 Zen MCP Server..."
if [ -f "$HOME/.claude-code-zen.sh" ]; then
    # 測試版本命令
    echo '{"jsonrpc":"2.0","method":"version","id":1}' | \
    timeout 10 "$HOME/.claude-code-zen.sh" > zen_test.json 2>&1
    
    if [ -s zen_test.json ]; then
        echo "✅ Zen MCP 回應正常"
    else
        echo "❌ Zen MCP 測試失敗"
    fi
else
    echo "⚠️  Zen MCP 未配置"
fi
```

### 2. Claude CLI 整合測試

```bash
echo -e "\n📋 Claude CLI 整合測試..."

# 列出所有註冊的 MCP Servers
claude mcp list > mcp_list.txt

# 檢查每個服務的註冊狀態
services=("perplexity" "zen" "openmemory" "serena" "taskmaster")
registered_count=0

for service in "${services[@]}"; do
    if grep -q "$service" mcp_list.txt; then
        echo "✅ $service - 已註冊"
        ((registered_count++))
    else
        echo "❌ $service - 未註冊"
    fi
done

echo -e "\n註冊統計: $registered_count / ${#services[@]} 服務已註冊"
```

### 3. CLAUDE.md 驗證

```bash
echo -e "\n📄 驗證 CLAUDE.md 更新..."

CLAUDE_MD="$HOME/.claude/CLAUDE.md"

if [ -f "$CLAUDE_MD" ]; then
    echo "✅ CLAUDE.md 文件存在"
    
    # 檢查關鍵內容
    if grep -q "MCP Server 開發原則" "$CLAUDE_MD"; then
        echo "✅ MCP 開發原則已添加"
    else
        echo "❌ MCP 開發原則未找到"
    fi
    
    if grep -q "check_mcp_ports" "$CLAUDE_MD"; then
        echo "✅ 端口保護函數已添加"
    else
        echo "❌ 端口保護函數未找到"
    fi
    
    # 檢查 MCP 端口是否在 COMMON_PORTS 中
    if grep -q "8765.*6333.*5432" "$CLAUDE_MD"; then
        echo "✅ MCP 端口已加入保護列表"
    else
        echo "⚠️  MCP 端口可能未完全加入保護列表"
    fi
else
    echo "❌ CLAUDE.md 文件不存在"
fi
```

### 4. 端口占用檢查

```bash
echo -e "\n🔍 端口使用情況..."

# MCP 端口列表
declare -A port_services=(
    [8765]="OpenMemory API"
    [6333]="Qdrant Vector DB"
    [5432]="PostgreSQL"
    [3000]="OpenMemory UI"
    [8080]="Perplexity HTTP"
    [9997]="Xinference"
    [1234]="LM Studio"
    [11434]="Ollama"
)

for port in "${!port_services[@]}"; do
    service=${port_services[$port]}
    if lsof -ti:$port >/dev/null 2>&1; then
        process=$(lsof -ti:$port | xargs ps -p 2>/dev/null | tail -n 1 | awk '{print $4}')
        echo "✅ Port $port ($service) - 使用中 by $process"
    else
        echo "⚠️  Port $port ($service) - 未使用"
    fi
done
```

### 5. 生成最終報告

```bash
# 生成綜合安裝報告
cat > installation_final_report.md << EOF
# MCP Server 部署最終報告

生成時間: $(date)
主機名稱: $(hostname)
macOS 版本: $(sw_vers -productVersion)

## 📊 部署摘要

### 環境狀態
- Node.js: $(node --version 2>/dev/null || echo "未安裝")
- Python: $(python3 --version 2>/dev/null || echo "未安裝")
- Docker: $(docker --version 2>/dev/null || echo "未安裝")
- Claude CLI: $(command -v claude >/dev/null && echo "已安裝" || echo "未安裝")

### MCP Server 狀態

| 服務 | 部署狀態 | 註冊狀態 | 健康檢查 |
|------|---------|---------|---------|
| Perplexity MCP | $(check_deployment perplexity) | $(check_registration perplexity) | $(check_health perplexity) |
| Zen MCP | $(check_deployment zen) | $(check_registration zen) | $(check_health zen) |
| OpenMemory | $(check_deployment openmemory) | $(check_registration openmemory) | $(check_health openmemory) |
| Serena | $(check_deployment serena) | $(check_registration serena) | $(check_health serena) |
| Task Master | $(check_deployment taskmaster) | $(check_registration taskmaster) | $(check_health taskmaster) |

### 端口使用情況
$(generate_port_report)

### CLAUDE.md 更新
- 文件存在: $([ -f "$HOME/.claude/CLAUDE.md" ] && echo "✅" || echo "❌")
- MCP 開發原則: $(grep -q "MCP Server 開發原則" "$HOME/.claude/CLAUDE.md" 2>/dev/null && echo "✅" || echo "❌")
- 端口保護: $(grep -q "check_mcp_ports" "$HOME/.claude/CLAUDE.md" 2>/dev/null && echo "✅" || echo "❌")

## 📝 建議後續步驟

$(generate_recommendations)

## 🔧 故障排除命令

### 檢查服務狀態
\`\`\`bash
# OpenMemory Docker 容器
docker ps | grep openmemory

# 檢查日誌
docker logs openmemory_openmemory_1

# 測試 Perplexity
echo '{"jsonrpc":"2.0","method":"tools/list","id":1}' | ~/.claude-code-perplexity.sh
\`\`\`

### 重新註冊服務
\`\`\`bash
# 移除並重新註冊
claude mcp remove <service-name>
claude mcp add <service-name> <command>
\`\`\`

## 📄 相關文件
- 安裝日誌: $(pwd)/install.log
- 註冊日誌: $(pwd)/registration.log
- 環境檢查: $(pwd)/environment-check.log

---
*報告生成完成*
EOF

echo -e "\n✅ 最終報告已生成: installation_final_report.md"
```

## 🎯 驗證檢查清單

執行以下檢查確保安裝成功：

- [ ] 所有必要的依賴已安裝
- [ ] MCP Servers 文件已部署
- [ ] API 金鑰已配置
- [ ] Claude CLI 可以列出註冊的服務
- [ ] 基本健康檢查通過
- [ ] CLAUDE.md 包含 MCP 開發原則
- [ ] 端口保護機制已配置
- [ ] 無嚴重錯誤日誌

## ✅ 完成標準

安裝成功的標誌：
1. 至少 4/5 的 MCP Server 成功部署
2. Claude CLI 整合正常
3. CLAUDE.md 更新完成
4. 基本功能測試通過
5. 生成完整的安裝報告

## 💡 給 Claude 的提醒

1. 詳細記錄所有測試結果
2. 對失敗的測試提供診斷建議
3. 生成用戶友好的報告格式
4. 提供清晰的後續步驟指引
5. 保存所有日誌供未來參考