#!/usr/bin/env python3
"""
Gemini MCP Server 連接測試

測試 MCP Server 的基本功能和連接性
"""

import asyncio
import json
import os
import sys
from typing import Dict, Any

# 添加 src 目錄到路徑
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))

async def test_mcp_connection():
    """測試 MCP 伺服器連接"""
    print("🧪 測試 Gemini MCP Server 連接...")
    
    try:
        from gemini_mcp_server import GeminiMCPServer
        
        # 檢查環境變數
        if not os.getenv("GOOGLE_API_KEY") and os.getenv("GOOGLE_GENAI_USE_VERTEXAI") != "true":
            print("⚠️  警告：未設置 GOOGLE_API_KEY，需要設置環境變數進行完整測試")
            return False
        
        # 建立伺服器實例
        server = GeminiMCPServer()
        print("✅ MCP Server 初始化成功")
        
        # 測試工具列表
        tools_result = await server.server.list_tools()()
        print(f"✅ 工具列表獲取成功，共 {len(tools_result.tools)} 個工具:")
        for tool in tools_result.tools:
            print(f"   - {tool.name}: {tool.description}")
        
        return True
        
    except Exception as e:
        print(f"❌ 測試失敗: {e}")
        return False

async def test_gemini_functionality():
    """測試 Gemini 功能"""
    print("\n🤖 測試 Gemini 功能...")
    
    if not os.getenv("GOOGLE_API_KEY"):
        print("⚠️  跳過 Gemini 功能測試（需要 GOOGLE_API_KEY）")
        return True
    
    try:
        from gemini_mcp_server import GeminiMCPServer
        
        server = GeminiMCPServer()
        
        # 測試基本對話
        test_args = {
            "message": "Hello, 請用繁體中文回答：1+1等於多少？",
            "temperature": 0.1
        }
        
        result = await server._chat(test_args)
        print("✅ 對話功能測試成功")
        print(f"   回應: {result.content[0].text[:100]}...")
        
        # 測試程式碼分析
        code_args = {
            "code": "def hello():\n    print('Hello World')",
            "language": "python",
            "analysis_type": "explain"
        }
        
        result = await server._analyze_code(code_args)
        print("✅ 程式碼分析功能測試成功")
        
        return True
        
    except Exception as e:
        print(f"❌ Gemini 功能測試失敗: {e}")
        return False

def main():
    """主函數"""
    print("=" * 50)
    print("Gemini MCP Server 測試套件")
    print("=" * 50)
    
    # 運行測試
    tests = [
        test_mcp_connection,
        test_gemini_functionality
    ]
    
    passed = 0
    total = len(tests)
    
    for test in tests:
        result = asyncio.run(test())
        if result:
            passed += 1
    
    print(f"\n📊 測試結果: {passed}/{total} 通過")
    
    if passed == total:
        print("🎉 所有測試通過！")
        return 0
    else:
        print("⚠️  部分測試失敗")
        return 1

if __name__ == "__main__":
    sys.exit(main())