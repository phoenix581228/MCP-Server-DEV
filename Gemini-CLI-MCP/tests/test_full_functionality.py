#!/usr/bin/env python3
"""
完整功能測試

測試 Gemini MCP Server 的所有功能
"""

import asyncio
import os
import sys
from dotenv import load_dotenv

# 載入環境變數
load_dotenv()

# 添加 src 目錄到路徑
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))

async def test_all_tools():
    """測試所有工具功能"""
    print("=" * 60)
    print("🧪 Gemini MCP Server 完整功能測試")
    print("=" * 60)
    
    if not os.getenv("GOOGLE_API_KEY"):
        print("❌ 錯誤：未設置 GOOGLE_API_KEY")
        return False
    
    try:
        from gemini_mcp_server import setup_authentication, chat_tool, generate_tool, analyze_code_tool
        
        # 初始化
        setup_authentication()
        print("✅ MCP Server 初始化成功")
        
        # 測試 1: 對話功能
        print("\n🗣️  測試 1: 對話功能")
        result = await chat_tool({
            "message": "請用一句話解釋什麼是人工智慧？",
            "temperature": 0.3
        })
        print(f"   回應: {result[0].text}")
        
        # 測試 2: 文本生成
        print("\n📝 測試 2: 文本生成")
        result = await generate_tool({
            "prompt": "寫一首關於程式設計的短詩",
            "max_output_tokens": 200,
            "temperature": 0.8
        })
        print(f"   生成內容:\n{result[0].text}")
        
        # 測試 3: 程式碼分析
        print("\n🔍 測試 3: 程式碼分析")
        test_code = """
def bubble_sort(arr):
    n = len(arr)
    for i in range(n):
        for j in range(0, n-i-1):
            if arr[j] > arr[j+1]:
                arr[j], arr[j+1] = arr[j+1], arr[j]
    return arr
        """
        
        result = await analyze_code_tool({
            "code": test_code,
            "language": "python",
            "analysis_type": "optimize"
        })
        print(f"   分析結果:\n{result[0].text[:300]}...")
        
        # 測試 4: 系統指令
        print("\n🎯 測試 4: 系統指令")
        result = await chat_tool({
            "message": "請幫我寫一個 Python 函數來計算階乘",
            "system_instruction": "你是一個專業的 Python 開發者，請提供簡潔高效的程式碼，並包含註解",
            "temperature": 0.1
        })
        print(f"   專業回應:\n{result[0].text}")
        
        print("\n" + "=" * 60)
        print("🎉 所有測試完成！")
        return True
        
    except Exception as e:
        print(f"❌ 測試失敗: {e}")
        return False

async def test_error_handling():
    """測試錯誤處理"""
    print("\n⚠️  錯誤處理測試")
    
    try:
        from gemini_mcp_server import vision_tool
        
        # 測試不存在的圖片檔案
        try:
            await vision_tool({
                "image_path": "/non/existent/image.jpg",
                "question": "描述這張圖片"
            })
        except FileNotFoundError as e:
            print("✅ 檔案不存在錯誤處理正確")
        
        print("✅ 錯誤處理測試通過")
        return True
        
    except Exception as e:
        print(f"❌ 錯誤處理測試失敗: {e}")
        return False

def main():
    """主函數"""
    print("🚀 開始測試...")
    
    # 檢查 API 金鑰
    if not os.getenv("GOOGLE_API_KEY"):
        print("請先設置 GOOGLE_API_KEY 環境變數")
        print("或者建立 .env 檔案並加入: GOOGLE_API_KEY=your_key_here")
        return 1
    
    # 運行測試
    try:
        success1 = asyncio.run(test_all_tools())
        success2 = asyncio.run(test_error_handling())
        
        if success1 and success2:
            print("\n🎊 所有測試都通過了！Gemini MCP Server 準備就緒！")
            return 0
        else:
            print("\n⚠️  部分測試失敗")
            return 1
            
    except KeyboardInterrupt:
        print("\n⏹️  測試被使用者中斷")
        return 1
    except Exception as e:
        print(f"\n💥 測試過程發生錯誤: {e}")
        return 1

if __name__ == "__main__":
    sys.exit(main())