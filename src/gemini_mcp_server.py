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
from datetime import datetime
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
        ),
        types.Tool(
            name="gemini_batch_video_script_analysis",
            description="批量影片場記分析 - 分析資料夾中的所有影片檔案並生成詳細場記報告",
            inputSchema={
                "type": "object",
                "properties": {
                    "folder_path": {
                        "type": "string",
                        "description": "包含影片檔案的資料夾路徑"
                    },
                    "output_filename": {
                        "type": "string",
                        "description": "輸出 JSON 檔案名稱 (預設: video_script_analysis.json)",
                        "default": "video_script_analysis.json"
                    },
                    "analysis_detail": {
                        "type": "string",
                        "description": "分析詳細度: basic (基本), detailed (詳細), comprehensive (全面)",
                        "enum": ["basic", "detailed", "comprehensive"],
                        "default": "detailed"
                    },
                    "include_technical_analysis": {
                        "type": "boolean",
                        "description": "是否包含技術分析 (鏡頭、燈光、音響等)",
                        "default": true
                    },
                    "max_concurrent_videos": {
                        "type": "integer",
                        "description": "同時處理的影片數量 (避免 API 限制)",
                        "minimum": 1,
                        "maximum": 5,
                        "default": 2
                    }
                },
                "required": ["folder_path"]
            }
        ),
        types.Tool(
            name="gemini_smart_preview",
            description="智能內容預覽與識別 - 路徑A：AI自動識別影片內容並建議最佳分析模式",
            inputSchema={
                "type": "object",
                "properties": {
                    "folder_path": {
                        "type": "string",
                        "description": "影片資料夾路徑"
                    },
                    "sample_count": {
                        "type": "integer",
                        "description": "預覽影片數量 (預設: 3)",
                        "minimum": 1,
                        "maximum": 10,
                        "default": 3
                    },
                    "content_types": {
                        "type": "array",
                        "items": {"type": "string"},
                        "description": "期望內容類型 ['drone', 'interview', 'tutorial', 'demo', 'event']",
                        "default": ["drone"]
                    }
                },
                "required": ["folder_path"]
            }
        ),
        types.Tool(
            name="gemini_parallel_analysis",
            description="並行路徑處理器 - 統一路徑A/B/C的智能分析與用戶引導介面",
            inputSchema={
                "type": "object",
                "properties": {
                    "folder_path": {
                        "type": "string",
                        "description": "影片資料夾路徑"
                    },
                    "processing_mode": {
                        "type": "string",
                        "description": "處理模式: auto (路徑A自動), guided (路徑B引導), universal (路徑C通用)",
                        "enum": ["auto", "guided", "universal"],
                        "default": "auto"
                    },
                    "group_size": {
                        "type": "integer",
                        "description": "每組處理的影片數量",
                        "minimum": 1,
                        "maximum": 5,
                        "default": 3
                    },
                    "cost_limit": {
                        "type": "number",
                        "description": "單次處理的成本上限 (USD)",
                        "minimum": 0.1,
                        "maximum": 50.0,
                        "default": 5.0
                    },
                    "interactive_mode": {
                        "type": "boolean",
                        "description": "啟用互動模式 (組間確認)",
                        "default": true
                    }
                },
                "required": ["folder_path"]
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
        elif name == "gemini_batch_video_script_analysis":
            return await batch_video_script_analysis_tool(arguments)
        elif name == "gemini_smart_preview":
            return await smart_preview_tool(arguments)
        elif name == "gemini_parallel_analysis":
            return await parallel_analysis_tool(arguments)
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
        "summary": """請以專業場記師的身份，為這段影片創建詳細的鏡頭分解表 (Shot List)。

按照以下格式分析每個鏡頭：

## 鏡頭分解表 (Shot List)

**格式範例：**
Shot 001 | TC: 00:00:00-00:00:03 | MS | 主角正面中景，桌前閱讀文件，自然光從左側窗戶照入

**必要資訊：**
- **鏡頭編號**: Shot 001, Shot 002... (依序編號)
- **時間碼**: TC: HH:MM:SS-HH:MM:SS (精確到秒)
- **景別代碼**: 
  - ECU (極特寫) - 眼睛、嘴部等細節
  - CU (特寫) - 頭部為主
  - MCU (中特寫) - 胸部以上
  - MS (中景) - 腰部以上
  - MLS (中遠景) - 膝蓋以上
  - LS (遠景) - 全身
  - ELS (極遠景) - 環境為主
- **鏡頭描述**: 主體、動作、視覺元素、光線條件

**分析要求：**
1. 按時間順序分解所有可識別的鏡頭
2. 準確標記每個鏡頭的起始和結束時間
3. 使用標準景別術語
4. 簡潔但完整地描述每個鏡頭的內容""",
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
                
                # 如果指定了目標解析度，建立新的策略
                if target_resolution:
                    from video_optimizer import OptimizationStrategy
                    
                    # 解析度映射
                    resolution_map = {
                        "high": (1280, 720),      # 720p
                        "standard": (854, 480),   # 480p  
                        "low": (640, 360)         # 360p
                    }
                    
                    if target_resolution in resolution_map:
                        target_width, target_height = resolution_map[target_resolution]
                        
                        # 建立新的優化策略
                        strategy = OptimizationStrategy(
                            target_width=target_width,
                            target_height=target_height,
                            target_fps=strategy.target_fps,
                            target_bitrate=strategy.target_bitrate,
                            target_format=strategy.target_format,
                            quality_preset=strategy.quality_preset,
                            max_duration=strategy.max_duration
                        )
                        
                        logger.info(f"🎯 目標解析度設定為: {target_resolution} ({target_width}x{target_height})")
                
                # 判斷是否需要優化處理
                needs_processing = (
                    target_resolution or  # 使用者指定解析度
                    video_info.width > strategy.target_width or  # 解析度過高
                    video_info.height > strategy.target_height or
                    video_info.file_size > 50 * 1024 * 1024  # 檔案大於 50MB
                )
                
                if needs_processing:
                    logger.info("影片需要優化，正在處理...")
                    optimized_video_path = optimizer.optimize_video(video_path, strategy=strategy)
                    
                    if optimized_video_path and os.path.exists(optimized_video_path):
                        final_video_path = optimized_video_path
                        optimization_info = f"\n🔧 影片已優化: {os.path.basename(optimized_video_path)}"
                        logger.info(f"影片優化完成: {final_video_path}")
                    else:
                        logger.warning("影片優化失敗，使用原檔案")
                        optimization_info = f"\n⚠️ 優化失敗，使用原檔案"
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

async def batch_video_script_analysis_tool(arguments: dict) -> list[types.TextContent]:
    """批量影片場記分析工具"""
    import glob
    import datetime
    from pathlib import Path
    
    try:
        folder_path = arguments["folder_path"]
        output_filename = arguments.get("output_filename", "video_script_analysis.json")
        analysis_detail = arguments.get("analysis_detail", "detailed")
        include_technical = arguments.get("include_technical_analysis", True)
        max_concurrent = arguments.get("max_concurrent_videos", 2)
        
        # 檢查資料夾是否存在
        if not os.path.exists(folder_path):
            return [
                types.TextContent(
                    type="text",
                    text=f"❌ 資料夾不存在: {folder_path}"
                )
            ]
        
        # 支援的影片格式
        video_extensions = ["*.mp4", "*.mov", "*.avi", "*.mkv", "*.webm", "*.m4v"]
        video_files = []
        
        for ext in video_extensions:
            video_files.extend(glob.glob(os.path.join(folder_path, ext)))
            video_files.extend(glob.glob(os.path.join(folder_path, ext.upper())))
        
        if not video_files:
            return [
                types.TextContent(
                    type="text",
                    text=f"❌ 在資料夾中未找到支援的影片檔案: {folder_path}"
                )
            ]
        
        # 準備分析報告結構
        project_name = os.path.basename(os.path.abspath(folder_path))
        analysis_report = {
            "project_name": project_name,
            "analysis_timestamp": datetime.datetime.now().isoformat(),
            "total_videos": len(video_files),
            "analysis_settings": {
                "detail_level": analysis_detail,
                "technical_analysis": include_technical,
                "max_concurrent": max_concurrent
            },
            "videos": [],
            "project_summary": {
                "total_duration": "00:00:00",
                "main_themes": [],
                "key_characters": [],
                "production_notes": ""
            }
        }
        
        # 定義場記分析提示詞
        def get_script_analysis_prompt(analysis_level, include_tech):
            base_prompt = """你是專業的影片場記分析師，專精於無人機航拍影片分析。請對這個無人機拍攝的影片進行詳細的場記分析，並以結構化的方式回應。

## 🚁 無人機影片場記分析要求

### 1. 基本資訊
- 影片整體時長和主要內容摘要
- 拍攝類型識別（風景航拍、建築記錄、活動追蹤、測量勘查等）
- 無人機型號推測（基於畫質、穩定性、飛行特性）

### 2. 航拍場景分析（按時間軸分段）
- 將影片分割為主要飛行場景
- 每個場景包含：
  * 時間軸範圍（MM:SS-MM:SS 格式）
  * 飛行高度估測（低空<30m、中空30-120m、高空>120m）
  * 拍攝地點和地理環境描述
  * 主要拍攝對象（建築、景觀、人群、車輛等）
  * 飛行動作和軌跡（懸停、環繞、推進、拉升等）
  * 重要地標和視覺元素
  * 光線條件和天氣狀況

### 3. 🎥 無人機攝影技法分析
- 飛行模式識別：
  * 定點懸停拍攝
  * 環繞飛行（Orbit）
  * 直線推進/拉遠
  * 側向飛行（Parallax）
  * 垂直升降
  * 跟隨模式
- 雲台控制技巧：
  * 俯視角度變化
  * 水平轉向
  * 傾斜拍攝
- 構圖應用：
  * 鳥瞰全景
  * 引導線構圖
  * 前景/背景層次"""

            if analysis_level == "comprehensive":
                base_prompt += """

### 3. 詳細內容分析
- 逐分鐘關鍵事件記錄
- 人物表情和肢體語言分析
- 對話重點和關鍵詞彙
- 視覺符號和隱含意義"""

            if include_tech:
                base_prompt += """

### 4. 🔧 技術層面專業分析
- 無人機飛行技術：
  * 飛行軌跡平滑度評估
  * 風力影響和補償能力
  * GPS 定位精度表現
  * 避障系統使用情況
- 影像品質分析：
  * 雲台穩定性效果
  * 鏡頭畸變修正
  * 曝光控制和動態範圍
  * 色彩平衡和飽和度
- 拍攝參數推測：
  * 快門速度和動態模糊
  * ISO 設定和噪點控制
  * 解析度和畫面品質
  * 幀率和流暢度
- 法規遵循評估：
  * 飛行高度是否合規
  * 禁航區域避讓
  * 安全距離維持
  * 視線範圍內操作"""

            base_prompt += """

### 5. 🎬 無人機航拍製作建議
- 飛行技巧改進：
  * 軌跡規劃優化建議
  * 速度控制建議
  * 高度變化技巧
  * 轉向平滑度改善
- 拍攝品質提升：
  * 構圖改善方向
  * 光線運用技巧
  * 色彩校正建議
  * 穩定性改善
- 後製處理建議：
  * 色彩調色方向
  * 穩定性後製需求
  * 速度調節建議
  * 音軌配置建議
- 安全與法規：
  * 飛行安全改善
  * 法規遵循提醒
  * 風險評估建議

## 📝 回應格式要求
請以 JSON 格式回應，包含以下結構：
{
  "summary": "影片整體摘要",
  "drone_analysis": {
    "flight_patterns": ["飛行模式列表"],
    "altitude_ranges": "高度範圍",
    "shooting_techniques": ["拍攝技法列表"]
  },
  "scenes": [
    {
      "timestamp": "MM:SS-MM:SS",
      "description": "場景描述",
      "flight_action": "飛行動作",
      "subjects": ["拍攝對象"],
      "technical_notes": "技術備註"
    }
  ],
  "technical_analysis": {
    "image_quality": "影像品質評估",
    "flight_performance": "飛行表現",
    "equipment_assessment": "設備評估"
  },
  "production_suggestions": {
    "improvements": ["改善建議"],
    "retakes": ["補拍建議"],
    "post_production": ["後製建議"]
  }
}

請以專業、詳細且結構化的方式分析，確保提供具體的時間軸標記和無人機專業術語。"""
            
            return base_prompt
        
        # 處理進度追蹤
        processed_count = 0
        failed_videos = []
        
        # 分批處理影片
        for i in range(0, len(video_files), max_concurrent):
            batch = video_files[i:i+max_concurrent]
            batch_tasks = []
            
            for video_path in batch:
                batch_tasks.append(analyze_single_video(video_path, get_script_analysis_prompt(analysis_detail, include_technical)))
            
            # 並行處理當前批次
            batch_results = await asyncio.gather(*batch_tasks, return_exceptions=True)
            
            for video_path, result in zip(batch, batch_results):
                processed_count += 1
                
                if isinstance(result, Exception):
                    failed_videos.append({
                        "filename": os.path.basename(video_path),
                        "error": str(result)
                    })
                    logger.error(f"Failed to analyze {video_path}: {result}")
                    continue
                
                # 獲取檔案資訊
                file_size = os.path.getsize(video_path)
                file_size_mb = round(file_size / (1024 * 1024), 2)
                
                video_analysis = {
                    "filename": os.path.basename(video_path),
                    "file_path": video_path,
                    "file_size": f"{file_size_mb} MB",
                    "analysis_status": "completed",
                    "analysis": result
                }
                
                analysis_report["videos"].append(video_analysis)
                
                # 進度回報
                progress = int((processed_count / len(video_files)) * 100)
                logger.info(f"處理進度: {processed_count}/{len(video_files)} ({progress}%)")
        
        # 生成專案總結
        if analysis_report["videos"]:
            themes = []
            characters = []
            total_duration_seconds = 0
            
            for video in analysis_report["videos"]:
                analysis = video.get("analysis", {})
                if isinstance(analysis, dict):
                    themes.extend(analysis.get("themes", []))
                    characters.extend(analysis.get("characters", []))
            
            analysis_report["project_summary"]["main_themes"] = list(set(themes))[:10]
            analysis_report["project_summary"]["key_characters"] = list(set(characters))[:20]
            analysis_report["project_summary"]["production_notes"] = f"共分析 {len(analysis_report['videos'])} 個影片檔案"
        
        # 添加失敗記錄
        if failed_videos:
            analysis_report["failed_analyses"] = failed_videos
        
        # 儲存 JSON 報告
        output_path = os.path.join(folder_path, output_filename)
        try:
            with open(output_path, 'w', encoding='utf-8') as f:
                json.dump(analysis_report, f, ensure_ascii=False, indent=2)
            
            # 成功報告
            success_count = len(analysis_report["videos"])
            failed_count = len(failed_videos)
            
            response_text = f"""✅ 批量影片場記分析完成！

📊 處理結果:
  - 專案名稱: {project_name}
  - 總影片數: {len(video_files)}
  - 成功分析: {success_count}
  - 失敗數量: {failed_count}
  - 分析等級: {analysis_detail}
  - 技術分析: {'是' if include_technical else '否'}

📁 輸出檔案: {output_path}

🎬 場記報告內容:
  - 每個影片的詳細場景分析
  - 時間軸標記和內容描述
  - 人物、動作、對話記錄"""

            if include_technical:
                response_text += """
  - 技術分析（鏡頭、燈光、音響）"""

            if failed_videos:
                response_text += f"""

⚠️ 處理失敗的檔案:"""
                for failed in failed_videos[:3]:  # 只顯示前3個
                    response_text += f"""
  - {failed['filename']}: {failed['error'][:50]}..."""
                
                if len(failed_videos) > 3:
                    response_text += f"""
  - 還有 {len(failed_videos) - 3} 個檔案失敗"""

            return [
                types.TextContent(
                    type="text",
                    text=response_text
                )
            ]
            
        except Exception as e:
            return [
                types.TextContent(
                    type="text",
                    text=f"❌ 儲存報告失敗: {str(e)}"
                )
            ]
            
    except Exception as e:
        logger.error(f"Batch video analysis error: {e}")
        return [
            types.TextContent(
                type="text",
                text=f"❌ 批量分析過程發生錯誤: {str(e)}"
            )
        ]

async def smart_preview_tool(arguments: dict) -> list[types.TextContent]:
    """智能內容預覽與識別 - 路徑A：AI自動識別"""
    folder_path = arguments["folder_path"]
    sample_count = arguments.get("sample_count", 3)
    content_types = arguments.get("content_types", ["drone"])
    
    try:
        # 掃描影片檔案
        import glob
        video_files = []
        for ext in ["*.MOV", "*.mp4", "*.mov", "*.avi", "*.mkv", "*.webm"]:
            video_files.extend(glob.glob(os.path.join(folder_path, ext)))
        
        if not video_files:
            return [
                types.TextContent(
                    type="text",
                    text=f"❌ 未在 {folder_path} 找到影片檔案"
                )
            ]
        
        # 選擇樣本影片 (取前面幾個)
        sample_videos = video_files[:sample_count]
        
        preview_results = {
            "folder_path": folder_path,
            "total_videos": len(video_files),
            "sampled_videos": len(sample_videos),
            "content_analysis": [],
            "recommended_mode": "universal",
            "confidence_score": 0.0
        }
        
        # 分析每個樣本影片
        content_analysis_prompt = """分析這個影片的內容類型和特徵，請以JSON格式回應：
{
  "content_type": "drone|interview|tutorial|demo|event|other",
  "confidence": 0.8,
  "features": ["aerial_view", "technical_demo", "person_speaking"],
  "complexity": "low|medium|high",
  "recommended_analysis": "comprehensive|detailed|basic"
}"""
        
        for video_path in sample_videos:
            try:
                logger.info(f"預覽分析: {os.path.basename(video_path)}")
                result = await analyze_single_video(video_path, content_analysis_prompt)
                
                # 如果是字典格式，直接使用
                if isinstance(result, dict) and "content_type" in result:
                    content_info = result
                else:
                    # 嘗試從字符串解析JSON
                    import re
                    json_match = re.search(r'\{[^}]+\}', str(result))
                    if json_match:
                        try:
                            content_info = json.loads(json_match.group())
                        except:
                            content_info = {"content_type": "unknown", "confidence": 0.3}
                    else:
                        content_info = {"content_type": "unknown", "confidence": 0.3}
                
                content_info["filename"] = os.path.basename(video_path)
                preview_results["content_analysis"].append(content_info)
                
            except Exception as e:
                logger.error(f"預覽分析失敗 {video_path}: {e}")
                preview_results["content_analysis"].append({
                    "filename": os.path.basename(video_path),
                    "content_type": "error",
                    "confidence": 0.0,
                    "error": str(e)
                })
        
        # 決定推薦模式
        if preview_results["content_analysis"]:
            # 計算內容類型的一致性
            types_found = [item.get("content_type", "unknown") for item in preview_results["content_analysis"]]
            confidence_scores = [item.get("confidence", 0.0) for item in preview_results["content_analysis"]]
            
            most_common_type = max(set(types_found), key=types_found.count)
            type_consistency = types_found.count(most_common_type) / len(types_found)
            avg_confidence = sum(confidence_scores) / len(confidence_scores) if confidence_scores else 0.0
            
            overall_confidence = type_consistency * avg_confidence
            preview_results["confidence_score"] = overall_confidence
            preview_results["detected_content_type"] = most_common_type
            
            # 推薦處理模式
            if overall_confidence > 0.7 and most_common_type in content_types:
                preview_results["recommended_mode"] = "auto"
            elif overall_confidence > 0.4:
                preview_results["recommended_mode"] = "guided"
            else:
                preview_results["recommended_mode"] = "universal"
        
        # 生成報告
        response_text = f"""🔍 智能內容預覽完成！

📊 預覽統計:
  - 資料夾: {folder_path}
  - 總影片數: {preview_results['total_videos']}
  - 預覽影片數: {preview_results['sampled_videos']}
  - 檢測內容類型: {preview_results.get('detected_content_type', 'unknown')}
  - 一致性信心度: {preview_results['confidence_score']:.2f}

🎯 推薦處理模式: {preview_results['recommended_mode']}

📋 預覽分析結果:"""
        
        for analysis in preview_results["content_analysis"]:
            confidence = analysis.get("confidence", 0.0)
            content_type = analysis.get("content_type", "unknown")
            response_text += f"\n  - {analysis['filename']}: {content_type} (信心度: {confidence:.2f})"
        
        if preview_results["recommended_mode"] == "auto":
            response_text += "\n\n✅ 建議使用自動模式 (路徑A) - 內容類型一致且符合預期"
        elif preview_results["recommended_mode"] == "guided":
            response_text += "\n\n⚠️ 建議使用引導模式 (路徑B) - 內容類型不確定，需要用戶確認"
        else:
            response_text += "\n\n🔄 建議使用通用模式 (路徑C) - 內容類型複雜，使用通用分析"
        
        return [
            types.TextContent(
                type="text",
                text=response_text
            )
        ]
        
    except Exception as e:
        logger.error(f"Smart preview error: {e}")
        return [
            types.TextContent(
                type="text",
                text=f"❌ 智能預覽失敗: {str(e)}"
            )
        ]

async def parallel_analysis_tool(arguments: dict) -> list[types.TextContent]:
    """並行路徑處理器 - 統一路徑A/B/C的智能分析與用戶引導介面"""
    folder_path = arguments["folder_path"]
    processing_mode = arguments.get("processing_mode", "auto")
    group_size = arguments.get("group_size", 3)
    cost_limit = arguments.get("cost_limit", 5.0)
    interactive_mode = arguments.get("interactive_mode", True)
    
    try:
        # 掃描影片檔案
        import glob
        video_files = []
        for ext in ["*.MOV", "*.mp4", "*.mov", "*.avi", "*.mkv", "*.webm"]:
            video_files.extend(glob.glob(os.path.join(folder_path, ext)))
        
        if not video_files:
            return [
                types.TextContent(
                    type="text",
                    text=f"❌ 未在 {folder_path} 找到影片檔案"
                )
            ]
        
        # 計算分組
        total_groups = (len(video_files) + group_size - 1) // group_size
        
        # 成本估算
        estimated_cost_per_video = 0.15  # 基於歷史數據
        total_estimated_cost = len(video_files) * estimated_cost_per_video
        
        # 檢查成本限制
        if total_estimated_cost > cost_limit:
            return [
                types.TextContent(
                    type="text",
                    text=f"""💰 成本警告！

預估總成本: ${total_estimated_cost:.2f} USD
設定上限: ${cost_limit:.2f} USD

建議調整:
1. 減少影片數量：處理前 {int(cost_limit / estimated_cost_per_video)} 個影片
2. 提高成本上限
3. 使用免費模型 (品質較低但成本為零)

是否繼續處理？請調整參數後重新執行。"""
                )
            ]
        
        # 路徑A: 自動模式
        if processing_mode == "auto":
            # 直接使用現有的批量分析工具，但加入分組和進度追蹤
            result = await batch_video_script_analysis_tool({
                "folder_path": folder_path,
                "output_filename": f"parallel_analysis_auto_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json",
                "analysis_detail": "comprehensive",
                "include_technical_analysis": True,
                "max_concurrent_videos": group_size
            })
            
            return [
                types.TextContent(
                    type="text",
                    text=f"🤖 路徑A - 自動模式完成\n\n{result[0].text}"
                )
            ]
        
        # 路徑B: 引導模式
        elif processing_mode == "guided":
            response_text = f"""🎯 路徑B - 引導模式啟動

📋 處理計劃:
  - 總影片數: {len(video_files)}
  - 分組數量: {total_groups}
  - 每組影片數: {group_size}
  - 預估成本: ${total_estimated_cost:.2f} USD

🎬 影片清單預覽:"""
            
            for i, video_file in enumerate(video_files[:10]):  # 顯示前10個
                file_size = os.path.getsize(video_file) / (1024*1024)
                response_text += f"\n  {i+1}. {os.path.basename(video_file)} ({file_size:.1f}MB)"
            
            if len(video_files) > 10:
                response_text += f"\n  ... 還有 {len(video_files) - 10} 個檔案"
            
            response_text += f"""

🔧 可選處理參數:
  - 分析等級: comprehensive (推薦)
  - 技術分析: 啟用
  - 無人機專項: 啟用

請確認是否開始分組處理？
下一步將創建詳細的執行計劃。"""
            
            return [
                types.TextContent(
                    type="text",
                    text=response_text
                )
            ]
        
        # 路徑C: 通用模式
        else:  # universal
            # 使用保守的通用設定
            result = await batch_video_script_analysis_tool({
                "folder_path": folder_path,
                "output_filename": f"parallel_analysis_universal_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json",
                "analysis_detail": "detailed",  # 降低一級以減少成本
                "include_technical_analysis": False,  # 關閉技術分析
                "max_concurrent_videos": 2  # 降低並發數
            })
            
            return [
                types.TextContent(
                    type="text",
                    text=f"🔄 路徑C - 通用模式完成\n\n{result[0].text}"
                )
            ]
    
    except Exception as e:
        logger.error(f"Parallel analysis error: {e}")
        return [
            types.TextContent(
                type="text",
                text=f"❌ 並行分析失敗: {str(e)}"
            )
        ]

async def analyze_single_video(video_path: str, analysis_prompt: str) -> dict:
    """分析單個影片檔案"""
    try:
        # 上傳影片到 Gemini
        video_file = genai.upload_file(path=video_path)
        logger.info(f"Uploaded video: {video_file.name}")
        
        # 等待處理完成
        while video_file.state.name == "PROCESSING":
            await asyncio.sleep(1)
            video_file = genai.get_file(video_file.name)
        
        if video_file.state.name == "FAILED":
            raise Exception(f"Video processing failed: {video_file.state.name}")
        
        # 生成分析內容
        response = model.generate_content([video_file, analysis_prompt])
        
        # 清理上傳的檔案
        genai.delete_file(video_file.name)
        
        # 使用智能JSON提取器解析回應
        from .json_extractor import IntelligentJSONExtractor
        
        extractor = IntelligentJSONExtractor()
        result = extractor.extract_json_from_response(response.text)
        
        # 添加處理元數據
        if "_metadata" not in result:
            result["_metadata"] = {}
        result["_metadata"]["video_file"] = video_path
        result["_metadata"]["analysis_timestamp"] = datetime.now().isoformat()
        
        return result
            
    except Exception as e:
        logger.error(f"Error analyzing video {video_path}: {e}")
        raise

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