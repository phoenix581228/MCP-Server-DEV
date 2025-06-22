#!/bin/bash

# Perplexity MCP Custom 2.0 - stdio 模式測試腳本

echo "🧪 測試 Perplexity MCP Custom 2.0 - stdio 模式"
echo "============================================"

# 設定測試環境變數
export PERPLEXITY_API_KEY="test_key_for_validation"
export DEBUG=true

# 測試 1: 初始化
echo -e "\n📍 測試 1: MCP 初始化"
echo '{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test-client","version":"1.0.0"}},"id":1}' | node dist/index.js | jq .

# 測試 2: 列出工具
echo -e "\n📍 測試 2: 列出可用工具"
echo '{"jsonrpc":"2.0","method":"tools/list","params":{},"id":2}' | node dist/index.js | jq .

# 測試 3: 工具調用（會因為假的 API key 失敗，但可以驗證工具被正確調用）
echo -e "\n📍 測試 3: 測試工具調用結構"
echo '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"perplexity_search_web","arguments":{"query":"test query"}},"id":3}' | node dist/index.js | jq .

echo -e "\n✅ stdio 模式測試完成！"