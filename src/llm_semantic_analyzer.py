#!/usr/bin/env python3
"""
LLM驅動語義分析器 - BigDipper AI剪輯系統

完全基於LLM+提示詞工程的動態語義分析系統，特點：
- 零硬編碼關鍵詞字典
- 智能人物引言精確匹配
- 多供應商LLM支援與自動切換
- XML結構化輸出確保BigDipper兼容性
- 主題自適應分析能力

主要功能：
- 修復人物引言歸屬Bug
- 動態關鍵詞生成
- 智能語義分析
- 結構化數據輸出
"""

import asyncio
import json
import logging
import re
import xml.etree.ElementTree as ET
from datetime import datetime
from typing import Dict, Any, List, Tuple, Optional
from dataclasses import dataclass

from llm_providers import LLMHealthManager, create_llm_providers, AnalysisResult
from prompt_templates import PromptTemplateManager, ArticleType, create_prompt_manager

logger = logging.getLogger("llm_semantic_analyzer")

@dataclass
class ArticleSection:
    """文章段落結構（保持向後兼容）"""
    title: str
    content: str
    section_type: str  # header, content, quote, conclusion
    order: int
    keywords: List[str]
    emotions: List[str]

@dataclass
class KeyPerson:
    """關鍵人物資訊（保持向後兼容）"""
    name: str
    title: str
    role: str
    quotes: List[str]
    expertise: List[str]

@dataclass
class TechnicalConcept:
    """技術概念（保持向後兼容）"""
    name: str
    description: str
    applications: List[str]
    importance_level: int  # 1-10

class LLMSemanticAnalyzer:
    """LLM驅動的新聞文章語義分析器"""
    
    def __init__(self):
        self.logger = logging.getLogger("llm_semantic_analyzer")
        
        # 初始化LLM管理器和提示詞模板
        self.llm_manager = create_llm_providers()
        self.prompt_manager = create_prompt_manager()
        
        # 分析統計
        self.total_analyses = 0
        self.successful_analyses = 0
        self.total_cost = 0.0
        
        self.logger.info("LLM語義分析器初始化完成")
    
    async def analyze_article(self, article_content: str, article_title: str = "") -> Dict[str, Any]:
        """
        分析新聞文章內容（主要入口方法，保持向後兼容）
        
        Args:
            article_content: 文章內容
            article_title: 文章標題（可選）
            
        Returns:
            Dict: 結構化的分析結果（與原系統兼容的格式）
        """
        
        analysis_start = datetime.now()
        self.total_analyses += 1
        
        try:
            # 1. 檢測文章類型
            article_type = self.prompt_manager.detect_article_type(article_content, article_title)
            self.logger.info(f"檢測到文章類型: {article_type.value}")
            
            # 2. 執行LLM語義分析
            llm_result = await self._perform_llm_analysis(article_content, article_type)
            
            if not llm_result.success:
                self.logger.error(f"LLM分析失敗: {llm_result.error_message}")
                return self._create_fallback_result(article_content, article_title, analysis_start)
            
            # 3. 解析LLM輸出的XML結構
            parsed_data = self._parse_llm_xml_output(llm_result.content)
            
            # 4. 修復人物引言問題（關鍵修復）
            fixed_persons = await self._fix_person_quotes(article_content, parsed_data.get('persons', []))
            
            # 5. 轉換為向後兼容的格式
            compatible_result = self._convert_to_compatible_format(
                parsed_data, 
                fixed_persons,
                article_content, 
                article_title, 
                analysis_start,
                llm_result
            )
            
            # 6. 更新統計
            self.successful_analyses += 1
            self.total_cost += llm_result.cost
            
            self.logger.info(f"分析完成，使用供應商: {llm_result.provider_used}")
            return compatible_result
            
        except Exception as e:
            self.logger.error(f"分析過程出錯: {e}")
            return self._create_fallback_result(article_content, article_title, analysis_start)
    
    async def _perform_llm_analysis(self, content: str, article_type: ArticleType) -> AnalysisResult:
        """執行LLM語義分析"""
        
        # 獲取適合的提示詞
        prompt = self.prompt_manager.get_semantic_analysis_prompt(content, article_type)
        
        # 使用回退機制調用LLM，使用簡單的模板形式
        # 因為prompt已經是完整的，我們用{content}佔位符來避免格式化問題
        result = await self.llm_manager.analyze_with_fallback(prompt, "{content}")
        
        return result
    
    def _parse_llm_xml_output(self, xml_content: str) -> Dict[str, Any]:
        """解析LLM輸出的XML結構化數據"""
        
        try:
            # 清理XML內容
            xml_content = self._clean_xml_content(xml_content)
            
            # 解析XML
            root = ET.fromstring(xml_content)
            
            parsed_data = {
                'persons': self._extract_persons_from_xml(root),
                'organizations': self._extract_organizations_from_xml(root),
                'events': self._extract_events_from_xml(root),
                'themes': self._extract_themes_from_xml(root),
                'sentiment': self._extract_sentiment_from_xml(root),
                'narrative_structure': self._extract_narrative_from_xml(root),
                'technical_concepts': self._extract_technical_concepts_from_xml(root),
                'editing_cues': self._extract_editing_cues_from_xml(root),
                'semantic_vectors': self._extract_semantic_vectors_from_xml(root)
            }
            
            return parsed_data
            
        except ET.ParseError as e:
            self.logger.error(f"XML解析失敗: {e}")
            # 嘗試使用正則表達式提取關鍵信息
            return self._extract_data_with_regex(xml_content)
        
        except Exception as e:
            self.logger.error(f"數據解析出錯: {e}")
            return {}
    
    def _clean_xml_content(self, xml_content: str) -> str:
        """清理和修復XML內容"""
        
        # 移除可能的markdown標記
        xml_content = re.sub(r'```xml\s*', '', xml_content)
        xml_content = re.sub(r'```\s*$', '', xml_content)
        
        # 確保有根節點
        if not xml_content.strip().startswith('<semantic_analysis>'):
            # 尋找semantic_analysis標籤
            match = re.search(r'<semantic_analysis>.*?</semantic_analysis>', xml_content, re.DOTALL)
            if match:
                xml_content = match.group(0)
            else:
                # 如果找不到完整結構，包裝現有內容
                xml_content = f"<semantic_analysis>{xml_content}</semantic_analysis>"
        
        # 移除無效字符
        xml_content = re.sub(r'[^\x09\x0A\x0D\x20-\x7E\u4e00-\u9fff\u3000-\u303f]', '', xml_content)
        
        return xml_content
    
    def _extract_persons_from_xml(self, root: ET.Element) -> List[Dict]:
        """從XML中提取人物信息"""
        persons = []
        
        persons_node = root.find('.//persons')
        if persons_node is not None:
            for person_node in persons_node.findall('person'):
                person_data = {
                    'name': person_node.get('name', ''),
                    'title': person_node.get('title', ''),
                    'role': person_node.get('role', ''),
                    'quotes': [],
                    'expertise': person_node.get('expertise', '').split(',') if person_node.get('expertise') else []
                }
                
                # 提取引言
                quotes_node = person_node.find('quotes')
                if quotes_node is not None:
                    for quote_node in quotes_node.findall('quote'):
                        if quote_node.text:
                            person_data['quotes'].append(quote_node.text.strip())
                
                persons.append(person_data)
        
        return persons
    
    def _extract_organizations_from_xml(self, root: ET.Element) -> List[Dict]:
        """從XML中提取組織信息"""
        organizations = []
        
        orgs_node = root.find('.//organizations')
        if orgs_node is not None:
            for org_node in orgs_node.findall('org'):
                org_data = {
                    'name': org_node.get('name', ''),
                    'type': org_node.get('type', ''),
                    'importance': org_node.get('importance', 'medium')
                }
                organizations.append(org_data)
        
        return organizations
    
    def _extract_events_from_xml(self, root: ET.Element) -> List[Dict]:
        """從XML中提取事件信息"""
        events = []
        
        events_node = root.find('.//events')
        if events_node is not None:
            for event_node in events_node.findall('event'):
                event_data = {
                    'name': event_node.get('name', ''),
                    'type': event_node.get('type', ''),
                    'impact_level': int(event_node.get('impact_level', '5')),
                    'timeframe': event_node.get('timeframe', '')
                }
                events.append(event_data)
        
        return events
    
    def _extract_themes_from_xml(self, root: ET.Element) -> List[str]:
        """從XML中提取主題信息"""
        themes = []
        
        themes_node = root.find('.//main_themes')
        if themes_node is not None:
            for theme_node in themes_node.findall('theme'):
                theme_name = theme_node.get('name', '')
                if theme_name:
                    themes.append(theme_name)
        
        return themes
    
    def _extract_sentiment_from_xml(self, root: ET.Element) -> Dict:
        """從XML中提取情感分析"""
        sentiment_data = {
            'overall': 'neutral',
            'confidence': 0.5,
            'by_paragraph': []
        }
        
        sentiment_node = root.find('.//sentiment_analysis')
        if sentiment_node is not None:
            overall_node = sentiment_node.find('overall')
            if overall_node is not None:
                sentiment_data['overall'] = overall_node.get('sentiment', 'neutral')
                sentiment_data['confidence'] = float(overall_node.get('confidence', '0.5'))
            
            # 提取段落情感
            paragraphs_node = sentiment_node.find('by_paragraph')
            if paragraphs_node is not None:
                for para_node in paragraphs_node.findall('paragraph'):
                    para_data = {
                        'id': int(para_node.get('id', '0')),
                        'sentiment': para_node.get('sentiment', 'neutral'),
                        'score': float(para_node.get('score', '0.5'))
                    }
                    sentiment_data['by_paragraph'].append(para_data)
        
        return sentiment_data
    
    def _extract_narrative_from_xml(self, root: ET.Element) -> Dict:
        """從XML中提取敘事結構"""
        narrative = {
            'introduction': [],
            'development': [],
            'climax': [],
            'conclusion': []
        }
        
        narrative_node = root.find('.//narrative_structure')
        if narrative_node is not None:
            for section_node in narrative_node.findall('section'):
                section_type = section_node.get('type', '')
                paragraphs = section_node.get('paragraphs', '')
                
                if section_type in narrative:
                    # 解析段落範圍
                    if '-' in paragraphs:
                        start, end = paragraphs.split('-')
                        para_range = list(range(int(start), int(end) + 1))
                    else:
                        para_range = [int(paragraphs)] if paragraphs.isdigit() else []
                    
                    narrative[section_type] = para_range
        
        return narrative
    
    def _extract_technical_concepts_from_xml(self, root: ET.Element) -> List[Dict]:
        """從XML中提取技術概念"""
        concepts = []
        
        concepts_node = root.find('.//technical_concepts')
        if concepts_node is not None:
            for concept_node in concepts_node.findall('concept'):
                concept_data = {
                    'name': concept_node.get('name', ''),
                    'description': concept_node.get('description', ''),
                    'importance': int(concept_node.get('importance', '5')),
                    'applications': concept_node.get('applications', '').split(',') if concept_node.get('applications') else []
                }
                concepts.append(concept_data)
        
        return concepts
    
    def _extract_editing_cues_from_xml(self, root: ET.Element) -> Dict:
        """從XML中提取剪輯線索"""
        editing_cues = {
            'primary': [],
            'secondary': [],
            'visual': [],
            'pacing': []
        }
        
        editing_node = root.find('.//editing_intelligence')
        if editing_node is not None:
            # 主要線索
            primary_node = editing_node.find('primary_cues')
            if primary_node is not None:
                for cue_node in primary_node.findall('cue'):
                    editing_cues['primary'].append(cue_node.get('description', ''))
            
            # 次要線索
            secondary_node = editing_node.find('secondary_cues')
            if secondary_node is not None:
                for cue_node in secondary_node.findall('cue'):
                    editing_cues['secondary'].append(cue_node.get('description', ''))
            
            # 視覺需求
            visual_node = editing_node.find('visual_requirements')
            if visual_node is not None:
                for req_node in visual_node.findall('requirement'):
                    editing_cues['visual'].append(req_node.get('description', ''))
            
            # 節奏建議
            pacing_node = editing_node.find('pacing_suggestions')
            if pacing_node is not None:
                for sug_node in pacing_node.findall('suggestion'):
                    editing_cues['pacing'].append(f"{sug_node.get('pace', '')}: {sug_node.get('reason', '')}")
        
        return editing_cues
    
    def _extract_semantic_vectors_from_xml(self, root: ET.Element) -> Dict:
        """從XML中提取語義向量"""
        vectors = {
            'content_keywords': [],
            'technical_keywords': [],
            'action_keywords': [],
            'emotion_keywords': []
        }
        
        vectors_node = root.find('.//semantic_vectors')
        if vectors_node is not None:
            for vector_type in vectors.keys():
                node = vectors_node.find(vector_type)
                if node is not None and node.text:
                    # 分割關鍵詞
                    keywords = [kw.strip() for kw in node.text.split(',') if kw.strip()]
                    vectors[vector_type] = keywords
        
        return vectors
    
    def _extract_data_with_regex(self, content: str) -> Dict:
        """使用正則表達式提取數據（XML解析失敗時的備用方案）"""
        self.logger.warning("使用正則表達式備用方案提取數據")
        
        extracted = {
            'persons': [],
            'organizations': [],
            'events': [],
            'themes': [],
            'sentiment': {'overall': 'neutral', 'confidence': 0.5, 'by_paragraph': []},
            'narrative_structure': {'introduction': [], 'development': [], 'climax': [], 'conclusion': []},
            'technical_concepts': [],
            'editing_cues': {'primary': [], 'secondary': [], 'visual': [], 'pacing': []},
            'semantic_vectors': {'content_keywords': [], 'technical_keywords': [], 'action_keywords': [], 'emotion_keywords': []}
        }
        
        # 提取人物信息
        person_matches = re.findall(r'<person[^>]*name="([^"]*)"[^>]*title="([^"]*)"[^>]*>', content)
        for name, title in person_matches:
            extracted['persons'].append({
                'name': name,
                'title': title,
                'role': '',
                'quotes': [],
                'expertise': []
            })
        
        return extracted
    
    async def _fix_person_quotes(self, content: str, persons: List[Dict]) -> List[Dict]:
        """修復人物引言歸屬問題（關鍵修復功能）"""
        
        if not persons:
            self.logger.info("沒有發現人物，跳過引言修復")
            return persons
        
        try:
            # 提取所有人物名稱
            person_names = [person['name'] for person in persons if person['name']]
            
            if not person_names:
                self.logger.warning("沒有有效的人物名稱")
                return persons
            
            # 使用專門的引言提取提示詞
            quote_prompt = self.prompt_manager.get_quote_extraction_prompt(
                content, 
                person_names,
                "precise_matching"
            )
            
            # 調用LLM進行精確的引言匹配
            quote_result = await self.llm_manager.analyze_with_fallback(quote_prompt, "{content}")
            
            if quote_result.success:
                # 解析LLM返回的引言匹配結果
                quote_data = self._parse_quote_extraction_result(quote_result.content)
                
                # 更新人物引言
                for person in persons:
                    person_name = person['name']
                    if person_name in quote_data.get('quote_extraction', {}):
                        person['quotes'] = quote_data['quote_extraction'][person_name]
                        self.logger.info(f"為 {person_name} 更新了 {len(person['quotes'])} 條引言")
                    else:
                        person['quotes'] = []
                        self.logger.info(f"{person_name} 沒有找到引言")
            
            else:
                self.logger.error(f"引言修復失敗: {quote_result.error_message}")
        
        except Exception as e:
            self.logger.error(f"引言修復過程出錯: {e}")
        
        return persons
    
    def _parse_quote_extraction_result(self, result_content: str) -> Dict:
        """解析引言提取結果"""
        
        try:
            # 嘗試解析JSON格式
            # 尋找JSON內容
            json_match = re.search(r'\{.*\}', result_content, re.DOTALL)
            if json_match:
                json_str = json_match.group(0)
                return json.loads(json_str)
            else:
                self.logger.warning("未找到JSON格式的引言數據")
                return {}
        
        except json.JSONDecodeError as e:
            self.logger.error(f"引言數據JSON解析失敗: {e}")
            
            # 備用方案：使用正則表達式提取
            return self._extract_quotes_with_regex(result_content)
    
    def _extract_quotes_with_regex(self, content: str) -> Dict:
        """使用正則表達式提取引言（備用方案）"""
        
        quote_extraction = {}
        
        # 簡單的引言提取邏輯
        lines = content.split('\n')
        current_person = None
        
        for line in lines:
            # 檢查是否包含人物名稱
            if '：' in line or ':' in line:
                parts = re.split('[：:]', line, 1)
                if len(parts) == 2:
                    potential_name = parts[0].strip().strip('"\'')
                    quote_text = parts[1].strip().strip('"\'')
                    
                    if potential_name and quote_text:
                        if potential_name not in quote_extraction:
                            quote_extraction[potential_name] = []
                        quote_extraction[potential_name].append(quote_text)
        
        return {'quote_extraction': quote_extraction}
    
    def _convert_to_compatible_format(self, 
                                    parsed_data: Dict, 
                                    fixed_persons: List[Dict],
                                    article_content: str, 
                                    article_title: str, 
                                    analysis_start: datetime,
                                    llm_result: AnalysisResult) -> Dict[str, Any]:
        """轉換為與原系統兼容的格式"""
        
        analysis_end = datetime.now()
        
        # 基本段落分析（簡化版，保持兼容性）
        sections = self._create_compatible_sections(article_content)
        
        # 轉換人物格式
        key_persons = []
        for person_data in fixed_persons:
            key_persons.append(KeyPerson(
                name=person_data.get('name', ''),
                title=person_data.get('title', ''),
                role=person_data.get('role', ''),
                quotes=person_data.get('quotes', []),
                expertise=person_data.get('expertise', [])
            ))
        
        # 轉換技術概念格式
        technical_concepts = []
        for concept_data in parsed_data.get('technical_concepts', []):
            technical_concepts.append(TechnicalConcept(
                name=concept_data.get('name', ''),
                description=concept_data.get('description', ''),
                applications=concept_data.get('applications', []),
                importance_level=concept_data.get('importance', 5)
            ))
        
        # 構建兼容的結果格式
        return {
            "article_metadata": {
                "title": article_title,
                "analysis_timestamp": analysis_start.isoformat(),
                "processing_time_ms": int((analysis_end - analysis_start).total_seconds() * 1000),
                "word_count": len(article_content),
                "section_count": len(sections),
                "llm_provider_used": llm_result.provider_used,
                "llm_tokens_used": llm_result.tokens_used,
                "llm_cost": llm_result.cost,
                "llm_response_time": llm_result.response_time
            },
            "content_structure": {
                "sections": [self._section_to_dict(section) for section in sections],
                "narrative_flow": parsed_data.get('narrative_structure', {}),
                "main_themes": parsed_data.get('themes', []),
                "emotional_arc": self._create_emotional_arc(sections, parsed_data.get('sentiment', {}))
            },
            "key_entities": {
                "persons": [self._person_to_dict(person) for person in key_persons],
                "technical_concepts": [self._concept_to_dict(concept) for concept in technical_concepts],
                "timeline": self._extract_timeline_from_parsed(parsed_data),
                "organizations": parsed_data.get('organizations', []),
                "events": parsed_data.get('events', [])
            },
            "editing_intelligence": {
                "primary_editing_cues": parsed_data.get('editing_cues', {}).get('primary', []),
                "secondary_editing_cues": parsed_data.get('editing_cues', {}).get('secondary', []),
                "visual_requirements": parsed_data.get('editing_cues', {}).get('visual', []),
                "pacing_suggestions": parsed_data.get('editing_cues', {}).get('pacing', [])
            },
            "semantic_vectors": parsed_data.get('semantic_vectors', {
                'content_keywords': [],
                'technical_keywords': [],
                'action_keywords': [],
                'emotion_keywords': []
            })
        }
    
    def _create_compatible_sections(self, content: str) -> List[ArticleSection]:
        """創建兼容的段落結構"""
        sections = []
        paragraphs = [p.strip() for p in content.split('\n') if p.strip()]
        
        for i, paragraph in enumerate(paragraphs):
            section_type = self._classify_section_type(paragraph)
            
            sections.append(ArticleSection(
                title="",
                content=paragraph,
                section_type=section_type,
                order=i,
                keywords=[],  # 由LLM動態生成，不使用硬編碼
                emotions=[]   # 由LLM動態生成，不使用硬編碼
            ))
        
        return sections
    
    def _classify_section_type(self, paragraph: str) -> str:
        """分類段落類型（簡化版）"""
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
    
    def _create_emotional_arc(self, sections: List[ArticleSection], sentiment_data: Dict) -> List[Dict[str, Any]]:
        """創建情感曲線"""
        emotional_arc = []
        
        by_paragraph = sentiment_data.get('by_paragraph', [])
        
        for i, section in enumerate(sections):
            # 尋找對應的段落情感數據
            para_sentiment = None
            for para_data in by_paragraph:
                if para_data.get('id') == i + 1:
                    para_sentiment = para_data
                    break
            
            if para_sentiment:
                emotional_arc.append({
                    "section_order": section.order,
                    "emotion_score": int(para_sentiment.get('score', 0.5) * 10),
                    "dominant_emotions": [para_sentiment.get('sentiment', 'neutral')],
                    "content_preview": section.content[:50] + "..."
                })
            else:
                # 默認中性情感
                emotional_arc.append({
                    "section_order": section.order,
                    "emotion_score": 5,
                    "dominant_emotions": ['neutral'],
                    "content_preview": section.content[:50] + "..."
                })
        
        return emotional_arc
    
    def _extract_timeline_from_parsed(self, parsed_data: Dict) -> List[Dict[str, str]]:
        """從解析數據中提取時間線"""
        timeline = []
        
        # 從事件數據中提取時間線
        events = parsed_data.get('events', [])
        for event in events:
            if event.get('timeframe'):
                timeline.append({
                    "time_reference": event.get('timeframe', ''),
                    "event": event.get('name', ''),
                    "importance": "high" if event.get('impact_level', 5) >= 7 else "medium"
                })
        
        return timeline
    
    def _create_fallback_result(self, article_content: str, article_title: str, analysis_start: datetime) -> Dict[str, Any]:
        """創建備用分析結果（當LLM分析失敗時）"""
        
        analysis_end = datetime.now()
        
        return {
            "article_metadata": {
                "title": article_title,
                "analysis_timestamp": analysis_start.isoformat(),
                "processing_time_ms": int((analysis_end - analysis_start).total_seconds() * 1000),
                "word_count": len(article_content),
                "section_count": len(article_content.split('\n')),
                "llm_provider_used": "fallback",
                "llm_tokens_used": 0,
                "llm_cost": 0.0,
                "error": "LLM分析失敗，使用備用結果"
            },
            "content_structure": {
                "sections": [],
                "narrative_flow": {},
                "main_themes": [],
                "emotional_arc": []
            },
            "key_entities": {
                "persons": [],
                "technical_concepts": [],
                "timeline": [],
                "organizations": [],
                "events": []
            },
            "editing_intelligence": {
                "primary_editing_cues": [],
                "secondary_editing_cues": [],
                "visual_requirements": [],
                "pacing_suggestions": []
            },
            "semantic_vectors": {
                'content_keywords': [],
                'technical_keywords': [],
                'action_keywords': [],
                'emotion_keywords': []
            }
        }
    
    # 向後兼容的轉換方法
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
    
    def get_analysis_stats(self) -> Dict[str, Any]:
        """獲取分析統計信息"""
        return {
            "total_analyses": self.total_analyses,
            "successful_analyses": self.successful_analyses,
            "success_rate": self.successful_analyses / self.total_analyses if self.total_analyses > 0 else 0,
            "total_cost": self.total_cost,
            "average_cost": self.total_cost / self.successful_analyses if self.successful_analyses > 0 else 0,
            "llm_provider_metrics": self.llm_manager.get_provider_metrics()
        }

# 便利函數（保持向後兼容）
async def analyze_news_article(article_content: str, article_title: str = "") -> Dict[str, Any]:
    """便利函數：快速分析新聞文章"""
    analyzer = LLMSemanticAnalyzer()
    return await analyzer.analyze_article(article_content, article_title)

# 測試函數
async def test_llm_semantic_analyzer():
    """測試LLM語義分析器功能"""
    # 測試用的文章片段（包含已知的人物引言Bug）
    test_article = """
發展科技應用能力　市公所攜手花蓮社大點燃無人機學習熱潮

隨著科技進步與應用場域擴展，無人機已從軍事科技走入民間生活。為推廣無人機知識與應用實務，花蓮市公所、花蓮縣社區大學與台灣國際無人機競技發展協會花蓮分會於28日上午，在化仁國中聯合舉辦「無人機時代來了」技術講座，競技遙控模型直升機世界冠軍林佐翰也現場展演穿越機及無人直升機飛行控制技巧。

**世界冠軍現場展演震撼全場**

由無人機飛齡11年，榮獲競技遙控模型直升機世界冠軍的林佐翰現場展演穿越機（FPV racing drone）與無人直升機飛行控制（Flight Control）技巧，只見他以精準飛控、疾速轉彎與高難度動作操作無人機，展現世界級競技實力。

林佐翰表示，2016年參加亞拓盃榮獲直升機組第一名，獲廠商青睞簽約成為試飛員。他期望更多年輕人投入，相信台灣飛手實力堅強。
    """
    
    print("🚀 開始測試LLM語義分析器...")
    
    analyzer = LLMSemanticAnalyzer()
    result = await analyzer.analyze_article(test_article, "無人機技術講座報導")
    
    print(f"\n📊 分析結果摘要:")
    metadata = result["article_metadata"]
    for key, value in metadata.items():
        print(f"  {key}: {value}")
    
    print(f"\n👥 關鍵人物分析:")
    for person in result["key_entities"]["persons"]:
        print(f"  📝 {person['name']} ({person['title']})")
        print(f"     角色: {person['role']}")
        print(f"     專業: {', '.join(person['expertise'])}")
        if person['quotes']:
            print(f"     引言: {person['quotes']}")
        print()
    
    print(f"\n🎬 剪輯智能分析:")
    editing = result["editing_intelligence"]
    
    print(f"  主要剪輯線索:")
    for cue in editing["primary_editing_cues"]:
        print(f"    • {cue}")
    
    print(f"  視覺需求:")
    for visual in editing["visual_requirements"]:
        print(f"    • {visual}")
    
    # 顯示分析統計
    stats = analyzer.get_analysis_stats()
    print(f"\n📈 分析統計:")
    for key, value in stats.items():
        if key != 'llm_provider_metrics':
            print(f"  {key}: {value}")
    
    print("\n✅ LLM語義分析器測試完成")

if __name__ == "__main__":
    asyncio.run(test_llm_semantic_analyzer())