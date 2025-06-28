# Gemini MCP Server 使用指南

## 可用工具

### 1. gemini_chat - 基本對話

與 Gemini AI 進行自然語言對話。

**參數：**
- `message` (必需): 要發送的訊息
- `system_instruction` (可選): 系統指令，用於指導 AI 行為
- `temperature` (可選): 創意度控制 (0.0-1.0)，預設 0.7

**使用範例：**
```javascript
// 在 Claude Code 中
gemini_chat({
  "message": "請解釋什麼是機器學習？",
  "temperature": 0.3
})
```

**進階使用：**
```javascript
gemini_chat({
  "message": "幫我寫一個 Python 函數來計算費波那契數列",
  "system_instruction": "你是一個專業的 Python 開發者，請提供清晰的程式碼和註解",
  "temperature": 0.1
})
```

### 2. gemini_generate - 文本生成

生成特定類型的文本內容。

**參數：**
- `prompt` (必需): 生成提示詞
- `max_output_tokens` (可選): 最大輸出 token 數量 (1-8192)
- `temperature` (可選): 創意度控制 (0.0-1.0)

**使用範例：**
```javascript
gemini_generate({
  "prompt": "寫一篇關於人工智慧未來發展的 500 字文章",
  "max_output_tokens": 1000,
  "temperature": 0.7
})
```

**創意寫作：**
```javascript
gemini_generate({
  "prompt": "以「未來的智慧城市」為主題，寫一個科幻短故事開頭",
  "temperature": 0.9,
  "max_output_tokens": 500
})
```

### 3. gemini_analyze_code - 程式碼分析

分析和改進程式碼質量。

**參數：**
- `code` (必需): 要分析的程式碼
- `language` (可選): 程式語言
- `analysis_type` (可選): 分析類型
  - `review`: 代碼審查 (預設)
  - `optimize`: 效能優化
  - `debug`: 錯誤偵測
  - `explain`: 程式碼解釋

**代碼審查範例：**
```javascript
gemini_analyze_code({
  "code": `
def factorial(n):
    if n == 0:
        return 1
    else:
        return n * factorial(n-1)
  `,
  "language": "python",
  "analysis_type": "review"
})
```

**效能優化範例：**
```javascript
gemini_analyze_code({
  "code": `
function findMax(arr) {
  let max = arr[0];
  for (let i = 1; i < arr.length; i++) {
    if (arr[i] > max) {
      max = arr[i];
    }
  }
  return max;
}
  `,
  "language": "javascript",
  "analysis_type": "optimize"
})
```

### 4. gemini_vision - 圖像分析

分析圖像內容並回答相關問題。

**參數：**
- `image_path` (必需): 圖像檔案路徑
- `question` (可選): 關於圖像的問題

**基本圖像描述：**
```javascript
gemini_vision({
  "image_path": "/path/to/your/image.jpg",
  "question": "請描述這張圖片的內容"
})
```

**技術圖表分析：**
```javascript
gemini_vision({
  "image_path": "/path/to/architecture_diagram.png",
  "question": "請分析這個系統架構圖，說明各組件的作用和關係"
})
```

## 實際應用場景

### 場景一：代碼審查工作流

```javascript
// 1. 分析程式碼問題
gemini_analyze_code({
  "code": "你的程式碼...",
  "analysis_type": "review"
})

// 2. 生成改進建議
gemini_generate({
  "prompt": "基於上述代碼審查結果，提供具體的重構步驟"
})

// 3. 與 AI 討論最佳實踐
gemini_chat({
  "message": "這個重構方案是否符合 SOLID 原則？",
  "system_instruction": "你是一個資深軟體架構師"
})
```

### 場景二：技術文件生成

```javascript
// 1. 分析程式碼功能
gemini_analyze_code({
  "code": "你的 API 代碼...",
  "analysis_type": "explain"
})

// 2. 生成 API 文件
gemini_generate({
  "prompt": "基於上述程式碼分析，生成詳細的 API 文件，包含參數說明和使用範例"
})
```

### 場景三：錯誤診斷

```javascript
// 1. 分析錯誤程式碼
gemini_analyze_code({
  "code": "你的有問題的程式碼...",
  "analysis_type": "debug"
})

// 2. 詢問具體解決方案
gemini_chat({
  "message": "基於上述分析，請提供修復這個問題的詳細步驟"
})
```

## 最佳實踐

### 1. 提示詞優化

**好的提示詞：**
```javascript
gemini_chat({
  "message": "請幫我設計一個 RESTful API 來管理用戶資料，需要包含 CRUD 操作，並考慮安全性和效能",
  "system_instruction": "你是一個有 10 年經驗的後端工程師，請提供實用且安全的解決方案"
})
```

**避免的提示詞：**
```javascript
gemini_chat({
  "message": "寫個 API"  // 太模糊
})
```

### 2. 溫度設定指導

- **程式碼相關**: `temperature: 0.1-0.3` (需要準確性)
- **創意寫作**: `temperature: 0.7-0.9` (需要創意)
- **一般對話**: `temperature: 0.5-0.7` (平衡)

### 3. 系統指令範例

```javascript
// 專業角色設定
"system_instruction": "你是一個專精於 Python 和機器學習的資深工程師"

// 輸出格式指定
"system_instruction": "請以 Markdown 格式輸出，包含程式碼區塊和清晰的說明"

// 特定要求
"system_instruction": "回答時請考慮效能、安全性和可維護性三個方面"
```

## 錯誤處理

### 常見錯誤碼

1. **認證錯誤**
   ```
   Error: Invalid API key
   ```
   解決：檢查 `GOOGLE_API_KEY` 設定

2. **配額超限**
   ```
   Error: Quota exceeded
   ```
   解決：檢查 API 使用量，考慮升級方案

3. **內容過濾**
   ```
   Error: Content filtered
   ```
   解決：修改提示詞，避免敏感內容

4. **圖片格式錯誤**
   ```
   Error: Unsupported image format
   ```
   解決：使用支援的格式 (JPEG, PNG, WebP)

## 效能優化

### 1. 選擇合適的模型

- `gemini-1.5-flash`: 快速回應，適合簡單任務
- `gemini-1.5-pro`: 複雜任務，更高品質輸出

### 2. 控制輸出長度

```javascript
gemini_generate({
  "prompt": "簡潔地說明...",  // 在提示詞中要求簡潔
  "max_output_tokens": 500   // 限制 token 數量
})
```

### 3. 批量處理

```javascript
// 一次處理多個相關問題
gemini_chat({
  "message": "請分別回答以下三個問題：1) ... 2) ... 3) ..."
})
```

## 監控和日誌

### 查看詳細日誌

```bash
# Docker 環境
docker-compose logs -f gemini-mcp-server

# 本地環境
export LOG_LEVEL=DEBUG
python src/gemini_mcp_server.py
```

### 監控 API 使用量

- 定期檢查 Google Cloud Console 中的 API 用量
- 設置用量警報
- 監控成本消耗