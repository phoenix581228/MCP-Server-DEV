# Claude Task Master 整合指南

本指南說明如何將 Claude Task Master 與其他系統和工具整合，特別是與現有的五個 MCP Server 的協同工作。

## 目錄

1. [MCP Server 生態系統整合](#mcp-server-生態系統整合)
2. [IDE 整合](#ide-整合)
3. [Git 工作流整合](#git-工作流整合)
4. [CI/CD 整合](#cicd-整合)
5. [API 整合](#api-整合)
6. [自定義擴展](#自定義擴展)

## MCP Server 生態系統整合

### 六大 MCP Server 協同架構

```
使用者 <-> Claude Code <-> MCP Protocol Layer
                              |
    +-------------+-------------+-------------+
    |             |             |             |
Taskmaster    Context7    Perplexity    Zen MCP
(專案管理)    (技術文檔)    (即時資訊)    (AI協作)
    |             |             |             |
    +-------------+-------------+-------------+
                  |             |
              OpenMemory    Serena
              (持久記憶)    (程式碼分析)
```

### 1. 與 Zen MCP 的整合

**使用場景**：任務實施時的深度分析

```bash
# 範例：為複雜任務請求 Zen MCP 分析
task-master show 15

# 在 Claude Code 中：
"請使用 Zen MCP 的 debug 功能幫我分析任務 15 的實施問題"
```

**協同工作流程**：
1. Task Master 定義任務需求
2. Zen MCP 提供實施分析
3. 結果回饋到任務更新

### 2. 與 Perplexity 的整合

**使用場景**：任務研究和技術調查

```bash
# 使用 Task Master 的研究功能（內部調用 Perplexity）
task-master research "OAuth 2.0 best practices" --save-to=15

# 協同使用
"使用 Perplexity 深入研究任務 15 的技術方案"
```

**整合配置**：
```json
{
  "models": {
    "research": {
      "provider": "perplexity",
      "modelId": "sonar-pro",
      "maxTokens": 8700
    }
  }
}
```

### 3. 與 Context7 的整合

**使用場景**：獲取任務相關的技術文檔

```bash
# 在實施任務時
task-master show 20  # 顯示 React 相關任務

# 請求 Context7 支援
"使用 Context7 查詢 React 18 的最新文檔來幫助實施任務 20"
```

### 4. 與 OpenMemory 的整合

**使用場景**：儲存任務決策和經驗

```bash
# 完成任務後的經驗總結
task-master set-status --id=15 --status=done

# 自動觸發記憶儲存
"請將任務 15 的實施經驗和決策儲存到 OpenMemory"
```

**整合腳本範例**：
```javascript
// 任務完成後自動儲存到 OpenMemory
async function saveTaskExperience(taskId) {
  const task = await getTask(taskId);
  const memory = {
    type: "task_completion",
    taskId: task.id,
    title: task.title,
    lessons: task.implementationNotes,
    decisions: task.decisions,
    timestamp: new Date()
  };
  
  // 調用 OpenMemory API
  await openMemory.add(memory);
}
```

### 5. 與 Serena 的整合

**使用場景**：任務實施時的程式碼分析

```bash
# 開始實施任務
task-master show 25  # API 端點實作任務

# 使用 Serena 分析現有程式碼
"使用 Serena 分析 src/api 目錄，為任務 25 找到最佳實施位置"
```

## IDE 整合

### Cursor AI 整合

1. **一鍵安裝**（Cursor 1.0+）：
```
cursor://anysphere.cursor-deeplink/mcp/install?name=taskmaster-ai&config=eyJjb21tYW5kIjoibnB4IiwiYXJncyI6WyIteSIsIi0tcGFja2FnZT10YXNrLW1hc3Rlci1haSIsInRhc2stbWFzdGVyLWFpIl0sImVudiI6eyJBTlRIUk9QSUNfQVBJX0tFWSI6IllPVVJfQU5USFJPUElDX0FQSV9LRVlfSEVSRSJ9fQo=
```

2. **Cursor 規則設定**（.cursorrules）：
```markdown
When working with Task Master:
1. Always check task dependencies before implementation
2. Update task status as you progress
3. Use `task-master next` to get the next task
4. Document decisions in subtask notes
```

### VS Code 整合

使用 VS Code 任務配置（.vscode/tasks.json）：

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Task Master: Next Task",
      "type": "shell",
      "command": "task-master next",
      "group": "build",
      "problemMatcher": []
    },
    {
      "label": "Task Master: List Tasks",
      "type": "shell",
      "command": "task-master list",
      "group": "build",
      "problemMatcher": []
    }
  ]
}
```

## Git 工作流整合

### 1. 分支策略整合

```bash
# 建立功能分支時自動建立任務標籤
git checkout -b feature/user-auth
task-master add-tag --from-branch

# 切換分支時切換任務上下文
git checkout feature/payment
task-master use-tag feature-payment
```

### 2. Git Hooks 整合

建立 `.git/hooks/post-checkout`：

```bash
#!/bin/bash
# 自動切換 Task Master 標籤

BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ $BRANCH == feature/* ]]; then
  TAG_NAME=$(echo $BRANCH | sed 's/feature\///')
  task-master use-tag $TAG_NAME 2>/dev/null || echo "No Task Master tag for $BRANCH"
fi
```

### 3. 提交訊息整合

```bash
# 自動生成提交訊息
task-master commit-message --id=15

# 輸出範例：
# feat: Implement user authentication (Task #15)
# 
# - Added JWT token generation
# - Implemented login/logout endpoints
# - Created auth middleware
```

## CI/CD 整合

### GitHub Actions 範例

```yaml
name: Task Management
on: 
  pull_request:
    types: [opened, synchronize]

jobs:
  task-validation:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '20'
      
      - name: Install Task Master
        run: npm install -g task-master-ai
      
      - name: Validate Dependencies
        run: task-master validate-dependencies
      
      - name: Check Task Completion
        run: |
          INCOMPLETE=$(task-master list --status=in-progress --format=json | jq length)
          if [ $INCOMPLETE -gt 0 ]; then
            echo "Warning: $INCOMPLETE tasks still in progress"
          fi
      
      - name: Generate Task Report
        run: task-master report --output=task-report.md
      
      - name: Comment PR
        uses: actions/github-script@v6
        with:
          script: |
            const fs = require('fs');
            const report = fs.readFileSync('task-report.md', 'utf8');
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: report
            });
```

### GitLab CI 範例

```yaml
stages:
  - validate
  - report

validate-tasks:
  stage: validate
  script:
    - npm install -g task-master-ai
    - task-master validate-dependencies
    - task-master lint

task-report:
  stage: report
  script:
    - npm install -g task-master-ai
    - task-master report --format=html > task-report.html
  artifacts:
    paths:
      - task-report.html
    expire_in: 1 week
```

## API 整合

### 1. 使用 Task Master 作為函式庫

```javascript
import { TaskMaster } from 'task-master-ai';

// 初始化
const tm = new TaskMaster({
  projectPath: './my-project',
  config: {
    models: {
      main: { provider: 'anthropic', modelId: 'claude-3-5-sonnet' }
    }
  }
});

// 程式化使用
async function createTaskFromIssue(issue) {
  const task = await tm.addTask({
    prompt: issue.title,
    description: issue.body,
    dependencies: issue.labels
      .filter(l => l.startsWith('depends-'))
      .map(l => parseInt(l.replace('depends-', '')))
  });
  
  return task;
}
```

### 2. REST API 包裝

建立簡單的 Express 服務器：

```javascript
const express = require('express');
const { exec } = require('child_process');
const app = express();

app.use(express.json());

// 列出任務
app.get('/api/tasks', async (req, res) => {
  exec('task-master list --format=json', (error, stdout) => {
    if (error) return res.status(500).json({ error });
    res.json(JSON.parse(stdout));
  });
});

// 新增任務
app.post('/api/tasks', async (req, res) => {
  const { prompt } = req.body;
  exec(`task-master add-task --prompt="${prompt}" --format=json`, 
    (error, stdout) => {
      if (error) return res.status(500).json({ error });
      res.json(JSON.parse(stdout));
    }
  );
});

app.listen(3000);
```

### 3. Webhook 整合

與專案管理工具整合：

```javascript
// Jira Webhook 處理
app.post('/webhooks/jira', async (req, res) => {
  const { issue, webhookEvent } = req.body;
  
  if (webhookEvent === 'jira:issue_created') {
    // 從 Jira issue 建立任務
    await createTaskFromJiraIssue(issue);
  }
  
  res.status(200).send('OK');
});

// GitHub Issues 整合
app.post('/webhooks/github', async (req, res) => {
  const { action, issue } = req.body;
  
  if (action === 'opened') {
    // 從 GitHub issue 建立任務
    await createTaskFromGitHubIssue(issue);
  }
  
  res.status(200).send('OK');
});
```

## 自定義擴展

### 1. 自定義命令

建立 `.taskmaster/commands/my-command.js`：

```javascript
module.exports = {
  name: 'my-command',
  description: 'Custom command for special workflow',
  options: [
    { name: '--option', description: 'Custom option' }
  ],
  execute: async (args, config) => {
    // 自定義邏輯
    console.log('Executing custom command with:', args);
    
    // 使用 Task Master API
    const tasks = await this.getTasks();
    // ... 自定義處理
  }
};
```

### 2. 事件鉤子

建立 `.taskmaster/hooks.js`：

```javascript
module.exports = {
  // 任務建立前
  beforeTaskCreate: async (taskData) => {
    // 驗證或修改任務資料
    if (!taskData.testStrategy) {
      taskData.testStrategy = 'Unit tests required';
    }
    return taskData;
  },
  
  // 任務完成後
  afterTaskComplete: async (task) => {
    // 發送通知
    await sendSlackNotification(`Task ${task.id} completed: ${task.title}`);
    
    // 更新外部系統
    await updateJiraTicket(task.externalId, 'Done');
  },
  
  // PRD 解析後
  afterPRDParse: async (tasks) => {
    // 自動分配任務
    await autoAssignTasks(tasks);
  }
};
```

### 3. 自定義 AI 提供者

```javascript
// .taskmaster/providers/custom-ai.js
module.exports = {
  name: 'custom-ai',
  async complete(prompt, options) {
    // 調用自定義 AI 服務
    const response = await fetch('https://my-ai-service.com/complete', {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${process.env.CUSTOM_AI_KEY}` },
      body: JSON.stringify({ prompt, ...options })
    });
    
    return response.json();
  }
};
```

## 最佳實踐

### 1. 錯誤處理

```javascript
try {
  const result = await taskMaster.addTask({ prompt });
} catch (error) {
  if (error.code === 'INVALID_DEPENDENCIES') {
    // 處理依賴錯誤
  } else if (error.code === 'AI_LIMIT_EXCEEDED') {
    // 切換到備用模型
  }
}
```

### 2. 批量操作

```javascript
// 批量更新任務狀態
const taskIds = [15, 16, 17];
await Promise.all(
  taskIds.map(id => 
    taskMaster.updateStatus(id, 'in-progress')
  )
);
```

### 3. 快取策略

```javascript
// 實現任務快取
const taskCache = new Map();

async function getCachedTask(id) {
  if (!taskCache.has(id)) {
    const task = await taskMaster.getTask(id);
    taskCache.set(id, task);
  }
  return taskCache.get(id);
}
```

---

**文檔版本**：1.0  
**更新日期**：2025-06-22