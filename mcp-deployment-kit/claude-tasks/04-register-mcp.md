# 任務 4：註冊 MCP Servers 到 Claude CLI

## 📋 任務概述
將所有部署的 MCP Server 註冊到 Claude Code CLI。

## 🎯 目標
- 智能檢測已註冊的服務
- 避免重複註冊
- 選擇適當的註冊範圍（全域 vs 專案）
- 處理 JSON Schema 相容性問題

## 🔧 Claude Code 執行步驟

### 1. 檢查現有註冊

```bash
# 獲取已註冊的 MCP Servers
echo "📋 檢查現有 MCP 註冊..."
claude mcp list > current_mcp_list.txt

# 解析已註冊的服務
registered_servers=$(claude mcp list | grep -E "^\s*-" | awk '{print $2}' || echo "")

echo "已註冊的服務："
echo "$registered_servers"
```

### 2. 智能註冊決策

```bash
# 註冊函數
register_mcp_server() {
    local name=$1
    local command=$2
    local scope=${3:-"project"}  # 預設為專案範圍
    
    # 檢查是否已註冊
    if echo "$registered_servers" | grep -q "^$name$"; then
        echo "⚠️  $name 已註冊，跳過"
        return 0
    fi
    
    echo "📝 註冊 $name..."
    
    # 嘗試註冊
    if [ "$scope" = "user" ]; then
        # 嘗試全域註冊
        if claude mcp add "$name" "$command" -s user 2>&1 | tee -a registration.log; then
            echo "✅ $name 已全域註冊"
        else
            # 如果失敗，降級到專案範圍
            echo "⚠️  全域註冊失敗，嘗試專案範圍註冊"
            claude mcp add "$name" "$command" 2>&1 | tee -a registration.log
        fi
    else
        # 專案範圍註冊
        claude mcp add "$name" "$command" 2>&1 | tee -a registration.log
    fi
}
```

### 3. 註冊各個 MCP Server

#### Perplexity MCP
```bash
# Perplexity - 使用包裝腳本避免 JSON Schema 問題
register_mcp_server "perplexity" "$HOME/.claude-code-perplexity.sh" "project"
```

#### Zen MCP Server
```bash
# Zen MCP - Python 服務
ZEN_PATH="$HOME/mcp-servers/zen-mcp-server"
if [ -d "$ZEN_PATH" ]; then
    # 創建啟動腳本
    cat > "$HOME/.claude-code-zen.sh" << EOF
#!/bin/bash
cd "$ZEN_PATH"
source venv/bin/activate 2>/dev/null || true
exec python -m server
EOF
    chmod +x "$HOME/.claude-code-zen.sh"
    
    register_mcp_server "zen" "$HOME/.claude-code-zen.sh" "project"
fi
```

#### OpenMemory MCP
```bash
# OpenMemory - 需要特殊的 SSE 配置
cat > "$HOME/.claude-code-openmemory.sh" << 'EOF'
#!/bin/bash
# OpenMemory MCP 包裝腳本
# 注意：OpenMemory 使用 SSE 而非 stdio

echo "OpenMemory 需要通過 HTTP API 訪問"
echo "API 端點: http://localhost:8765"
echo "請確保 Docker 服務正在運行"
EOF
chmod +x "$HOME/.claude-code-openmemory.sh"

# OpenMemory 可能需要特殊處理
echo "⚠️  OpenMemory 使用 SSE 協議，可能需要手動配置"
```

#### Serena MCP
```bash
# Serena - Python 服務
SERENA_PATH="$HOME/mcp-servers/serena"
if [ -d "$SERENA_PATH" ]; then
    register_mcp_server "serena" "$SERENA_PATH/run-serena.sh" "project"
fi
```

#### Task Master MCP
```bash
# Task Master
if command -v claude-task-master >/dev/null 2>&1; then
    register_mcp_server "taskmaster" "claude-task-master" "user"
else
    echo "⚠️  Task Master 未安裝，跳過註冊"
fi
```

### 4. 驗證註冊結果

```bash
echo -e "\n📋 驗證註冊結果..."
claude mcp list

# 統計註冊數量
new_count=$(claude mcp list | grep -c "registered" || echo "0")
echo -e "\n✅ 總共註冊了 $new_count 個 MCP Server"
```

### 5. 生成註冊報告

```bash
cat > registration_report.md << EOF
# MCP Server 註冊報告

生成時間: $(date)

## 註冊摘要

| 服務名稱 | 註冊狀態 | 註冊範圍 | 備註 |
|---------|---------|---------|------|
| Perplexity | $(check_registration "perplexity") | 專案 | 使用包裝腳本 |
| Zen MCP | $(check_registration "zen") | 專案 | Python 服務 |
| OpenMemory | $(check_registration "openmemory") | - | SSE 協議 |
| Serena | $(check_registration "serena") | 專案 | LSP 整合 |
| Task Master | $(check_registration "taskmaster") | 全域 | npm 全域包 |

## 詳細日誌
\`\`\`
$(cat registration.log)
\`\`\`

EOF
```

## 🌳 決策樹

### JSON Schema 相容性處理
```
註冊失敗?
├─ JSON Schema 錯誤 → 使用包裝腳本
│   └─ 創建 shell 腳本包裝原始命令
├─ 命令未找到 → 檢查安裝路徑
│   └─ 更新 PATH 或使用絕對路徑
└─ 權限問題 → 修復執行權限
    └─ chmod +x 腳本文件
```

### 註冊範圍決策
```
選擇註冊範圍
├─ 檢查 JSON Schema 相容性
│   ├─ 相容 → 可以使用 -s user（全域）
│   └─ 不相容 → 只能使用專案範圍
└─ 考慮使用場景
    ├─ 所有專案都需要 → 優先全域
    └─ 特定專案使用 → 使用專案範圍
```

## 🚨 錯誤處理

### 常見錯誤

1. **JSON Schema 不相容**
   ```
   Error: tools.0.inputSchema: JSON schema is invalid
   ```
   解決：使用包裝腳本而非直接 npx 命令

2. **命令未找到**
   ```
   Error: Command not found
   ```
   解決：使用完整路徑或更新 PATH

3. **重複註冊**
   ```
   Error: Server 'name' already exists
   ```
   解決：先移除再重新註冊
   ```bash
   claude mcp remove <name>
   claude mcp add <name> <command>
   ```

## ✅ 完成標準

- 所有可用的 MCP Server 都已註冊
- 無重複註冊錯誤
- 註冊命令可以正常執行
- 生成完整的註冊報告

## 💡 給 Claude 的提醒

1. 優先使用包裝腳本避免 JSON Schema 問題
2. 記錄所有註冊命令供未來參考
3. 對於 SSE 協議的服務（如 OpenMemory）需要特殊說明
4. 保存註冊日誌以便故障排除
5. 確保所有腳本都有執行權限