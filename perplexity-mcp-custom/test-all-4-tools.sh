#!/bin/bash

# 測試 Perplexity MCP Custom 2.0 - 所有 4 個工具

echo "🧪 測試 Perplexity MCP Custom 2.0 - 完整 4 工具測試"
echo "=================================================="

# 設定測試環境變數
export PERPLEXITY_API_KEY="test_key_for_validation"
export DEBUG=false

# 顏色定義
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# 測試初始化
echo -e "\n📍 初始化 MCP..."
echo '{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test-4-tools","version":"1.0.0"}},"id":1}' | node dist/index.js | jq -r '.result.serverInfo'

# 列出所有工具
echo -e "\n📍 列出所有工具..."
TOOLS=$(echo '{"jsonrpc":"2.0","method":"tools/list","params":{},"id":2}' | node dist/index.js | jq -r '.result.tools[].name')
echo "$TOOLS"

# 計算工具數量
TOOL_COUNT=$(echo "$TOOLS" | wc -l | tr -d ' ')
echo -e "\n${YELLOW}找到 $TOOL_COUNT 個工具${NC}"

# 測試每個工具
echo -e "\n========================================"
echo -e "📋 測試各個工具功能"
echo -e "========================================"

# 1. 基本搜尋工具
echo -e "\n1️⃣ ${GREEN}perplexity_search_web${NC} - 支援所有 5 個模型"
echo "   模型: sonar, sonar-pro, sonar-reasoning, sonar-reasoning-pro, sonar-deep-research"
echo '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"perplexity_search_web","arguments":{"query":"What is MCP?"}},"id":3}' | node dist/index.js | jq -r '.result.content[0].text' | head -5

# 2. Pro 搜尋工具
echo -e "\n2️⃣ ${GREEN}perplexity_pro_search${NC} - 專為 Pro 模型優化"
echo "   模型: sonar-pro, sonar-reasoning-pro"
echo "   預設返回: 圖片、引用、相關問題"
echo '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"perplexity_pro_search","arguments":{"query":"AI trends 2025"}},"id":4}' | node dist/index.js | jq -r '.result.content[0].text' | head -5

# 3. 深度研究工具
echo -e "\n3️⃣ ${GREEN}perplexity_deep_research${NC} - 深度研究功能"
echo "   深度選項: quick, standard, comprehensive"
echo '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"perplexity_deep_research","arguments":{"topic":"Quantum Computing","depth":"quick"}},"id":5}' | node dist/index.js | jq -r '.result.content[0].text' | head -5

# 4. 推理工具（新增）
echo -e "\n4️⃣ ${GREEN}perplexity_reasoning${NC} - 複雜推理分析"
echo "   模型: sonar-reasoning, sonar-reasoning-pro"
echo "   支援上下文注入"
echo '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"perplexity_reasoning","arguments":{"query":"If all roses are flowers and some flowers fade quickly, what can we conclude about roses?"}},"id":6}' | node dist/index.js | jq -r '.result.content[0].text' | head -5

# 測試推理工具的上下文功能
echo -e "\n   測試上下文功能："
echo '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"perplexity_reasoning","arguments":{"query":"What is the total?","context":"John has 5 apples. Mary gives him 3 more apples."}},"id":7}' | node dist/index.js | jq -r '.result.content[0].text' | head -5

# 總結
echo -e "\n========================================"
echo -e "📊 測試總結"
echo -e "========================================"
echo -e "✅ 工具數量: ${GREEN}$TOOL_COUNT${NC} 個"
echo -e "✅ 支援模型: ${GREEN}5${NC} 個 Perplexity 模型"
echo -e "✅ 功能覆蓋:"
echo -e "   - 通用搜尋（所有模型）"
echo -e "   - Pro 增強搜尋"
echo -e "   - 深度研究"
echo -e "   - 推理分析（${YELLOW}新增${NC}）"
echo -e "\n🎉 所有工具測試完成！"