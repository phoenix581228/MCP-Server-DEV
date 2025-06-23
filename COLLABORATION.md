# MCP Server 開發團隊協作指南

## 快速設置：添加協作者

### 1. 在 GitHub 網站上操作
1. 進入倉庫：https://github.com/phoenix581228/MCP-Server-DEV
2. 點擊 **Settings** → **Manage access**
3. 點擊 **Invite a collaborator**
4. 輸入協作者的 GitHub 用戶名或郵箱
5. 選擇權限級別並發送邀請

### 2. 權限級別說明
- **Write**: 可以推送代碼、創建分支、管理 issues
- **Maintain**: 額外可以管理倉庫設置、webhooks
- **Admin**: 完全控制（包括刪除倉庫）

## 進階設置：使用 GitHub Organization

### 優點
- 統一管理多個倉庫
- 細緻的權限控制
- 團隊結構清晰
- 支援 SSO（單點登錄）

### 設置步驟
1. **創建 Organization**
   - 訪問：https://github.com/organizations/new
   - 選擇 Free 計劃
   - 設置組織名稱

2. **轉移倉庫**
   - Settings → Transfer ownership
   - 輸入 Organization 名稱

3. **創建 Teams**
   ```
   核心團隊（Core Team）
   ├── 權限：Admin
   └── 成員：創始成員
   
   開發團隊（Developers）
   ├── 權限：Write
   └── 成員：所有開發者
   
   貢獻者（Contributors）
   ├── 權限：Triage
   └── 成員：外部貢獻者
   ```

## 協作工作流程

### 1. 分支策略
```bash
main
├── develop           # 開發分支
├── feature/*        # 功能分支
├── bugfix/*         # 錯誤修復
└── release/*        # 發布分支
```

### 2. Pull Request 流程
1. Fork 或創建功能分支
2. 開發並提交代碼
3. 創建 Pull Request
4. Code Review（至少 1 人審核）
5. 合併到目標分支

### 3. 保護主分支
```bash
# 在 Settings → Branches 設置
- Require pull request reviews (1-2 人)
- Dismiss stale pull request approvals
- Require status checks to pass
- Include administrators
```

## 團隊溝通

### 1. Issues 管理
- **Bug Report**: 錯誤報告
- **Feature Request**: 功能請求
- **Discussion**: 技術討論
- **Documentation**: 文檔改進

### 2. 標籤系統
- `priority: high/medium/low`
- `type: bug/feature/docs`
- `status: in-progress/review/done`
- `mcp: perplexity/zen/openmemory/serena/taskmaster`

### 3. 專案看板
使用 GitHub Projects 追蹤進度：
- To Do
- In Progress
- Review
- Done

## 開發環境同步

### 1. 克隆倉庫
```bash
# Organization 倉庫
git clone https://github.com/[org-name]/MCP-Server-DEV.git

# 或 Fork 後克隆
git clone https://github.com/[your-username]/MCP-Server-DEV.git
```

### 2. 設置上游
```bash
git remote add upstream https://github.com/[org-name]/MCP-Server-DEV.git
git fetch upstream
```

### 3. 同步更新
```bash
git checkout main
git pull upstream main
git push origin main
```

## 代碼規範

### 1. Commit 訊息格式
```
<type>(<scope>): <subject>

<body>

<footer>
```

類型：
- feat: 新功能
- fix: 錯誤修復
- docs: 文檔更新
- style: 格式調整
- refactor: 重構
- test: 測試
- chore: 維護

### 2. 代碼審查要點
- 功能完整性
- 代碼品質
- 測試覆蓋
- 文檔更新
- 安全性考量

## 安全注意事項

### 1. 敏感資訊
- **禁止**提交 API 金鑰
- **禁止**提交密碼或 token
- 使用 `.env.example` 作為模板

### 2. 依賴管理
- 定期更新依賴
- 檢查安全漏洞
- 使用 `npm audit` 或 `pip-audit`

## 聯絡方式

- **Issues**: 技術問題和功能請求
- **Discussions**: 一般討論和想法
- **Email**: [團隊郵箱]
- **Discord/Slack**: [即時通訊]

---

*最後更新：2025-01-23*