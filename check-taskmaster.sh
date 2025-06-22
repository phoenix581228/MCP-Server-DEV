#!/bin/bash

echo "🔍 檢查 Task Master AI MCP Server 狀態..."
echo "========================================="

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 檢查最新版本
echo -e "\n${YELLOW}檢查最新版本...${NC}"
LATEST_VERSION=$(npm view task-master-ai version 2>/dev/null)
echo "最新版本: $LATEST_VERSION"

# 檢查更新記錄
echo -e "\n${YELLOW}檢查最近更新...${NC}"
npm view task-master-ai time.modified 2>/dev/null

# 測試功能
echo -e "\n${YELLOW}測試 MCP 初始化...${NC}"
TEST_OUTPUT=$(echo '{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0.0"}},"id":1}' | npx -y task-master-ai 2>&1 | head -20)

if echo "$TEST_OUTPUT" | grep -q "No configuration file found in project"; then
    echo -e "${RED}❌ Task Master AI 仍有無限循環 bug${NC}"
    echo -e "${RED}   問題未修復，請使用替代方案${NC}"
else
    echo -e "${GREEN}✅ Task Master AI 可能已修復！${NC}"
    echo -e "${GREEN}   請進行完整測試確認${NC}"
fi

echo -e "\n${YELLOW}GitHub Issue 連結:${NC}"
echo "https://github.com/eyaltoledano/claude-task-master/discussions/680"

echo -e "\n========================================="
echo "檢查完成！"