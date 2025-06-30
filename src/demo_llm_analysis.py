#!/usr/bin/env python3
"""
LLM智能語義分析功能演示
"""

import asyncio
import sys
from pathlib import Path

# 確保可以導入模組
sys.path.insert(0, str(Path(__file__).parent))

from llm_semantic_analyzer import LLMSemanticAnalyzer

async def demo_llm_analysis():
    """演示LLM智能語義分析功能"""
    
    print("🚀 LLM智能語義分析功能演示")
    print("=" * 60)
    
    # 測試用的新聞文章
    test_article = """
發展科技應用能力　市公所攜手花蓮社大點燃無人機學習熱潮

隨著科技進步與應用場域擴展，無人機已從軍事科技走入民間生活。為推廣無人機知識與應用實務，花蓮市公所、花蓮縣社區大學與台灣國際無人機競技發展協會花蓮分會於28日上午，在化仁國中聯合舉辦「無人機時代來了」技術講座，競技遙控模型直升機世界冠軍林佐翰也現場展演穿越機及無人直升機飛行控制技巧。

**世界冠軍現場展演震撼全場**

由無人機飛齡11年，榮獲競技遙控模型直升機世界冠軍的林佐翰現場展演穿越機（FPV racing drone）與無人直升機飛行控制（Flight Control）技巧，只見他以精準飛控、疾速轉彎與高難度動作操作無人機，展現世界級競技實力。

林佐翰表示，2016年參加亞拓盃榮獲直升機組第一名，獲廠商青睞簽約成為試飛員。他期望更多年輕人投入，相信台灣飛手實力堅強。

市長魏嘉彥指出，花蓮市公所全力支持科技教育發展，希望透過這樣的活動讓更多民眾了解無人機的實用性。

理事長張孟義也強調，協會將持續推動無人機技術的普及化，讓這項技術真正走入民間應用。

**技術講座吸引民眾踴躍參與**

當天活動吸引了超過百位民眾參與，包含學生、教師及對無人機技術有興趣的民眾。講座內容涵蓋無人機基礎知識、操作技巧、安全規範及實際應用場域介紹。
"""
    
    print("📄 測試文章：無人機技術講座報導")
    print("📝 文章長度：", len(test_article), "字符")
    
    try:
        # 創建LLM語義分析器
        analyzer = LLMSemanticAnalyzer()
        
        print("\n🔄 開始LLM智能分析...")
        
        # 執行分析
        result = await analyzer.analyze_article(test_article, "無人機技術講座報導")
        
        # 顯示分析結果
        print("\n" + "=" * 60)
        print("📊 LLM智能語義分析結果")
        print("=" * 60)
        
        # 元數據
        metadata = result["article_metadata"]
        print(f"\n📈 分析統計：")
        print(f"  ├─ 使用供應商：{metadata.get('llm_provider_used', 'unknown')}")
        print(f"  ├─ Token使用量：{metadata.get('llm_tokens_used', 0)}")
        print(f"  ├─ 分析成本：${metadata.get('llm_cost', 0):.6f}")
        print(f"  ├─ 響應時間：{metadata.get('llm_response_time', 0):.2f}秒")
        print(f"  └─ 處理時間：{metadata.get('processing_time_ms', 0)}ms")
        
        # 關鍵實體分析
        entities = result["key_entities"]
        
        print(f"\n👥 人物分析：")
        persons = entities.get("persons", [])
        if persons:
            for person in persons:
                print(f"  👤 {person['name']} ({person['title']})")
                print(f"     ├─ 角色：{person['role']}")
                if person['quotes']:
                    print(f"     ├─ 引言：{len(person['quotes'])}條")
                    for i, quote in enumerate(person['quotes'][:2], 1):  # 顯示前2條
                        print(f"     │   {i}. \"{quote[:50]}{'...' if len(quote) > 50 else ''}\"")
                else:
                    print(f"     ├─ 引言：無")
                if person['expertise']:
                    print(f"     └─ 專業：{', '.join(person['expertise'])}")
                print()
        else:
            print("  ⚠️  未識別到人物")
        
        # 組織機構
        organizations = entities.get("organizations", [])
        if organizations:
            print(f"🏢 組織機構：")
            for org in organizations:
                print(f"  • {org['name']} ({org['type']}) - 重要性：{org['importance']}")
        
        # 事件分析
        events = entities.get("events", [])
        if events:
            print(f"\n📅 事件分析：")
            for event in events:
                print(f"  • {event['name']} - 影響程度：{event['impact_level']}/10")
        
        # 技術概念
        tech_concepts = entities.get("technical_concepts", [])
        if tech_concepts:
            print(f"\n💡 技術概念：")
            for concept in tech_concepts:
                print(f"  • {concept['name']} - 重要性：{concept['importance_level']}/10")
                print(f"    {concept['description']}")
        
        # 語義向量（關鍵詞）
        vectors = result["semantic_vectors"]
        print(f"\n🎯 智能關鍵詞提取：")
        for vector_type, keywords in vectors.items():
            if keywords:
                type_name = {
                    'content_keywords': '內容關鍵詞',
                    'technical_keywords': '技術關鍵詞', 
                    'action_keywords': '動作關鍵詞',
                    'emotion_keywords': '情感關鍵詞'
                }.get(vector_type, vector_type)
                print(f"  {type_name}：{', '.join(keywords[:5])}")  # 顯示前5個
        
        # 剪輯智能建議
        editing = result["editing_intelligence"]
        if any(editing.values()):
            print(f"\n🎬 智能剪輯建議：")
            if editing["primary_editing_cues"]:
                print(f"  主要線索：{', '.join(editing['primary_editing_cues'][:3])}")
            if editing["visual_requirements"]:
                print(f"  視覺需求：{', '.join(editing['visual_requirements'][:3])}")
        
        # 成功指標
        success_indicators = []
        if metadata.get('llm_provider_used') != 'fallback':
            success_indicators.append("✅ LLM調用成功")
        if len(persons) > 0:
            success_indicators.append("✅ 人物識別成功")
        if vectors.get('content_keywords'):
            success_indicators.append("✅ 關鍵詞提取成功")
        
        print(f"\n🎉 功能驗證：")
        for indicator in success_indicators:
            print(f"  {indicator}")
        
        if len(success_indicators) >= 2:
            print(f"\n🚀 LLM智能語義分析功能運行正常！")
        else:
            print(f"\n⚠️  部分功能可能需要調整")
        
        return True
        
    except Exception as e:
        print(f"\n❌ 分析過程發生錯誤：{e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    success = asyncio.run(demo_llm_analysis())
    if success:
        print(f"\n✨ 演示完成！LLM智能語義分析功能已可用。")
    else:
        print(f"\n⚠️  演示失敗，可能需要檢查配置。")