# Gemini 模型影片分析技術規格與限制

## 📊 模型能力對比表

| 模型版本 | 上下文視窗 | 最大影片長度 (標準解析度) | 最大影片長度 (低解析度) | 檔案大小限制 | 支援解析度 |
|---------|-----------|------------------------|----------------------|------------|----------|
| **gemini-2.0-flash-001** | 2M tokens | 2 小時 | 6 小時 | 2GB (GCS) / 15MB (HTTP) | 720p/480p/360p |
| **gemini-2.5-flash** | 2M tokens | 2 小時 | 6 小時 | 2GB (GCS) / 15MB (HTTP) | 720p/480p/360p |
| **gemini-2.5-pro** | 2M tokens | 2 小時 | 6 小時 | 2GB (GCS) / 15MB (HTTP) | 720p/480p/360p |
| **gemini-1.5-pro** | 1M tokens | 1 小時 | 3 小時 | 2GB (GCS) / 15MB (HTTP) | 720p/480p/360p |
| **gemini-1.5-flash** | 1M tokens | 1 小時 | 3 小時 | 2GB (GCS) / 15MB (HTTP) | 720p/480p/360p |

## 🎯 詳細技術規格

### 檔案大小限制

| 上傳方式 | 最大檔案大小 | 說明 |
|---------|-------------|------|
| **Cloud Storage URI** | 2GB | 推薦用於大型影片檔案 |
| **HTTP URL 上傳** | 15MB | 適合中小型檔案 |
| **Firebase AI Logic SDK** | 20MB | 總請求大小限制 |
| **直接上傳 (Base64)** | 20MB | 包含在 HTTP 請求中 |

### 影片解析度支援

| 解析度級別 | 實際解析度 | Token 消耗率 | 適用場景 |
|-----------|-----------|-------------|---------|
| **High** | 720p | ~300 tokens/秒 | 高品質分析、細節重要的影片 |
| **Standard (預設)** | 480p | ~300 tokens/秒 | 一般分析用途 |
| **Low** | 360p | ~100 tokens/秒 | 長影片、節省資源 |

### 影片處理參數

| 參數 | 預設值 | 可調整範圍 | 說明 |
|------|-------|-----------|------|
| **取樣率 (FPS)** | 1 fps | 0.1 - 60 fps | 影片幀提取頻率 |
| **音訊處理** | 1Kbps | 固定 | 單聲道音訊 |
| **最大影片數** | 1 | 1 | 每個請求限制 |
| **額外檔案** | - | 1 音訊 + 10 圖片 | 可同時處理 |

### Token 消耗估算

| 影片長度 | 標準解析度 Token | 低解析度 Token | 上下文限制 |
|---------|----------------|---------------|-----------|
| **1 分鐘** | ~18,000 | ~6,000 | 所有模型 |
| **10 分鐘** | ~180,000 | ~60,000 | 所有模型 |
| **1 小時** | ~1,080,000 | ~360,000 | 需要 1M+ 上下文 |
| **2 小時** | ~2,160,000 | ~720,000 | 需要 2M 上下文 |

## ⚙️ 自動格式轉換建議

### 檔案大小超限處理

```bash
# 當檔案 > 15MB (HTTP) 時，建議壓縮
ffmpeg -i input.mp4 -vcodec h264 -acodec aac -b:v 2M output.mp4

# 當檔案 > 2GB 時，必須分段處理
ffmpeg -i input.mp4 -t 7200 -c copy part1.mp4  # 前 2 小時
ffmpeg -i input.mp4 -ss 7200 -c copy part2.mp4  # 後續部分
```

### 解析度最佳化

```bash
# 高品質分析 (720p)
ffmpeg -i input.mp4 -vf scale=1280:720 -r 1 output_hq.mp4

# 標準分析 (480p) - 推薦
ffmpeg -i input.mp4 -vf scale=854:480 -r 1 output_std.mp4

# 低解析度長影片 (360p)
ffmpeg -i input.mp4 -vf scale=640:360 -r 1 output_low.mp4
```

### 動態 FPS 調整

```bash
# 運動/遊戲影片 (高 FPS)
ffmpeg -i sports.mp4 -r 10 output_sports.mp4

# 靜態內容 (低 FPS)
ffmpeg -i lecture.mp4 -r 0.5 output_lecture.mp4

# 一般內容 (標準 FPS)
ffmpeg -i general.mp4 -r 1 output_general.mp4
```

## 🔄 智慧預處理策略

### 檔案分析階段

1. **檢查檔案大小**
   - < 15MB: 直接上傳
   - 15MB - 2GB: 建議使用 GCS
   - > 2GB: 強制分段

2. **檢查影片長度**
   - 根據模型上下文限制調整解析度
   - 超長影片自動切分時間段

3. **內容類型偵測**
   - 運動/遊戲: 提高 FPS
   - 講座/演講: 降低 FPS
   - 一般內容: 使用預設 FPS

### 自動化決策流程

```python
def optimize_video_for_gemini(file_path, target_model):
    file_size = get_file_size(file_path)
    duration = get_video_duration(file_path)
    
    # 選擇解析度
    if target_model in ['gemini-2.0-flash-001', 'gemini-2.5-pro']:
        max_duration_std = 7200  # 2 hours
        max_duration_low = 21600  # 6 hours
    else:
        max_duration_std = 3600   # 1 hour  
        max_duration_low = 10800  # 3 hours
    
    # 決策邏輯
    if duration > max_duration_std:
        if duration <= max_duration_low:
            return {"resolution": "low", "segment": False}
        else:
            return {"resolution": "low", "segment": True}
    
    if file_size > 15 * 1024 * 1024:  # 15MB
        return {"resolution": "standard", "compress": True}
    
    return {"resolution": "standard", "compress": False}
```

## 🚨 重要注意事項

### 效能考量

- **快速動作場景**: 1 FPS 取樣可能遺失細節
- **Token 成本**: 高解析度消耗 3 倍 Token
- **處理時間**: 大檔案需要更長上傳和處理時間

### 最佳實踐

1. **標準工作流程**: 使用 480p、1 FPS 作為預設
2. **長影片處理**: 優先考慮 360p 低解析度
3. **高品質需求**: 僅在必要時使用 720p
4. **檔案管理**: 大檔案優先使用 Cloud Storage

### 限制與約束

- 每個請求限制 1 個影片檔案
- 不支援即時串流分析
- 音訊固定為單聲道 1Kbps
- 某些編碼格式可能不支援

---

**更新日期**: 2024年12月  
**適用版本**: Gemini API 2024-2025