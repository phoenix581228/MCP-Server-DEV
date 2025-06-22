#!/bin/bash

# 測試 Perplexity MCP Server HTTP 模式

echo "🧪 測試 Perplexity MCP Server HTTP 模式"
echo "========================================="

# 檢查環境變數
if [ -z "$PERPLEXITY_API_KEY" ]; then
    echo "❌ 錯誤：需要設定 PERPLEXITY_API_KEY"
    exit 1
fi

# 啟動 HTTP server
echo "🚀 啟動 HTTP server on port 3000..."
DEBUG=true npm start -- --http --port 3000 &
SERVER_PID=$!

# 等待 server 啟動
echo "⏳ 等待 server 啟動..."
sleep 3

# 測試健康檢查端點
echo -e "\n📍 測試健康檢查端點..."
curl -s http://localhost:3000/health | jq .

# 測試初始化請求
echo -e "\n📍 測試 MCP 初始化..."
INIT_RESPONSE=$(curl -s -X POST http://localhost:3000/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "initialize",
    "params": {
      "protocolVersion": "2024-11-05",
      "capabilities": {},
      "clientInfo": {
        "name": "test-client",
        "version": "1.0.0"
      }
    },
    "id": 1
  }')

echo "$INIT_RESPONSE" | jq .

# 提取 session ID
SESSION_ID=$(echo "$INIT_RESPONSE" | jq -r '.sessionId // empty')

if [ -z "$SESSION_ID" ]; then
    echo "❌ 無法獲取 session ID"
    kill $SERVER_PID
    exit 1
fi

echo -e "\n✅ 獲得 Session ID: $SESSION_ID"

# 測試列出工具
echo -e "\n📍 測試列出工具..."
curl -s -X POST http://localhost:3000/mcp \
  -H "Content-Type: application/json" \
  -H "MCP-Session-Id: $SESSION_ID" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/list",
    "params": {},
    "id": 2
  }' | jq .

# 測試搜尋功能
echo -e "\n📍 測試搜尋功能..."
curl -s -X POST http://localhost:3000/mcp \
  -H "Content-Type: application/json" \
  -H "MCP-Session-Id: $SESSION_ID" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {
      "name": "perplexity_search_web",
      "arguments": {
        "query": "What is MCP Model Context Protocol?"
      }
    },
    "id": 3
  }' | jq .

# 測試 SSE 連接
echo -e "\n📍 測試 SSE 連接..."
echo "建立 SSE 連接 (按 Ctrl+C 停止)..."
curl -N -H "MCP-Session-Id: $SESSION_ID" \
     -H "Accept: text/event-stream" \
     http://localhost:3000/mcp &
SSE_PID=$!

sleep 2

# 清理
echo -e "\n🧹 清理..."
kill $SSE_PID 2>/dev/null
kill $SERVER_PID

echo -e "\n✅ 測試完成！"