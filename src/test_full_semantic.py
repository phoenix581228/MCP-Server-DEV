#!/usr/bin/env python3
"""
完整語義分析測試 - 使用真實新聞文章
"""

import json
import sys
from pathlib import Path

# 確保可以導入模組
sys.path.insert(0, str(Path(__file__).parent))

from semantic_analyzer import NewsSemanticAnalyzer

def load_real_article():
    """載入真實新聞文章"""
    article_path = "/Users/chih-hungtseng/Downloads/發展科技應用能力市公所攜手花蓮社大點燃無人機學習熱潮.md"
    
    try:
        with open(article_path, 'r', encoding='utf-8') as f:
            content = f.read()
        return content
    except Exception as e:
        print(f"無法載入文章: {e}")
        return None

def test_full_semantic_analysis():
    """完整語義分析測試"""
    print("🎯 完整語義分析測試")
    print("=" * 60)
    
    # 載入真實文章
    article_content = load_real_article()
    if not article_content:
        print("❌ 無法載入測試文章")
        return
    
    print(f"📄 文章載入成功，長度: {len(article_content)} 字符")
    
    # 進行語義分析
    analyzer = NewsSemanticAnalyzer()
    result = analyzer.analyze_article(
        article_content, 
        "發展科技應用能力　市公所攜手花蓮社大點燃無人機學習熱潮"
    )
    
    # 顯示分析結果
    print("\n📊 分析結果摘要:")
    metadata = result["article_metadata"]
    print(f"  • 處理時間: {metadata['processing_time_ms']}ms")
    print(f"  • 字詞數量: {metadata['word_count']}")
    print(f"  • 段落數量: {metadata['section_count']}")
    
    print(f"\n🎭 主要主題:")
    for theme in result["content_structure"]["main_themes"]:
        print(f"  • {theme}")
    
    print(f"\n👥 關鍵人物分析:")
    for person in result["key_entities"]["persons"]:
        print(f"  📝 {person['name']} ({person['title']})")
        print(f"     角色: {person['role']}")
        print(f"     專業: {', '.join(person['expertise'])}")
        if person['quotes']:
            print(f"     引言: {person['quotes'][0][:50]}...")
        print()
    
    print(f"\n🔧 技術概念:")
    for concept in result["key_entities"]["technical_concepts"]:
        print(f"  • {concept['name']} (重要性: {concept['importance_level']}/10)")
        print(f"    描述: {concept['description']}")
        print(f"    應用: {', '.join(concept['applications'][:3])}")
        print()
    
    print(f"\n⏰ 時間線分析:")
    for event in result["key_entities"]["timeline"]:
        print(f"  {event['time_reference']}: {event['event'][:60]}...")
    
    print(f"\n🎬 剪輯智能分析:")
    editing = result["editing_intelligence"]
    
    print(f"  主要剪輯線索:")
    for cue in editing["primary_editing_cues"]:
        print(f"    • {cue}")
    
    print(f"  視覺需求:")
    for visual in editing["visual_requirements"]:
        print(f"    • {visual}")
    
    print(f"  節奏建議:")
    for pacing in editing["pacing_suggestions"]:
        print(f"    • {pacing}")
    
    print(f"\n📈 情感曲線分析:")
    emotional_arc = result["content_structure"]["emotional_arc"]
    for point in emotional_arc[:5]:  # 只顯示前5個點
        emotions = ', '.join(point['dominant_emotions']) if point['dominant_emotions'] else '中性'
        print(f"  段落 {point['section_order']}: 情感強度 {point['emotion_score']}/10 ({emotions})")
    
    print(f"\n🔍 語義向量:")
    vectors = result["semantic_vectors"]
    print(f"  技術關鍵詞: {', '.join(vectors['technical_keywords'])}")
    print(f"  動作關鍵詞: {', '.join(vectors['action_keywords'])}")
    print(f"  情感關鍵詞: {', '.join(vectors['emotion_keywords'][:8])}")
    
    # 保存完整結果
    output_file = "semantic_analysis_result.json"
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(result, f, ensure_ascii=False, indent=2)
    
    print(f"\n💾 完整分析結果已保存至: {output_file}")
    print("\n" + "=" * 60)
    print("✅ 語義分析測試完成！")

def generate_editing_report():
    """生成剪輯報告"""
    print("\n📋 生成剪輯指導報告...")
    
    article_content = load_real_article()
    if not article_content:
        return
    
    analyzer = NewsSemanticAnalyzer()
    result = analyzer.analyze_article(article_content)
    
    report = []
    report.append("# 無人機影片剪輯指導報告")
    report.append("## 基於語義分析的剪輯建議\n")
    
    # 主要剪輯線索
    report.append("### 🎬 主要剪輯線索")
    for cue in result["editing_intelligence"]["primary_editing_cues"]:
        report.append(f"- {cue}")
    report.append("")
    
    # 人物重點
    report.append("### 👥 重點人物片段")
    for person in result["key_entities"]["persons"]:
        if person['role'] == "技術專家":
            report.append(f"- **{person['name']}** - 重點展示其{', '.join(person['expertise'])}能力")
    report.append("")
    
    # 技術展示重點
    report.append("### 🔧 技術展示重點")
    high_importance_concepts = [c for c in result["key_entities"]["technical_concepts"] if c['importance_level'] >= 7]
    for concept in high_importance_concepts:
        report.append(f"- **{concept['name']}**: {concept['description']}")
    report.append("")
    
    # 節奏建議
    report.append("### ⏱️ 剪輯節奏建議")
    for suggestion in result["editing_intelligence"]["pacing_suggestions"]:
        report.append(f"- {suggestion}")
    
    # 保存報告
    with open("editing_guide_report.md", 'w', encoding='utf-8') as f:
        f.write('\n'.join(report))
    
    print("📄 剪輯指導報告已保存至: editing_guide_report.md")

if __name__ == "__main__":
    test_full_semantic_analysis()
    generate_editing_report()