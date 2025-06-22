#!/bin/bash

# 測試全域部署的 Perplexity MCP Custom 2.0

echo "🧪 測試全域部署的 Perplexity MCP Custom 2.0"
echo "=========================================="

# 測試從不同目錄執行
cd /tmp

echo -e "\n📍 當前目錄: $(pwd)"
echo -e "\n📍 測試 MCP 服務列表..."
claude mcp list | grep perplexity-custom

echo -e "\n📍 測試直接執行包裝腳本..."
# 測試初始化
echo '{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"global-test","version":"1.0.0"}},"id":1}' | ~/.claude-code-perplexity-custom.sh | jq -C '.result.serverInfo'

echo -e "\n✅ 全域部署測試完成！"
echo "服務已可在任何專案中使用：perplexity-custom"