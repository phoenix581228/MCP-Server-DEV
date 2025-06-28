#!/usr/bin/env python3
"""
Gemini MCP Server v2

A Model Context Protocol (MCP) server that provides access to Google Gemini AI capabilities.
"""

import asyncio
import json
import logging
import os
import sys
from typing import Any, Dict, List, Optional, Union

import google.generativeai as genai
from mcp.server.models import InitializationOptions
import mcp.types as types
from mcp.server import NotificationOptions, Server
import mcp.server.stdio

# 配置日誌
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger("gemini-mcp-server")

# 建立伺服器實例
server = Server("gemini-mcp-server")

# 全域模型變數
model = None

def setup_authentication():
    """設置 Google Gemini API 認證"""
    global model
    
    api_key = os.getenv("GOOGLE_API_KEY")
    use_vertex_ai = os.getenv("GOOGLE_GENAI_USE_VERTEXAI", "false").lower() == "true"
    
    if use_vertex_ai:
        # 使用 Vertex AI
        project_id = os.getenv("GOOGLE_CLOUD_PROJECT")
        location = os.getenv("GOOGLE_CLOUD_LOCATION", "us-central1")
        
        if not project_id:
            raise ValueError("GOOGLE_CLOUD_PROJECT is required for Vertex AI")
        
        logger.info(f"Using Vertex AI with project: {project_id}, location: {location}")
        
    elif api_key:
        # 使用 Google AI Studio API
        genai.configure(api_key=api_key)
        logger.info("Using Google AI Studio API")
    else:
        raise ValueError("Either GOOGLE_API_KEY or Vertex AI credentials are required")
    
    # 初始化模型
    model_name = os.getenv("GEMINI_MODEL", "gemini-1.5-flash")
    try:
        model = genai.GenerativeModel(model_name)
        logger.info(f"Initialized model: {model_name}")
    except Exception as e:
        logger.error(f"Failed to initialize model {model_name}: {e}")
        raise

@server.list_tools()
async def handle_list_tools() -> list[types.Tool]:
    """列出所有可用的工具"""
    return [
        types.Tool(
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
        types.Tool(
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
        types.Tool(
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
        types.Tool(
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
        ),
        types.Tool(
            name="gemini_video_analysis",
            description="使用 Gemini 分析影片內容，支援自動優化",
            inputSchema={
                "type": "object",
                "properties": {
                    "video_path": {
                        "type": "string",
                        "description": "影片檔案路徑 (支援格式: mp4, mov, avi, mkv, webm)"
                    },
                    "question": {
                        "type": "string",
                        "description": "關於影片的問題或分析要求"
                    },
                    "analysis_type": {
                        "type": "string",
                        "description": "分析類型: summary (摘要), action (動作分析), object (物體識別), text (文字識別)",
                        "enum": ["summary", "action", "object", "text"]
                    },
                    "auto_optimize": {
                        "type": "boolean",
                        "description": "是否自動優化影片格式 (預設: true)",
                        "default": True
                    },
                    "target_resolution": {
                        "type": "string",
                        "description": "目標解析度: high (720p), standard (480p), low (360p)",
                        "enum": ["high", "standard", "low"]
                    }
                },
                "required": ["video_path"]
            }
        ),
        types.Tool(
            name="gemini_video_optimizer",
            description="分析並優化影片檔案以符合 Gemini 模型需求",
            inputSchema={
                "type": "object",
                "properties": {
                    "video_path": {
                        "type": "string", 
                        "description": "影片檔案路徑"
                    },
                    "target_model": {
                        "type": "string",
                        "description": "目標 Gemini 模型",
                        "enum": ["gemini-2.0-flash-001", "gemini-2.5-flash", "gemini-2.5-pro", "gemini-1.5-pro", "gemini-1.5-flash"]
                    },
                    "analyze_only": {
                        "type": "boolean",
                        "description": "僅分析不處理 (預設: false)",
                        "default": False
                    }
                },
                "required": ["video_path"]
            }
        )
    ]

@server.call_tool()
async def handle_call_tool(name: str, arguments: dict) -> list[types.TextContent]:
    """執行指定的工具"""
    try:
        if name == "gemini_chat":
            return await chat_tool(arguments)
        elif name == "gemini_generate":
            return await generate_tool(arguments)
        elif name == "gemini_analyze_code":
            return await analyze_code_tool(arguments)
        elif name == "gemini_vision":
            return await vision_tool(arguments)
        elif name == "gemini_video_analysis":
            return await video_analysis_tool(arguments)
        elif name == "gemini_video_optimizer":
            return await video_optimizer_tool(arguments)
        else:
            raise ValueError(f"Unknown tool: {name}")
    
    except Exception as e:
        logger.error(f"Error calling tool {name}: {e}")
        return [
            types.TextContent(
                type="text",
                text=f"Error: {str(e)}"
            )
        ]

async def chat_tool(arguments: dict) -> list[types.TextContent]:
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
            chat_model = genai.GenerativeModel(
                model_name=model.model_name,
                generation_config=generation_config,
                system_instruction=system_instruction
            )
        else:
            chat_model = genai.GenerativeModel(
                model_name=model.model_name,
                generation_config=generation_config
            )
        
        response = await chat_model.generate_content_async(message)
        
        return [
            types.TextContent(
                type="text",
                text=response.text
            )
        ]
    
    except Exception as e:
        logger.error(f"Chat error: {e}")
        raise

async def generate_tool(arguments: dict) -> list[types.TextContent]:
    """文本生成功能"""
    prompt = arguments["prompt"]
    max_tokens = arguments.get("max_output_tokens", 2048)
    temperature = arguments.get("temperature", 0.7)
    
    try:
        generation_config = genai.types.GenerationConfig(
            max_output_tokens=max_tokens,
            temperature=temperature
        )
        
        gen_model = genai.GenerativeModel(
            model_name=model.model_name,
            generation_config=generation_config
        )
        
        response = await gen_model.generate_content_async(prompt)
        
        return [
            types.TextContent(
                type="text",
                text=response.text
            )
        ]
    
    except Exception as e:
        logger.error(f"Generation error: {e}")
        raise

async def analyze_code_tool(arguments: dict) -> list[types.TextContent]:
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
        response = await model.generate_content_async(prompt)
        
        return [
            types.TextContent(
                type="text",
                text=response.text
            )
        ]
    
    except Exception as e:
        logger.error(f"Code analysis error: {e}")
        raise

async def vision_tool(arguments: dict) -> list[types.TextContent]:
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
        
        response = await model.generate_content_async([question, image])
        
        return [
            types.TextContent(
                type="text",
                text=response.text
            )
        ]
    
    except Exception as e:
        logger.error(f"Vision analysis error: {e}")
        raise

async def video_analysis_tool(arguments: dict) -> list[types.TextContent]:
    """影片分析功能"""
    video_path = arguments["video_path"]
    question = arguments.get("question", "請描述這段影片的內容")
    analysis_type = arguments.get("analysis_type", "summary")
    auto_optimize = arguments.get("auto_optimize", True)
    target_resolution = arguments.get("target_resolution")
    
    # 分析類型對應的提示詞
    analysis_prompts = {
        "summary": "請提供這段影片的詳細摘要，包括主要內容、場景和重要細節：",
        "action": "請分析影片中的動作和活動，描述人物或物體的行為：",
        "object": "請識別並描述影片中出現的物體、人物和場景元素：",
        "text": "請識別影片中出現的任何文字內容："
    }
    
    # 根據分析類型調整問題
    if analysis_type in analysis_prompts:
        enhanced_question = f"{analysis_prompts[analysis_type]} {question}"
    else:
        enhanced_question = question
    
    try:
        # 檢查影片檔案是否存在
        if not os.path.exists(video_path):
            raise FileNotFoundError(f"Video file not found: {video_path}")
        
        # 檢查檔案格式
        supported_formats = ['.mp4', '.mov', '.avi', '.mkv', '.webm']
        file_ext = os.path.splitext(video_path)[1].lower()
        if file_ext not in supported_formats:
            raise ValueError(f"Unsupported video format: {file_ext}. Supported formats: {', '.join(supported_formats)}")
        
        # 自動優化影片（如果啟用）
        final_video_path = video_path
        optimization_info = ""
        
        if auto_optimize:
            try:
                from video_optimizer import VideoOptimizer
                
                current_model = os.getenv("GEMINI_MODEL", "gemini-1.5-flash")
                optimizer = VideoOptimizer(current_model)
                
                # 分析影片
                video_info = optimizer.analyze_video(video_path)
                strategy = optimizer.get_optimization_strategy(video_info)
                
                # 如果指定了目標解析度，覆蓋策略
                if target_resolution:
                    strategy['target_resolution'] = target_resolution
                    strategy['needs_processing'] = True
                
                if strategy['needs_processing']:
                    logger.info("影片需要優化，正在處理...")
                    optimization_result = optimizer.optimize_video(video_path)
                    
                    if optimization_result['success']:
                        final_video_path = optimization_result['optimized_files'][0]
                        optimization_info = f"\n🔧 影片已優化: {optimization_result['message']}"
                        logger.info(f"影片優化完成: {final_video_path}")
                    else:
                        logger.warning(f"影片優化失敗，使用原檔案: {optimization_result['message']}")
                        optimization_info = f"\n⚠️ 優化失敗，使用原檔案: {optimization_result['message']}"
                else:
                    optimization_info = "\n✅ 影片格式已最佳化，無需處理"
                    
            except ImportError:
                logger.warning("VideoOptimizer 未安裝，跳過自動優化")
                optimization_info = "\n⚠️ 自動優化功能未可用"
            except Exception as e:
                logger.warning(f"自動優化失敗: {e}")
                optimization_info = f"\n⚠️ 自動優化失敗: {str(e)}"
        
        # 上傳影片檔案到 Gemini
        logger.info(f"Uploading video file: {final_video_path}")
        video_file = genai.upload_file(final_video_path)
        logger.info(f"Video uploaded successfully. URI: {video_file.uri}")
        
        # 等待檔案處理完成
        import time
        while video_file.state.name == "PROCESSING":
            logger.info("Video processing...")
            time.sleep(2)
            video_file = genai.get_file(video_file.name)
        
        if video_file.state.name == "FAILED":
            raise ValueError(f"Video processing failed: {video_file.state}")
        
        logger.info("Video processing completed, generating analysis...")
        
        # 選擇支援影片分析的模型
        # 優先順序：gemini-2.0-flash-001 > gemini-1.5-pro > gemini-1.5-flash
        video_models = ['gemini-2.0-flash-001', 'gemini-1.5-pro', 'gemini-1.5-flash']
        current_model = os.getenv("GEMINI_MODEL", "gemini-1.5-flash")
        
        # 如果當前模型支援影片分析，使用當前模型，否則使用 gemini-1.5-pro
        if current_model in video_models:
            video_model_name = current_model
        else:
            video_model_name = 'gemini-1.5-pro'
            logger.info(f"Current model {current_model} doesn't support video analysis, using {video_model_name}")
        
        # 建立支援影片分析的模型
        vision_model = genai.GenerativeModel(video_model_name)
        logger.info(f"Using model {video_model_name} for video analysis")
        response = await vision_model.generate_content_async([enhanced_question, video_file])
        
        # 清理上傳的檔案
        try:
            genai.delete_file(video_file.name)
            logger.info("Uploaded video file cleaned up")
        except Exception as cleanup_error:
            logger.warning(f"Failed to cleanup uploaded file: {cleanup_error}")
        
        # 清理優化後的檔案（如果不是原始檔案）
        if final_video_path != video_path and os.path.exists(final_video_path):
            try:
                os.remove(final_video_path)
                logger.info("Optimized video file cleaned up")
            except Exception as cleanup_error:
                logger.warning(f"Failed to cleanup optimized file: {cleanup_error}")
        
        return [
            types.TextContent(
                type="text",
                text=response.text + optimization_info
            )
        ]
    
    except Exception as e:
        logger.error(f"Video analysis error: {e}")
        # 嘗試清理可能的上傳檔案
        try:
            if 'video_file' in locals():
                genai.delete_file(video_file.name)
        except:
            pass
        raise

async def video_optimizer_tool(arguments: dict) -> list[types.TextContent]:
    """影片優化工具"""
    video_path = arguments["video_path"]
    target_model = arguments.get("target_model", os.getenv("GEMINI_MODEL", "gemini-1.5-flash"))
    analyze_only = arguments.get("analyze_only", False)
    
    try:
        from video_optimizer import VideoOptimizer
        
        optimizer = VideoOptimizer(target_model)
        
        if analyze_only:
            # 僅分析模式
            summary = optimizer.get_processing_summary(video_path)
            return [
                types.TextContent(
                    type="text",
                    text=f"📊 影片分析報告\n\n{summary}"
                )
            ]
        else:
            # 完整優化模式
            result = optimizer.optimize_video(video_path)
            
            if result['success']:
                response_text = f"✅ 影片優化完成\n\n"
                response_text += f"📊 原始檔案: {result['original_file']}\n"
                response_text += f"🎯 目標模型: {target_model}\n"
                response_text += f"📈 處理結果: {result['message']}\n\n"
                
                if len(result['optimized_files']) > 1:
                    response_text += f"📁 生成檔案 ({len(result['optimized_files'])} 個):\n"
                    for i, file in enumerate(result['optimized_files'], 1):
                        response_text += f"  {i}. {file}\n"
                else:
                    response_text += f"📁 優化檔案: {result['optimized_files'][0]}\n"
                
                # 添加策略資訊
                strategy = result['strategy']
                response_text += f"\n🎯 優化策略:\n"
                response_text += f"  - 解析度: {strategy['target_resolution']}\n"
                response_text += f"  - 幀率: {strategy['target_fps']} fps\n"
                response_text += f"  - 預估 Token: {strategy['estimated_tokens']:,}\n"
                response_text += f"  - 上傳方式: {strategy['upload_method']}\n"
                
                if strategy['recommendations']:
                    response_text += f"\n💡 建議:\n"
                    for rec in strategy['recommendations']:
                        response_text += f"  - {rec}\n"
                
                return [
                    types.TextContent(
                        type="text",
                        text=response_text
                    )
                ]
            else:
                return [
                    types.TextContent(
                        type="text",
                        text=f"❌ 優化失敗: {result['message']}"
                    )
                ]
                
    except ImportError:
        return [
            types.TextContent(
                type="text",
                text="❌ 影片優化功能未安裝\n請確保已安裝 ffmpeg 和相關依賴"
            )
        ]
    except Exception as e:
        logger.error(f"Video optimization error: {e}")
        return [
            types.TextContent(
                type="text",
                text=f"❌ 優化過程發生錯誤: {str(e)}"
            )
        ]

async def main():
    """主函數"""
    # 設置認證
    setup_authentication()
    
    # 使用 stdio 伺服器
    async with mcp.server.stdio.stdio_server() as (read_stream, write_stream):
        await server.run(
            read_stream,
            write_stream,
            InitializationOptions(
                server_name="gemini-mcp-server",
                server_version="1.0.0",
                capabilities=server.get_capabilities(
                    notification_options=NotificationOptions(),
                    experimental_capabilities={},
                )
            )
        )

if __name__ == "__main__":
    try:
        logger.info("Starting Gemini MCP Server...")
        asyncio.run(main())
    except KeyboardInterrupt:
        logger.info("Server stopped by user")
    except Exception as e:
        logger.error(f"Server error: {e}")
        sys.exit(1)