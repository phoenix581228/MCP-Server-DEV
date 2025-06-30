#!/usr/bin/env python3
"""
最終人物引言Bug修復測試
"""

import asyncio
import os
import sys
from pathlib import Path

# 設定環境變數
os.environ['GOOGLE_API_KEY'] = 'AIzaSyAl-FjDm7RKaRX_q-oKqQ7H4SgXF4bBqoY'

# 確保可以導入模組
sys.path.insert(0, str(Path(__file__).parent))

from llm_semantic_analyzer import LLMSemanticAnalyzer

def load_test_article():
    """載入測試文章"""
    return """
發展科技應用能力　市公所攜手花蓮社大點燃無人機學習熱潮

隨著科技進步與應用場域擴展，無人機已從軍事科技走入民間生活。為推廣無人機知識與應用實務，花蓮市公所、花蓮縣社區大學與台灣國際無人機競技發展協會花蓮分會於28日上午，在化仁國中聯合舉辦「無人機時代來了」技術講座，競技遙控模型直升機世界冠軍林佐翰也現場展演穿越機及無人直升機飛行控制技巧。

**世界冠軍現場展演震撼全場**

由無人機飛齡11年，榮獲競技遙控模型直升機世界冠軍的林佐翰現場展演穿越機（FPV racing drone）與無人直升機飛行控制（Flight Control）技巧，只見他以精準飛控、疾速轉彎與高難度動作操作無人機，展現世界級競技實力。

林佐翰表示，2016年參加亞拓盃榮獲直升機組第一名，獲廠商青睞簽約成為試飛員。他期望更多年輕人投入，相信台灣飛手實力堅強。

市長魏嘉彥指出，花蓮市公所全力支持科技教育發展，希望透過這樣的活動讓更多民眾了解無人機的實用性。

理事長張孟義也強調，協會將持續推動無人機技術的普及化，讓這項技術真正走入民間應用。
"""

async def test_llm_quote_fix():
    """測試LLM引言修復"""
    
    print("🚀 最終測試 - LLM驅動的人物引言Bug修復")
    print("=" * 60)
    
    analyzer = LLMSemanticAnalyzer()
    result = await analyzer.analyze_article(load_test_article(), "無人機技術講座報導")
    
    print(f"\n📊 LLM系統分析結果:")
    
    # 檢查元數據
    metadata = result["article_metadata"]
    print(f"  供應商: {metadata.get('llm_provider_used', 'unknown')}")
    print(f"  Token數: {metadata.get('llm_tokens_used', 0)}")
    print(f"  成本: ${metadata.get('llm_cost', 0):.6f}")
    print(f"  響應時間: {metadata.get('llm_response_time', 0):.2f}秒")
    
    # 分析人物
    persons = result["key_entities"]["persons"]
    print(f"\n👥 識別到的人物數量: {len(persons)}")
    
    person_quote_mapping = {}
    
    for person in persons:
        print(f"\n  👤 {person['name']} ({person['title']})")
        if person['quotes']:
            print(f"     引言: {person['quotes']}")
            person_quote_mapping[person['name']] = person['quotes']
        else:
            print(f"     引言: 無")
            person_quote_mapping[person['name']] = []
    
    # 分析引言歸屬準確性
    print(f"\n🎯 引言歸屬分析:")
    
    expected_quotes = {
        "林佐翰": ["2016年參加亞拓盃榮獲直升機組第一名", "期望更多年輕人投入"],
        "魏嘉彥": ["花蓮市公所全力支持科技教育發展"],
        "張孟義": ["協會將持續推動無人機技術的普及化"]
    }
    
    total_accuracy = 0
    correct_assignments = 0
    
    for person_name, expected in expected_quotes.items():
        if person_name in person_quote_mapping:
            actual_quotes = person_quote_mapping[person_name]
            
            if actual_quotes:
                # 檢查引言內容的相似性
                accuracy = calculate_simple_accuracy(expected, actual_quotes)
                total_accuracy += accuracy
                if accuracy > 0.5:
                    correct_assignments += 1
                print(f"  ✅ {person_name}: 引言匹配度 {accuracy:.1%}")
            else:
                print(f"  ⚠️  {person_name}: 未找到引言")
        else:
            print(f"  ❌ {person_name}: 人物未識別")
    
    # 檢查是否有引言重複分配
    all_quotes = []
    for quotes in person_quote_mapping.values():
        all_quotes.extend(quotes)
    
    unique_quotes = set(all_quotes)
    if len(all_quotes) > len(unique_quotes):
        print(f"  ⚠️  檢測到重複的引言分配")
    else:
        print(f"  ✅ 沒有重複的引言分配")
    
    # 總結修復效果
    print(f"\n📋 修復效果總結:")
    overall_accuracy = total_accuracy / len(expected_quotes) if expected_quotes else 0
    print(f"  整體匹配準確度: {overall_accuracy:.1%}")
    print(f"  正確歸屬人數: {correct_assignments}/{len(expected_quotes)}")
    
    if overall_accuracy > 0.7 and len(all_quotes) == len(unique_quotes):
        print(f"  🎉 Bug修復成功！人物引言歸屬問題已解決")
    else:
        print(f"  ⚠️  Bug修復仍需改進")
    
    print(f"\n💰 修復成本: ${metadata.get('llm_cost', 0):.6f}")
    print(f"🚀 處理效率: {metadata.get('llm_response_time', 0):.1f}秒")
    
    return result

def calculate_simple_accuracy(expected_quotes, actual_quotes):
    """簡單計算引言相似性分數"""
    if not actual_quotes:
        return 0.0
    
    total_score = 0
    for expected in expected_quotes:
        best_match = 0
        for actual in actual_quotes:
            # 檢查關鍵詞是否包含
            if any(word in actual for word in expected.split() if len(word) > 2):
                best_match = max(best_match, 0.8)
        total_score += best_match
    
    return total_score / len(expected_quotes) if expected_quotes else 0.0

if __name__ == "__main__":
    asyncio.run(test_llm_quote_fix())