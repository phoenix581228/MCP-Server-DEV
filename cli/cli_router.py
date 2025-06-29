#!/usr/bin/env python3
"""
CLI路由器和成本控制系統 - TaskMaster 任務7
北斗七星協作架構的統一命令行介面
"""

import os
import sys
import json
import argparse
import asyncio
from datetime import datetime
from typing import Dict, List, Optional
from pathlib import Path

# 設定環境
sys.path.insert(0, 'src')

class CostController:
    """成本控制管理器"""
    
    def __init__(self):
        self.cost_history = []
        self.daily_limit = 20.0  # 每日上限 $20 USD
        self.session_limit = 10.0  # 單次會話上限 $10 USD
        self.cost_per_video_estimates = {
            "gemini-1.5-pro": 0.15,
            "gemini-2.5-flash": 0.05,
            "gemini-1.5-flash": 0.03
        }
    
    def estimate_cost(self, video_count: int, model: str = "gemini-1.5-pro", 
                     analysis_level: str = "detailed") -> Dict:
        """估算處理成本"""
        base_cost = self.cost_per_video_estimates.get(model, 0.15)
        
        # 分析等級影響成本
        level_multipliers = {
            "basic": 0.6,
            "detailed": 1.0,
            "comprehensive": 1.5
        }
        
        multiplier = level_multipliers.get(analysis_level, 1.0)
        estimated_cost = video_count * base_cost * multiplier
        
        return {
            "total_cost": estimated_cost,
            "cost_per_video": base_cost * multiplier,
            "model": model,
            "analysis_level": analysis_level,
            "video_count": video_count,
            "within_session_limit": estimated_cost <= self.session_limit,
            "recommended_batch_size": int(self.session_limit / (base_cost * multiplier))
        }
    
    def check_daily_usage(self) -> Dict:
        """檢查今日使用量"""
        today = datetime.now().strftime('%Y-%m-%d')
        today_costs = [c for c in self.cost_history if c.get('date', '').startswith(today)]
        today_total = sum(c.get('cost', 0) for c in today_costs)
        
        return {
            "date": today,
            "used": today_total,
            "limit": self.daily_limit,
            "remaining": self.daily_limit - today_total,
            "percentage": (today_total / self.daily_limit) * 100
        }
    
    def log_usage(self, cost: float, details: Dict):
        """記錄使用量"""
        entry = {
            "timestamp": datetime.now().isoformat(),
            "date": datetime.now().strftime('%Y-%m-%d'),
            "cost": cost,
            "details": details
        }
        self.cost_history.append(entry)
        
        # 儲存到檔案
        self.save_cost_history()
    
    def save_cost_history(self):
        """儲存成本記錄"""
        try:
            with open('.cost_history.json', 'w') as f:
                json.dump(self.cost_history, f, indent=2)
        except Exception as e:
            print(f"⚠️ 無法儲存成本記錄: {e}")
    
    def load_cost_history(self):
        """載入成本記錄"""
        try:
            if os.path.exists('.cost_history.json'):
                with open('.cost_history.json', 'r') as f:
                    self.cost_history = json.load(f)
        except Exception as e:
            print(f"⚠️ 無法載入成本記錄: {e}")

class CLIRouter:
    """命令行路由器"""
    
    def __init__(self):
        self.cost_controller = CostController()
        self.cost_controller.load_cost_history()
        self.current_session = {
            "session_id": datetime.now().strftime('%Y%m%d_%H%M%S'),
            "start_time": datetime.now()
        }
    
    def setup_argparser(self) -> argparse.ArgumentParser:
        """設置命令行參數解析器"""
        parser = argparse.ArgumentParser(
            description="北斗七星並行影片分析系統",
            formatter_class=argparse.RawDescriptionHelpFormatter,
            epilog="""
使用範例:
  # 智能預覽模式
  python cli_router.py preview /path/to/videos

  # 自動處理模式 (路徑A)
  python cli_router.py auto /path/to/videos --cost-limit 5.0

  # 引導處理模式 (路徑B)  
  python cli_router.py guided /path/to/videos --group-size 3

  # 通用處理模式 (路徑C)
  python cli_router.py universal /path/to/videos --low-cost

  # 成本統計查看
  python cli_router.py cost-status

  # 批量處理設定
  python cli_router.py batch /path/to/videos --model flash --analysis basic
            """
        )
        
        subparsers = parser.add_subparsers(dest='command', help='可用命令')
        
        # 預覽命令
        preview_parser = subparsers.add_parser('preview', help='智能內容預覽')
        preview_parser.add_argument('folder', help='影片資料夾路徑')
        preview_parser.add_argument('--samples', type=int, default=3, help='預覽影片數量')
        preview_parser.add_argument('--content-type', default='drone', help='預期內容類型')
        
        # 自動模式 (路徑A)
        auto_parser = subparsers.add_parser('auto', help='路徑A: AI自動識別模式')
        auto_parser.add_argument('folder', help='影片資料夾路徑')
        auto_parser.add_argument('--cost-limit', type=float, default=5.0, help='成本上限 (USD)')
        auto_parser.add_argument('--group-size', type=int, default=3, help='分組大小')
        
        # 引導模式 (路徑B)
        guided_parser = subparsers.add_parser('guided', help='路徑B: 用戶引導模式')
        guided_parser.add_argument('folder', help='影片資料夾路徑')
        guided_parser.add_argument('--group-size', type=int, default=3, help='分組大小')
        guided_parser.add_argument('--interactive', action='store_true', help='啟用互動模式')
        
        # 通用模式 (路徑C)
        universal_parser = subparsers.add_parser('universal', help='路徑C: 通用分析模式')
        universal_parser.add_argument('folder', help='影片資料夾路徑')
        universal_parser.add_argument('--low-cost', action='store_true', help='低成本模式')
        universal_parser.add_argument('--group-size', type=int, default=2, help='分組大小')
        
        # 批量處理命令
        batch_parser = subparsers.add_parser('batch', help='自定義批量處理')
        batch_parser.add_argument('folder', help='影片資料夾路徑')
        batch_parser.add_argument('--model', choices=['pro', 'flash'], default='flash', help='使用模型')
        batch_parser.add_argument('--analysis', choices=['basic', 'detailed', 'comprehensive'], 
                                default='detailed', help='分析等級')
        batch_parser.add_argument('--concurrent', type=int, default=2, help='並發數量')
        batch_parser.add_argument('--cost-limit', type=float, default=10.0, help='成本上限')
        
        # 成本狀態命令
        cost_parser = subparsers.add_parser('cost-status', help='查看成本使用狀態')
        cost_parser.add_argument('--history', action='store_true', help='顯示歷史記錄')
        
        # 系統狀態命令
        status_parser = subparsers.add_parser('status', help='系統狀態檢查')
        
        return parser
    
    async def handle_preview(self, args) -> bool:
        """處理預覽命令"""
        print(f"🔍 智能內容預覽模式")
        print(f"📂 資料夾: {args.folder}")
        print(f"📊 樣本數: {args.samples}")
        
        try:
            from gemini_mcp_server import setup_authentication, smart_preview_tool
            
            # 設置認證
            self._setup_model_auth('pro')  # 預覽使用 Pro 模型
            setup_authentication()
            
            # 執行預覽
            result = await smart_preview_tool({
                "folder_path": args.folder,
                "sample_count": args.samples,
                "content_types": [args.content_type]
            })
            
            print(result[0].text)
            
            # 記錄最小成本 (預覽成本很低)
            self.cost_controller.log_usage(0.05, {
                "command": "preview",
                "folder": args.folder,
                "samples": args.samples
            })
            
            return True
            
        except Exception as e:
            print(f"❌ 預覽失敗: {e}")
            return False
    
    async def handle_auto(self, args) -> bool:
        """處理自動模式命令"""
        print(f"🤖 路徑A - AI自動識別模式")
        print(f"📂 資料夾: {args.folder}")
        print(f"💰 成本上限: ${args.cost_limit}")
        
        try:
            from gemini_mcp_server import setup_authentication, parallel_analysis_tool
            
            # 設置認證
            self._setup_model_auth('pro')
            setup_authentication()
            
            # 執行自動分析
            result = await parallel_analysis_tool({
                "folder_path": args.folder,
                "processing_mode": "auto",
                "group_size": args.group_size,
                "cost_limit": args.cost_limit,
                "interactive_mode": False
            })
            
            print(result[0].text)
            return True
            
        except Exception as e:
            print(f"❌ 自動模式失敗: {e}")
            return False
    
    async def handle_guided(self, args) -> bool:
        """處理引導模式命令"""
        print(f"🎯 路徑B - 用戶引導模式")
        print(f"📂 資料夾: {args.folder}")
        print(f"👥 分組大小: {args.group_size}")
        
        try:
            from gemini_mcp_server import setup_authentication, parallel_analysis_tool
            
            self._setup_model_auth('pro')
            setup_authentication()
            
            # 執行引導分析
            result = await parallel_analysis_tool({
                "folder_path": args.folder,
                "processing_mode": "guided",
                "group_size": args.group_size,
                "cost_limit": 5.0,
                "interactive_mode": args.interactive
            })
            
            print(result[0].text)
            return True
            
        except Exception as e:
            print(f"❌ 引導模式失敗: {e}")
            return False
    
    async def handle_universal(self, args) -> bool:
        """處理通用模式命令"""
        print(f"🔄 路徑C - 通用分析模式")
        print(f"📂 資料夾: {args.folder}")
        print(f"💸 低成本模式: {args.low_cost}")
        
        try:
            from gemini_mcp_server import setup_authentication, parallel_analysis_tool
            
            # 根據低成本模式選擇模型
            model = 'flash' if args.low_cost else 'pro'
            cost_limit = 2.0 if args.low_cost else 5.0
            
            self._setup_model_auth(model)
            setup_authentication()
            
            result = await parallel_analysis_tool({
                "folder_path": args.folder,
                "processing_mode": "universal",
                "group_size": args.group_size,
                "cost_limit": cost_limit,
                "interactive_mode": False
            })
            
            print(result[0].text)
            return True
            
        except Exception as e:
            print(f"❌ 通用模式失敗: {e}")
            return False
    
    async def handle_batch(self, args) -> bool:
        """處理批量命令"""
        print(f"📦 自定義批量處理")
        print(f"🔧 模型: {args.model}")
        print(f"📊 分析等級: {args.analysis}")
        
        # 成本估算
        import glob
        video_files = []
        for ext in ["*.MOV", "*.mp4", "*.mov"]:
            video_files.extend(glob.glob(os.path.join(args.folder, ext)))
        
        model_name = "gemini-1.5-pro" if args.model == 'pro' else "gemini-2.5-flash"
        cost_estimate = self.cost_controller.estimate_cost(
            len(video_files), model_name, args.analysis
        )
        
        print(f"💰 成本估算: ${cost_estimate['total_cost']:.2f}")
        print(f"📹 影片數量: {len(video_files)}")
        
        if not cost_estimate['within_session_limit']:
            print(f"⚠️ 成本超出會話限制，建議分批處理")
            return False
        
        try:
            from gemini_mcp_server import setup_authentication, batch_video_script_analysis_tool
            
            self._setup_model_auth(args.model)
            setup_authentication()
            
            result = await batch_video_script_analysis_tool({
                "folder_path": args.folder,
                "output_filename": f"batch_analysis_{self.current_session['session_id']}.json",
                "analysis_detail": args.analysis,
                "include_technical_analysis": args.analysis == "comprehensive",
                "max_concurrent_videos": args.concurrent
            })
            
            print(result[0].text)
            
            # 記錄實際成本
            self.cost_controller.log_usage(cost_estimate['total_cost'], {
                "command": "batch",
                "model": args.model,
                "analysis": args.analysis,
                "video_count": len(video_files)
            })
            
            return True
            
        except Exception as e:
            print(f"❌ 批量處理失敗: {e}")
            return False
    
    def handle_cost_status(self, args) -> bool:
        """處理成本狀態命令"""
        print("💰 成本使用狀態")
        print("=" * 40)
        
        # 今日使用量
        daily_usage = self.cost_controller.check_daily_usage()
        print(f"📅 今日使用量:")
        print(f"  已使用: ${daily_usage['used']:.2f}")
        print(f"  每日限額: ${daily_usage['limit']:.2f}")
        print(f"  剩餘額度: ${daily_usage['remaining']:.2f}")
        print(f"  使用率: {daily_usage['percentage']:.1f}%")
        
        # 會話限制
        print(f"\n🔧 會話設定:")
        print(f"  單次會話限額: ${self.cost_controller.session_limit:.2f}")
        print(f"  當前會話ID: {self.current_session['session_id']}")
        
        # 模型成本
        print(f"\n📊 模型成本 (每影片):")
        for model, cost in self.cost_controller.cost_per_video_estimates.items():
            print(f"  {model}: ${cost:.3f}")
        
        # 歷史記錄
        if args.history and self.cost_controller.cost_history:
            print(f"\n📋 最近5次使用記錄:")
            for entry in self.cost_controller.cost_history[-5:]:
                timestamp = entry['timestamp'][:19]
                cost = entry['cost']
                command = entry.get('details', {}).get('command', 'unknown')
                print(f"  {timestamp} | {command} | ${cost:.2f}")
        
        return True
    
    def handle_status(self, args) -> bool:
        """處理系統狀態命令"""
        print("🔧 系統狀態檢查")
        print("=" * 40)
        
        # API 金鑰檢查
        api_key = os.getenv('GOOGLE_API_KEY')
        if api_key:
            print(f"✅ API 金鑰: 已設定 (...{api_key[-4:]})")
        else:
            print(f"❌ API 金鑰: 未設定")
        
        # 模型設定
        model = os.getenv('GEMINI_MODEL', 'gemini-1.5-flash')
        print(f"🤖 當前模型: {model}")
        
        # 會話資訊
        print(f"📅 會話ID: {self.current_session['session_id']}")
        print(f"⏰ 開始時間: {self.current_session['start_time'].strftime('%Y-%m-%d %H:%M:%S')}")
        
        # MCP Server 檢查
        try:
            sys.path.insert(0, 'src')
            from gemini_mcp_server import setup_authentication
            print(f"✅ MCP Server: 可用")
        except Exception as e:
            print(f"❌ MCP Server: 不可用 ({e})")
        
        return True
    
    def _setup_model_auth(self, model_type: str):
        """設置模型認證"""
        if model_type == 'pro':
            os.environ['GEMINI_MODEL'] = "gemini-1.5-pro"
            os.environ['GOOGLE_API_KEY'] = "AIzaSyAIq5Jaf6jqR7Edu6rXXBF_dxI9jH4EbF0"  # 付費版
        else:  # flash
            os.environ['GEMINI_MODEL'] = "gemini-2.5-flash"
            os.environ['GOOGLE_API_KEY'] = "AIzaSyD5d2sfGCNN7FJQM-GHi5cndJJ2_uIxDpU"  # 免費版
    
    async def run(self, args):
        """主執行流程"""
        print(f"🌟 北斗七星並行影片分析系統 CLI v1.0")
        print(f"🎯 命令: {args.command}")
        print(f"📅 會話: {self.current_session['session_id']}")
        print("=" * 60)
        
        # 路由到對應的處理函數
        if args.command == 'preview':
            return await self.handle_preview(args)
        elif args.command == 'auto':
            return await self.handle_auto(args)
        elif args.command == 'guided':
            return await self.handle_guided(args)
        elif args.command == 'universal':
            return await self.handle_universal(args)
        elif args.command == 'batch':
            return await self.handle_batch(args)
        elif args.command == 'cost-status':
            return self.handle_cost_status(args)
        elif args.command == 'status':
            return self.handle_status(args)
        else:
            print(f"❌ 未知命令: {args.command}")
            return False

async def main():
    """主程式入口"""
    router = CLIRouter()
    parser = router.setup_argparser()
    
    args = parser.parse_args()
    
    if args.command is None:
        parser.print_help()
        return
    
    try:
        success = await router.run(args)
        if success:
            print(f"\n✅ 命令執行成功")
        else:
            print(f"\n❌ 命令執行失敗")
            sys.exit(1)
    except KeyboardInterrupt:
        print(f"\n⚠️ 用戶中斷執行")
    except Exception as e:
        print(f"\n❌ 未預期錯誤: {e}")
        sys.exit(1)

if __name__ == "__main__":
    asyncio.run(main())