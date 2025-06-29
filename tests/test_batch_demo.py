#!/usr/bin/env python3
"""
批量影片場記分析功能演示
"""

import os
import asyncio
import json
from pathlib import Path

# 設定 API 金鑰
os.environ['GOOGLE_API_KEY'] = "AIzaSyD5d2sfGCNN7FJQM-GHi5cndJJ2_uIxDpU"

import sys
sys.path.insert(0, 'src')

async def demo_batch_analysis():
    """演示批量分析功能（無需真實影片檔案）"""
    print("🎬 北斗七星批量影片場記分析演示")
    print("=" * 50)
    
    # 設置認證
    from gemini_mcp_server import setup_authentication
    setup_authentication()
    print("✅ Gemini API 認證成功")
    
    # 創建測試資料夾
    test_folder = "/tmp/demo_videos"
    os.makedirs(test_folder, exist_ok=True)
    print(f"📁 創建測試資料夾: {test_folder}")
    
    # 模擬場記分析請求結構
    demo_request = {
        "folder_path": test_folder,
        "output_filename": "demo_script_analysis.json",
        "analysis_detail": "detailed",
        "include_technical_analysis": True,
        "max_concurrent_videos": 2
    }
    
    print("\n📋 分析參數:")
    for key, value in demo_request.items():
        print(f"  - {key}: {value}")
    
    # 展示預期的 JSON 輸出格式
    demo_output = {
        "project_name": "demo_videos",
        "analysis_timestamp": "2025-06-29T15:30:00Z",
        "total_videos": 3,
        "analysis_settings": {
            "detail_level": "detailed",
            "technical_analysis": True,
            "max_concurrent": 2
        },
        "videos": [
            {
                "filename": "scene_01.mp4",
                "file_path": "/tmp/demo_videos/scene_01.mp4",
                "file_size": "45.2 MB",
                "analysis_status": "completed",
                "analysis": {
                    "summary": "開場場景：主角登場，建立故事背景",
                    "scenes": [
                        {
                            "timestamp": "00:00-00:30",
                            "description": "室內客廳場景，溫暖燈光",
                            "characters": ["主角", "配角A"],
                            "actions": ["開門進入", "打招呼"],
                            "dialogue": "你好，很高興見到你",
                            "visual_elements": ["沙發", "茶几", "書架"],
                            "camera_movement": "從門口推進到中景"
                        },
                        {
                            "timestamp": "00:30-01:00",
                            "description": "對話場景，情感建立",
                            "characters": ["主角", "配角A"],
                            "actions": ["坐下", "倒茶"],
                            "dialogue": "這次的計劃需要你的幫助",
                            "visual_elements": ["茶具", "文件"],
                            "camera_movement": "反打鏡頭對話"
                        }
                    ],
                    "technical_notes": {
                        "lighting": "溫暖色調，主要使用自然光加輔助燈",
                        "audio_quality": "清晰對話，背景音樂輕柔",
                        "camera_angle": "多用中景和特寫，營造親密感",
                        "editing_notes": "節奏平穩，適合開場建立氛圍"
                    }
                }
            },
            {
                "filename": "action_scene.mp4",
                "file_path": "/tmp/demo_videos/action_scene.mp4",
                "file_size": "78.5 MB",
                "analysis_status": "completed",
                "analysis": {
                    "summary": "動作場景：緊張追逐，衝突高潮",
                    "scenes": [
                        {
                            "timestamp": "00:00-00:45",
                            "description": "街道追逐場景",
                            "characters": ["主角", "反派", "路人"],
                            "actions": ["奔跑", "追逐", "躲避"],
                            "dialogue": "站住！不要跑！",
                            "visual_elements": ["汽車", "建築物", "人群"],
                            "camera_movement": "手持攝影，跟隨運動"
                        }
                    ],
                    "technical_notes": {
                        "lighting": "自然光，對比強烈",
                        "audio_quality": "環境音豐富，腳步聲清晰",
                        "camera_angle": "多角度快切，增加緊張感",
                        "editing_notes": "快節奏剪輯，增強動感"
                    }
                }
            }
        ],
        "project_summary": {
            "main_themes": ["友情", "冒險", "成長"],
            "key_characters": ["主角", "配角A", "反派"],
            "production_notes": "共分析 2 個影片檔案，建議在後製時注意音效平衡"
        }
    }
    
    # 儲存演示 JSON
    output_path = os.path.join(test_folder, "demo_script_analysis.json")
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(demo_output, f, ensure_ascii=False, indent=2)
    
    print(f"\n📄 演示 JSON 報告已生成: {output_path}")
    
    # 顯示 JSON 結構
    print("\n🎭 場記報告結構預覽:")
    print(f"  📂 專案名稱: {demo_output['project_name']}")
    print(f"  📊 影片數量: {demo_output['total_videos']}")
    print(f"  📅 分析時間: {demo_output['analysis_timestamp']}")
    print(f"  ⚙️  分析設定: {demo_output['analysis_settings']['detail_level']}")
    
    print("\n🎬 影片分析內容:")
    for i, video in enumerate(demo_output['videos']):
        print(f"  {i+1}. {video['filename']} ({video['file_size']})")
        print(f"     📝 摘要: {video['analysis']['summary']}")
        print(f"     🎞️  場景數: {len(video['analysis']['scenes'])}")
        
        if video['analysis']['scenes']:
            first_scene = video['analysis']['scenes'][0]
            print(f"     ⏰ 首場景: {first_scene['timestamp']}")
            print(f"     🎭 人物: {', '.join(first_scene['characters'])}")
    
    print(f"\n🎯 專案主題: {', '.join(demo_output['project_summary']['main_themes'])}")
    print(f"👥 主要角色: {', '.join(demo_output['project_summary']['key_characters'])}")
    
    # 展示實際工具調用格式
    print("\n" + "=" * 50)
    print("📱 MCP 工具調用格式:")
    print("""
gemini_batch_video_script_analysis({
  "folder_path": "/path/to/your/videos",
  "output_filename": "project_script_analysis.json",
  "analysis_detail": "detailed",
  "include_technical_analysis": true,
  "max_concurrent_videos": 2
})
""")
    
    print("✅ 演示完成！")
    print("\n💡 使用說明:")
    print("1. 將影片檔案放在同一資料夾中")
    print("2. 使用上述 MCP 工具調用格式")
    print("3. 系統會自動分析所有支援的影片格式")
    print("4. 生成的 JSON 報告包含詳細的場記資訊")
    print("5. 支援的格式: mp4, mov, avi, mkv, webm, m4v")
    
    # 清理
    os.remove(output_path)
    os.rmdir(test_folder)
    print("\n🧹 清理完成")

if __name__ == "__main__":
    asyncio.run(demo_batch_analysis())