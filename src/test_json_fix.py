#!/usr/bin/env python3
"""
測試智能JSON提取器對真實BigDipper數據的修復效果
"""

import json
import sys
import os
from pathlib import Path

# 確保可以導入json_extractor
sys.path.insert(0, str(Path(__file__).parent))

from json_extractor import IntelligentJSONExtractor

def load_sample_data():
    """載入花社大無人機的實際場記數據進行測試"""
    sample_file = "/Users/chih-hungtseng/Movies/花社大無人機/花社大無人機_場記分析_付費版.json"
    
    try:
        with open(sample_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
        return data
    except Exception as e:
        print(f"無法載入測試數據: {e}")
        return None

def test_string_wrapped_json():
    """測試字串包裝的JSON解析"""
    
    # 模擬BigDipper中的問題數據
    problematic_response = '''```json
{
  "summary": "一位台灣無人機飛手分享了他接觸無人機並成為職業飛手的經歷。他描述了從2011年觀看一場無人機比賽開始，對無人機產生興趣，並在父親的啟發下開始練習。2016年，他贏得了台灣亞拓杯無人機比賽的第一名，並獲得廠商簽約成為廠機師。",
  "drone_analysis": {
    "flight_patterns": ["定點懸停"],
    "altitude_ranges": "低空（估計<5m）",
    "shooting_techniques": ["定點拍攝", "人物訪談"]
  },
  "scenes": [
    {
      "timestamp": "00:00-02:36",
      "description": "在學校操場拍攝，背景是教學樓和部分街景。",
      "flight_action": "定點懸停",
      "subjects": ["人物"],
      "technical_notes": "無人機保持靜止，主要捕捉人物訪談畫面。"
    }
  ],
  "technical_analysis": {
    "image_quality": "畫面清晰穩定，光線充足，色彩自然。",
    "flight_performance": "飛行平穩，無明顯抖動或漂移。",
    "equipment_assessment": "推測使用消費級或專業級無人機，配備雲台穩定器。"
  }
}
```'''
    
    print("測試智能JSON提取器對字串包裝JSON的處理...")
    
    extractor = IntelligentJSONExtractor()
    result = extractor.extract_json_from_response(problematic_response)
    
    print(f"✅ 提取成功: {result.get('_metadata', {}).get('extraction_success', False)}")
    print(f"📊 提取方法: {result.get('_metadata', {}).get('extraction_method', 'unknown')}")
    print(f"📝 摘要內容: {result.get('summary', 'N/A')[:100]}...")
    print(f"🎬 場景數量: {len(result.get('scenes', []))}")
    print(f"🔧 技術分析: {'有' if result.get('technical_analysis') else '無'}")
    
    return result

def test_real_bigdipper_data():
    """測試真實BigDipper數據的解析"""
    print("\n測試真實BigDipper數據解析...")
    
    data = load_sample_data()
    if not data:
        print("❌ 無法載入測試數據")
        return None
    
    print(f"載入數據: {data.get('total_videos', 0)} 支影片")
    
    extractor = IntelligentJSONExtractor()
    fixed_count = 0
    problem_count = 0
    
    # 測試前幾個影片的數據
    for video in data.get('videos', [])[:5]:  # 只測試前5個
        analysis = video.get('analysis', {})
        summary = analysis.get('summary', '')
        
        # 檢查是否為字串包裝的JSON
        if isinstance(summary, str) and '```json' in summary:
            problem_count += 1
            print(f"\n發現問題數據: {video.get('filename', 'unknown')}")
            
            # 嘗試修復
            fixed_result = extractor.extract_json_from_response(summary)
            if fixed_result.get('_metadata', {}).get('extraction_success', False):
                fixed_count += 1
                print(f"  ✅ 修復成功: {fixed_result.get('_metadata', {}).get('extraction_method')}")
                print(f"  📝 修復後摘要: {fixed_result.get('summary', 'N/A')[:80]}...")
            else:
                print(f"  ❌ 修復失敗")
    
    print(f"\n統計結果:")
    print(f"  發現問題數據: {problem_count}")
    print(f"  成功修復: {fixed_count}")
    print(f"  修復成功率: {(fixed_count/max(1,problem_count))*100:.1f}%")
    
    # 顯示提取器統計
    stats = extractor.get_extraction_stats()
    print(f"\n提取器統計:")
    for key, value in stats.items():
        print(f"  {key}: {value}")

def test_fallback_mechanism():
    """測試回退機制"""
    print("\n測試回退機制...")
    
    # 測試完全無效的輸入
    invalid_inputs = [
        "",
        "這不是JSON",
        "{invalid json}",
        "```\n無效內容\n```"
    ]
    
    extractor = IntelligentJSONExtractor()
    
    for i, invalid_input in enumerate(invalid_inputs, 1):
        print(f"\n測試無效輸入 {i}: '{invalid_input[:20]}...'")
        result = extractor.extract_json_from_response(invalid_input)
        
        print(f"  回退機制啟動: {result.get('_metadata', {}).get('extraction_method') == 'fallback'}")
        print(f"  需要手動審核: {result.get('_metadata', {}).get('requires_manual_review', False)}")
        print(f"  有基本結構: {'video_metadata' in result}")

def main():
    """主測試函數"""
    print("🧪 BigDipper JSON修復效果測試")
    print("=" * 50)
    
    # 測試1: 字串包裝JSON
    test_string_wrapped_json()
    
    # 測試2: 真實BigDipper數據
    test_real_bigdipper_data()
    
    # 測試3: 回退機制
    test_fallback_mechanism()
    
    print("\n" + "=" * 50)
    print("✅ 測試完成！")

if __name__ == "__main__":
    main()