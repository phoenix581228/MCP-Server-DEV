# OpenMemory MCP 安裝錯誤修正指南

## 問題描述

使用者遇到兩個問題：
1. docker-compose.yml 中的 `version` 屬性已過時的警告
2. 無法找到 `/docker/web` 目錄的錯誤

### 錯誤訊息
```
WARN[0000] docker-compose.yml: the attribute `version` is obsolete, it will be ignored
unable to prepare context: path "/Users/phoenix/Projects/MCP-Server-DEV/openmemory-mcp-cli-installer/docker/web" not found
```

## 解決方案

### 1. 移除過時的 version 屬性

新版本的 Docker Compose 不再需要 `version` 屬性。已從 docker-compose.yml 中移除：

```yaml
# 舊版（錯誤）
version: '3.9'
services:
  ...

# 新版（正確）
services:
  ...
```

### 2. 修正缺少的目錄和檔案

安裝腳本缺少以下內容：
- 創建 `docker/web` 目錄
- 創建 Web UI 的 Dockerfile 和相關檔案

已修正的內容：
1. 在 `prepare_docker_env()` 函數中添加目錄創建
2. 在 `build_docker_images()` 函數中添加 Web UI 相關檔案的創建

## 修正內容詳情

### 1. 目錄創建修正

```bash
# 準備 Docker 環境
prepare_docker_env() {
    info "準備 Docker 環境..."
    
    # 創建必要目錄
    mkdir -p docker/volumes/postgres
    mkdir -p docker/volumes/qdrant
    mkdir -p docker/backups
    mkdir -p docker/configs
    mkdir -p docker/web        # 新增
    mkdir -p docker/api        # 新增
    mkdir -p docker/mcp        # 新增
```

### 2. Web UI Dockerfile 創建

添加了完整的 Web UI 相關檔案：
- `docker/web/Dockerfile` - Next.js 應用的 Docker 映像
- `docker/web/package.json` - Node.js 依賴
- `docker/web/next.config.js` - Next.js 配置
- `docker/web/pages/index.js` - 主頁面
- `docker/web/pages/_app.js` - 應用入口
- `docker/web/styles/globals.css` - 全域樣式
- `docker/web/postcss.config.js` - PostCSS 配置
- `docker/web/tailwind.config.js` - Tailwind CSS 配置

### 3. 其他優化

移除了在函數中間重複的 `mkdir -p` 命令，統一在 `prepare_docker_env()` 中處理。

## 手動修正步驟

如果需要手動修正現有安裝：

### 1. 創建缺少的目錄
```bash
cd openmemory-mcp-cli-installer
mkdir -p docker/web
mkdir -p docker/api
mkdir -p docker/mcp
```

### 2. 更新 docker-compose.yml
編輯 `docker/docker-compose.yml`，移除第一行的 `version: '3.9'`

### 3. 重新構建
```bash
cd docker
docker-compose build
```

## 驗證修正

執行以下命令驗證修正是否成功：

```bash
# 檢查目錄結構
ls -la docker/

# 驗證 docker-compose 配置
docker-compose -f docker/docker-compose.yml config

# 嘗試構建映像
docker-compose -f docker/docker-compose.yml build --no-cache
```

## 預防措施

為避免類似問題：
1. 始終在創建檔案前先創建目錄
2. 追蹤 Docker Compose 規範的更新
3. 在安裝腳本中添加目錄存在性檢查
4. 測試完整的安裝流程

## 相關資訊

- Docker Compose 規範：https://docs.docker.com/compose/compose-file/
- Next.js Docker 部署：https://nextjs.org/docs/deployment#docker-image