#!/usr/bin/env python3
"""
深度調試Xinference問題
"""

import asyncio
import sys
from pathlib import Path

# 確保可以導入模組
sys.path.insert(0, str(Path(__file__).parent))

from llm_providers import XinferenceQwenProvider, ProviderConfig

async def debug_xinference():
    """調試Xinference問題"""
    
    print("🔍 深度調試Xinference問題...")
    
    # 創建配置
    config = ProviderConfig(
        name="xinference_qwen",
        api_key="",  # 本機服務不需要API key
        model_name="qwen3",
        max_tokens=100,
        temperature=0.7,
        cost_per_token=0.0  # 本機服務免費
    )
    
    # 創建供應商
    provider = XinferenceQwenProvider(config)
    
    # 測試健康檢查
    print("\n🏥 測試健康檢查...")
    health_result = await provider.health_check()
    print(f"健康檢查結果: {health_result}")
    print(f"供應商狀態: {provider.status}")
    
    # 測試內容分析
    print("\n📊 測試內容分析...")
    test_content = "這是一個測試"
    test_template = "請分析以下內容：{content}"
    
    try:
        result = await provider.analyze_content(test_content, test_template)
        print(f"分析成功: {result.success}")
        print(f"供應商: {result.provider_used}")
        print(f"內容長度: {len(result.content)}")
        print(f"錯誤訊息: {result.error_message}")
        if result.content:
            print(f"內容前100字符: {result.content[:100]}...")
    except Exception as e:
        print(f"❌ 分析過程出錯: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(debug_xinference())