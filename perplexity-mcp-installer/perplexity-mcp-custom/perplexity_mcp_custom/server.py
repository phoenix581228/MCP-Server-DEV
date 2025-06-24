#!/usr/bin/env python3
"""
Perplexity Custom MCP Server for Claude Code CLI
支援 MCP 協議的 stdio 通訊
"""

import os
import sys
import json
import logging
from typing import Dict, Any, Optional, List
import requests
from dotenv import load_dotenv

# 載入環境變數
load_dotenv(override=True)

# 設定日誌
logging.basicConfig(
    level=logging.DEBUG if os.getenv("DEBUG") else logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[logging.FileHandler('/tmp/perplexity-mcp.log')]
)
logger = logging.getLogger(__name__)


class PerplexityMCPServer:
    """Perplexity MCP Server 實現"""
    
    def __init__(self):
        self.api_key = os.getenv("PERPLEXITY_API_KEY")
        self.model = os.getenv("PERPLEXITY_MODEL", "sonar-pro")
        self.base_url = "https://api.perplexity.ai"
        self.session_id = None
        
        if not self.api_key:
            logger.error("PERPLEXITY_API_KEY 環境變數未設定")
            raise ValueError("PERPLEXITY_API_KEY environment variable is required")
    
    def handle_request(self, request: Dict[str, Any]) -> Dict[str, Any]:
        """處理 JSON-RPC 請求"""
        method = request.get("method", "")
        request_id = request.get("id")
        
        logger.debug(f"收到請求: {method}")
        
        # 路由到對應的處理方法
        handlers = {
            "initialize": self._handle_initialize,
            "initialized": self._handle_initialized,
            "tools/list": self._handle_tools_list,
            "tools/call": self._handle_tools_call,
        }
        
        handler = handlers.get(method)
        if handler:
            try:
                result = handler(request)
                if request_id is not None:
                    return {
                        "jsonrpc": "2.0",
                        "id": request_id,
                        "result": result
                    }
                return None  # 通知不需要回應
            except Exception as e:
                logger.error(f"處理請求時發生錯誤: {e}")
                if request_id is not None:
                    return {
                        "jsonrpc": "2.0",
                        "id": request_id,
                        "error": {
                            "code": -32603,
                            "message": str(e)
                        }
                    }
                return None
        else:
            logger.warning(f"未知的方法: {method}")
            if request_id is not None:
                return {
                    "jsonrpc": "2.0",
                    "id": request_id,
                    "error": {
                        "code": -32601,
                        "message": f"Method not found: {method}"
                    }
                }
            return None
    
    def _handle_initialize(self, request: Dict[str, Any]) -> Dict[str, Any]:
        """處理初始化請求"""
        params = request.get("params", {})
        protocol_version = params.get("protocolVersion", "2024-11-05")
        
        logger.info(f"初始化 MCP Server, 協議版本: {protocol_version}")
        
        return {
            "protocolVersion": protocol_version,
            "capabilities": {
                "tools": {
                    "listChanged": False
                },
                "logging": {}
            },
            "serverInfo": {
                "name": "perplexity-mcp-custom",
                "version": "2.0.0"
            }
        }
    
    def _handle_initialized(self, request: Dict[str, Any]) -> None:
        """處理初始化完成通知"""
        logger.info("MCP Server 初始化完成")
        return None
    
    def _handle_tools_list(self, request: Dict[str, Any]) -> Dict[str, Any]:
        """列出可用工具"""
        tools = [
            {
                "name": "perplexity_search_web",
                "description": "使用 Perplexity AI 搜尋網路以獲取最新資訊",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "query": {
                            "type": "string",
                            "description": "搜尋查詢字串",
                            "minLength": 1,
                            "maxLength": 1000
                        },
                        "model": {
                            "type": "string",
                            "description": "Perplexity 模型選擇",
                            "enum": ["sonar", "sonar-pro", "sonar-deep-research"],
                            "default": self.model
                        },
                        "options": {
                            "type": "object",
                            "properties": {
                                "return_citations": {
                                    "type": "boolean",
                                    "description": "是否返回引用來源",
                                    "default": True
                                },
                                "return_images": {
                                    "type": "boolean",
                                    "description": "是否返回圖片",
                                    "default": False
                                },
                                "return_related_questions": {
                                    "type": "boolean",
                                    "description": "是否返回相關問題",
                                    "default": False
                                },
                                "search_domain": {
                                    "type": "string",
                                    "description": "限定搜尋的網域"
                                },
                                "search_recency": {
                                    "type": "string",
                                    "description": "搜尋時間範圍",
                                    "enum": ["day", "week", "month", "year"]
                                }
                            },
                            "additionalProperties": False
                        }
                    },
                    "required": ["query"],
                    "additionalProperties": False
                }
            },
            {
                "name": "perplexity_pro_search",
                "description": "使用 Perplexity Pro 模型進行進階搜尋，具有增強功能",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "query": {
                            "type": "string",
                            "description": "搜尋查詢字串",
                            "minLength": 1,
                            "maxLength": 1000
                        },
                        "model": {
                            "type": "string",
                            "description": "Pro 模型選擇",
                            "enum": ["sonar-pro", "sonar-reasoning-pro"],
                            "default": "sonar-pro"
                        },
                        "options": {
                            "type": "object",
                            "properties": {
                                "return_citations": {
                                    "type": "boolean",
                                    "default": True
                                },
                                "return_images": {
                                    "type": "boolean",
                                    "default": True
                                },
                                "return_related_questions": {
                                    "type": "boolean",
                                    "default": True
                                },
                                "search_domain": {
                                    "type": "string"
                                },
                                "search_recency": {
                                    "type": "string",
                                    "enum": ["day", "week", "month", "year"]
                                }
                            },
                            "additionalProperties": False
                        }
                    },
                    "required": ["query"],
                    "additionalProperties": False
                }
            },
            {
                "name": "perplexity_deep_research",
                "description": "使用 Perplexity AI 對主題進行深度研究",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "topic": {
                            "type": "string",
                            "description": "研究主題",
                            "minLength": 1,
                            "maxLength": 500
                        },
                        "depth": {
                            "type": "string",
                            "description": "研究深度",
                            "enum": ["quick", "standard", "comprehensive"],
                            "default": "standard"
                        },
                        "focus_areas": {
                            "type": "array",
                            "description": "重點研究領域",
                            "items": {
                                "type": "string"
                            }
                        }
                    },
                    "required": ["topic"],
                    "additionalProperties": False
                }
            },
            {
                "name": "perplexity_reasoning",
                "description": "使用 Perplexity 推理模型進行複雜推理和逐步分析",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "query": {
                            "type": "string",
                            "description": "推理查詢字串",
                            "minLength": 1,
                            "maxLength": 1000
                        },
                        "model": {
                            "type": "string",
                            "description": "推理模型選擇",
                            "enum": ["sonar-reasoning", "sonar-reasoning-pro"],
                            "default": "sonar-reasoning"
                        },
                        "context": {
                            "type": "string",
                            "description": "額外的上下文資訊"
                        }
                    },
                    "required": ["query"],
                    "additionalProperties": False
                }
            }
        ]
        
        return {"tools": tools}
    
    def _handle_tools_call(self, request: Dict[str, Any]) -> Dict[str, Any]:
        """執行工具調用"""
        params = request.get("params", {})
        tool_name = params.get("name", "")
        arguments = params.get("arguments", {})
        
        logger.info(f"執行工具: {tool_name}")
        
        # 路由到對應的工具處理方法
        tool_handlers = {
            "perplexity_search_web": self._search_web,
            "perplexity_pro_search": self._pro_search,
            "perplexity_deep_research": self._deep_research,
            "perplexity_reasoning": self._reasoning,
        }
        
        handler = tool_handlers.get(tool_name)
        if handler:
            try:
                result = handler(arguments)
                return {
                    "content": [
                        {
                            "type": "text",
                            "text": result
                        }
                    ]
                }
            except Exception as e:
                logger.error(f"工具執行失敗: {e}")
                return {
                    "content": [
                        {
                            "type": "text",
                            "text": f"錯誤: {str(e)}"
                        }
                    ],
                    "isError": True
                }
        else:
            return {
                "content": [
                    {
                        "type": "text",
                        "text": f"未知的工具: {tool_name}"
                    }
                ],
                "isError": True
            }
    
    def _search_web(self, arguments: Dict[str, Any]) -> str:
        """執行網路搜尋"""
        query = arguments.get("query", "")
        model = arguments.get("model", self.model)
        options = arguments.get("options", {})
        
        # 構建請求
        payload = {
            "model": model,
            "messages": [
                {
                    "role": "user",
                    "content": query
                }
            ],
            "return_citations": options.get("return_citations", True),
            "return_images": options.get("return_images", False),
            "return_related_questions": options.get("return_related_questions", False),
        }
        
        # 添加可選參數
        if "search_domain" in options:
            payload["search_domain"] = options["search_domain"]
        if "search_recency" in options:
            payload["search_recency"] = options["search_recency"]
        
        # 發送請求
        response = self._make_api_request("/chat/completions", payload)
        
        # 格式化回應
        return self._format_response(response, include_citations=options.get("return_citations", True))
    
    def _pro_search(self, arguments: Dict[str, Any]) -> str:
        """執行專業搜尋"""
        # Pro 搜尋使用相同的 API，但預設開啟更多功能
        arguments["options"] = arguments.get("options", {})
        arguments["options"]["return_citations"] = True
        arguments["options"]["return_images"] = True
        arguments["options"]["return_related_questions"] = True
        arguments["model"] = arguments.get("model", "sonar-pro")
        
        return self._search_web(arguments)
    
    def _deep_research(self, arguments: Dict[str, Any]) -> str:
        """執行深度研究"""
        topic = arguments.get("topic", "")
        depth = arguments.get("depth", "standard")
        focus_areas = arguments.get("focus_areas", [])
        
        # 構建深度研究提示
        prompt = f"請對以下主題進行{depth}深度的研究分析：\n\n主題：{topic}"
        
        if focus_areas:
            prompt += f"\n\n重點關注領域：\n" + "\n".join(f"- {area}" for area in focus_areas)
        
        # 使用深度研究模型
        payload = {
            "model": "sonar-deep-research",
            "messages": [
                {
                    "role": "user",
                    "content": prompt
                }
            ],
            "return_citations": True,
            "return_images": True,
        }
        
        response = self._make_api_request("/chat/completions", payload)
        return self._format_response(response, include_citations=True)
    
    def _reasoning(self, arguments: Dict[str, Any]) -> str:
        """執行推理分析"""
        query = arguments.get("query", "")
        model = arguments.get("model", "sonar-reasoning")
        context = arguments.get("context", "")
        
        # 構建推理請求
        messages = []
        if context:
            messages.append({
                "role": "system",
                "content": f"請基於以下上下文進行推理分析：\n{context}"
            })
        
        messages.append({
            "role": "user",
            "content": query
        })
        
        payload = {
            "model": model,
            "messages": messages,
            "return_citations": True,
        }
        
        response = self._make_api_request("/chat/completions", payload)
        return self._format_response(response, include_citations=True)
    
    def _make_api_request(self, endpoint: str, payload: Dict[str, Any]) -> Dict[str, Any]:
        """發送 API 請求到 Perplexity"""
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }
        
        url = f"{self.base_url}{endpoint}"
        
        try:
            response = requests.post(url, json=payload, headers=headers, timeout=60)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            logger.error(f"API 請求失敗: {e}")
            raise Exception(f"Perplexity API 請求失敗: {str(e)}")
    
    def _format_response(self, response: Dict[str, Any], include_citations: bool = True) -> str:
        """格式化 API 回應"""
        try:
            # 提取主要內容
            content = response.get("choices", [{}])[0].get("message", {}).get("content", "")
            
            # 添加引用資訊
            if include_citations and response.get("citations"):
                content += "\n\n## 參考來源\n"
                for i, citation in enumerate(response["citations"], 1):
                    content += f"{i}. [{citation.get('title', 'Unknown')}]({citation.get('url', '#')})\n"
            
            # 添加相關問題
            if response.get("related_questions"):
                content += "\n\n## 相關問題\n"
                for question in response["related_questions"]:
                    content += f"- {question}\n"
            
            return content
        except Exception as e:
            logger.error(f"格式化回應失敗: {e}")
            return json.dumps(response, ensure_ascii=False, indent=2)
    
    def run(self):
        """運行 MCP Server"""
        logger.info("Perplexity MCP Server 啟動中...")
        
        # 從 stdin 讀取請求，寫入回應到 stdout
        for line in sys.stdin:
            try:
                request = json.loads(line.strip())
                response = self.handle_request(request)
                
                if response:
                    print(json.dumps(response, ensure_ascii=False))
                    sys.stdout.flush()
                    
            except json.JSONDecodeError as e:
                logger.error(f"解析 JSON 失敗: {e}")
            except Exception as e:
                logger.error(f"處理請求時發生錯誤: {e}")


def main():
    """主入口點"""
    try:
        server = PerplexityMCPServer()
        server.run()
    except KeyboardInterrupt:
        logger.info("Server 被使用者中斷")
    except Exception as e:
        logger.error(f"Server 發生錯誤: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()