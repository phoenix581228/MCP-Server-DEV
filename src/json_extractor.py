#!/usr/bin/env python3
"""
智能JSON提取器 - 解決BigDipper系統中的JSON字串包裝問題

此模組專門處理Gemini API回應中常見的JSON格式問題：
- ```json markdown包裝
- 字串化的JSON數據
- 多層嵌套的JSON結構
- 格式化和清理問題
"""

import re
import json
import logging
from typing import Dict, Any, Optional, List
from datetime import datetime

class IntelligentJSONExtractor:
    """智能JSON提取器 - 解決多格式JSON解析問題"""
    
    def __init__(self):
        self.logger = logging.getLogger("json_extractor")
        
        # JSON區塊檢測模式 - 按優先順序排列
        self.json_patterns = [
            # 標準markdown JSON包裝
            r'```json\s*\n(.*?)\n\s*```',
            # 通用代碼塊包裝  
            r'```\s*\n(.*?)\n\s*```',
            # 直接JSON對象 (最嚴格的模式)
            r'(\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\})',
            # 寬鬆JSON對象匹配
            r'(\{.*?\})',
        ]
        
        # 統計信息
        self.stats = {
            "total_extractions": 0,
            "direct_parsing_success": 0,
            "pattern_matching_success": 0,
            "fallback_used": 0,
            "extraction_methods": {}
        }
    
    def extract_json_from_response(self, response_text: str) -> Dict[str, Any]:
        """
        從Gemini回應中提取JSON數據
        
        Args:
            response_text: Gemini原始回應文本
            
        Returns:
            Dict: 解析後的結構化數據
        """
        self.stats["total_extractions"] += 1
        
        if not response_text or not response_text.strip():
            self.logger.warning("Empty response text provided")
            return self.generate_fallback_structure("Empty response")
        
        # 步驟1: 嘗試直接解析
        try:
            parsed_data = json.loads(response_text.strip())
            self.logger.info("Direct JSON parsing successful")
            self.stats["direct_parsing_success"] += 1
            
            if self.validate_extracted_data(parsed_data):
                return self._add_extraction_metadata(parsed_data, "direct_parsing")
            else:
                self.logger.warning("Direct parsing succeeded but validation failed")
                
        except json.JSONDecodeError:
            self.logger.debug("Direct parsing failed, trying pattern extraction")
        
        # 步驟2: 模式匹配提取
        extraction_result = self._try_pattern_extraction(response_text)
        if extraction_result:
            return extraction_result
        
        # 步驟3: 智能清理和重試
        cleaned_result = self._try_cleaned_extraction(response_text)
        if cleaned_result:
            return cleaned_result
        
        # 步驟4: 回退方案
        self.logger.warning("All extraction methods failed, generating fallback structure")
        self.stats["fallback_used"] += 1
        return self.generate_fallback_structure(response_text)
    
    def _try_pattern_extraction(self, response_text: str) -> Optional[Dict[str, Any]]:
        """嘗試使用模式匹配提取JSON"""
        
        for i, pattern in enumerate(self.json_patterns):
            matches = re.findall(pattern, response_text, re.DOTALL | re.IGNORECASE)
            
            for match in matches:
                try:
                    extracted_data = json.loads(match.strip())
                    
                    if self.validate_extracted_data(extracted_data):
                        self.logger.info(f"Pattern extraction successful using pattern {i+1}")
                        self.stats["pattern_matching_success"] += 1
                        method_name = f"pattern_{i+1}_extraction"
                        self.stats["extraction_methods"][method_name] = self.stats["extraction_methods"].get(method_name, 0) + 1
                        
                        return self._add_extraction_metadata(extracted_data, method_name)
                        
                except json.JSONDecodeError:
                    continue
        
        return None
    
    def _try_cleaned_extraction(self, response_text: str) -> Optional[Dict[str, Any]]:
        """嘗試清理文本後再解析"""
        
        cleaned_versions = [
            self.clean_response_text(response_text),
            self.aggressive_clean(response_text),
            self.extract_json_like_content(response_text)
        ]
        
        for i, cleaned_text in enumerate(cleaned_versions):
            if not cleaned_text:
                continue
                
            try:
                parsed_data = json.loads(cleaned_text)
                if self.validate_extracted_data(parsed_data):
                    self.logger.info(f"Cleaned extraction successful (method {i+1})")
                    method_name = f"cleaned_method_{i+1}"
                    self.stats["extraction_methods"][method_name] = self.stats["extraction_methods"].get(method_name, 0) + 1
                    
                    return self._add_extraction_metadata(parsed_data, method_name)
                    
            except json.JSONDecodeError:
                continue
        
        return None
    
    def validate_extracted_data(self, data: Dict[str, Any]) -> bool:
        """驗證提取的數據結構是否有效"""
        
        if not isinstance(data, dict):
            return False
        
        # 檢查是否包含基本的視頻分析結構
        basic_indicators = [
            "summary", "scenes", "technical_analysis", "production_suggestions",
            "video_metadata", "content_analysis", "scene_breakdown"
        ]
        
        # 至少要有一個主要指標
        has_basic_structure = any(key in data for key in basic_indicators)
        
        # 檢查數據不為空
        has_content = len(data) > 0 and any(
            value for value in data.values() 
            if value is not None and value != "" and value != []
        )
        
        return has_basic_structure and has_content
    
    def clean_response_text(self, text: str) -> str:
        """基本清理回應文本"""
        # 移除markdown標記
        text = re.sub(r'```(?:json)?\s*\n?', '', text)
        text = re.sub(r'\n?\s*```', '', text)
        
        # 移除多餘的換行和空格
        text = re.sub(r'\n+', ' ', text)
        text = re.sub(r'\s+', ' ', text)
        
        return text.strip()
    
    def aggressive_clean(self, text: str) -> str:
        """積極清理文本"""
        # 移除所有可能的markdown和格式標記
        text = re.sub(r'```[^`]*```', '', text)  # 移除代碼塊
        text = re.sub(r'`[^`]*`', '', text)      # 移除行內代碼
        text = re.sub(r'#{1,6}\s*', '', text)    # 移除標題標記
        text = re.sub(r'\*{1,2}([^*]*)\*{1,2}', r'\1', text)  # 移除粗體/斜體
        
        # 清理換行和空格
        text = re.sub(r'\n+', ' ', text)
        text = re.sub(r'\s+', ' ', text)
        
        return text.strip()
    
    def extract_json_like_content(self, text: str) -> str:
        """提取類似JSON的內容"""
        # 尋找大括號包圍的內容
        json_match = re.search(r'\{.*\}', text, re.DOTALL)
        if json_match:
            content = json_match.group(0)
            
            # 嘗試修復常見的JSON問題
            content = re.sub(r',\s*}', '}', content)  # 移除尾隨逗號
            content = re.sub(r',\s*]', ']', content)  # 移除數組尾隨逗號
            
            return content
        
        return ""
    
    def generate_fallback_structure(self, original_text: str) -> Dict[str, Any]:
        """生成回退數據結構"""
        return {
            "video_metadata": {
                "filename": "unknown",
                "analysis_timestamp": datetime.now().isoformat(),
                "parsing_status": "failed"
            },
            "content_analysis": {
                "summary": self._extract_summary_from_text(original_text),
                "main_subjects": [],
                "key_events": [],
                "emotional_tone": "unknown"
            },
            "technical_specs": {
                "image_quality": "需要重新分析",
                "stability": "需要重新分析", 
                "lighting": "需要重新分析",
                "audio_quality": "需要重新分析"
            },
            "drone_performance": {
                "flight_patterns": [],
                "altitude_ranges": "未知",
                "shooting_techniques": [],
                "operator_skill_level": "unknown"
            },
            "scene_breakdown": [],
            "production_assessment": {
                "overall_quality": 0,
                "editing_potential": 0,
                "story_value": 0,
                "improvements": ["需要重新進行分析"],
                "retakes": [],
                "post_production": []
            },
            "_metadata": {
                "extraction_method": "fallback",
                "requires_manual_review": True,
                "original_response_preview": original_text[:200] if original_text else "",
                "extraction_timestamp": datetime.now().isoformat(),
                "fallback_reason": "JSON parsing failed"
            }
        }
    
    def _extract_summary_from_text(self, text: str) -> str:
        """從原始文本中嘗試提取摘要"""
        if not text:
            return "無法提取內容摘要"
        
        # 尋找可能的摘要內容
        summary_patterns = [
            r'summary["\']?\s*:\s*["\']([^"\']{20,200})["\']',
            r'摘要[：:]\s*(.{20,200})',
            r'這.*?影片.*?(.{20,200})',
        ]
        
        for pattern in summary_patterns:
            match = re.search(pattern, text, re.IGNORECASE)
            if match:
                return match.group(1).strip()
        
        # 如果找不到特定摘要，返回前200字符
        clean_text = re.sub(r'[{}"\'`,\[\]]', ' ', text)
        clean_text = re.sub(r'\s+', ' ', clean_text).strip()
        
        return clean_text[:200] + "..." if len(clean_text) > 200 else clean_text
    
    def _add_extraction_metadata(self, data: Dict[str, Any], method: str) -> Dict[str, Any]:
        """為提取的數據添加元數據"""
        if "_metadata" not in data:
            data["_metadata"] = {}
        
        data["_metadata"].update({
            "extraction_method": method,
            "extraction_timestamp": datetime.now().isoformat(),
            "requires_manual_review": False,
            "extraction_success": True
        })
        
        return data
    
    def get_extraction_stats(self) -> Dict[str, Any]:
        """獲取提取統計信息"""
        success_rate = 0
        if self.stats["total_extractions"] > 0:
            successful = (self.stats["direct_parsing_success"] + 
                         self.stats["pattern_matching_success"])
            success_rate = (successful / self.stats["total_extractions"]) * 100
        
        return {
            **self.stats,
            "success_rate_percentage": round(success_rate, 2),
            "fallback_rate_percentage": round(
                (self.stats["fallback_used"] / max(1, self.stats["total_extractions"])) * 100, 2
            )
        }
    
    def reset_stats(self):
        """重置統計信息"""
        self.stats = {
            "total_extractions": 0,
            "direct_parsing_success": 0,
            "pattern_matching_success": 0,
            "fallback_used": 0,
            "extraction_methods": {}
        }


# 便利函數
def extract_json_from_gemini_response(response_text: str) -> Dict[str, Any]:
    """便利函數：快速從Gemini回應中提取JSON"""
    extractor = IntelligentJSONExtractor()
    return extractor.extract_json_from_response(response_text)


# 測試函數
def test_extractor():
    """測試提取器功能"""
    extractor = IntelligentJSONExtractor()
    
    # 測試案例1: markdown包裝的JSON
    test_case_1 = '''```json
{
  "summary": "這是一個測試影片",
  "scenes": [{"timestamp": "00:00-01:00", "description": "測試場景"}],
  "technical_analysis": {"image_quality": "良好"}
}
```'''
    
    # 測試案例2: 字串包裝的JSON (模擬BigDipper問題)
    test_case_2 = '''```json
{
  "summary": "這部影片展示了無人機飛行",
  "drone_analysis": {
    "flight_patterns": ["定點懸停"],
    "altitude_ranges": "低空"
  },
  "scenes": [{
    "timestamp": "00:00-02:36",
    "description": "無人機表演場景"
  }]
}
```'''
    
    test_cases = [test_case_1, test_case_2]
    
    print("開始測試智能JSON提取器...")
    for i, test_case in enumerate(test_cases, 1):
        print(f"\n測試案例 {i}:")
        result = extractor.extract_json_from_response(test_case)
        print(f"提取成功: {result.get('_metadata', {}).get('extraction_success', False)}")
        print(f"提取方法: {result.get('_metadata', {}).get('extraction_method', 'unknown')}")
    
    print(f"\n統計信息:")
    stats = extractor.get_extraction_stats()
    for key, value in stats.items():
        print(f"  {key}: {value}")


if __name__ == "__main__":
    test_extractor()