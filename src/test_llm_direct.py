#!/usr/bin/env python3
"""
直接測試LLM調用
"""

import asyncio
import sys
from pathlib import Path

# 確保可以導入模組
sys.path.insert(0, str(Path(__file__).parent))

from llm_providers import create_llm_providers
from prompt_templates import create_prompt_manager, ArticleType

async def test_direct_llm_call():
    """直接測試LLM調用"""
    
    # 測試文章
    test_content = """
發展科技應用能力　市公所攜手花蓮社大點燃無人機學習熱潮

隨著科技進步與應用場域擴展，無人機已從軍事科技走入民間生活。為推廣無人機知識與應用實務，花蓮市公所、花蓮縣社區大學與台灣國際無人機競技發展協會花蓮分會於28日上午，在化仁國中聯合舉辦「無人機時代來了」技術講座，競技遙控模型直升機世界冠軍林佐翰也現場展演穿越機及無人直升機飛行控制技巧。

林佐翰表示，2016年參加亞拓盃榮獲直升機組第一名，獲廠商青睞簽約成為試飛員。他期望更多年輕人投入，相信台灣飛手實力堅強。

市長魏嘉彥指出，花蓮市公所全力支持科技教育發展，希望透過這樣的活動讓更多民眾了解無人機的實用性。
"""
    
    print("🧪 直接測試LLM調用...")
    
    # 創建管理器
    llm_manager = create_llm_providers()
    prompt_manager = create_prompt_manager()
    
    # 生成提示詞
    article_type = ArticleType.TECHNOLOGY
    prompt = prompt_manager.get_semantic_analysis_prompt(test_content, article_type)
    
    print(f"📝 生成的提示詞長度: {len(prompt)} 字符")
    print(f"🎯 提示詞前100字符: {prompt[:100]}...")
    
    # 直接調用LLM
    print("\n🚀 呼叫LLM...")
    result = await llm_manager.analyze_with_fallback(prompt, "{content}")
    
    print(f"\n📊 調用結果:")
    print(f"  成功: {result.success}")
    print(f"  供應商: {result.provider_used}")
    print(f"  Token數: {result.tokens_used}")
    print(f"  成本: ${result.cost:.6f}")
    print(f"  響應時間: {result.response_time:.2f}秒")
    
    if result.success:
        print(f"  回應長度: {len(result.content)} 字符")
        print(f"  回應前200字符: {result.content[:200]}...")
    else:
        print(f"  錯誤: {result.error_message}")
    
    # 顯示供應商指標
    metrics = llm_manager.get_provider_metrics()
    print(f"\n📈 供應商指標:")
    for name, metric in metrics.items():
        print(f"  {name}: {metric}")

if __name__ == "__main__":
    asyncio.run(test_direct_llm_call())