#!/usr/bin/env python3
"""
進度追蹤和中斷恢復系統 - TaskMaster 任務8
實現真正的互動式分組處理，解決「黑洞」批處理問題
"""

import os
import sys
import json
import asyncio
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Tuple
from pathlib import Path
from dataclasses import dataclass, asdict
import time

sys.path.insert(0, 'src')

@dataclass
class VideoProcessingState:
    """單個影片處理狀態"""
    filename: str
    file_path: str
    file_size_mb: float
    status: str  # pending, uploading, analyzing, completed, failed
    start_time: Optional[str] = None
    end_time: Optional[str] = None
    error_message: Optional[str] = None
    analysis_result: Optional[Dict] = None
    estimated_cost: float = 0.0
    actual_cost: float = 0.0

@dataclass
class GroupProcessingState:
    """分組處理狀態"""
    group_id: int
    videos: List[VideoProcessingState]
    status: str  # pending, processing, completed, failed
    start_time: Optional[str] = None
    end_time: Optional[str] = None
    completed_count: int = 0
    failed_count: int = 0
    total_cost: float = 0.0

@dataclass
class SessionState:
    """會話處理狀態"""
    session_id: str
    folder_path: str
    total_videos: int
    total_groups: int
    current_group: int
    processing_mode: str
    groups: List[GroupProcessingState]
    start_time: str
    status: str  # running, paused, completed, failed
    total_cost: float = 0.0
    config: Dict = None

class ProgressTracker:
    """進度追蹤器"""
    
    def __init__(self, session_id: str):
        self.session_id = session_id
        self.state_file = f".progress_{session_id}.json"
        self.session_state: Optional[SessionState] = None
        
    def initialize_session(self, folder_path: str, video_files: List[str], 
                          group_size: int, processing_mode: str, config: Dict) -> SessionState:
        """初始化會話狀態"""
        
        # 創建影片狀態
        videos = []
        for video_path in video_files:
            try:
                file_size_mb = os.path.getsize(video_path) / (1024 * 1024)
            except:
                file_size_mb = 0.0
                
            video_state = VideoProcessingState(
                filename=os.path.basename(video_path),
                file_path=video_path,
                file_size_mb=file_size_mb,
                status="pending"
            )
            videos.append(video_state)
        
        # 創建分組
        groups = []
        for i in range(0, len(videos), group_size):
            group_videos = videos[i:i + group_size]
            group = GroupProcessingState(
                group_id=len(groups) + 1,
                videos=group_videos,
                status="pending"
            )
            groups.append(group)
        
        # 創建會話狀態
        self.session_state = SessionState(
            session_id=self.session_id,
            folder_path=folder_path,
            total_videos=len(videos),
            total_groups=len(groups),
            current_group=1,
            processing_mode=processing_mode,
            groups=groups,
            start_time=datetime.now().isoformat(),
            status="running",
            config=config
        )
        
        self.save_state()
        return self.session_state
    
    def load_state(self) -> Optional[SessionState]:
        """載入會話狀態"""
        try:
            if os.path.exists(self.state_file):
                with open(self.state_file, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                
                # 重建 SessionState 物件
                groups = []
                for group_data in data['groups']:
                    videos = [VideoProcessingState(**v) for v in group_data['videos']]
                    group = GroupProcessingState(**{**group_data, 'videos': videos})
                    groups.append(group)
                
                self.session_state = SessionState(**{**data, 'groups': groups})
                return self.session_state
        except Exception as e:
            print(f"⚠️ 載入狀態失敗: {e}")
        return None
    
    def save_state(self):
        """儲存會話狀態"""
        if self.session_state:
            try:
                with open(self.state_file, 'w', encoding='utf-8') as f:
                    # 將 dataclass 轉換為字典
                    data = asdict(self.session_state)
                    json.dump(data, f, ensure_ascii=False, indent=2)
            except Exception as e:
                print(f"⚠️ 儲存狀態失敗: {e}")
    
    def update_video_status(self, group_id: int, video_filename: str, 
                          status: str, **kwargs):
        """更新影片狀態"""
        if not self.session_state:
            return
            
        group = self.session_state.groups[group_id - 1]
        for video in group.videos:
            if video.filename == video_filename:
                video.status = status
                
                if status == "uploading":
                    video.start_time = datetime.now().isoformat()
                elif status in ["completed", "failed"]:
                    video.end_time = datetime.now().isoformat()
                
                # 更新其他屬性
                for key, value in kwargs.items():
                    if hasattr(video, key):
                        setattr(video, key, value)
                
                # 更新分組統計
                self._update_group_stats(group)
                break
        
        self.save_state()
    
    def _update_group_stats(self, group: GroupProcessingState):
        """更新分組統計"""
        completed = sum(1 for v in group.videos if v.status == "completed")
        failed = sum(1 for v in group.videos if v.status == "failed")
        
        group.completed_count = completed
        group.failed_count = failed
        
        # 更新分組狀態
        if completed + failed == len(group.videos):
            group.status = "completed"
            group.end_time = datetime.now().isoformat()
        elif any(v.status in ["uploading", "analyzing"] for v in group.videos):
            group.status = "processing"
        
        # 計算分組成本
        group.total_cost = sum(v.actual_cost for v in group.videos)
    
    def get_current_group(self) -> Optional[GroupProcessingState]:
        """獲取當前分組"""
        if self.session_state and self.session_state.current_group <= len(self.session_state.groups):
            return self.session_state.groups[self.session_state.current_group - 1]
        return None
    
    def move_to_next_group(self) -> bool:
        """移動到下一組"""
        if self.session_state:
            if self.session_state.current_group < self.session_state.total_groups:
                self.session_state.current_group += 1
                self.save_state()
                return True
        return False
    
    def generate_progress_report(self) -> str:
        """生成進度報告"""
        if not self.session_state:
            return "❌ 無會話狀態"
        
        state = self.session_state
        current_group = self.get_current_group()
        
        # 整體進度
        completed_videos = sum(g.completed_count for g in state.groups)
        failed_videos = sum(g.failed_count for g in state.groups)
        progress_percentage = (completed_videos / state.total_videos) * 100
        
        report = f"""📊 處理進度報告 - 會話 {state.session_id}
{'='*60}

🎯 整體進度:
  📂 資料夾: {state.folder_path}
  📹 總影片數: {state.total_videos}
  ✅ 已完成: {completed_videos}
  ❌ 失敗: {failed_videos}
  📈 完成率: {progress_percentage:.1f}%

👥 分組進度:
  📦 總分組數: {state.total_groups}
  🔄 當前分組: {state.current_group}
  📊 分組狀態:"""
        
        for group in state.groups:
            status_icon = {"pending": "⏳", "processing": "🔄", "completed": "✅", "failed": "❌"}
            icon = status_icon.get(group.status, "❓")
            
            report += f"\n    {icon} Group {group.group_id}: {group.completed_count}/{len(group.videos)} 完成"
            if group.status == "processing":
                processing_videos = [v.filename for v in group.videos if v.status in ["uploading", "analyzing"]]
                if processing_videos:
                    report += f" (處理中: {', '.join(processing_videos)})"
        
        # 當前分組詳情
        if current_group:
            report += f"\n\n🔍 當前分組 {current_group.group_id} 詳情:"
            for video in current_group.videos:
                status_icons = {
                    "pending": "⏳", "uploading": "📤", "analyzing": "🧠", 
                    "completed": "✅", "failed": "❌"
                }
                icon = status_icons.get(video.status, "❓")
                
                size_info = f"({video.file_size_mb:.1f}MB)"
                report += f"\n  {icon} {video.filename} {size_info}"
                
                if video.status == "failed" and video.error_message:
                    report += f" - 錯誤: {video.error_message[:50]}..."
        
        # 成本統計
        total_cost = sum(g.total_cost for g in state.groups)
        report += f"\n\n💰 成本統計:\n  總成本: ${total_cost:.2f} USD"
        
        # 時間統計
        start_time = datetime.fromisoformat(state.start_time)
        elapsed = datetime.now() - start_time
        report += f"\n\n⏰ 時間統計:\n  已用時間: {str(elapsed).split('.')[0]}"
        
        if completed_videos > 0:
            avg_time_per_video = elapsed.total_seconds() / completed_videos
            remaining_videos = state.total_videos - completed_videos
            estimated_remaining = remaining_videos * avg_time_per_video
            report += f"\n  預估剩餘: {str(timedelta(seconds=int(estimated_remaining)))}"
        
        return report

class InteractiveProcessor:
    """互動式處理器"""
    
    def __init__(self):
        self.tracker: Optional[ProgressTracker] = None
        
    async def start_interactive_processing(self, folder_path: str, 
                                         processing_mode: str = "guided",
                                         group_size: int = 3,
                                         session_id: Optional[str] = None) -> bool:
        """開始互動式處理"""
        
        # 創建或恢復會話
        if session_id:
            self.tracker = ProgressTracker(session_id)
            session_state = self.tracker.load_state()
            if session_state:
                print(f"🔄 恢復會話: {session_id}")
                print(self.tracker.generate_progress_report())
                
                if input("\n是否繼續此會話？(y/N): ").lower() == 'y':
                    return await self._continue_processing()
        
        # 新會話
        if not session_id:
            session_id = datetime.now().strftime('session_%Y%m%d_%H%M%S')
        
        self.tracker = ProgressTracker(session_id)
        
        # 掃描影片檔案
        import glob
        video_files = []
        for ext in ["*.MOV", "*.mp4", "*.mov", "*.avi", "*.mkv", "*.webm"]:
            video_files.extend(glob.glob(os.path.join(folder_path, ext)))
        
        if not video_files:
            print(f"❌ 未在 {folder_path} 找到影片檔案")
            return False
        
        print(f"📂 找到 {len(video_files)} 個影片檔案")
        print(f"👥 分組大小: {group_size}")
        print(f"📦 預計分組數: {(len(video_files) + group_size - 1) // group_size}")
        
        # 初始化會話
        config = {
            "group_size": group_size,
            "processing_mode": processing_mode,
            "analysis_detail": "comprehensive",
            "include_technical_analysis": True
        }
        
        session_state = self.tracker.initialize_session(
            folder_path, video_files, group_size, processing_mode, config
        )
        
        print(f"✅ 會話 {session_id} 已建立")
        print(self.tracker.generate_progress_report())
        
        if input("\n開始處理？(Y/n): ").lower() != 'n':
            return await self._continue_processing()
        
        return False
    
    async def _continue_processing(self) -> bool:
        """繼續處理流程"""
        if not self.tracker or not self.tracker.session_state:
            return False
        
        try:
            from gemini_mcp_server import setup_authentication
            
            # 設置認證
            os.environ['GOOGLE_API_KEY'] = "AIzaSyAIq5Jaf6jqR7Edu6rXXBF_dxI9jH4EbF0"
            os.environ['GEMINI_MODEL'] = "gemini-1.5-pro"
            setup_authentication()
            
            while True:
                current_group = self.tracker.get_current_group()
                if not current_group or current_group.status == "completed":
                    if not self.tracker.move_to_next_group():
                        print("🎉 所有分組處理完成！")
                        break
                    current_group = self.tracker.get_current_group()
                
                # 處理當前分組
                print(f"\n🔄 開始處理分組 {current_group.group_id}")
                await self._process_group(current_group)
                
                # 顯示進度報告
                print(self.tracker.generate_progress_report())
                
                # 詢問是否繼續
                if current_group.group_id < self.tracker.session_state.total_groups:
                    response = input(f"\n繼續處理下一組？(Y/n/s=狀態): ").lower()
                    if response == 'n':
                        print("⏸️ 處理已暫停，可稍後恢復")
                        self.tracker.session_state.status = "paused"
                        self.tracker.save_state()
                        return True
                    elif response == 's':
                        print(self.tracker.generate_progress_report())
                        continue
            
            self.tracker.session_state.status = "completed"
            self.tracker.save_state()
            return True
            
        except KeyboardInterrupt:
            print("\n⚠️ 用戶中斷，進度已儲存")
            self.tracker.session_state.status = "paused"
            self.tracker.save_state()
            return True
        except Exception as e:
            print(f"❌ 處理失敗: {e}")
            return False
    
    async def _process_group(self, group: GroupProcessingState):
        """處理單一分組"""
        group.status = "processing"
        group.start_time = datetime.now().isoformat()
        self.tracker.save_state()
        
        # 模擬並行處理
        tasks = []
        for video in group.videos:
            task = self._process_single_video(group.group_id, video)
            tasks.append(task)
        
        # 並行執行
        await asyncio.gather(*tasks, return_exceptions=True)
        
        # 更新分組狀態
        self.tracker._update_group_stats(group)
    
    async def _process_single_video(self, group_id: int, video: VideoProcessingState):
        """處理單個影片 (示範版本)"""
        try:
            # 模擬上傳階段
            self.tracker.update_video_status(group_id, video.filename, "uploading")
            print(f"📤 上傳中: {video.filename}")
            
            # 模擬上傳時間 (基於檔案大小)
            upload_time = min(video.file_size_mb * 0.1, 10)  # 最多10秒
            await asyncio.sleep(upload_time)
            
            # 模擬分析階段
            self.tracker.update_video_status(group_id, video.filename, "analyzing")
            print(f"🧠 分析中: {video.filename}")
            
            # 模擬分析時間
            analysis_time = min(video.file_size_mb * 0.05, 30)  # 最多30秒
            await asyncio.sleep(analysis_time)
            
            # 模擬成功完成
            mock_result = {
                "summary": f"分析完成: {video.filename}",
                "scenes": [{"timestamp": "00:00-00:30", "description": "模擬場景"}],
                "technical_notes": {"quality": "good"}
            }
            
            estimated_cost = 0.15  # 模擬成本
            
            self.tracker.update_video_status(
                group_id, video.filename, "completed",
                analysis_result=mock_result,
                actual_cost=estimated_cost
            )
            
            print(f"✅ 完成: {video.filename} (${estimated_cost:.2f})")
            
        except Exception as e:
            self.tracker.update_video_status(
                group_id, video.filename, "failed",
                error_message=str(e)
            )
            print(f"❌ 失敗: {video.filename} - {e}")

async def main():
    """主程式測試"""
    print("🎬 互動式影片處理器測試")
    print("=" * 50)
    
    processor = InteractiveProcessor()
    
    # 測試資料夾
    test_folder = "/Users/chih-hungtseng/Movies/花社大無人機"
    
    # 開始互動式處理
    await processor.start_interactive_processing(
        folder_path=test_folder,
        processing_mode="guided",
        group_size=3
    )

if __name__ == "__main__":
    asyncio.run(main())