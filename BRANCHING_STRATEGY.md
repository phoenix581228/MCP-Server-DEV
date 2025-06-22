# Git 分支管理策略

本文檔定義 MCP Server Development 專案的 Git 分支管理策略。

## 分支結構

### 主要分支

#### `main` (主分支)
- **用途**: 穩定的生產版本
- **保護**: 需要 PR 和程式碼審查
- **合併來源**: 只接受來自 `develop` 的合併
- **標籤**: 每次發布打上版本標籤 (如 v1.0.0)

#### `develop` (開發分支)
- **用途**: 整合開發中的功能
- **保護**: 需要通過測試
- **合併來源**: feature 和 hotfix 分支
- **更新頻率**: 持續整合

### 支援分支

#### `feature/*` (功能分支)
- **命名**: `feature/功能描述` (如 `feature/add-openai-provider`)
- **來源**: 從 `develop` 分支創建
- **合併目標**: 合併回 `develop`
- **生命週期**: 功能完成後刪除

#### `hotfix/*` (熱修復分支)
- **命名**: `hotfix/問題描述` (如 `hotfix/fix-api-timeout`)
- **來源**: 從 `main` 分支創建
- **合併目標**: 同時合併到 `main` 和 `develop`
- **生命週期**: 修復完成後刪除

#### `release/*` (發布分支)
- **命名**: `release/版本號` (如 `release/1.2.0`)
- **來源**: 從 `develop` 分支創建
- **合併目標**: 合併到 `main` 和 `develop`
- **用途**: 發布前的最終測試和準備

## 工作流程

### 1. 開發新功能

```bash
# 從 develop 創建功能分支
git checkout develop
git pull origin develop
git checkout -b feature/new-feature-name

# 開發功能...
git add .
git commit -m "feat: 實作新功能"

# 推送到遠端
git push -u origin feature/new-feature-name

# 創建 Pull Request 到 develop
```

### 2. 修復緊急問題

```bash
# 從 main 創建熱修復分支
git checkout main
git pull origin main
git checkout -b hotfix/fix-critical-bug

# 修復問題...
git add .
git commit -m "fix: 修復關鍵錯誤"

# 推送並合併到 main 和 develop
git push -u origin hotfix/fix-critical-bug
```

### 3. 發布新版本

```bash
# 從 develop 創建發布分支
git checkout develop
git pull origin develop
git checkout -b release/1.2.0

# 更新版本號、準備發布...
git add .
git commit -m "chore: 準備發布 v1.2.0"

# 合併到 main
git checkout main
git merge --no-ff release/1.2.0
git tag -a v1.2.0 -m "Release version 1.2.0"

# 合併回 develop
git checkout develop
git merge --no-ff release/1.2.0
```

## 提交訊息規範

使用約定式提交 (Conventional Commits):

- `feat:` 新功能
- `fix:` 錯誤修復
- `docs:` 文檔更新
- `style:` 程式碼格式調整（不影響功能）
- `refactor:` 重構（不新增功能或修復錯誤）
- `test:` 測試相關
- `chore:` 構建過程或輔助工具的變動

範例：
```
feat: 新增 Perplexity 深度研究功能
fix: 修復環境變數載入問題
docs: 更新 API 使用說明
```

## 版本標籤

使用語意化版本控制 (Semantic Versioning):

- **主版本號 (MAJOR)**: 不相容的 API 變更
- **次版本號 (MINOR)**: 向下相容的功能新增
- **修訂號 (PATCH)**: 向下相容的錯誤修復

格式: `v主版本.次版本.修訂號`

範例:
- `v1.0.0` - 首次穩定發布
- `v1.1.0` - 新增功能
- `v1.1.1` - 錯誤修復

## 子專案版本管理

每個子專案可以有獨立的版本號：

### perplexity-mcp-custom
- 標籤前綴: `perplexity/`
- 範例: `perplexity/v1.0.0`

### zen-mcp-server
- 標籤前綴: `zen/`
- 範例: `zen/v2.3.0`

### openmemory-mcp-config
- 標籤前綴: `openmemory/`
- 範例: `openmemory/v1.0.0`

### serena-mcp-server
- 標籤前綴: `serena/`
- 範例: `serena/v1.0.0`

## 最佳實踐

1. **經常同步**: 定期從上游分支拉取最新變更
2. **小型提交**: 保持提交小而專注
3. **清晰的訊息**: 寫清楚的提交訊息
4. **程式碼審查**: 所有合併都需要審查
5. **測試優先**: 確保測試通過再合併
6. **文檔更新**: 功能變更時更新相關文檔

## 分支保護規則

### main 分支
- 禁止直接推送
- 需要 PR 審查
- 需要狀態檢查通過
- 需要分支是最新的

### develop 分支
- 需要 PR 審查
- 需要測試通過
- 自動刪除已合併的分支

## 緊急情況處理

如果需要緊急修復生產問題：

1. 從 `main` 創建 `hotfix` 分支
2. 最小化變更範圍
3. 充分測試
4. 優先合併到 `main`
5. 立即同步到 `develop`

---

最後更新: 2025-06-22