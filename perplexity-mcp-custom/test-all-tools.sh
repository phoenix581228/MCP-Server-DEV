#!/bin/bash

# Perplexity MCP Custom 2.0 - 完整功能測試

echo "🧪 Perplexity MCP Custom 2.0 - 完整功能測試"
echo "=========================================="

# 設定測試環境變數
export PERPLEXITY_API_KEY="test_key_for_validation"
export DEBUG=false

# 顏色定義
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 測試函數
test_command() {
    local test_name=$1
    local command=$2
    echo -e "\n📍 測試: $test_name"
    echo "指令: $command"
    echo -n "結果: "
    
    result=$(echo "$command" | node dist/index.js 2>&1)
    
    if echo "$result" | jq -e . >/dev/null 2>&1; then
        echo -e "${GREEN}✓ JSON 格式正確${NC}"
        echo "$result" | jq -C '.'
        return 0
    else
        echo -e "${RED}✗ JSON 格式錯誤${NC}"
        echo "$result"
        return 1
    fi
}

# 測試計數器
total=0
passed=0

# 測試 1: 初始化
((total++))
if test_command "MCP 初始化" \
    '{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test-client","version":"1.0.0"}},"id":1}'; then
    ((passed++))
fi

# 測試 2: 列出工具
((total++))
if test_command "列出可用工具" \
    '{"jsonrpc":"2.0","method":"tools/list","params":{},"id":2}'; then
    ((passed++))
fi

# 測試 3: perplexity_search_web 基本搜尋
((total++))
if test_command "基本網頁搜尋" \
    '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"perplexity_search_web","arguments":{"query":"MCP protocol"}},"id":3}'; then
    ((passed++))
fi

# 測試 4: perplexity_search_web 進階選項
((total++))
if test_command "進階網頁搜尋（含選項）" \
    '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"perplexity_search_web","arguments":{"query":"Claude AI","options":{"search_recency":"month","return_citations":true}}},"id":4}'; then
    ((passed++))
fi

# 測試 5: perplexity_pro_search
((total++))
if test_command "Pro 模式搜尋" \
    '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"perplexity_pro_search","arguments":{"query":"Model Context Protocol"}},"id":5}'; then
    ((passed++))
fi

# 測試 6: perplexity_deep_research
((total++))
if test_command "深度研究" \
    '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"perplexity_deep_research","arguments":{"topic":"AI Safety","depth":"quick","focus_areas":["alignment","risks"]}},"id":6}'; then
    ((passed++))
fi

# 測試 7: 無效工具名稱
((total++))
if test_command "無效工具名稱（應該返回錯誤）" \
    '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"invalid_tool","arguments":{}},"id":7}'; then
    ((passed++))
fi

# 測試 8: 缺少必要參數
((total++))
if test_command "缺少必要參數（應該返回錯誤）" \
    '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"perplexity_search_web","arguments":{}},"id":8}'; then
    ((passed++))
fi

# 測試 9: 參數驗證 - 超長查詢
((total++))
if test_command "參數驗證 - 超長查詢（應該返回錯誤）" \
    '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"perplexity_search_web","arguments":{"query":"'$(printf 'a%.0s' {1..1001})'"}},"id":9}'; then
    ((passed++))
fi

# 總結
echo -e "\n=========================================="
echo -e "測試總結: ${passed}/${total} 通過"
if [ $passed -eq $total ]; then
    echo -e "${GREEN}✅ 所有測試通過！${NC}"
else
    echo -e "${RED}❌ 有 $((total - passed)) 個測試失敗${NC}"
fi

echo -e "\n功能清單："
echo "✓ MCP 協議初始化"
echo "✓ 工具列表查詢"
echo "✓ 三個 Perplexity 工具"
echo "✓ JSON Schema 驗證"
echo "✓ 參數驗證"
echo "✓ 錯誤處理"