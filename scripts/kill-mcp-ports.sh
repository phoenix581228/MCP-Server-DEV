#!/bin/bash

# MCP Server Port Kill Script
# 用於快速釋放 MCP Server 占用的端口

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# MCP 保留端口
MCP_PORTS=(8765 6333 5432 3000 8080 9997 1234 11434)

echo -e "${BLUE}=== MCP Server Port Kill Utility ===${NC}"

# 檢查參數
if [ "$1" == "--all" ]; then
    echo -e "${YELLOW}準備終止所有 MCP 端口的程序...${NC}"
    
    for port in "${MCP_PORTS[@]}"; do
        if lsof -ti:$port >/dev/null 2>&1; then
            echo -e "終止端口 $port 的程序..."
            kill $(lsof -ti:$port) 2>/dev/null
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✅ Port $port 已釋放${NC}"
            else
                echo -e "${RED}❌ Port $port 釋放失敗${NC}"
            fi
        fi
    done
    
elif [ -n "$1" ]; then
    # 終止特定端口
    port=$1
    
    # 檢查是否為 MCP 保留端口
    if [[ " ${MCP_PORTS[@]} " =~ " ${port} " ]]; then
        if lsof -ti:$port >/dev/null 2>&1; then
            process_info=$(lsof -ti:$port | xargs ps -p 2>/dev/null | tail -n 1)
            echo -e "${YELLOW}準備終止端口 $port 的程序：${NC}"
            echo "$process_info"
            
            read -p "確定要終止嗎？(y/N) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                kill $(lsof -ti:$port)
                if [ $? -eq 0 ]; then
                    echo -e "${GREEN}✅ Port $port 已釋放${NC}"
                else
                    echo -e "${RED}❌ 釋放失敗，嘗試強制終止...${NC}"
                    kill -9 $(lsof -ti:$port)
                fi
            else
                echo -e "${YELLOW}已取消${NC}"
            fi
        else
            echo -e "${GREEN}Port $port 未被使用${NC}"
        fi
    else
        echo -e "${RED}錯誤：$port 不是 MCP 保留端口${NC}"
        echo -e "MCP 保留端口：${MCP_PORTS[@]}"
    fi
    
else
    # 顯示使用說明
    echo "使用方式："
    echo "  $0 <port>    - 終止特定端口的程序"
    echo "  $0 --all     - 終止所有 MCP 端口的程序"
    echo ""
    echo "MCP 保留端口："
    echo "  8765  - OpenMemory MCP API"
    echo "  6333  - Qdrant Vector DB"
    echo "  5432  - PostgreSQL"
    echo "  3000  - OpenMemory Web UI"
    echo "  8080  - Perplexity HTTP/SSE"
    echo "  9997  - Xinference API"
    echo "  1234  - LM Studio API"
    echo "  11434 - Ollama API"
fi