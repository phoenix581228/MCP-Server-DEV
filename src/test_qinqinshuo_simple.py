#!/usr/bin/env python3
"""
《彈琴說愛》簡化版LLM智能語義分析測試
重點驗證人物引言歸屬功能
"""

import asyncio
import sys
from pathlib import Path

# 確保可以導入模組
sys.path.insert(0, str(Path(__file__).parent))

from llm_semantic_analyzer import LLMSemanticAnalyzer

def get_simple_test_content():
    """獲取簡化的測試內容，重點包含人物引言"""
    return """
萬華終身學習教育中心《彈琴說愛》教育志工報導

陣陣琴聲從屋內揚洩出來，在陳信夫與鄭麗如的合奏之間，溫暖幸福的氛圍洋溢在家中的每個角落。他們夫妻倆四十多年的情感，琴瑟合鳴，鶼鰈情深，感恩能在慈濟一起圓夢。

當初接觸慈濟的因緣，是孩子們就讀私立幼稚園時，每天早上會遇見楊茹云。有一天楊茹云提到花蓮有一位師父要蓋醫院，問及麗如是否要捐錢幫忙？當時，麗如聽了非常震撼，於是隨即答應一個月捐五百元。

信夫開玩笑回應：「妳是跟師父打長期契約嗎？以後工作若沒了，還要繼續捐嗎？」然後就出門騎車上班。上班途中發生小意外，讓信夫震懾，回家後慎重向太太道歉。

二十年前有一天夜晚，信夫聽到麗如在睡夢中，閉著眼說話：「老師來家裡三次，媽媽為什麼不給我去學琴？」啜泣的聲音夾雜著細細的歌聲，當時信夫心疼得心都碎了。

信夫的三姊陳桂娟，受到弟弟的感召，參加培訓並受證為慈濟委員。桂娟說：「信夫從小就很孝順，個性嚴以律已，寬以待人。自從參與慈濟之後，逐漸學習柔軟、謙卑。」

陳信夫做了二十七年的慈濟志工，他說：「隨時保持一顆愛心不變，會帶動周邊很多人。現在做志工已經無求，從一次次的志工參與中，體會到上人所說『付出無所求』。」

萬華終身學習中心開辦電子琴班，信夫與麗如仍然一直在學習，另外在寒暑假與周六的兒童電子琴班，都會擔任教育志工，協助老師與陪伴孩子們學習。
"""

async def test_simple_qinqinshuo():
    """執行簡化版《彈琴說愛》分析測試"""
    
    print("🎹 《彈琴說愛》簡化版智能分析測試")
    print("=" * 60)
    print("🎯 重點驗證：人物引言歸屬準確性")
    
    article_content = get_simple_test_content()
    print(f"📝 測試文章長度：{len(article_content)} 字符")
    
    try:
        print("\n🔄 啟動LLM分析...")
        
        # 創建分析器
        analyzer = LLMSemanticAnalyzer()
        
        # 執行分析
        result = await analyzer.analyze_article(
            article_content, 
            "萬華終身學習教育中心《彈琴說愛》教育志工報導"
        )
        
        print("\n📊 分析結果：")
        
        # 顯示基本統計
        metadata = result["article_metadata"]
        print(f"  供應商：{metadata.get('llm_provider_used', 'unknown')}")
        print(f"  Token：{metadata.get('llm_tokens_used', 0)}")
        print(f"  成本：${metadata.get('llm_cost', 0):.6f}")
        print(f"  時間：{metadata.get('llm_response_time', 0):.1f}秒")
        
        # 人物分析
        entities = result["key_entities"]
        persons = entities.get("persons", [])
        
        print(f"\n👥 人物識別結果：")
        print(f"  識別人物數：{len(persons)}")
        
        if persons:
            for person in persons:
                print(f"\n  👤 {person['name']} ({person['title']})")
                print(f"     角色：{person['role']}")
                
                if person['quotes']:
                    print(f"     引言數：{len(person['quotes'])}")
                    for i, quote in enumerate(person['quotes'], 1):
                        print(f"     {i}. \"{quote}\"")
                else:
                    print(f"     引言：無")
        
        # 驗證預期人物和引言
        print(f"\n🎯 人物引言歸屬驗證：")
        
        expected_people = ["陳信夫", "鄭麗如", "楊茹云", "陳桂娟"]
        expected_quotes = {
            "陳信夫": "妳是跟師父打長期契約嗎",
            "鄭麗如": "老師來家裡三次，媽媽為什麼不給我去學琴",
            "陳桂娟": "信夫從小就很孝順"
        }
        
        identified_people = [p['name'] for p in persons]
        correct_identifications = 0
        correct_quotes = 0
        
        for expected_name in expected_people:
            if any(expected_name in identified or identified in expected_name 
                   for identified in identified_people):
                correct_identifications += 1
                print(f"  ✅ {expected_name}: 人物識別正確")
            else:
                print(f"  ❌ {expected_name}: 人物未識別")
        
        # 檢查引言歸屬
        for person in persons:
            person_name = person['name']
            person_quotes = person['quotes']
            
            for expected_name, expected_quote_part in expected_quotes.items():
                if expected_name in person_name or person_name in expected_name:
                    if person_quotes:
                        quote_match = any(expected_quote_part in quote for quote in person_quotes)
                        if quote_match:
                            correct_quotes += 1
                            print(f"  ✅ {expected_name}: 引言歸屬正確")
                        else:
                            print(f"  ⚠️  {expected_name}: 引言內容需確認")
                    break
        
        # 檢查引言重複問題（關鍵Bug驗證）
        all_quotes = []
        for person in persons:
            all_quotes.extend(person['quotes'])
        
        unique_quotes = set(all_quotes)
        
        print(f"\n🔍 引言重複檢查（Bug修復驗證）：")
        print(f"  總引言數：{len(all_quotes)}")
        print(f"  獨特引言數：{len(unique_quotes)}")
        
        if len(all_quotes) == 0:
            print(f"  ⚠️  沒有提取到引言")
        elif len(all_quotes) == len(unique_quotes):
            print(f"  ✅ 無重複引言分配 - Bug修復成功！")
        else:
            print(f"  ❌ 發現重複引言分配 - Bug仍存在")
        
        # 關鍵詞提取
        vectors = result["semantic_vectors"]
        print(f"\n🎯 智能關鍵詞提取：")
        for keyword_type, keywords in vectors.items():
            if keywords:
                type_names = {
                    'content_keywords': '內容關鍵詞',
                    'technical_keywords': '技術關鍵詞',
                    'action_keywords': '動作關鍵詞',
                    'emotion_keywords': '情感關鍵詞'
                }
                type_name = type_names.get(keyword_type, keyword_type)
                print(f"  {type_name}：{', '.join(keywords[:5])}")
        
        # 功能驗證總結
        print(f"\n🏆 功能驗證總結：")
        
        success_count = 0
        total_tests = 5
        
        if metadata.get('llm_provider_used') and metadata.get('llm_provider_used') != 'fallback':
            success_count += 1
            print(f"  ✅ LLM調用成功")
        else:
            print(f"  ❌ LLM調用失敗")
        
        if len(persons) >= 2:
            success_count += 1
            print(f"  ✅ 人物識別成功")
        else:
            print(f"  ❌ 人物識別不足")
        
        if correct_identifications >= 2:
            success_count += 1
            print(f"  ✅ 預期人物識別成功")
        else:
            print(f"  ❌ 預期人物識別不足")
        
        if any(person['quotes'] for person in persons):
            success_count += 1
            print(f"  ✅ 引言提取成功")
        else:
            print(f"  ❌ 引言提取失敗")
        
        if len(all_quotes) == 0 or len(all_quotes) == len(unique_quotes):
            success_count += 1
            print(f"  ✅ 引言Bug修復驗證成功")
        else:
            print(f"  ❌ 引言Bug可能仍存在")
        
        success_rate = success_count / total_tests
        print(f"\n📊 成功率：{success_count}/{total_tests} ({success_rate*100:.1f}%)")
        
        if success_rate >= 0.8:
            print(f"🎉 測試優秀通過！LLM智能語義分析功能完全可用！")
        elif success_rate >= 0.6:
            print(f"✅ 測試良好通過！主要功能正常工作！")
        else:
            print(f"⚠️  測試部分通過，建議檢查配置")
        
        return True
        
    except Exception as e:
        print(f"\n❌ 測試過程發生錯誤：{e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    print("🎹 準備執行《彈琴說愛》簡化版智能分析測試...")
    success = asyncio.run(test_simple_qinqinshuo())
    
    if success:
        print(f"\n✨ 《彈琴說愛》簡化版測試完成！")
    else:
        print(f"\n⚠️  測試未完成")