#!/usr/bin/env python3
"""
新聞文章語義分析模組 - BigDipper AI剪輯系統

此模組負責分析新聞文章內容，提取關鍵資訊並為後續的語義匹配做準備。
主要功能包括：
- 文章段落分解和結構化分析
- 關鍵詞提取：人物、事件、技術、情感
- 敘事結構識別：起承轉合、時間線
- 剪輯線索生成：為影片匹配提供語義線索
"""

import re
import logging
from typing import Dict, Any, List, Tuple, Optional
from datetime import datetime
from dataclasses import dataclass

@dataclass
class ArticleSection:
    """文章段落結構"""
    title: str
    content: str
    section_type: str  # header, content, quote, conclusion
    order: int
    keywords: List[str]
    emotions: List[str]

@dataclass
class KeyPerson:
    """關鍵人物資訊"""
    name: str
    title: str
    role: str
    quotes: List[str]
    expertise: List[str]

@dataclass
class TechnicalConcept:
    """技術概念"""
    name: str
    description: str
    applications: List[str]
    importance_level: int  # 1-10

class NewsSemanticAnalyzer:
    """新聞文章語義分析器"""
    
    def __init__(self):
        self.logger = logging.getLogger("semantic_analyzer")
        
        # 技術關鍵詞字典
        self.tech_keywords = {
            "無人機": ["drone", "UAV", "飛行器", "航拍", "遙控"],
            "AI": ["人工智慧", "智能化", "機器學習", "AI系統"],
            "競技": ["比賽", "競賽", "世界冠軍", "飛手", "技巧"],
            "應用": ["農業", "監測", "檢測", "救災", "觀光", "警政", "消防"],
            "技術": ["飛控", "FPV", "穿越機", "直升機", "操控"]
        }
        
        # 情感詞彙字典
        self.emotion_keywords = {
            "讚嘆": ["嘆為觀止", "驚嘆", "精彩", "震撼", "令人目不暇給"],
            "興奮": ["熱潮", "爆發式", "無限商機", "展現", "提升"],
            "專業": ["技術長", "世界冠軍", "專業服務", "實力堅強"],
            "創新": ["革新", "趨勢", "前瞻", "創新", "轉型升級"],
            "支持": ["全力支持", "積極發展", "持續推動", "鼓勵"]
        }
        
        # 敘事結構模式
        self.narrative_patterns = {
            "引言": ["隨著", "為推廣", "於.*舉辦"],
            "現場": ["現場", "展演", "只見", "令現場"],
            "專業分析": ["表示", "他說", "指出"],
            "未來展望": ["期望", "相信", "將", "有助於"]
        }
    
    def analyze_article(self, article_content: str, article_title: str = "") -> Dict[str, Any]:
        """
        分析新聞文章內容
        
        Args:
            article_content: 文章內容
            article_title: 文章標題（可選）
            
        Returns:
            Dict: 結構化的分析結果
        """
        
        analysis_start = datetime.now()
        
        # 基本處理
        sections = self._segment_article(article_content)
        key_persons = self._extract_key_persons(article_content)
        technical_concepts = self._extract_technical_concepts(article_content)
        narrative_structure = self._analyze_narrative_structure(sections)
        
        # 語義分析
        main_themes = self._identify_main_themes(article_content)
        emotional_arc = self._analyze_emotional_arc(sections)
        editing_cues = self._generate_editing_cues(sections, key_persons, technical_concepts)
        
        # 時間線分析
        timeline = self._extract_timeline(article_content)
        
        analysis_end = datetime.now()
        
        return {
            "article_metadata": {
                "title": article_title,
                "analysis_timestamp": analysis_start.isoformat(),
                "processing_time_ms": int((analysis_end - analysis_start).total_seconds() * 1000),
                "word_count": len(article_content),
                "section_count": len(sections)
            },
            "content_structure": {
                "sections": [self._section_to_dict(section) for section in sections],
                "narrative_flow": narrative_structure,
                "main_themes": main_themes,
                "emotional_arc": emotional_arc
            },
            "key_entities": {
                "persons": [self._person_to_dict(person) for person in key_persons],
                "technical_concepts": [self._concept_to_dict(concept) for concept in technical_concepts],
                "timeline": timeline
            },
            "editing_intelligence": {
                "primary_editing_cues": editing_cues["primary"],
                "secondary_editing_cues": editing_cues["secondary"],
                "visual_requirements": editing_cues["visual"],
                "pacing_suggestions": editing_cues["pacing"]
            },
            "semantic_vectors": {
                "content_keywords": self._extract_content_keywords(article_content),
                "technical_keywords": self._extract_technical_keywords(article_content),
                "action_keywords": self._extract_action_keywords(article_content),
                "emotion_keywords": self._extract_emotion_keywords(article_content)
            }
        }
    
    def _segment_article(self, content: str) -> List[ArticleSection]:
        """將文章分段並分類"""
        sections = []
        paragraphs = [p.strip() for p in content.split('\n') if p.strip()]
        
        for i, paragraph in enumerate(paragraphs):
            section_type = self._classify_section_type(paragraph)
            keywords = self._extract_paragraph_keywords(paragraph)
            emotions = self._extract_paragraph_emotions(paragraph)
            
            # 識別標題
            title = ""
            if paragraph.startswith('**') and paragraph.endswith('**'):
                title = paragraph.strip('*')
                section_type = "header"
            elif '記者' in paragraph and '報導' in paragraph:
                section_type = "byline"
            
            sections.append(ArticleSection(
                title=title,
                content=paragraph,
                section_type=section_type,
                order=i,
                keywords=keywords,
                emotions=emotions
            ))
        
        return sections
    
    def _classify_section_type(self, paragraph: str) -> str:
        """分類段落類型"""
        if paragraph.startswith('**') and paragraph.endswith('**'):
            return "header"
        elif '記者' in paragraph and '報導' in paragraph:
            return "byline"
        elif any(pattern in paragraph for pattern in ["表示", "他說", "指出"]):
            return "quote"
        elif any(pattern in paragraph for pattern in ["期望", "相信", "將"]):
            return "conclusion"
        else:
            return "content"
    
    def _extract_key_persons(self, content: str) -> List[KeyPerson]:
        """提取關鍵人物"""
        persons = []
        
        # 模式匹配人物和職稱
        person_patterns = [
            r'(.*?)(市長|理事長|校長|技術長|世界冠軍)(.*?)([表指]出|說)',
            r'由(.*?)(主講|展演)',
            r'(林佐翰|張孟義|魏嘉彥|蘇俊源|沈君茹)'
        ]
        
        for pattern in person_patterns:
            matches = re.finditer(pattern, content)
            for match in matches:
                # 提取人物資訊
                full_match = match.group(0)
                name = self._extract_person_name(full_match)
                title = self._extract_person_title(full_match)
                quotes = self._extract_person_quotes(content, name)
                
                if name:
                    persons.append(KeyPerson(
                        name=name,
                        title=title,
                        role=self._determine_person_role(title, quotes),
                        quotes=quotes,
                        expertise=self._determine_expertise(quotes, title)
                    ))
        
        return self._deduplicate_persons(persons)
    
    def _identify_main_themes(self, content: str) -> List[str]:
        """識別文章主要主題"""
        themes = []
        
        theme_patterns = {
            "技術展演": ["展演", "技巧", "世界冠軍", "飛行控制"],
            "產業發展": ["產業", "商機", "趨勢", "應用"],
            "教育推廣": ["講座", "學習", "培訓", "推廣"],
            "政府支持": ["市公所", "支持", "推動", "發展"],
            "技術競技": ["比賽", "競賽", "冠軍", "競技"]
        }
        
        for theme, keywords in theme_patterns.items():
            score = sum(content.count(keyword) for keyword in keywords)
            if score >= 2:  # 至少出現2次相關詞彙
                themes.append(theme)
        
        return themes
    
    def _extract_person_name(self, text: str) -> str:
        """從文本中提取人名"""
        known_names = ["林佐翰", "張孟義", "魏嘉彥", "蘇俊源", "沈君茹"]
        for name in known_names:
            if name in text:
                return name
        return ""
    
    def _extract_person_title(self, text: str) -> str:
        """提取職稱"""
        titles = ["市長", "理事長", "校長", "技術長", "世界冠軍"]
        for title in titles:
            if title in text:
                return title
        return ""
    
    def _extract_person_quotes(self, content: str, name: str) -> List[str]:
        """提取人物引言"""
        if not name:
            return []
        
        quotes = []
        # 尋找包含該人物的段落
        paragraphs = content.split('\n')
        for paragraph in paragraphs:
            if name in paragraph or any(word in paragraph for word in ["他說", "表示", "指出"]):
                # 提取引言部分
                quote_match = re.search(r'[他她]?[說表指][出示]?[，：:](.*?)。', paragraph)
                if quote_match:
                    quotes.append(quote_match.group(1).strip())
        
        return quotes
    
    def _determine_person_role(self, title: str, quotes: List[str]) -> str:
        """根據職稱和引言確定人物角色"""
        role_mapping = {
            "世界冠軍": "技術專家",
            "技術長": "產業專家", 
            "市長": "政府官員",
            "理事長": "協會領導",
            "校長": "教育領導"
        }
        return role_mapping.get(title, "相關人士")
    
    def _determine_expertise(self, quotes: List[str], title: str) -> List[str]:
        """確定專業領域"""
        expertise = []
        combined_text = ' '.join(quotes) + ' ' + title
        
        expertise_keywords = {
            "飛行技術": ["飛行", "操控", "技巧", "世界冠軍"],
            "產業趨勢": ["趨勢", "商機", "產業", "發展"],
            "政策支持": ["支持", "推動", "政府", "市長"],
            "教育培訓": ["教育", "培訓", "學習", "校長"],
            "技術應用": ["應用", "檢測", "監測", "救災"]
        }
        
        for field, keywords in expertise_keywords.items():
            if any(keyword in combined_text for keyword in keywords):
                expertise.append(field)
        
        return expertise
    
    def _extract_technical_concepts(self, content: str) -> List[TechnicalConcept]:
        """提取技術概念"""
        concepts = []
        
        # 定義技術概念模式
        tech_patterns = {
            "無人機": {
                "keywords": ["無人機", "UAV", "drone"],
                "description": "無人駕駛飛行器",
                "applications": ["農業監測", "基礎設施檢測", "救災", "觀光導覽"]
            },
            "穿越機": {
                "keywords": ["穿越機", "FPV racing drone"],
                "description": "第一人稱視角競技無人機",
                "applications": ["競技比賽", "技術展演", "娛樂"]
            },
            "AI智能化": {
                "keywords": ["AI", "智能化", "人工智慧"],
                "description": "人工智慧技術應用",
                "applications": ["系統整合", "效能提升", "自動化"]
            }
        }
        
        for concept_name, info in tech_patterns.items():
            if any(keyword in content for keyword in info["keywords"]):
                importance = self._calculate_concept_importance(content, info["keywords"])
                
                concepts.append(TechnicalConcept(
                    name=concept_name,
                    description=info["description"],
                    applications=info["applications"],
                    importance_level=importance
                ))
        
        return concepts
    
    def _calculate_concept_importance(self, content: str, keywords: List[str]) -> int:
        """計算技術概念的重要性（1-10）"""
        total_mentions = sum(content.count(keyword) for keyword in keywords)
        
        # 基於出現次數和上下文重要性評分
        if total_mentions >= 10:
            return 10
        elif total_mentions >= 5:
            return 8
        elif total_mentions >= 3:
            return 6
        elif total_mentions >= 1:
            return 4
        else:
            return 1
    
    def _analyze_narrative_structure(self, sections: List[ArticleSection]) -> Dict[str, Any]:
        """分析敘事結構"""
        structure = {
            "introduction": [],
            "development": [],
            "climax": [],
            "conclusion": []
        }
        
        for section in sections:
            section_position = section.order / len(sections)
            
            if section_position <= 0.25:
                structure["introduction"].append(section.order)
            elif section_position <= 0.75:
                if any(word in section.content for word in ["展演", "現場", "驚嘆"]):
                    structure["climax"].append(section.order)
                else:
                    structure["development"].append(section.order)
            else:
                structure["conclusion"].append(section.order)
        
        return structure
    
    def _analyze_emotional_arc(self, sections: List[ArticleSection]) -> List[Dict[str, Any]]:
        """分析情感曲線"""
        emotional_arc = []
        
        for section in sections:
            emotion_score = 0
            dominant_emotions = []
            
            # 計算情感強度
            for emotion, keywords in self.emotion_keywords.items():
                count = sum(1 for keyword in keywords if keyword in section.content)
                if count > 0:
                    emotion_score += count * 2
                    dominant_emotions.append(emotion)
            
            emotional_arc.append({
                "section_order": section.order,
                "emotion_score": min(emotion_score, 10),  # 限制在1-10
                "dominant_emotions": dominant_emotions,
                "content_preview": section.content[:50] + "..."
            })
        
        return emotional_arc
    
    def _generate_editing_cues(self, sections: List[ArticleSection], 
                              persons: List[KeyPerson], 
                              concepts: List[TechnicalConcept]) -> Dict[str, List[str]]:
        """生成剪輯線索"""
        
        cues = {
            "primary": [],    # 主要剪輯線索
            "secondary": [],  # 次要剪輯線索
            "visual": [],     # 視覺需求
            "pacing": []      # 節奏建議
        }
        
        # 主要剪輯線索 - 基於重要人物和技術概念
        for person in persons:
            if "世界冠軍" in person.title:
                cues["primary"].append(f"技術展演：{person.name}飛行技巧")
                cues["visual"].append("動態飛行畫面")
                cues["pacing"].append("快節奏剪輯")
        
        for concept in concepts:
            if concept.importance_level >= 8:
                cues["primary"].append(f"技術重點：{concept.name}")
                cues["visual"].append(f"{concept.name}相關畫面")
        
        # 次要剪輯線索 - 基於內容結構
        for section in sections:
            if section.section_type == "quote" and section.emotions:
                cues["secondary"].append(f"專家觀點：{section.content[:30]}...")
            
            if "現場" in section.content:
                cues["visual"].append("現場活動畫面")
                cues["pacing"].append("中等節奏")
        
        # 節奏建議
        if any("震撼" in section.content for section in sections):
            cues["pacing"].append("高潮段落使用慢鏡頭")
        
        return cues
    
    def _extract_timeline(self, content: str) -> List[Dict[str, str]]:
        """提取時間線"""
        timeline = []
        
        # 時間模式匹配
        time_patterns = [
            r'(\d{4})年.*?([^。]*)',
            r'28日.*?([^。]*)',
            r'2016年.*?([^。]*)',
            r'2017年.*?([^。]*)',
            r'國小六年級.*?([^。]*)'
        ]
        
        for pattern in time_patterns:
            matches = re.finditer(pattern, content)
            for match in matches:
                timeline.append({
                    "time_reference": match.group(1) if len(match.groups()) > 1 else match.group(0)[:10],
                    "event": match.group(2) if len(match.groups()) > 1 else match.group(0),
                    "importance": "high" if any(word in match.group(0) for word in ["冠軍", "比賽", "簽約"]) else "medium"
                })
        
        return timeline
    
    def _extract_content_keywords(self, content: str) -> List[str]:
        """提取內容關鍵詞"""
        keywords = []
        for category, words in self.tech_keywords.items():
            for word in words:
                if word in content:
                    keywords.append(word)
        return list(set(keywords))
    
    def _extract_technical_keywords(self, content: str) -> List[str]:
        """提取技術關鍵詞"""
        tech_words = ["飛控", "FPV", "穿越機", "直升機", "AI", "智能化", "監測", "檢測"]
        return [word for word in tech_words if word in content]
    
    def _extract_action_keywords(self, content: str) -> List[str]:
        """提取動作關鍵詞"""
        action_words = ["飛行", "操控", "展演", "翻飛", "盤旋", "穿梭", "劃破", "翻滾"]
        return [word for word in action_words if word in content]
    
    def _extract_emotion_keywords(self, content: str) -> List[str]:
        """提取情感關鍵詞"""
        emotion_words = []
        for emotion, keywords in self.emotion_keywords.items():
            for keyword in keywords:
                if keyword in content:
                    emotion_words.append(keyword)
        return emotion_words
    
    def _extract_paragraph_keywords(self, paragraph: str) -> List[str]:
        """提取段落關鍵詞"""
        keywords = []
        for category, words in self.tech_keywords.items():
            for word in words:
                if word in paragraph:
                    keywords.append(word)
        return keywords
    
    def _extract_paragraph_emotions(self, paragraph: str) -> List[str]:
        """提取段落情感詞"""
        emotions = []
        for emotion, keywords in self.emotion_keywords.items():
            if any(keyword in paragraph for keyword in keywords):
                emotions.append(emotion)
        return emotions
    
    def _deduplicate_persons(self, persons: List[KeyPerson]) -> List[KeyPerson]:
        """去除重複人物"""
        seen_names = set()
        unique_persons = []
        
        for person in persons:
            if person.name and person.name not in seen_names:
                seen_names.add(person.name)
                unique_persons.append(person)
        
        return unique_persons
    
    def _section_to_dict(self, section: ArticleSection) -> Dict[str, Any]:
        """將ArticleSection轉換為字典"""
        return {
            "title": section.title,
            "content": section.content,
            "section_type": section.section_type,
            "order": section.order,
            "keywords": section.keywords,
            "emotions": section.emotions
        }
    
    def _person_to_dict(self, person: KeyPerson) -> Dict[str, Any]:
        """將KeyPerson轉換為字典"""
        return {
            "name": person.name,
            "title": person.title,
            "role": person.role,
            "quotes": person.quotes,
            "expertise": person.expertise
        }
    
    def _concept_to_dict(self, concept: TechnicalConcept) -> Dict[str, Any]:
        """將TechnicalConcept轉換為字典"""
        return {
            "name": concept.name,
            "description": concept.description,
            "applications": concept.applications,
            "importance_level": concept.importance_level
        }


# 便利函數
def analyze_news_article(article_content: str, article_title: str = "") -> Dict[str, Any]:
    """便利函數：快速分析新聞文章"""
    analyzer = NewsSemanticAnalyzer()
    return analyzer.analyze_article(article_content, article_title)


# 測試函數
def test_semantic_analyzer():
    """測試語義分析器功能"""
    # 測試用的文章片段
    test_article = """
發展科技應用能力　市公所攜手花蓮社大點燃無人機學習熱潮

隨著科技進步與應用場域擴展，無人機已從軍事科技走入民間生活。為推廣無人機知識與應用實務，花蓮市公所、花蓮縣社區大學與台灣國際無人機競技發展協會花蓮分會於28日上午，在化仁國中聯合舉辦「無人機時代來了」技術講座，競技遙控模型直升機世界冠軍林佐翰也現場展演穿越機及無人直升機飛行控制技巧。

**世界冠軍現場展演震撼全場**

由無人機飛齡11年，榮獲競技遙控模型直升機世界冠軍的林佐翰現場展演穿越機（FPV racing drone）與無人直升機飛行控制（Flight Control）技巧，只見他以精準飛控、疾速轉彎與高難度動作操作無人機，展現世界級競技實力。

林佐翰表示，2016年參加亞拓盃榮獲直升機組第一名，獲廠商青睞簽約成為試飛員。他期望更多年輕人投入，相信台灣飛手實力堅強。
    """
    
    print("開始測試新聞語義分析器...")
    
    analyzer = NewsSemanticAnalyzer()
    result = analyzer.analyze_article(test_article, "無人機技術講座報導")
    
    print(f"\n文章元數據:")
    metadata = result["article_metadata"]
    for key, value in metadata.items():
        print(f"  {key}: {value}")
    
    print(f"\n關鍵人物:")
    for person in result["key_entities"]["persons"]:
        print(f"  {person['name']} ({person['title']}) - 角色: {person['role']}")
        print(f"    專業: {', '.join(person['expertise'])}")
    
    print(f"\n技術概念:")
    for concept in result["key_entities"]["technical_concepts"]:
        print(f"  {concept['name']} (重要性: {concept['importance_level']}/10)")
    
    print(f"\n主要剪輯線索:")
    for cue in result["editing_intelligence"]["primary_editing_cues"]:
        print(f"  • {cue}")
    
    print(f"\n語義關鍵詞:")
    vectors = result["semantic_vectors"]
    print(f"  技術詞彙: {', '.join(vectors['technical_keywords'][:5])}")
    print(f"  動作詞彙: {', '.join(vectors['action_keywords'][:5])}")
    print(f"  情感詞彙: {', '.join(vectors['emotion_keywords'][:5])}")


if __name__ == "__main__":
    test_semantic_analyzer()