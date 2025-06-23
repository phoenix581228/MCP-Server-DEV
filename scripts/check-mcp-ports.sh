#!/bin/bash

# MCP Server Port Protection Script
# 用於檢查和保護 MCP Server 專用端口

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# MCP 保留端口定義
MCP_PORT_8765="OpenMemory MCP API Server"
MCP_PORT_6333="Qdrant Vector Database"
MCP_PORT_5432="PostgreSQL Database"
MCP_PORT_3000="OpenMemory Web UI"
MCP_PORT_8080="Perplexity HTTP/SSE"
MCP_PORT_9997="Xinference API"
MCP_PORT_1234="LM Studio API"
MCP_PORT_11434="Ollama API"

# 端口列表
MCP_PORTS=(8765 6333 5432 3000 8080 9997 1234 11434)

echo -e "${BLUE}=== MCP Server Port Protection Check ===${NC}"
echo -e "Checking MCP reserved ports...\n"

conflict_count=0
available_count=0

# 檢查每個端口
for port in "${MCP_PORTS[@]}"; do
    # 獲取服務名稱
    var_name="MCP_PORT_${port}"
    service="${!var_name}"
    
    if lsof -ti:$port >/dev/null 2>&1; then
        # 端口被占用
        pids=$(lsof -ti:$port)
        pid_count=$(echo "$pids" | wc -l)
        first_pid=$(echo "$pids" | head -n 1)
        process_info=$(ps -p $first_pid 2>/dev/null | tail -n 1)
        process_name=$(echo "$process_info" | awk '{print $4}')
        
        # 檢查是否為 MCP 相關服務
        # 特殊處理某些已知服務
        is_mcp_service=false
        
        # LM Studio 在 port 1234
        if [[ "$port" == "1234" && "$process_name" =~ "LM" ]]; then
            is_mcp_service=true
        # Xinference 在 port 9997 (Python 進程)
        elif [[ "$port" == "9997" && "$process_name" =~ "Python" ]]; then
            # 檢查是否真的是 xinference
            if ps -p $first_pid -o args= | grep -q "xinference"; then
                is_mcp_service=true
            fi
        # Docker 容器可能是 OpenMemory
        elif [[ "$process_name" =~ "docker" && ("$port" == "3000" || "$port" == "6333" || "$port" == "8765") ]]; then
            # 檢查是否有 OpenMemory 相關的 Docker 容器在運行
            if docker ps 2>/dev/null | grep -q "openmemory"; then
                is_mcp_service=true
            fi
        # 其他已知的 MCP 服務
        elif [[ "$process_name" =~ (openmemory|perplexity|mcp|qdrant|postgres|ollama) ]]; then
            is_mcp_service=true
        fi
        
        if [ "$is_mcp_service" = true ]; then
            echo -e "${GREEN}✅ Port $port${NC} - $service (正常使用中)"
        else
            echo -e "${RED}❌ Port $port${NC} - $service"
            echo -e "   ${YELLOW}被非 MCP 程序占用: $process_name${NC}"
            if [ $pid_count -gt 1 ]; then
                echo -e "   PIDs: $(echo $pids | tr '\n' ' ')"
            else
                echo -e "   PID: $first_pid"
            fi
            echo -e "   終止指令: ${RED}kill $first_pid${NC}"
            ((conflict_count++))
        fi
    else
        # 端口可用
        echo -e "${GREEN}✅ Port $port${NC} - $service (可用)"
        ((available_count++))
    fi
done

echo -e "\n${BLUE}=== 總結 ===${NC}"
echo -e "可用端口: ${GREEN}$available_count${NC}"
echo -e "衝突端口: ${RED}$conflict_count${NC}"

if [ $conflict_count -gt 0 ]; then
    echo -e "\n${YELLOW}⚠️  警告：發現端口衝突！${NC}"
    echo -e "請解決衝突後再啟動 MCP 服務。"
    exit 1
else
    echo -e "\n${GREEN}✅ 所有 MCP 端口已受保護${NC}"
    exit 0
fi