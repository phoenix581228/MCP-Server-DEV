#!/usr/bin/env python3
"""
LLM Provider 抽象層 - BigDipper AI剪輯系統

支援多供應商LLM服務的統一抽象層，包括：
- Claude Sonnet 4 (主力供應商)
- GPT-4o mini (備援供應商) 
- Gemini Pro (整合現有MCP)

主要功能：
- 統一的LLM API接口
- 健康檢查與自動切換
- 成本監控與配額管理
- 非同步調用支援
"""

import asyncio
import json
import logging
import os
import time
from abc import ABC, abstractmethod
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Union, Any
from dataclasses import dataclass
from enum import Enum

import aiohttp
import openai
import google.generativeai as genai

logger = logging.getLogger("llm_providers")

class ProviderStatus(Enum):
    """供應商狀態枚舉"""
    HEALTHY = "healthy"
    DEGRADED = "degraded"
    UNHEALTHY = "unhealthy"
    UNKNOWN = "unknown"

@dataclass
class ProviderConfig:
    """供應商配置"""
    name: str
    api_key: str
    model_name: str
    max_tokens: int = 4000
    temperature: float = 0.7
    timeout: int = 120
    retry_attempts: int = 3
    cost_per_token: float = 0.000015  # 預設每token成本

@dataclass
class AnalysisResult:
    """LLM分析結果"""
    content: str
    provider_used: str
    tokens_used: int
    cost: float
    response_time: float
    success: bool
    error_message: Optional[str] = None

class LLMProvider(ABC):
    """LLM供應商抽象基類"""
    
    def __init__(self, config: ProviderConfig):
        self.config = config
        self.status = ProviderStatus.UNKNOWN
        self.last_health_check = None
        self.total_tokens_used = 0
        self.total_cost = 0.0
        self.request_count = 0
        self.success_count = 0
    
    @abstractmethod
    async def analyze_content(self, content: str, prompt_template: str) -> AnalysisResult:
        """分析內容的抽象方法"""
        pass
    
    @abstractmethod
    async def health_check(self) -> bool:
        """健康檢查的抽象方法"""
        pass
    
    async def get_status(self) -> ProviderStatus:
        """獲取供應商狀態"""
        if self.last_health_check is None:
            await self.health_check()
        return self.status
    
    def update_metrics(self, tokens_used: int, cost: float, success: bool):
        """更新使用指標"""
        self.request_count += 1
        if success:
            self.success_count += 1
            self.total_tokens_used += tokens_used
            self.total_cost += cost
    
    def get_success_rate(self) -> float:
        """獲取成功率"""
        if self.request_count == 0:
            return 0.0
        return self.success_count / self.request_count

class XinferenceQwenProvider(LLMProvider):
    """Xinference Qwen3 本機服務主力供應商"""
    
    def __init__(self, config: ProviderConfig):
        super().__init__(config)
        self.api_url = "http://localhost:9997/v1/chat/completions"
        self.models_url = "http://localhost:9997/v1/models"
        self.headers = {
            "Content-Type": "application/json"
        }
        self._cached_model_uid = None
    
    async def analyze_content(self, content: str, prompt_template: str) -> AnalysisResult:
        """使用Xinference Qwen3分析內容"""
        start_time = time.time()
        
        try:
            # 獲取真實的模型 UID
            model_uid = await self._resolve_model_uid()
            if not model_uid:
                model_uid = self.config.model_name  # 回退到配置的名稱
                
            prompt = prompt_template.format(content=content)
            
            payload = {
                "model": model_uid,
                "max_tokens": self.config.max_tokens,
                "temperature": self.config.temperature,
                "messages": [
                    {"role": "user", "content": prompt}
                ]
            }
            
            async with aiohttp.ClientSession() as session:
                async with session.post(
                    self.api_url,
                    headers=self.headers,
                    json=payload,
                    timeout=aiohttp.ClientTimeout(total=self.config.timeout)
                ) as response:
                    
                    if response.status == 200:
                        result = await response.json()
                        # 處理Qwen3的特殊回應格式
                        message = result["choices"][0]["message"]
                        response_content = message.get("content", "")
                        if not response_content and "reasoning_content" in message:
                            # 如果content為空，使用reasoning_content
                            response_content = message["reasoning_content"]
                        
                        tokens_used = result["usage"]["total_tokens"]
                        cost = 0.0  # 本機服務免費
                        response_time = time.time() - start_time
                        
                        self.update_metrics(tokens_used, cost, True)
                        self.status = ProviderStatus.HEALTHY
                        
                        return AnalysisResult(
                            content=response_content,
                            provider_used=self.config.name,
                            tokens_used=tokens_used,
                            cost=cost,
                            response_time=response_time,
                            success=True
                        )
                    else:
                        error_msg = f"Xinference API錯誤: {response.status}"
                        logger.error(error_msg)
                        self.status = ProviderStatus.UNHEALTHY
                        
                        return AnalysisResult(
                            content="",
                            provider_used=self.config.name,
                            tokens_used=0,
                            cost=0.0,
                            response_time=time.time() - start_time,
                            success=False,
                            error_message=error_msg
                        )
        
        except Exception as e:
            error_msg = f"Xinference調用異常: {str(e)}"
            logger.error(error_msg)
            logger.error(f"詳細錯誤: {repr(e)}")
            import traceback
            logger.error(f"錯誤堆疊: {traceback.format_exc()}")
            self.status = ProviderStatus.UNHEALTHY
            self.update_metrics(0, 0.0, False)
            
            return AnalysisResult(
                content="",
                provider_used=self.config.name,
                tokens_used=0,
                cost=0.0,
                response_time=time.time() - start_time,
                success=False,
                error_message=error_msg
            )
    
    async def _resolve_model_uid(self) -> Optional[str]:
        """解析真實的模型 UID"""
        if self._cached_model_uid:
            return self._cached_model_uid
            
        try:
            async with aiohttp.ClientSession() as session:
                async with session.get(
                    self.models_url,
                    headers=self.headers,
                    timeout=aiohttp.ClientTimeout(total=10)
                ) as response:
                    
                    if response.status == 200:
                        result = await response.json()
                        models = result.get("data", [])
                        
                        # 尋找匹配的模型，優先選擇更大的模型
                        matching_models = []
                        for model in models:
                            model_id = model.get("id", "")
                            # 精確匹配或包含匹配
                            if (model_id == self.config.model_name or 
                                self.config.model_name in model_id or 
                                model_id.startswith(self.config.model_name)):
                                matching_models.append(model)
                        
                        # 如果有多個匹配，選擇最大的模型
                        if matching_models:
                            # 按模型大小排序（降序）
                            best_model = max(matching_models, 
                                           key=lambda m: m.get("model_size_in_billions", 0))
                            model_id = best_model.get("id", "")
                            model_size = best_model.get("model_size_in_billions", 0)
                            quantization = best_model.get("quantization", "unknown")
                            
                            self._cached_model_uid = model_id
                            logger.info(f"Xinference模型映射: {self.config.model_name} -> {model_id} ({model_size}B, {quantization})")
                            return model_id
                        
                        # 如果沒找到匹配，列出可用模型
                        available_models = [m.get("id", "") for m in models]
                        logger.warning(f"未找到匹配的模型 '{self.config.model_name}'，可用模型: {available_models}")
                        return None
                    else:
                        logger.error(f"獲取模型列表失敗: {response.status}")
                        return None
                        
        except Exception as e:
            logger.error(f"解析模型UID失敗: {e}")
            return None
    
    async def health_check(self) -> bool:
        """Xinference Qwen3健康檢查"""
        try:
            # 獲取真實的模型 UID
            model_uid = await self._resolve_model_uid()
            if not model_uid:
                model_uid = self.config.model_name  # 回退到配置的名稱
                
            test_payload = {
                "model": model_uid,
                "max_tokens": 10,
                "messages": [{"role": "user", "content": "test"}]
            }
            
            async with aiohttp.ClientSession() as session:
                async with session.post(
                    self.api_url,
                    headers=self.headers,
                    json=test_payload,
                    timeout=aiohttp.ClientTimeout(total=10)
                ) as response:
                    
                    if response.status == 200:
                        self.status = ProviderStatus.HEALTHY
                        self.last_health_check = datetime.now()
                        return True
                    else:
                        self.status = ProviderStatus.UNHEALTHY
                        return False
        
        except Exception as e:
            logger.error(f"Xinference健康檢查失敗: {e}")
            self.status = ProviderStatus.UNHEALTHY
            return False

class GPT4oMiniProvider(LLMProvider):
    """GPT-4o mini 備援供應商"""
    
    def __init__(self, config: ProviderConfig):
        super().__init__(config)
        openai.api_key = config.api_key
        self.client = openai.AsyncOpenAI(api_key=config.api_key)
    
    async def analyze_content(self, content: str, prompt_template: str) -> AnalysisResult:
        """使用GPT-4o mini分析內容"""
        start_time = time.time()
        
        try:
            prompt = prompt_template.format(content=content)
            
            response = await self.client.chat.completions.create(
                model=self.config.model_name,
                messages=[{"role": "user", "content": prompt}],
                max_tokens=self.config.max_tokens,
                temperature=self.config.temperature
            )
            
            response_content = response.choices[0].message.content
            tokens_used = response.usage.total_tokens
            cost = tokens_used * self.config.cost_per_token
            response_time = time.time() - start_time
            
            self.update_metrics(tokens_used, cost, True)
            self.status = ProviderStatus.HEALTHY
            
            return AnalysisResult(
                content=response_content,
                provider_used=self.config.name,
                tokens_used=tokens_used,
                cost=cost,
                response_time=response_time,
                success=True
            )
        
        except Exception as e:
            error_msg = f"GPT-4o mini調用異常: {str(e)}"
            logger.error(error_msg)
            self.status = ProviderStatus.UNHEALTHY
            self.update_metrics(0, 0.0, False)
            
            return AnalysisResult(
                content="",
                provider_used=self.config.name,
                tokens_used=0,
                cost=0.0,
                response_time=time.time() - start_time,
                success=False,
                error_message=error_msg
            )
    
    async def health_check(self) -> bool:
        """GPT-4o mini健康檢查"""
        try:
            response = await self.client.chat.completions.create(
                model=self.config.model_name,
                messages=[{"role": "user", "content": "test"}],
                max_tokens=5
            )
            
            if response.choices[0].message.content:
                self.status = ProviderStatus.HEALTHY
                self.last_health_check = datetime.now()
                return True
            else:
                self.status = ProviderStatus.UNHEALTHY
                return False
        
        except Exception as e:
            logger.error(f"GPT-4o mini健康檢查失敗: {e}")
            self.status = ProviderStatus.UNHEALTHY
            return False

class GeminiProProvider(LLMProvider):
    """Gemini Pro 供應商（整合現有MCP）"""
    
    def __init__(self, config: ProviderConfig):
        super().__init__(config)
        genai.configure(api_key=config.api_key)
        self.model = genai.GenerativeModel(config.model_name)
    
    async def analyze_content(self, content: str, prompt_template: str) -> AnalysisResult:
        """使用Gemini Pro分析內容"""
        start_time = time.time()
        
        try:
            prompt = prompt_template.format(content=content)
            
            # Gemini API 是同步的，我們在這裡包裝為異步
            loop = asyncio.get_event_loop()
            response = await loop.run_in_executor(
                None, 
                lambda: self.model.generate_content(
                    prompt,
                    generation_config=genai.types.GenerationConfig(
                        max_output_tokens=self.config.max_tokens,
                        temperature=self.config.temperature
                    )
                )
            )
            
            response_content = response.text
            # Gemini API 不提供token使用量，我們估算
            tokens_used = len(prompt.split()) + len(response_content.split())
            cost = tokens_used * self.config.cost_per_token
            response_time = time.time() - start_time
            
            self.update_metrics(tokens_used, cost, True)
            self.status = ProviderStatus.HEALTHY
            
            return AnalysisResult(
                content=response_content,
                provider_used=self.config.name,
                tokens_used=tokens_used,
                cost=cost,
                response_time=response_time,
                success=True
            )
        
        except Exception as e:
            error_msg = f"Gemini Pro調用異常: {str(e)}"
            logger.error(error_msg)
            self.status = ProviderStatus.UNHEALTHY
            self.update_metrics(0, 0.0, False)
            
            return AnalysisResult(
                content="",
                provider_used=self.config.name,
                tokens_used=0,
                cost=0.0,
                response_time=time.time() - start_time,
                success=False,
                error_message=error_msg
            )
    
    async def health_check(self) -> bool:
        """Gemini Pro健康檢查"""
        try:
            loop = asyncio.get_event_loop()
            response = await loop.run_in_executor(
                None,
                lambda: self.model.generate_content("test")
            )
            
            if response.text:
                self.status = ProviderStatus.HEALTHY
                self.last_health_check = datetime.now()
                return True
            else:
                self.status = ProviderStatus.UNHEALTHY
                return False
        
        except Exception as e:
            logger.error(f"Gemini Pro健康檢查失敗: {e}")
            self.status = ProviderStatus.UNHEALTHY
            return False

class LLMHealthManager:
    """LLM供應商健康檢查與自動切換管理器"""
    
    def __init__(self):
        self.providers: Dict[str, LLMProvider] = {}
        self.priority_order = ["xinference_qwen", "gemini_pro"]
        self.health_check_interval = timedelta(minutes=5)
        self.max_consecutive_failures = 3
        self.consecutive_failures = {}
    
    def register_provider(self, name: str, provider: LLMProvider):
        """註冊LLM供應商"""
        self.providers[name] = provider
        self.consecutive_failures[name] = 0
        logger.info(f"已註冊LLM供應商: {name}")
    
    async def get_healthy_provider(self) -> Optional[LLMProvider]:
        """獲取健康的LLM供應商"""
        for provider_name in self.priority_order:
            if provider_name not in self.providers:
                continue
            
            provider = self.providers[provider_name]
            
            # 檢查是否需要重新進行健康檢查
            if (provider.last_health_check is None or 
                datetime.now() - provider.last_health_check > self.health_check_interval):
                
                is_healthy = await provider.health_check()
                
                if is_healthy:
                    self.consecutive_failures[provider_name] = 0
                    logger.info(f"使用LLM供應商: {provider_name}")
                    return provider
                else:
                    self.consecutive_failures[provider_name] += 1
                    logger.warning(f"LLM供應商 {provider_name} 健康檢查失敗")
            
            elif provider.status == ProviderStatus.HEALTHY:
                logger.info(f"使用LLM供應商: {provider_name}")
                return provider
        
        logger.error("所有LLM供應商都不可用")
        return None
    
    async def analyze_with_fallback(self, content: str, prompt_template: str) -> AnalysisResult:
        """使用回退機制進行分析"""
        last_error = None
        
        for provider_name in self.priority_order:
            if provider_name not in self.providers:
                continue
                
            provider = self.providers[provider_name]
            
            # 跳過連續失敗過多的供應商
            if self.consecutive_failures[provider_name] >= self.max_consecutive_failures:
                continue
            
            try:
                result = await provider.analyze_content(content, prompt_template)
                
                if result.success:
                    self.consecutive_failures[provider_name] = 0
                    return result
                else:
                    self.consecutive_failures[provider_name] += 1
                    last_error = result.error_message
                    
            except Exception as e:
                self.consecutive_failures[provider_name] += 1
                last_error = str(e)
                logger.error(f"供應商 {provider_name} 調用失敗: {e}")
        
        # 所有供應商都失敗了
        return AnalysisResult(
            content="",
            provider_used="none",
            tokens_used=0,
            cost=0.0,
            response_time=0.0,
            success=False,
            error_message=f"所有LLM供應商都失敗了，最後錯誤: {last_error}"
        )
    
    def get_provider_metrics(self) -> Dict[str, Dict]:
        """獲取所有供應商的使用指標"""
        metrics = {}
        
        for name, provider in self.providers.items():
            metrics[name] = {
                "status": provider.status.value,
                "total_tokens_used": provider.total_tokens_used,
                "total_cost": provider.total_cost,
                "request_count": provider.request_count,
                "success_rate": provider.get_success_rate(),
                "consecutive_failures": self.consecutive_failures[name],
                "last_health_check": provider.last_health_check.isoformat() if provider.last_health_check else None
            }
        
        return metrics

# 工廠函數用於創建配置好的LLM供應商
def create_llm_providers() -> LLMHealthManager:
    """創建並配置所有LLM供應商"""
    manager = LLMHealthManager()
    
    # Xinference Qwen3 配置（主力本機服務）
    xinference_config = ProviderConfig(
        name="xinference_qwen",
        api_key="",  # 本機服務不需要API key
        model_name="qwen3",
        max_tokens=4000,
        temperature=0.7,
        cost_per_token=0.0  # 本機服務免費
    )
    
    xinference_provider = XinferenceQwenProvider(xinference_config)
    manager.register_provider("xinference_qwen", xinference_provider)
    
    # Gemini Pro 配置（備援免費API）
    gemini_config = ProviderConfig(
        name="gemini_pro", 
        api_key=os.getenv("GOOGLE_API_KEY", ""),
        model_name="gemini-pro",
        max_tokens=4000,
        temperature=0.7,
        cost_per_token=0.0  # Gemini免費版
    )
    
    if gemini_config.api_key:
        gemini_provider = GeminiProProvider(gemini_config)
        manager.register_provider("gemini_pro", gemini_provider)
    
    return manager

# 測試函數
async def test_llm_providers():
    """測試LLM供應商功能"""
    manager = create_llm_providers()
    
    test_content = "這是一篇測試新聞文章。"
    test_prompt = "請分析以下內容：{content}"
    
    print("測試LLM供應商...")
    
    result = await manager.analyze_with_fallback(test_content, test_prompt)
    
    if result.success:
        print(f"分析成功，使用供應商: {result.provider_used}")
        print(f"回應時間: {result.response_time:.2f}秒")
        print(f"使用Token: {result.tokens_used}")
        print(f"成本: ${result.cost:.6f}")
    else:
        print(f"分析失敗: {result.error_message}")
    
    # 顯示供應商指標
    metrics = manager.get_provider_metrics()
    print("\n供應商指標:")
    for name, metric in metrics.items():
        print(f"{name}: {metric}")

if __name__ == "__main__":
    asyncio.run(test_llm_providers())