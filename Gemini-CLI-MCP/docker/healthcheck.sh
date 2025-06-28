#!/bin/bash

# Gemini MCP Server Health Check

# 檢查 Python 進程是否在運行
if pgrep -f "gemini_mcp_server.py" > /dev/null; then
    echo "✅ Gemini MCP Server process is running"
    exit 0
else
    echo "❌ Gemini MCP Server process not found"
    exit 1
fi