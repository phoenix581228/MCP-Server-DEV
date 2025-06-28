#!/usr/bin/env python3
"""
影片優化工具

根據 Gemini 模型能力自動優化影片格式、解析度和分段
"""

import os
import subprocess
import json
import logging
from pathlib import Path
from typing import Dict, Any, Tuple, Optional
import tempfile

logger = logging.getLogger(__name__)

class VideoOptimizer:
    """影片優化器 - 根據 Gemini 模型規格自動優化影片"""
    
    # 模型規格定義
    MODEL_SPECS = {
        'gemini-2.0-flash-001': {
            'context_window': 2_000_000,
            'max_duration_std': 7200,    # 2 hours
            'max_duration_low': 21600,   # 6 hours
            'supports_high_res': True
        },
        'gemini-2.5-flash': {
            'context_window': 2_000_000,
            'max_duration_std': 7200,
            'max_duration_low': 21600,
            'supports_high_res': True
        },
        'gemini-2.5-pro': {
            'context_window': 2_000_000,
            'max_duration_std': 7200,
            'max_duration_low': 21600,
            'supports_high_res': True
        },
        'gemini-1.5-pro': {
            'context_window': 1_000_000,
            'max_duration_std': 3600,    # 1 hour
            'max_duration_low': 10800,   # 3 hours
            'supports_high_res': True
        },
        'gemini-1.5-flash': {
            'context_window': 1_000_000,
            'max_duration_std': 3600,
            'max_duration_low': 10800,
            'supports_high_res': True
        }
    }
    
    # 檔案大小限制 (bytes)
    SIZE_LIMITS = {
        'http_upload': 15 * 1024 * 1024,      # 15MB
        'gcs_upload': 2 * 1024 * 1024 * 1024, # 2GB
        'firebase_total': 20 * 1024 * 1024     # 20MB
    }
    
    # 解析度設定
    RESOLUTION_CONFIGS = {
        'high': {
            'scale': '1280:720',
            'description': '720p - 高品質分析',
            'token_rate': 300  # tokens per second
        },
        'standard': {
            'scale': '854:480', 
            'description': '480p - 標準分析',
            'token_rate': 300
        },
        'low': {
            'scale': '640:360',
            'description': '360p - 長影片優化',
            'token_rate': 100
        }
    }
    
    def __init__(self, model_name: str = 'gemini-1.5-flash'):
        """初始化優化器
        
        Args:
            model_name: 目標 Gemini 模型名稱
        """
        self.model_name = model_name
        self.model_spec = self.MODEL_SPECS.get(model_name, self.MODEL_SPECS['gemini-1.5-flash'])
        
    def analyze_video(self, video_path: str) -> Dict[str, Any]:
        """分析影片檔案
        
        Args:
            video_path: 影片檔案路徑
            
        Returns:
            包含影片資訊的字典
        """
        if not os.path.exists(video_path):
            raise FileNotFoundError(f"影片檔案不存在: {video_path}")
        
        try:
            # 使用 ffprobe 獲取影片資訊
            cmd = [
                'ffprobe', '-v', 'quiet', '-print_format', 'json',
                '-show_format', '-show_streams', video_path
            ]
            
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            info = json.loads(result.stdout)
            
            # 提取關鍵資訊
            video_stream = next((s for s in info['streams'] if s['codec_type'] == 'video'), None)
            audio_stream = next((s for s in info['streams'] if s['codec_type'] == 'audio'), None)
            
            if not video_stream:
                raise ValueError("無法找到影片串流")
            
            analysis = {
                'file_path': video_path,
                'file_size': os.path.getsize(video_path),
                'duration': float(info['format']['duration']),
                'width': int(video_stream['width']),
                'height': int(video_stream['height']),
                'fps': eval(video_stream['r_frame_rate']),  # 轉換分數格式
                'codec': video_stream['codec_name'],
                'has_audio': audio_stream is not None,
                'bit_rate': int(info['format'].get('bit_rate', 0))
            }
            
            logger.info(f"影片分析完成: {analysis}")
            return analysis
            
        except subprocess.CalledProcessError as e:
            raise RuntimeError(f"無法分析影片: {e}")
        except (json.JSONDecodeError, KeyError, ValueError) as e:
            raise RuntimeError(f"解析影片資訊失敗: {e}")
    
    def get_optimization_strategy(self, video_info: Dict[str, Any]) -> Dict[str, Any]:
        """根據影片資訊決定優化策略
        
        Args:
            video_info: 影片分析結果
            
        Returns:
            優化策略字典
        """
        duration = video_info['duration']
        file_size = video_info['file_size']
        
        strategy = {
            'needs_processing': False,
            'target_resolution': 'standard',
            'target_fps': 1,
            'segment_required': False,
            'compress_required': False,
            'upload_method': 'direct',
            'estimated_tokens': 0,
            'recommendations': []
        }
        
        # 1. 檢查檔案大小
        if file_size > self.SIZE_LIMITS['gcs_upload']:
            strategy['segment_required'] = True
            strategy['recommendations'].append("檔案過大，需要分段處理")
        elif file_size > self.SIZE_LIMITS['http_upload']:
            strategy['upload_method'] = 'gcs'
            strategy['recommendations'].append("建議使用 Cloud Storage 上傳")
        
        # 2. 檢查影片長度和選擇解析度
        max_std = self.model_spec['max_duration_std']
        max_low = self.model_spec['max_duration_low']
        
        if duration > max_std:
            if duration <= max_low:
                strategy['target_resolution'] = 'low'
                strategy['needs_processing'] = True
                strategy['recommendations'].append(f"影片超過 {max_std/3600:.1f} 小時，建議使用低解析度")
            else:
                strategy['segment_required'] = True
                strategy['target_resolution'] = 'low'
                strategy['needs_processing'] = True
                strategy['recommendations'].append(f"影片超過 {max_low/3600:.1f} 小時，需要分段處理")
        
        # 3. 內容類型檢測 (簡單啟發式)
        if video_info['fps'] > 24:
            strategy['target_fps'] = 10  # 運動/遊戲影片
            strategy['recommendations'].append("檢測到高幀率影片，適合運動分析")
        elif video_info['fps'] < 15:
            strategy['target_fps'] = 0.5  # 靜態內容
            strategy['recommendations'].append("檢測到低幀率影片，適合講座分析")
        
        # 4. 壓縮建議
        if file_size > self.SIZE_LIMITS['http_upload'] and not strategy['segment_required']:
            strategy['compress_required'] = True
            strategy['needs_processing'] = True
            strategy['recommendations'].append("建議壓縮以減小檔案大小")
        
        # 5. Token 估算
        token_rate = self.RESOLUTION_CONFIGS[strategy['target_resolution']]['token_rate']
        strategy['estimated_tokens'] = int(duration * token_rate)
        
        # 6. 檢查是否需要處理
        current_res = f"{video_info['width']}:{video_info['height']}"
        target_res = self.RESOLUTION_CONFIGS[strategy['target_resolution']]['scale']
        
        if (current_res != target_res or 
            video_info['fps'] != strategy['target_fps'] or
            strategy['compress_required'] or
            strategy['segment_required']):
            strategy['needs_processing'] = True
        
        return strategy
    
    def optimize_video(self, video_path: str, output_dir: Optional[str] = None) -> Dict[str, Any]:
        """優化影片檔案
        
        Args:
            video_path: 輸入影片路徑
            output_dir: 輸出目錄 (可選)
            
        Returns:
            優化結果字典
        """
        # 分析影片
        video_info = self.analyze_video(video_path)
        strategy = self.get_optimization_strategy(video_info)
        
        result = {
            'original_file': video_path,
            'video_info': video_info,
            'strategy': strategy,
            'optimized_files': [],
            'success': True,
            'message': ''
        }
        
        # 如果不需要處理，直接返回
        if not strategy['needs_processing']:
            result['optimized_files'] = [video_path]
            result['message'] = '影片已符合最佳格式，無需處理'
            return result
        
        try:
            # 設定輸出目錄
            if output_dir is None:
                output_dir = tempfile.mkdtemp(prefix='gemini_video_opt_')
            else:
                os.makedirs(output_dir, exist_ok=True)
            
            input_file = Path(video_path)
            
            if strategy['segment_required']:
                # 分段處理
                result['optimized_files'] = self._segment_video(
                    video_path, output_dir, strategy
                )
            else:
                # 單檔處理
                output_file = Path(output_dir) / f"{input_file.stem}_optimized{input_file.suffix}"
                self._process_single_video(video_path, str(output_file), strategy)
                result['optimized_files'] = [str(output_file)]
            
            result['message'] = f'影片優化完成，生成 {len(result["optimized_files"])} 個檔案'
            
        except Exception as e:
            result['success'] = False
            result['message'] = f'優化失敗: {str(e)}'
            logger.error(f"影片優化失敗: {e}")
        
        return result
    
    def _process_single_video(self, input_path: str, output_path: str, strategy: Dict[str, Any]):
        """處理單個影片檔案"""
        resolution_config = self.RESOLUTION_CONFIGS[strategy['target_resolution']]
        
        cmd = ['ffmpeg', '-i', input_path, '-y']  # -y 覆蓋輸出檔案
        
        # 設定解析度
        cmd.extend(['-vf', f"scale={resolution_config['scale']}"])
        
        # 設定 FPS
        cmd.extend(['-r', str(strategy['target_fps'])])
        
        # 設定編碼參數
        if strategy['compress_required']:
            cmd.extend(['-c:v', 'libx264', '-crf', '23'])  # 適中的壓縮
        else:
            cmd.extend(['-c:v', 'libx264'])
        
        # 音訊處理
        cmd.extend(['-c:a', 'aac', '-b:a', '128k'])
        
        cmd.append(output_path)
        
        logger.info(f"執行 FFmpeg 命令: {' '.join(cmd)}")
        subprocess.run(cmd, check=True, capture_output=True)
    
    def _segment_video(self, input_path: str, output_dir: str, strategy: Dict[str, Any]) -> list:
        """分段處理影片"""
        video_info = self.analyze_video(input_path)
        duration = video_info['duration']
        
        # 計算分段時間
        max_duration = self.model_spec['max_duration_low']
        segment_count = int(duration / max_duration) + 1
        segment_duration = duration / segment_count
        
        output_files = []
        input_file = Path(input_path)
        
        for i in range(segment_count):
            start_time = i * segment_duration
            output_file = Path(output_dir) / f"{input_file.stem}_part{i+1:02d}{input_file.suffix}"
            
            cmd = ['ffmpeg', '-i', input_path, '-y']
            cmd.extend(['-ss', str(start_time)])
            cmd.extend(['-t', str(segment_duration)])
            
            # 應用優化設定
            resolution_config = self.RESOLUTION_CONFIGS[strategy['target_resolution']]
            cmd.extend(['-vf', f"scale={resolution_config['scale']}"])
            cmd.extend(['-r', str(strategy['target_fps'])])
            cmd.extend(['-c:v', 'libx264', '-c:a', 'aac'])
            
            cmd.append(str(output_file))
            
            logger.info(f"處理分段 {i+1}/{segment_count}: {output_file.name}")
            subprocess.run(cmd, check=True, capture_output=True)
            
            output_files.append(str(output_file))
        
        return output_files
    
    def get_processing_summary(self, video_path: str) -> str:
        """獲取處理建議摘要"""
        try:
            video_info = self.analyze_video(video_path)
            strategy = self.get_optimization_strategy(video_info)
            
            summary = [
                f"影片分析 - {self.model_name}",
                f"檔案: {Path(video_path).name}",
                f"大小: {video_info['file_size'] / (1024*1024):.1f} MB",
                f"時長: {video_info['duration'] / 60:.1f} 分鐘",
                f"解析度: {video_info['width']}x{video_info['height']}",
                f"幀率: {video_info['fps']:.1f} fps",
                "",
                "建議策略:",
                f"- 目標解析度: {strategy['target_resolution']} ({self.RESOLUTION_CONFIGS[strategy['target_resolution']]['description']})",
                f"- 目標幀率: {strategy['target_fps']} fps", 
                f"- 預估 Token: {strategy['estimated_tokens']:,}",
                f"- 上傳方式: {strategy['upload_method']}",
            ]
            
            if strategy['recommendations']:
                summary.append("")
                summary.append("額外建議:")
                for rec in strategy['recommendations']:
                    summary.append(f"- {rec}")
            
            return "\n".join(summary)
            
        except Exception as e:
            return f"分析失敗: {str(e)}"

def main():
    """命令列工具主函數"""
    import argparse
    
    parser = argparse.ArgumentParser(description='Gemini 影片優化工具')
    parser.add_argument('video_path', help='影片檔案路徑')
    parser.add_argument('--model', default='gemini-1.5-flash', 
                       choices=list(VideoOptimizer.MODEL_SPECS.keys()),
                       help='目標 Gemini 模型')
    parser.add_argument('--output-dir', help='輸出目錄')
    parser.add_argument('--analyze-only', action='store_true', help='僅分析，不處理')
    
    args = parser.parse_args()
    
    # 設定日誌
    logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')
    
    optimizer = VideoOptimizer(args.model)
    
    if args.analyze_only:
        # 僅顯示分析結果
        summary = optimizer.get_processing_summary(args.video_path)
        print(summary)
    else:
        # 執行優化
        result = optimizer.optimize_video(args.video_path, args.output_dir)
        
        if result['success']:
            print(f"✅ {result['message']}")
            print("優化後的檔案:")
            for file in result['optimized_files']:
                print(f"  - {file}")
        else:
            print(f"❌ {result['message']}")

if __name__ == '__main__':
    main()