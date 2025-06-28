#!/usr/bin/env python3
"""
Gemini MCP Server

A Model Context Protocol (MCP) server that provides access to Google Gemini AI capabilities.
This server allows MCP clients (like Claude Code) to use Gemini's AI features through 
standardized MCP protocol.

Core Features:
- gemini_chat: Basic conversation functionality
- gemini_generate: Text generation and completion
- gemini_analyze_code: Code analysis and review
- gemini_vision: Image analysis (if supported)

Authentication:
- GOOGLE_API_KEY: For Google AI Studio API access
- Or use Google Cloud credentials for Vertex AI access
"""

import asyncio
import json
import logging
import os
import sys
from typing import Any, Dict, List, Optional, Union

import google.generativeai as genai
from mcp.server import Server
from mcp.types import (
    CallToolResult,
    ListToolsResult,
    Tool,
    TextContent,
    ImageContent,
    EmbeddedResource,
)
from pydantic import BaseModel

# 配置日誌
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger("gemini-mcp-server")

class GeminiMCPServer:
    """Gemini MCP Server implementation"""
    
    def __init__(self):
        self.server = Server("gemini-mcp-server")
        self.model = None
        self._setup_authentication()
        self._register_tools()
    
    def _setup_authentication(self):
        """設置 Google Gemini API 認證"""
        api_key = os.getenv("GOOGLE_API_KEY")
        use_vertex_ai = os.getenv("GOOGLE_GENAI_USE_VERTEXAI", "false").lower() == "true"
        
        if use_vertex_ai:
            # 使用 Vertex AI
            project_id = os.getenv("GOOGLE_CLOUD_PROJECT")
            location = os.getenv("GOOGLE_CLOUD_LOCATION", "us-central1")
            
            if not project_id:
                raise ValueError("GOOGLE_CLOUD_PROJECT is required for Vertex AI")
            
            logger.info(f"Using Vertex AI with project: {project_id}, location: {location}")
            # Vertex AI 配置需要額外設置
            
        elif api_key:
            # 使用 Google AI Studio API
            genai.configure(api_key=api_key)
            logger.info("Using Google AI Studio API")
        else:
            raise ValueError("Either GOOGLE_API_KEY or Vertex AI credentials are required")
        
        # 初始化模型
        model_name = os.getenv("GEMINI_MODEL", "gemini-1.5-flash")
        try:
            self.model = genai.GenerativeModel(model_name)
            logger.info(f"Initialized model: {model_name}")
        except Exception as e:
            logger.error(f"Failed to initialize model {model_name}: {e}")
            raise
    
    def _register_tools(self):
        """註冊 MCP 工具"""
        
        @self.server.list_tools()
        async def handle_list_tools() -> ListToolsResult:
            """列出所有可用的工具"""
            return ListToolsResult(
                tools=[
                    Tool(
                        name="gemini_chat",
                        description="使用 Gemini 進行基本對話和問答",
                        inputSchema={
                            "type": "object",
                            "properties": {
                                "message": {
                                    "type": "string",
                                    "description": "要發送給 Gemini 的訊息"
                                },
                                "system_instruction": {
                                    "type": "string",
                                    "description": "可選的系統指令，用於指導 AI 的行為"
                                },
                                "temperature": {
                                    "type": "number",
                                    "description": "創意度控制 (0.0-1.0)，預設 0.7",
                                    "minimum": 0.0,
                                    "maximum": 1.0
                                }
                            },
                            "required": ["message"]
                        }
                    ),
                    Tool(
                        name="gemini_generate",
                        description="使用 Gemini 生成文本內容",
                        inputSchema={
                            "type": "object",
                            "properties": {
                                "prompt": {
                                    "type": "string",
                                    "description": "生成文本的提示詞"
                                },
                                "max_output_tokens": {
                                    "type": "integer",
                                    "description": "最大輸出 token 數量",
                                    "minimum": 1,
                                    "maximum": 8192
                                },
                                "temperature": {
                                    "type": "number",
                                    "description": "創意度控制 (0.0-1.0)",
                                    "minimum": 0.0,
                                    "maximum": 1.0
                                }
                            },
                            "required": ["prompt"]
                        }
                    ),
                    Tool(
                        name="gemini_analyze_code",
                        description="使用 Gemini 分析程式碼，提供改進建議",
                        inputSchema={
                            "type": "object",
                            "properties": {
                                "code": {
                                    "type": "string",
                                    "description": "要分析的程式碼"
                                },
                                "language": {
                                    "type": "string",
                                    "description": "程式語言 (python, javascript, typescript, etc.)"
                                },
                                "analysis_type": {
                                    "type": "string",
                                    "description": "分析類型: review, optimize, debug, explain",
                                    "enum": ["review", "optimize", "debug", "explain"]
                                }
                            },
                            "required": ["code"]
                        }
                    ),
                    Tool(
                        name="gemini_vision",
                        description="使用 Gemini 分析圖像內容",
                        inputSchema={
                            "type": "object",
                            "properties": {
                                "image_path": {
                                    "type": "string",
                                    "description": "圖像檔案路徑"
                                },
                                "question": {
                                    "type": "string",
                                    "description": "關於圖像的問題或分析要求"
                                }
                            },
                            "required": ["image_path"]
                        }
                    )
                ]
            )
        
        @self.server.call_tool()
        async def handle_call_tool(name: str, arguments: Dict[str, Any]) -> CallToolResult:
            """執行指定的工具"""
            try:
                if name == "gemini_chat":
                    return await self._chat(arguments)
                elif name == "gemini_generate":
                    return await self._generate(arguments)
                elif name == "gemini_analyze_code":
                    return await self._analyze_code(arguments)
                elif name == "gemini_vision":
                    return await self._vision_analysis(arguments)
                else:
                    raise ValueError(f"Unknown tool: {name}")
            
            except Exception as e:
                logger.error(f"Error calling tool {name}: {e}")
                return CallToolResult(
                    content=[
                        TextContent(
                            type="text",
                            text=f"Error: {str(e)}"
                        )
                    ]
                )
    
    async def _chat(self, arguments: Dict[str, Any]) -> CallToolResult:
        """基本對話功能"""
        message = arguments["message"]
        system_instruction = arguments.get("system_instruction")
        temperature = arguments.get("temperature", 0.7)
        
        try:
            # 設置生成配置
            generation_config = genai.types.GenerationConfig(
                temperature=temperature
            )
            
            # 如果有系統指令，建立新的模型實例
            if system_instruction:
                model = genai.GenerativeModel(
                    model_name=self.model.model_name,
                    generation_config=generation_config,
                    system_instruction=system_instruction
                )
            else:
                model = genai.GenerativeModel(
                    model_name=self.model.model_name,
                    generation_config=generation_config
                )
            
            response = await model.generate_content_async(message)
            
            return CallToolResult(
                content=[
                    TextContent(
                        type="text",
                        text=response.text
                    )
                ]
            )
        
        except Exception as e:
            logger.error(f"Chat error: {e}")
            raise
    
    async def _generate(self, arguments: Dict[str, Any]) -> CallToolResult:
        """文本生成功能"""
        prompt = arguments["prompt"]
        max_tokens = arguments.get("max_output_tokens", 2048)
        temperature = arguments.get("temperature", 0.7)
        
        try:
            generation_config = genai.types.GenerationConfig(
                max_output_tokens=max_tokens,
                temperature=temperature
            )
            
            model = genai.GenerativeModel(
                model_name=self.model.model_name,
                generation_config=generation_config
            )
            
            response = await model.generate_content_async(prompt)
            
            return CallToolResult(
                content=[
                    TextContent(
                        type="text",
                        text=response.text
                    )
                ]
            )
        
        except Exception as e:
            logger.error(f"Generation error: {e}")
            raise
    
    async def _analyze_code(self, arguments: Dict[str, Any]) -> CallToolResult:
        """程式碼分析功能"""
        code = arguments["code"]
        language = arguments.get("language", "未指定")
        analysis_type = arguments.get("analysis_type", "review")
        
        # 建立分析提示詞
        analysis_prompts = {
            "review": f"請對以下 {language} 程式碼進行代碼審查，指出潛在問題、改進建議和最佳實踐：",
            "optimize": f"請分析以下 {language} 程式碼的性能，提供優化建議：",
            "debug": f"請幫助調試以下 {language} 程式碼，找出可能的錯誤和問題：",
            "explain": f"請解釋以下 {language} 程式碼的功能和邏輯："
        }
        
        prompt = f"{analysis_prompts.get(analysis_type, analysis_prompts['review'])}\n\n```{language}\n{code}\n```"
        
        try:
            response = await self.model.generate_content_async(prompt)
            
            return CallToolResult(
                content=[
                    TextContent(
                        type="text",
                        text=response.text
                    )
                ]
            )
        
        except Exception as e:
            logger.error(f"Code analysis error: {e}")
            raise
    
    async def _vision_analysis(self, arguments: Dict[str, Any]) -> CallToolResult:
        """圖像分析功能"""
        image_path = arguments["image_path"]
        question = arguments.get("question", "請描述這張圖片的內容")
        
        try:
            # 檢查圖片檔案是否存在
            if not os.path.exists(image_path):
                raise FileNotFoundError(f"Image file not found: {image_path}")
            
            # 讀取圖片
            import PIL.Image
            image = PIL.Image.open(image_path)
            
            response = await self.model.generate_content_async([question, image])
            
            return CallToolResult(
                content=[
                    TextContent(
                        type="text",
                        text=response.text
                    )
                ]
            )
        
        except Exception as e:
            logger.error(f"Vision analysis error: {e}")
            raise

    async def run(self):
        """運行 MCP 伺服器"""
        logger.info("Starting Gemini MCP Server...")
        
        # 使用 stdio 傳輸
        from mcp.server.stdio import stdio_server
        
        async with stdio_server() as (read_stream, write_stream):
            await self.server.run(
                read_stream,
                write_stream,
                self.server.create_initialization_options()
            )

def main():
    """主函數"""
    try:
        server = GeminiMCPServer()
        asyncio.run(server.run())
    except KeyboardInterrupt:
        logger.info("Server stopped by user")
    except Exception as e:
        logger.error(f"Server error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()