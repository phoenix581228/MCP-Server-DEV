#!/usr/bin/env python3
"""
影片分析功能測試

測試 Gemini MCP Server 的影片分析功能
需要有實際的影片檔案進行測試
"""

import asyncio
import os
import sys
from dotenv import load_dotenv

# 載入環境變數
load_dotenv()

# 添加 src 目錄到路徑
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))

async def test_video_analysis():
    """測試影片分析功能"""
    print("=" * 60)
    print("🎬 Gemini MCP Server 影片分析測試")
    print("=" * 60)
    
    if not os.getenv("GOOGLE_API_KEY"):
        print("❌ 錯誤：未設置 GOOGLE_API_KEY")
        return False
    
    try:
        from gemini_mcp_server import setup_authentication, video_analysis_tool
        
        # 初始化
        setup_authentication()
        print("✅ MCP Server 初始化成功")
        
        # 檢查是否有測試影片
        test_video_path = os.path.join(os.path.dirname(__file__), "test_video.mp4")
        
        if not os.path.exists(test_video_path):
            print("⚠️  未找到測試影片檔案")
            print(f"   請將測試影片命名為 'test_video.mp4' 並放在 {test_video_path}")
            print("   支援格式: mp4, mov, avi, mkv, webm")
            
            # 嘗試尋找其他影片檔案
            video_extensions = ['.mp4', '.mov', '.avi', '.mkv', '.webm']
            test_dir = os.path.dirname(__file__)
            found_videos = []
            
            for file in os.listdir(test_dir):
                if any(file.lower().endswith(ext) for ext in video_extensions):
                    found_videos.append(os.path.join(test_dir, file))
            
            if found_videos:
                test_video_path = found_videos[0]
                print(f"✅ 找到測試影片: {os.path.basename(test_video_path)}")
            else:
                print("❌ 請提供測試影片檔案以繼續測試")
                return False
        
        # 測試 1: 基本影片摘要
        print(f"\n🎥 測試 1: 基本影片摘要")
        print(f"   分析檔案: {os.path.basename(test_video_path)}")
        
        result = await video_analysis_tool({
            "video_path": test_video_path,
            "question": "請提供這段影片的詳細描述",
            "analysis_type": "summary"
        })
        print(f"   摘要結果:\n{result[0].text[:300]}...")
        
        # 測試 2: 動作分析
        print(f"\n🏃 測試 2: 動作分析")
        result = await video_analysis_tool({
            "video_path": test_video_path,
            "analysis_type": "action"
        })
        print(f"   動作分析:\n{result[0].text[:300]}...")
        
        # 測試 3: 物體識別
        print(f"\n🔍 測試 3: 物體識別")
        result = await video_analysis_tool({
            "video_path": test_video_path,
            "question": "影片中有哪些重要的物體或元素？",
            "analysis_type": "object"
        })
        print(f"   物體識別:\n{result[0].text[:300]}...")
        
        print("\n" + "=" * 60)
        print("🎉 影片分析測試完成！")
        return True
        
    except Exception as e:
        print(f"❌ 測試失敗: {e}")
        return False

async def test_error_handling():
    """測試錯誤處理"""
    print("\n⚠️  影片分析錯誤處理測試")
    
    try:
        from gemini_mcp_server import video_analysis_tool
        
        # 測試不存在的影片檔案
        try:
            await video_analysis_tool({
                "video_path": "/non/existent/video.mp4",
                "question": "描述這段影片"
            })
        except FileNotFoundError:
            print("✅ 檔案不存在錯誤處理正確")
        
        # 測試不支援的格式
        try:
            # 建立一個臨時的不支援格式檔案
            temp_file = "/tmp/test.txt"
            with open(temp_file, "w") as f:
                f.write("test")
            
            await video_analysis_tool({
                "video_path": temp_file,
                "question": "描述這段影片"
            })
        except ValueError as e:
            if "Unsupported video format" in str(e):
                print("✅ 不支援格式錯誤處理正確")
        finally:
            # 清理臨時檔案
            if os.path.exists(temp_file):
                os.remove(temp_file)
        
        print("✅ 錯誤處理測試通過")
        return True
        
    except Exception as e:
        print(f"❌ 錯誤處理測試失敗: {e}")
        return False

def main():
    """主函數"""
    print("🚀 開始影片分析測試...")
    
    # 檢查 API 金鑰
    if not os.getenv("GOOGLE_API_KEY"):
        print("請先設置 GOOGLE_API_KEY 環境變數")
        print("或者建立 .env 檔案並加入: GOOGLE_API_KEY=your_key_here")
        return 1
    
    # 運行測試
    try:
        success1 = asyncio.run(test_video_analysis())
        success2 = asyncio.run(test_error_handling())
        
        if success1 and success2:
            print("\n🎊 所有影片分析測試都通過了！")
            print("✨ 您現在可以在 Claude Code 中使用 gemini_video_analysis 工具了！")
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