#!/usr/bin/env python3
"""
測試Xinference Qwen3連接
"""

import asyncio
import aiohttp
import json

async def test_xinference_connection():
    """測試Xinference連接"""
    
    api_url = "http://localhost:9997/v1/chat/completions"
    
    payload = {
        "model": "qwen3",
        "max_tokens": 100,
        "temperature": 0.7,
        "messages": [
            {"role": "user", "content": "你好，請簡單介紹一下你自己"}
        ]
    }
    
    headers = {
        "Content-Type": "application/json"
    }
    
    try:
        async with aiohttp.ClientSession() as session:
            async with session.post(
                api_url,
                headers=headers,
                json=payload,
                timeout=aiohttp.ClientTimeout(total=30)
            ) as response:
                
                print(f"Status: {response.status}")
                result = await response.json()
                print(f"Response: {json.dumps(result, ensure_ascii=False, indent=2)}")
                
                if response.status == 200:
                    content = result["choices"][0]["message"]["content"]
                    print(f"\n✅ Xinference Qwen3 回應: {content}")
                    return True
                else:
                    print(f"❌ API錯誤: {response.status}")
                    return False
    
    except Exception as e:
        print(f"❌ 連接失敗: {e}")
        return False

if __name__ == "__main__":
    print("🧪 測試Xinference Qwen3連接...")
    result = asyncio.run(test_xinference_connection())
    print(f"測試結果: {'成功' if result else '失敗'}")