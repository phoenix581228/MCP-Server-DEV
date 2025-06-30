#!/usr/bin/env python3
"""
提示詞模板管理器 - BigDipper AI剪輯系統

主題自適應提示詞模板系統，支援：
- 動態語義分析提示詞
- XML結構化輸出規範
- 人物引言精確匹配
- 主題特定分析優化
- 多層次關鍵詞生成
"""

from typing import Dict, List, Optional, Any
from enum import Enum
import logging

logger = logging.getLogger("prompt_templates")

class ArticleType(Enum):
    """文章類型枚舉"""
    TECHNOLOGY = "technology"      # 科技新聞
    POLITICS = "politics"          # 政治新聞  
    BUSINESS = "business"          # 商業新聞
    SPORTS = "sports"              # 體育新聞
    ENTERTAINMENT = "entertainment" # 娛樂新聞
    EDUCATION = "education"        # 教育新聞
    GENERAL = "general"            # 一般新聞

class PromptTemplateManager:
    """主題自適應提示詞模板管理器"""
    
    def __init__(self):
        self.base_xml_schema = self._get_base_xml_schema()
        self.semantic_analysis_templates = self._init_semantic_templates()
        self.quote_extraction_templates = self._init_quote_templates()
        self.keyword_generation_templates = self._init_keyword_templates()
        self.topic_specific_contexts = self._init_topic_contexts()
    
    def _get_base_xml_schema(self) -> str:
        """基礎XML輸出結構規範"""
        return """
<semantic_analysis>
    <metadata>
        <article_type>{article_type}</article_type>
        <main_topic>{main_topic}</main_topic>
        <processing_timestamp>{timestamp}</processing_timestamp>
    </metadata>
    
    <entities>
        <persons>
            <!-- 每個人物單獨列出，確保引言正確歸屬 -->
            <person name="姓名" title="職稱" role="角色類型">
                <quotes>
                    <quote>實際引言內容1</quote>
                    <quote>實際引言內容2</quote>
                </quotes>
                <expertise>專業領域1,專業領域2</expertise>
            </person>
        </persons>
        
        <organizations>
            <org name="組織名稱" type="類型" importance="high/medium/low"/>
        </organizations>
        
        <locations>
            <location name="地點名稱" type="city/country/venue" relevance="核心/次要"/>
        </locations>
        
        <events>
            <event name="事件名稱" type="類型" impact_level="1-10" timeframe="時間範圍"/>
        </events>
    </entities>
    
    <content_analysis>
        <main_themes>
            <theme name="主題名稱" relevance_score="0.0-1.0" keywords="關鍵詞列表"/>
        </main_themes>
        
        <sentiment_analysis>
            <overall sentiment="positive/negative/neutral" confidence="0.0-1.0" intensity="1-10"/>
            <by_paragraph>
                <paragraph id="1" sentiment="positive/negative/neutral" score="0.0-1.0" key_emotions="情感詞彙"/>
            </by_paragraph>
        </sentiment_analysis>
        
        <narrative_structure>
            <section type="introduction" paragraphs="1-2" purpose="引言說明"/>
            <section type="development" paragraphs="3-5" purpose="事件發展"/>
            <section type="climax" paragraphs="6-7" purpose="高潮重點"/>
            <section type="conclusion" paragraphs="8-9" purpose="結論展望"/>
        </narrative_structure>
        
        <technical_concepts>
            <concept name="技術概念" description="描述" importance="1-10" applications="應用領域"/>
        </technical_concepts>
    </content_analysis>
    
    <editing_intelligence>
        <primary_cues>
            <cue type="visual" description="視覺重點" timing="建議時機"/>
        </primary_cues>
        
        <secondary_cues>
            <cue type="audio" description="音頻重點" emphasis="強調程度"/>
        </secondary_cues>
        
        <pacing_suggestions>
            <suggestion segment="段落範圍" pace="快/中/慢" reason="節奏原因"/>
        </pacing_suggestions>
        
        <visual_requirements>
            <requirement type="scene_type" description="場景需求" priority="high/medium/low"/>
        </visual_requirements>
    </editing_intelligence>
    
    <semantic_vectors>
        <content_keywords>動態生成的內容關鍵詞</content_keywords>
        <technical_keywords>技術相關關鍵詞</technical_keywords>
        <action_keywords>動作描述關鍵詞</action_keywords>
        <emotion_keywords>情感表達關鍵詞</emotion_keywords>
    </semantic_vectors>
</semantic_analysis>
"""
    
    def _init_semantic_templates(self) -> Dict[ArticleType, str]:
        """初始化語義分析模板"""
        templates = {}
        
        # 科技新聞模板
        templates[ArticleType.TECHNOLOGY] = """
你是一個專業的科技新聞語義分析專家。請仔細分析以下科技新聞文章，特別關注：

🔍 **分析重點**：
- 技術概念和創新點
- 專家觀點和技術評估
- 產業趨勢和應用場景
- 技術演示和實際效果

⚠️ **重要提醒**：
1. 人物引言必須精確匹配，每個人的實際話語內容
2. 技術術語需要準確識別和解釋
3. 注意區分技術概念的重要性等級
4. 識別創新性和實用性特徵

📋 **輸出要求**：
請嚴格按照以下XML格式輸出分析結果：

{xml_schema}

📄 **待分析文章**：
{content}

請確保：
- 所有人物引言都準確歸屬
- 技術概念按重要性排序
- 視覺需求具體明確
- 剪輯建議符合科技主題特點
"""
        
        # 一般新聞模板
        templates[ArticleType.GENERAL] = """
你是一個專業的新聞語義分析專家。請仔細分析以下新聞文章，提取所有關鍵信息：

🔍 **分析重點**：
- 關鍵人物及其觀點立場
- 重要事件和時間線
- 主要組織機構
- 情感色彩和敘事結構

⚠️ **重要提醒**：
1. 人物引言必須精確匹配，避免混淆不同人物的話語
2. 確保所有實體信息準確提取
3. 情感分析要客觀中性
4. 敘事結構要符合新聞特點

📋 **輸出要求**：
請嚴格按照以下XML格式輸出分析結果：

{xml_schema}

📄 **待分析文章**：
{content}

請確保：
- 人物-引言對應關係100%準確
- 組織機構類型正確標註
- 事件時間線清晰
- 剪輯建議實用可行
"""
        
        # 商業新聞模板
        templates[ArticleType.BUSINESS] = """
你是一個專業的商業新聞語義分析專家。請分析以下商業新聞，重點關注：

🔍 **分析重點**：
- 商業決策和策略方向
- 市場趨勢和財務數據
- 企業領導人觀點
- 競爭態勢和影響分析

⚠️ **重要提醒**：
1. 準確區分不同企業高管的觀點
2. 注意財務數據和市場預測
3. 識別商業模式和策略創新
4. 分析對行業的整體影響

📋 **輸出要求**：
請嚴格按照以下XML格式輸出分析結果：

{xml_schema}

📄 **待分析文章**：
{content}

請確保商業術語準確，數據分析客觀，引言歸屬正確。
"""
        
        return templates
    
    def _init_quote_templates(self) -> Dict[str, str]:
        """初始化人物引言提取模板"""
        return {
            "precise_matching": """
請精確匹配以下人物與其在文章中的實際引言。這是修復引言歸屬錯誤的關鍵任務。

🎯 **任務重點**：
- 確保每個引言正確歸屬於說話者
- 只提取直接引言（引號內容或明確說話標記後的內容）
- 避免將同一句話分配給多個人物

⚠️ **嚴格要求**：
1. 仔細分析每個"表示"、"指出"、"他說"、"她說"前後的人物名稱
2. 如果某人物在文章中沒有直接引言，返回空數組
3. 不要推測或補充沒有明確標示的內容
4. 保持引言的原始完整性

🔍 **人物列表**：
{person_names}

📋 **輸出格式**：
請以JSON格式返回：
```json
{{
    "quote_extraction": {{
        "person_name_1": ["實際引言1", "實際引言2"],
        "person_name_2": ["實際引言3"],
        "person_name_3": []
    }},
    "extraction_confidence": {{
        "person_name_1": 0.95,
        "person_name_2": 0.90,
        "person_name_3": 0.0
    }},
    "problematic_matches": [
        {{"person": "name", "issue": "描述問題", "original_text": "原文段落"}}
    ]
}}
```

📄 **文章內容**：
{content}

⚡ **修復重點**：這是解決「所有人物被分配相同引言」bug的關鍵步驟，請格外仔細。
""",
            
            "context_aware": """
基於文章上下文，智能提取人物觀點和立場：

🔍 **提取目標**：
- 直接引言（引號標記）
- 間接觀點（轉述內容）
- 立場態度（支持/反對/中性）
- 專業判斷（基於角色身份）

📋 **上下文分析**：
請考慮人物的：
- 職業背景和專業領域
- 在事件中的角色定位
- 與其他人物的關係
- 觀點的一致性和邏輯性

📄 **文章內容**：
{content}

請提供結構化的人物觀點分析。
"""
        }
    
    def _init_keyword_templates(self) -> Dict[str, str]:
        """初始化關鍵詞生成模板"""
        return {
            "dynamic_semantic": """
基於文章內容和主題，動態生成最相關的語義關鍵詞：

🎯 **生成目標**：
- 核心概念詞彙（5-8個）
- 動作描述詞彙（3-5個）
- 情感表達詞彙（3-5個）
- 技術專業詞彙（5-10個，如適用）

📋 **質量標準**：
1. 關鍵詞必須在文章中真實出現或直接相關
2. 避免過於通用的詞彙（如"重要"、"很好"）
3. 優先選擇能體現文章核心特色的詞彙
4. 考慮後續剪輯匹配的實用性

⚠️ **禁止硬編碼**：
- 不使用預設字典
- 不依賴固定規則
- 完全基於內容動態生成

📋 **輸出格式**：
```json
{{
    "content_keywords": ["關鍵詞1", "關鍵詞2", ...],
    "action_keywords": ["動作詞1", "動作詞2", ...],
    "emotion_keywords": ["情感詞1", "情感詞2", ...],
    "technical_keywords": ["技術詞1", "技術詞2", ...],
    "keyword_confidence": {{
        "content": 0.9,
        "action": 0.85,
        "emotion": 0.8,
        "technical": 0.95
    }}
}}
```

📄 **文章內容**：
{content}

請確保生成的關鍵詞具有高度相關性和實用價值。
""",
            
            "context_enhanced": """
結合文章主題和上下文信息，生成增強型語義標籤：

🔍 **增強要素**：
- 文章標題和副標題
- 段落層次結構
- 人物角色關係
- 事件發展脈絡

📋 **上下文信息**：
- 主題類型：{article_type}
- 核心人物：{key_persons}
- 主要事件：{main_events}

📄 **文章內容**：
{content}

請生成上下文增強的語義標籤集合。
"""
        }
    
    def _init_topic_contexts(self) -> Dict[ArticleType, Dict]:
        """初始化主題特定上下文"""
        return {
            ArticleType.TECHNOLOGY: {
                "focus_areas": ["技術創新", "產品功能", "市場應用", "專家評價"],
                "key_entities": ["技術公司", "產品名稱", "技術規格", "應用場景"],
                "visual_requirements": ["產品演示", "技術圖表", "實際應用", "用戶反應"],
                "pacing_style": "科技感快節奏"
            },
            
            ArticleType.BUSINESS: {
                "focus_areas": ["財務數據", "市場策略", "競爭分析", "高管觀點"],
                "key_entities": ["上市公司", "財務指標", "市場數據", "商業模式"],
                "visual_requirements": ["企業標誌", "數據圖表", "高管訪談", "辦公場景"],
                "pacing_style": "穩重專業節奏"
            },
            
            ArticleType.GENERAL: {
                "focus_areas": ["事件發展", "人物觀點", "社會影響", "未來展望"],
                "key_entities": ["關鍵人物", "重要機構", "事件地點", "時間節點"],
                "visual_requirements": ["現場畫面", "人物訪談", "相關場景", "背景資料"],
                "pacing_style": "平衡敘事節奏"
            }
        }
    
    def get_semantic_analysis_prompt(self, 
                                   content: str, 
                                   article_type: ArticleType = ArticleType.GENERAL,
                                   additional_context: Dict = None) -> str:
        """獲取語義分析提示詞"""
        
        template = self.semantic_analysis_templates.get(
            article_type, 
            self.semantic_analysis_templates[ArticleType.GENERAL]
        )
        
        xml_schema = self.base_xml_schema
        
        # 根據文章類型調整XML結構
        if article_type == ArticleType.TECHNOLOGY:
            xml_schema = xml_schema.replace(
                "<technical_concepts>",
                "<technical_concepts><!-- 科技新聞重點分析 -->"
            )
        
        # 修復XML schema中的佔位符
        from datetime import datetime
        xml_schema = xml_schema.format(
            article_type=article_type.value,
            main_topic="待分析",
            timestamp=datetime.now().isoformat()
        )
        
        return template.format(
            content=content,
            xml_schema=xml_schema
        )
    
    def get_quote_extraction_prompt(self, 
                                  content: str, 
                                  person_names: List[str],
                                  extraction_type: str = "precise_matching") -> str:
        """獲取人物引言提取提示詞"""
        
        template = self.quote_extraction_templates.get(
            extraction_type,
            self.quote_extraction_templates["precise_matching"]
        )
        
        names_str = ", ".join(person_names) if person_names else "無明確人物列表"
        
        return template.format(
            content=content,
            person_names=names_str
        )
    
    def get_keyword_generation_prompt(self, 
                                    content: str,
                                    article_type: ArticleType = ArticleType.GENERAL,
                                    key_persons: List[str] = None,
                                    main_events: List[str] = None) -> str:
        """獲取關鍵詞生成提示詞"""
        
        # 選擇基礎模板
        if key_persons or main_events:
            template = self.keyword_generation_templates["context_enhanced"]
            return template.format(
                content=content,
                article_type=article_type.value,
                key_persons=", ".join(key_persons) if key_persons else "未指定",
                main_events=", ".join(main_events) if main_events else "未指定"
            )
        else:
            template = self.keyword_generation_templates["dynamic_semantic"]
            return template.format(content=content)
    
    def get_topic_context(self, article_type: ArticleType) -> Dict:
        """獲取主題特定上下文"""
        return self.topic_contexts.get(
            article_type,
            self.topic_contexts[ArticleType.GENERAL]
        )
    
    def detect_article_type(self, content: str, title: str = "") -> ArticleType:
        """自動檢測文章類型"""
        
        # 結合標題和內容進行檢測
        full_text = f"{title} {content}".lower()
        
        # 定義各類型的關鍵詞指標
        type_indicators = {
            ArticleType.TECHNOLOGY: [
                "科技", "技術", "AI", "人工智慧", "無人機", "機器人", "軟體", "硬體",
                "創新", "數位", "智能", "系統", "平台", "應用", "開發", "程式"
            ],
            ArticleType.BUSINESS: [
                "股價", "營收", "財報", "投資", "市場", "企業", "公司", "商業",
                "經濟", "產業", "業績", "獲利", "資金", "併購", "上市", "董事"
            ],
            ArticleType.POLITICS: [
                "政府", "總統", "立法院", "政策", "選舉", "政治", "法案", "部長",
                "市長", "議會", "行政", "法律", "條例", "公共", "民眾", "社會"
            ],
            ArticleType.SPORTS: [
                "比賽", "運動", "選手", "冠軍", "球隊", "教練", "賽事", "體育",
                "競技", "訓練", "成績", "紀錄", "聯盟", "球員", "勝利", "defeats"
            ],
            ArticleType.EDUCATION: [
                "學校", "教育", "學生", "老師", "課程", "學習", "校長", "大學",
                "研究", "學術", "知識", "培訓", "教學", "考試", "畢業", "招生"
            ]
        }
        
        # 計算各類型的匹配分數
        type_scores = {}
        for article_type, keywords in type_indicators.items():
            score = sum(1 for keyword in keywords if keyword in full_text)
            type_scores[article_type] = score
        
        # 找出最高分的類型
        if type_scores:
            best_type = max(type_scores, key=type_scores.get)
            if type_scores[best_type] > 0:
                logger.info(f"檢測到文章類型: {best_type.value}")
                return best_type
        
        logger.info("無法確定文章類型，使用一般類型")
        return ArticleType.GENERAL

# 便利函數
def create_prompt_manager() -> PromptTemplateManager:
    """創建提示詞模板管理器實例"""
    return PromptTemplateManager()

# 測試函數
def test_prompt_templates():
    """測試提示詞模板功能"""
    manager = PromptTemplateManager()
    
    test_content = """
    發展科技應用能力　市公所攜手花蓮社大點燃無人機學習熱潮
    
    隨著科技進步與應用場域擴展，無人機已從軍事科技走入民間生活。為推廣無人機知識與應用實務，花蓮市公所、花蓮縣社區大學與台灣國際無人機競技發展協會花蓮分會於28日上午，在化仁國中聯合舉辦「無人機時代來了」技術講座，競技遙控模型直升機世界冠軍林佐翰也現場展演穿越機及無人直升機飛行控制技巧。
    
    林佐翰表示，2016年參加亞拓盃榮獲直升機組第一名，獲廠商青睞簽約成為試飛員。他期望更多年輕人投入，相信台灣飛手實力堅強。
    """
    
    # 測試文章類型檢測
    article_type = manager.detect_article_type(test_content)
    print(f"檢測到的文章類型: {article_type.value}")
    
    # 測試語義分析提示詞
    semantic_prompt = manager.get_semantic_analysis_prompt(test_content, article_type)
    print(f"\n語義分析提示詞長度: {len(semantic_prompt)} 字符")
    
    # 測試引言提取提示詞
    quote_prompt = manager.get_quote_extraction_prompt(
        test_content, 
        ["林佐翰"]
    )
    print(f"引言提取提示詞長度: {len(quote_prompt)} 字符")
    
    # 測試關鍵詞生成提示詞
    keyword_prompt = manager.get_keyword_generation_prompt(test_content, article_type)
    print(f"關鍵詞生成提示詞長度: {len(keyword_prompt)} 字符")
    
    print("\n✅ 提示詞模板測試完成")

if __name__ == "__main__":
    test_prompt_templates()