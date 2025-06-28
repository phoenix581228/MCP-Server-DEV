#!/bin/bash
set -e

# Gemini MCP Server Docker Entry Point

echo "🚀 Starting Gemini MCP Server..."

# 檢查必要的環境變數
if [ -z "$GOOGLE_API_KEY" ] && [ "$GOOGLE_GENAI_USE_VERTEXAI" != "true" ]; then
    echo "❌ Error: GOOGLE_API_KEY is required or set GOOGLE_GENAI_USE_VERTEXAI=true"
    exit 1
fi

if [ "$GOOGLE_GENAI_USE_VERTEXAI" = "true" ] && [ -z "$GOOGLE_CLOUD_PROJECT" ]; then
    echo "❌ Error: GOOGLE_CLOUD_PROJECT is required when using Vertex AI"
    exit 1
fi

# 顯示配置資訊
echo "📋 Configuration:"
echo "  - Gemini Model: ${GEMINI_MODEL:-gemini-1.5-flash}"
echo "  - Server Mode: ${MCP_SERVER_MODE:-stdio}"
echo "  - Log Level: ${LOG_LEVEL:-INFO}"

if [ "$GOOGLE_GENAI_USE_VERTEXAI" = "true" ]; then
    echo "  - Using Vertex AI"
    echo "  - Project: $GOOGLE_CLOUD_PROJECT"
    echo "  - Location: ${GOOGLE_CLOUD_LOCATION:-us-central1}"
else
    echo "  - Using Google AI Studio API"
fi

# 等待一下讓日誌輸出
sleep 1

# 執行傳入的命令
exec "$@"