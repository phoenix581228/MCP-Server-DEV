#!/bin/bash

# 快速測試 HTTP 模式

echo "🧪 快速測試 Perplexity MCP Server HTTP 模式"
echo "========================================="

# 啟動 server
npm start -- --http --port 3333 &
SERVER_PID=$!

# 等待啟動
sleep 2

# 健康檢查
echo "📍 測試健康檢查..."
curl -s http://localhost:3333/health | jq .

# 停止 server
kill $SERVER_PID 2>/dev/null

echo "✅ 測試完成！"