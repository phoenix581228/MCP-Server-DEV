# Serena MCP Server 工具參考

本文檔詳細介紹 Serena 提供的所有工具，包括使用方式和範例。

## 工具分類

### 專案管理工具

#### activate_project
啟動指定的專案。

**參數**：
- `project_name` (string): 專案名稱

**範例**：
```
使用 activate_project 工具啟動名為 "my-app" 的專案
```

#### get_active_project
獲取當前啟用的專案名稱，並列出所有可用專案。

**參數**：無

**範例**：
```
使用 get_active_project 工具查看當前專案狀態
```

#### onboarding
執行專案初始化，識別專案結構、測試框架、建置系統等。

**參數**：無

**範例**：
```
使用 onboarding 工具初始化這個專案
```

#### check_onboarding_performed
檢查專案是否已完成初始化。

**參數**：無

**範例**：
```
使用 check_onboarding_performed 工具確認專案初始化狀態
```

### 檔案操作工具

#### create_text_file
在專案目錄中創建或覆寫檔案。

**參數**：
- `file_path` (string): 相對於專案根目錄的檔案路徑
- `content` (string): 檔案內容

**範例**：
```
使用 create_text_file 工具創建 src/utils/helper.py，內容為：
def format_date(date):
    return date.strftime("%Y-%m-%d")
```

#### read_file
讀取專案內的檔案。

**參數**：
- `file_path` (string): 檔案路徑

**範例**：
```
使用 read_file 工具讀取 src/main.py 的內容
```

#### list_dir
列出目錄中的檔案和子目錄。

**參數**：
- `directory_path` (string): 目錄路徑
- `recursive` (boolean, 可選): 是否遞迴列出

**範例**：
```
使用 list_dir 工具遞迴列出 src 目錄的所有檔案
```

### 符號搜尋工具

#### find_symbol
全域或區域搜尋符號（類別、函數、變數等）。

**參數**：
- `symbol_name` (string): 符號名稱或子字串
- `symbol_type` (string, 可選): 符號類型（class, function, variable 等）
- `scope` (string, 可選): 搜尋範圍（global, local）

**範例**：
```
使用 find_symbol 工具搜尋所有包含 "User" 的類別名稱
```

#### get_symbols_overview
獲取檔案或目錄中定義的頂層符號概覽。

**參數**：
- `path` (string): 檔案或目錄路徑

**範例**：
```
使用 get_symbols_overview 工具查看 src/models/ 目錄的結構
```

#### find_referencing_symbols
尋找引用特定符號的所有位置。

**參數**：
- `file_path` (string): 符號所在檔案
- `line` (number): 符號所在行號
- `column` (number): 符號所在列號
- `symbol_type` (string, 可選): 過濾引用符號的類型

**範例**：
```
使用 find_referencing_symbols 工具找出所有呼叫 UserService.login 方法的地方
```

#### find_referencing_code_snippets
尋找引用特定符號的程式碼片段。

**參數**：
- `file_path` (string): 符號所在檔案
- `line` (number): 符號所在行號
- `column` (number): 符號所在列號

**範例**：
```
使用 find_referencing_code_snippets 工具查看如何使用 config.DATABASE_URL
```

### 程式碼編輯工具

#### replace_symbol_body
替換符號的完整定義。

**參數**：
- `file_path` (string): 檔案路徑
- `line` (number): 符號開始行號
- `column` (number): 符號開始列號
- `new_body` (string): 新的符號定義

**範例**：
```
使用 replace_symbol_body 工具更新 calculate_total 函數的實作
```

#### insert_before_symbol
在符號定義之前插入內容。

**參數**：
- `file_path` (string): 檔案路徑
- `line` (number): 符號行號
- `column` (number): 符號列號
- `content` (string): 要插入的內容

**範例**：
```
使用 insert_before_symbol 工具在 UserModel 類別前添加文檔字串
```

#### insert_after_symbol
在符號定義之後插入內容。

**參數**：
- `file_path` (string): 檔案路徑
- `line` (number): 符號行號
- `column` (number): 符號列號
- `content` (string): 要插入的內容

**範例**：
```
使用 insert_after_symbol 工具在 login 方法後添加 logout 方法
```

#### insert_at_line
在指定行號插入內容。

**參數**：
- `file_path` (string): 檔案路徑
- `line_number` (number): 行號
- `content` (string): 要插入的內容

**範例**：
```
使用 insert_at_line 工具在第 15 行插入 import 語句
```

#### replace_lines
替換指定範圍的行。

**參數**：
- `file_path` (string): 檔案路徑
- `start_line` (number): 開始行號
- `end_line` (number): 結束行號
- `new_content` (string): 新內容

**範例**：
```
使用 replace_lines 工具替換第 20-25 行的程式碼
```

#### delete_lines
刪除指定範圍的行。

**參數**：
- `file_path` (string): 檔案路徑
- `start_line` (number): 開始行號
- `end_line` (number): 結束行號

**範例**：
```
使用 delete_lines 工具刪除第 30-35 行的註解
```

### 搜尋工具

#### search_for_pattern
在專案中搜尋文字模式。

**參數**：
- `pattern` (string): 搜尋模式（支援正則表達式）
- `file_pattern` (string, 可選): 檔案名稱模式
- `case_sensitive` (boolean, 可選): 是否區分大小寫

**範例**：
```
使用 search_for_pattern 工具搜尋所有包含 "TODO" 的註解
```

### 記憶管理工具

#### write_memory
儲存命名記憶供未來參考。

**參數**：
- `name` (string): 記憶名稱
- `content` (string): 記憶內容

**範例**：
```
使用 write_memory 工具記錄 "api_endpoints" 的資訊：
- POST /api/login
- GET /api/users
- PUT /api/users/{id}
```

#### read_memory
讀取指定的記憶。

**參數**：
- `name` (string): 記憶名稱

**範例**：
```
使用 read_memory 工具讀取 "api_endpoints" 的內容
```

#### list_memories
列出所有儲存的記憶。

**參數**：無

**範例**：
```
使用 list_memories 工具查看所有已儲存的記憶
```

#### delete_memory
刪除指定的記憶。

**參數**：
- `name` (string): 記憶名稱

**範例**：
```
使用 delete_memory 工具刪除 "temp_notes" 記憶
```

### 系統工具

#### execute_shell_command
執行 shell 命令（需要適當權限）。

**參數**：
- `command` (string): 要執行的命令
- `working_directory` (string, 可選): 工作目錄

**範例**：
```
使用 execute_shell_command 工具執行 "python -m pytest tests/"
```

#### restart_language_server
重新啟動 Language Server（當編輯未透過 Serena 進行時可能需要）。

**參數**：無

**範例**：
```
使用 restart_language_server 工具重新啟動語言伺服器
```

#### get_current_config
顯示當前的代理配置，包括啟用的模式、工具和上下文。

**參數**：無

**範例**：
```
使用 get_current_config 工具查看當前配置
```

#### switch_modes
切換操作模式。

**參數**：
- `modes` (array): 要啟用的模式列表

**範例**：
```
使用 switch_modes 工具啟用 ["planning", "no-onboarding"] 模式
```

### 思考工具

#### think_about_collected_information
評估收集到的資訊是否完整。

**參數**：
- `context` (string): 當前上下文描述

**範例**：
```
使用 think_about_collected_information 工具評估是否已收集足夠資訊來實作登入功能
```

#### think_about_task_adherence
確認是否仍在正確的任務軌道上。

**參數**：
- `current_task` (string): 當前任務描述
- `actions_taken` (array): 已執行的動作列表

**範例**：
```
使用 think_about_task_adherence 工具確認重構工作是否偏離原始目標
```

#### think_about_whether_you_are_done
判斷任務是否真正完成。

**參數**：
- `task_description` (string): 任務描述
- `completed_items` (array): 已完成項目列表

**範例**：
```
使用 think_about_whether_you_are_done 工具確認 API 整合是否完全完成
```

### 輔助工具

#### initial_instructions
獲取當前專案的初始指令（用於無法設定系統提示的客戶端）。

**參數**：無

**範例**：
```
使用 initial_instructions 工具獲取專案特定的初始化指令
```

#### prepare_for_new_conversation
提供準備新對話的指令，以保持必要的上下文。

**參數**：無

**範例**：
```
使用 prepare_for_new_conversation 工具準備下一次對話
```

#### summarize_changes
提供總結程式碼變更的指令。

**參數**：無

**範例**：
```
使用 summarize_changes 工具生成本次會話的變更摘要
```

## 使用技巧

### 1. 符號導航工作流

```
1. 使用 find_symbol 搜尋目標符號
2. 使用 get_symbols_overview 了解相關檔案結構
3. 使用 find_referencing_symbols 追蹤使用情況
4. 使用 replace_symbol_body 進行重構
```

### 2. 專案理解工作流

```
1. 使用 onboarding 初始化專案理解
2. 使用 list_dir 探索專案結構
3. 使用 get_symbols_overview 分析主要模組
4. 使用 write_memory 記錄重要發現
```

### 3. 程式碼修改工作流

```
1. 使用 read_file 查看目標檔案
2. 使用 find_symbol 定位要修改的符號
3. 使用適當的編輯工具進行修改
4. 使用 search_for_pattern 驗證修改影響
```

### 4. 除錯工作流

```
1. 使用 search_for_pattern 搜尋錯誤訊息
2. 使用 find_referencing_code_snippets 追蹤呼叫鏈
3. 使用 read_memory 查看之前的除錯記錄
4. 使用 write_memory 記錄新發現
```

## 最佳實踐

1. **使用語意工具優於文字搜尋**：優先使用 `find_symbol` 而非 `search_for_pattern`
2. **保持記憶組織**：使用有意義的記憶名稱，定期清理不需要的記憶
3. **批次操作**：可能的話，使用單一工具完成多個變更
4. **驗證變更**：修改後使用搜尋工具確認影響範圍
5. **善用思考工具**：在複雜任務中定期使用思考工具保持專注

## 工具限制

- **檔案大小**：單一檔案操作通常限制在 10MB 以內
- **搜尋結果**：預設限制 100 個結果，可在配置中調整
- **執行時間**：長時間操作可能會超時（預設 30 秒）
- **路徑限制**：只能操作專案目錄內的檔案

---

如需更多資訊，請參考 [配置指南](CONFIGURATION.md) 或 [整合指南](INTEGRATION.md)。