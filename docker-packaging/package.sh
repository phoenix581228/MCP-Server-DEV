#!/bin/bash
# 北斗七星陣一鍵安裝包打包工具
# Big Dipper Formation - Installation Package Builder

set -e

# 顏色定義
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# 全域變數
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
PACKAGE_NAME="bigdipper-mcp-installer"
VERSION="1.0.0"
BUILD_DIR="$SCRIPT_DIR/build"
DIST_DIR="$SCRIPT_DIR/dist"
TEMP_DIR="/tmp/bigdipper_package_$$"

# 建立目錄
mkdir -p "$BUILD_DIR" "$DIST_DIR" "$TEMP_DIR"

# 日誌函數
log_info() {
    echo -e "${GREEN}[打包]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[警告]${NC} $1"
}

log_error() {
    echo -e "${RED}[錯誤]${NC} $1"
}

log_step() {
    echo -e "${CYAN}[步驟]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[成功]${NC} $1"
}

log_package() {
    echo -e "${PURPLE}[打包]${NC} $1"
}

# 顯示打包橫幅
show_package_banner() {
    clear
    echo -e "${PURPLE}"
    cat << 'EOF'
    ╔══════════════════════════════════════════════════════════════════════╗
    ║                    📦 北斗七星陣安裝包打包工具                        ║
    ║               Big Dipper Formation Package Builder                   ║
    ║                                                                      ║
    ║                  創建完整的一鍵安裝包                                 ║
    ║               Create Complete One-Click Installer                    ║
    ╚══════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo
}

# 檢查前置條件
check_prerequisites() {
    log_step "檢查打包前置條件..."
    
    local missing_tools=()
    
    # 檢查必要工具
    local required_tools=("tar" "gzip" "zip")
    
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        log_error "缺少必要工具: ${missing_tools[*]}"
        exit 1
    fi
    
    # 檢查來源檔案
    local required_files=(
        "$SCRIPT_DIR/install.sh"
        "$SCRIPT_DIR/utils/system-check.sh"
        "$SCRIPT_DIR/utils/api-wizard.sh"
        "$SCRIPT_DIR/utils/auto-deploy.sh"
        "$SCRIPT_DIR/utils/test-validator.sh"
        "$SCRIPT_DIR/utils/uninstall.sh"
    )
    
    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            log_error "找不到必要檔案: $file"
            exit 1
        fi
    done
    
    log_success "前置條件檢查通過"
}

# 準備打包檔案
prepare_package_files() {
    log_step "準備打包檔案..."
    
    local package_dir="$BUILD_DIR/$PACKAGE_NAME-$VERSION"
    
    # 清理並建立打包目錄
    rm -rf "$package_dir"
    mkdir -p "$package_dir"
    
    # 複製主要安裝檔案
    log_info "複製安裝腳本..."
    cp "$SCRIPT_DIR/install.sh" "$package_dir/"
    chmod +x "$package_dir/install.sh"
    
    # 複製工具腳本
    log_info "複製工具腳本..."
    mkdir -p "$package_dir/utils"
    cp "$SCRIPT_DIR/utils/"*.sh "$package_dir/utils/"
    chmod +x "$package_dir/utils/"*.sh
    
    # 複製 Docker 相關檔案
    log_info "複製 Docker 檔案..."
    if [ -f "$PROJECT_DIR/docker-compose-bigdipper.yml" ]; then
        cp "$PROJECT_DIR/docker-compose-bigdipper.yml" "$package_dir/"
    fi
    
    if [ -f "$PROJECT_DIR/.env.bigdipper.template" ]; then
        cp "$PROJECT_DIR/.env.bigdipper.template" "$package_dir/"
    fi
    
    # 複製 Dockerfile 目錄
    if [ -d "$PROJECT_DIR/docker" ]; then
        log_info "複製 Docker 建置檔案..."
        cp -r "$PROJECT_DIR/docker" "$package_dir/"
    fi
    
    # 複製文檔
    log_info "複製文檔檔案..."
    mkdir -p "$package_dir/docs"
    
    if [ -f "$PROJECT_DIR/README.md" ]; then
        cp "$PROJECT_DIR/README.md" "$package_dir/"
    fi
    
    if [ -d "$PROJECT_DIR/docs" ]; then
        cp -r "$PROJECT_DIR/docs/"* "$package_dir/docs/" 2>/dev/null || true
    fi
    
    # 複製管理腳本
    if [ -d "$PROJECT_DIR/scripts" ]; then
        log_info "複製管理腳本..."
        cp -r "$PROJECT_DIR/scripts" "$package_dir/"
        chmod +x "$package_dir/scripts/"*.sh 2>/dev/null || true
    fi
    
    log_success "檔案準備完成: $package_dir"
}

# 建立啟動器腳本
create_launcher() {
    log_step "建立啟動器腳本..."
    
    local package_dir="$BUILD_DIR/$PACKAGE_NAME-$VERSION"
    local launcher="$package_dir/start-installer.sh"
    
    cat > "$launcher" << 'EOF'
#!/bin/bash
# 北斗七星陣一鍵安裝器啟動器
# Big Dipper Formation - One-Click Installer Launcher

set -e

# 顏色定義
GREEN='\033[0;32m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

# 獲取腳本目錄
INSTALLER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 顯示歡迎訊息
clear
echo -e "${PURPLE}"
cat << 'BANNER'
    ╔══════════════════════════════════════════════════════════════════════╗
    ║                        北斗七星陣 MCP 團隊                           ║
    ║                   Big Dipper Formation                               ║
    ║                      一鍵安裝器 v1.0.0                              ║
    ║                                                                      ║
    ║  🌟 天樞星 TaskMaster    🌟 天璇星 Perplexity                      ║
    ║  🌟 天璣星 Context7      🌟 天權星 OpenMemory                      ║
    ║  🌟 玉衡星 Zen MCP       🌟 開陽星 Serena                          ║
    ║  🌟 瑤光星 Sequential Thinking                                     ║
    ║                                                                      ║
    ║              智能協作，引導開發方向                                   ║
    ║           One-Click Installation & Configuration                     ║
    ╚══════════════════════════════════════════════════════════════════════╝
BANNER
echo -e "${NC}"
echo

echo -e "${CYAN}歡迎使用北斗七星陣一鍵安裝器！${NC}"
echo
echo "此安裝器將為您部署完整的北斗七星陣 MCP 團隊系統，包括："
echo "• 🌟 七大 MCP Server 成員"
echo "• 🐳 Docker 容器化部署"
echo "• 🔧 自動化配置和註冊"
echo "• 📊 監控和管理工具"
echo

echo -e "${GREEN}開始安裝...${NC}"
echo

# 執行主安裝腳本
cd "$INSTALLER_DIR"
exec ./install.sh "$@"
EOF
    
    chmod +x "$launcher"
    log_success "啟動器腳本建立完成"
}

# 建立自解壓安裝包
create_self_extracting_installer() {
    log_step "建立自解壓安裝包..."
    
    local package_dir="$BUILD_DIR/$PACKAGE_NAME-$VERSION"
    local self_extract_script="$DIST_DIR/$PACKAGE_NAME-$VERSION-installer.sh"
    
    # 建立 tar.gz 壓縮檔
    local archive_file="$TEMP_DIR/package.tar.gz"
    cd "$BUILD_DIR"
    tar -czf "$archive_file" "$PACKAGE_NAME-$VERSION"
    
    # 建立自解壓腳本
    cat > "$self_extract_script" << 'EOF'
#!/bin/bash
# 北斗七星陣自解壓安裝包
# Big Dipper Formation - Self-Extracting Installer

set -e

# 顏色定義
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

# 全域變數
EXTRACT_DIR="$HOME/.bigdipper-installer"
TEMP_EXTRACT="/tmp/bigdipper-extract-$$"

# 清理函數
cleanup() {
    rm -rf "$TEMP_EXTRACT" 2>/dev/null || true
}
trap cleanup EXIT

# 顯示橫幅
show_banner() {
    clear
    echo -e "${PURPLE}"
    cat << 'BANNER'
    ╔══════════════════════════════════════════════════════════════════════╗
    ║                🚀 北斗七星陣自解壓安裝包                             ║
    ║               Big Dipper Self-Extracting Installer                  ║
    ║                                                                      ║
    ║                     正在解壓安裝檔案...                              ║
    ║                    Extracting installation files...                 ║
    ╚══════════════════════════════════════════════════════════════════════╝
BANNER
    echo -e "${NC}"
    echo
}

# 解壓安裝檔案
extract_installer() {
    echo -e "${CYAN}正在解壓安裝檔案...${NC}"
    
    # 建立解壓目錄
    mkdir -p "$TEMP_EXTRACT"
    
    # 找到壓縮檔案開始位置
    local archive_start=$(awk '/^__ARCHIVE_BELOW__/ {print NR + 1; exit 0; }' "$0")
    
    # 解壓檔案
    tail -n +$archive_start "$0" | tar -xzf - -C "$TEMP_EXTRACT"
    
    # 移動到最終位置
    rm -rf "$EXTRACT_DIR" 2>/dev/null || true
    mv "$TEMP_EXTRACT"/* "$EXTRACT_DIR"
    
    echo -e "${GREEN}解壓完成！${NC}"
    echo "安裝檔案位置: $EXTRACT_DIR"
    echo
}

# 執行安裝
run_installer() {
    echo -e "${CYAN}啟動安裝程序...${NC}"
    echo
    
    cd "$EXTRACT_DIR"
    exec ./start-installer.sh "$@"
}

# 主程序
main() {
    show_banner
    extract_installer
    run_installer "$@"
}

# 檢查是否為解壓模式
case "${1:-}" in
    --extract-only)
        echo "僅解壓模式"
        extract_installer
        echo "檔案已解壓到: $EXTRACT_DIR"
        echo "執行以下指令開始安裝:"
        echo "  cd $EXTRACT_DIR && ./start-installer.sh"
        exit 0
        ;;
    --help|-h)
        echo "北斗七星陣自解壓安裝包"
        echo ""
        echo "用法: $0 [選項]"
        echo ""
        echo "選項:"
        echo "  --extract-only   僅解壓檔案，不執行安裝"
        echo "  --help, -h       顯示此幫助資訊"
        echo ""
        echo "預設會自動解壓並啟動安裝程序"
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac

exit 0

__ARCHIVE_BELOW__
EOF
    
    # 附加壓縮檔到腳本
    cat "$archive_file" >> "$self_extract_script"
    
    # 設定執行權限
    chmod +x "$self_extract_script"
    
    log_success "自解壓安裝包建立完成: $self_extract_script"
}

# 建立 ZIP 壓縮包
create_zip_package() {
    log_step "建立 ZIP 壓縮包..."
    
    local package_dir="$BUILD_DIR/$PACKAGE_NAME-$VERSION"
    local zip_file="$DIST_DIR/$PACKAGE_NAME-$VERSION.zip"
    
    cd "$BUILD_DIR"
    zip -r "$zip_file" "$PACKAGE_NAME-$VERSION" >/dev/null
    
    log_success "ZIP 壓縮包建立完成: $zip_file"
}

# 建立 TAR.GZ 壓縮包
create_tar_package() {
    log_step "建立 TAR.GZ 壓縮包..."
    
    local package_dir="$BUILD_DIR/$PACKAGE_NAME-$VERSION"
    local tar_file="$DIST_DIR/$PACKAGE_NAME-$VERSION.tar.gz"
    
    cd "$BUILD_DIR"
    tar -czf "$tar_file" "$PACKAGE_NAME-$VERSION"
    
    log_success "TAR.GZ 壓縮包建立完成: $tar_file"
}

# 建立校驗檔案
create_checksums() {
    log_step "建立校驗檔案..."
    
    local checksum_file="$DIST_DIR/checksums.txt"
    
    cd "$DIST_DIR"
    
    {
        echo "# 北斗七星陣安裝包校驗檔案"
        echo "# Big Dipper Formation - Package Checksums"
        echo "# 生成時間: $(date)"
        echo ""
        
        for file in *.{sh,zip,tar.gz} 2>/dev/null; do
            if [ -f "$file" ]; then
                local sha256=$(shasum -a 256 "$file" | cut -d' ' -f1)
                local md5=$(md5sum "$file" 2>/dev/null | cut -d' ' -f1 || md5 "$file" | cut -d' ' -f4)
                local size=$(ls -lh "$file" | awk '{print $5}')
                
                echo "檔案: $file"
                echo "大小: $size"
                echo "MD5:  $md5"
                echo "SHA256: $sha256"
                echo ""
            fi
        done
    } > "$checksum_file"
    
    log_success "校驗檔案建立完成: $checksum_file"
}

# 建立安裝說明
create_installation_guide() {
    log_step "建立安裝說明..."
    
    local guide_file="$DIST_DIR/INSTALLATION.md"
    
    cat > "$guide_file" << 'EOF'
# 北斗七星陣 MCP 團隊 - 安裝指南

## 系統需求

### 最小需求
- **作業系統**: Linux (Ubuntu 18.04+, CentOS 7+) 或 macOS (10.15+)
- **記憶體**: 4GB RAM
- **CPU**: 2 核心
- **磁碟空間**: 10GB
- **網路**: 可連接網際網路

### 建議需求
- **記憶體**: 16GB RAM
- **CPU**: 8 核心
- **磁碟空間**: 50GB SSD
- **Docker**: 20.10.0+
- **Docker Compose**: 2.0+

## 安裝方式

### 方式一：自解壓安裝包（推薦）

1. 下載自解壓安裝包：
   ```bash
   # 下載最新版本
   wget https://github.com/your-repo/releases/download/v1.0.0/bigdipper-mcp-installer-1.0.0-installer.sh
   ```

2. 執行安裝：
   ```bash
   chmod +x bigdipper-mcp-installer-1.0.0-installer.sh
   ./bigdipper-mcp-installer-1.0.0-installer.sh
   ```

### 方式二：解壓縮安裝

1. 下載壓縮包：
   ```bash
   # 下載 ZIP 或 TAR.GZ
   wget https://github.com/your-repo/releases/download/v1.0.0/bigdipper-mcp-installer-1.0.0.tar.gz
   ```

2. 解壓縮：
   ```bash
   tar -xzf bigdipper-mcp-installer-1.0.0.tar.gz
   cd bigdipper-mcp-installer-1.0.0
   ```

3. 執行安裝：
   ```bash
   ./start-installer.sh
   ```

## 安裝選項

### 完整安裝（推薦）
```bash
./start-installer.sh
```

### 快速安裝
```bash
./start-installer.sh --quick
```

### 自訂安裝
```bash
./start-installer.sh --custom
```

### 僅檢查系統
```bash
./start-installer.sh --check-only
```

## 安裝後配置

### 1. 註冊 MCP Servers

安裝完成後，執行以下指令註冊 MCP Servers：

```bash
./register_bigdipper_mcp.sh
```

### 2. 驗證安裝

執行驗證測試：

```bash
./utils/test-validator.sh
```

### 3. 管理服務

使用管理指令：

```bash
# 檢查狀態
bigdipper status

# 查看日誌
bigdipper logs

# 重啟服務
bigdipper restart

# 監控面板
bigdipper monitor
```

## 服務端點

安裝完成後，您可以訪問以下服務：

- **🌟 TaskMaster AI**: http://localhost:9120
- **🌟 Perplexity Custom**: http://localhost:8080
- **🌟 Context7 Cached**: http://localhost:9119
- **🌟 OpenMemory API**: http://localhost:8765
- **🌟 OpenMemory Web UI**: http://localhost:3000
- **🌟 Zen MCP**: http://localhost:8082
- **🌟 Serena**: http://localhost:9121
- **🌟 Serena Dashboard**: http://localhost:24282
- **🌟 Sequential Thinking**: http://localhost:9122

## API 金鑰配置

安裝過程中需要配置以下 API 金鑰：

### 必需的 API 金鑰
- **Anthropic API**: Claude AI 服務
- **Perplexity API**: 即時搜尋和研究

### 可選的 API 金鑰
- **OpenAI API**: GPT 模型支援
- **Google Gemini API**: 大文件處理
- **XAI Grok API**: 創意思考
- **OpenRouter API**: 多模型聚合

## 故障排除

### 常見問題

1. **端口衝突**
   ```bash
   # 檢查端口占用
   netstat -tuln | grep :8080
   
   # 停止占用端口的程序
   kill $(lsof -ti:8080)
   ```

2. **Docker 權限問題**
   ```bash
   # 將使用者加入 docker 群組
   sudo usermod -aG docker $USER
   newgrp docker
   ```

3. **記憶體不足**
   ```bash
   # 檢查記憶體使用
   docker stats
   
   # 調整服務配置
   nano .env
   ```

### 日誌查看

```bash
# 查看安裝日誌
tail -f ~/.bigdipper/install.log

# 查看服務日誌
docker-compose -f docker-compose-bigdipper.yml logs -f

# 查看特定服務日誌
docker logs openmemory_api
```

### 重新安裝

```bash
# 停止服務
./utils/uninstall.sh --stop-only

# 完整重新安裝
./utils/uninstall.sh --force
./start-installer.sh
```

## 解除安裝

如需移除北斗七星陣：

```bash
# 互動式解除安裝
./utils/uninstall.sh

# 快速解除安裝
./utils/uninstall.sh --force

# 僅停止服務
./utils/uninstall.sh --stop-only
```

## 支援與幫助

- **文檔**: [完整文檔](./README.md)
- **問題回報**: [GitHub Issues](https://github.com/your-repo/issues)
- **社群討論**: [Discussions](https://github.com/your-repo/discussions)

---

**版本**: 1.0.0  
**更新時間**: 2025-06-26
EOF
    
    log_success "安裝說明建立完成: $guide_file"
}

# 建立發布說明
create_release_notes() {
    log_step "建立發布說明..."
    
    local release_file="$DIST_DIR/RELEASE_NOTES.md"
    
    cat > "$release_file" << 'EOF'
# 北斗七星陣 MCP 團隊 v1.0.0 發布說明

## 🌟 重大特性

### 完整的 MCP 團隊生態系統
- **七大 MCP Server 成員**：TaskMaster、Perplexity、Context7、OpenMemory、Zen MCP、Serena、Sequential Thinking
- **統一容器化部署**：使用 Docker 和 Docker Compose 進行標準化部署
- **智能路由系統**：根據任務複雜度自動選擇最適合的 MCP Server

### 一鍵安裝體驗
- **自解壓安裝包**：單一檔案包含所有必要組件
- **系統需求檢查**：自動檢測和驗證系統環境
- **API 配置精靈**：智能引導完成 API 金鑰配置
- **自動化部署**：CI/CD 級別的部署流程

### 企業級功能
- **健康檢查**：全面的服務監控和狀態檢測
- **日誌管理**：結構化日誌和故障診斷
- **備份恢復**：重要資料的自動備份機制
- **解除安裝**：完整且安全的移除流程

## 🚀 核心組件

### 🌟 天樞星 - TaskMaster AI
- **專案管理大師**：任務規劃、進度追蹤、複雜度分析
- **PRD 解析**：自動將產品需求文檔轉換為可執行任務
- **智能擴展**：根據複雜度自動分解任務為子任務

### 🌟 天璇星 - Perplexity Custom 2.0
- **研究分析專家**：即時資訊搜尋、技術趨勢分析
- **多模型支援**：sonar、sonar-pro、sonar-deep-research
- **HTTP/SSE 雙模式**：支援即時串流和傳統 HTTP 通信

### 🌟 天璣星 - Context7 Cached
- **知識庫守護者**：技術文檔查詢、API 規範檢索
- **無需認證**：直接查詢公開 GitHub 專案文檔
- **智能快取**：提升查詢效能和使用者體驗

### 🌟 天權星 - OpenMemory
- **記憶宮殿管理者**：知識儲存、經驗累積
- **向量搜尋**：基於 Qdrant 的高效語意檢索
- **Web UI**：直觀的記憶管理界面

### 🌟 玉衡星 - Zen MCP
- **多模型智能中心**：整合 Gemini Pro、ChatGPT O3 等
- **智能路由**：根據任務類型自動選擇最適合的模型
- **深度分析**：代碼審查、架構分析、安全檢測

### 🌟 開陽星 - Serena
- **代碼精煉師**：語言伺服器整合、符號操作
- **IDE 級功能**：精確的代碼查找、重構、編輯
- **專案感知**：理解代碼結構和專案脈絡

### 🌟 瑤光星 - Sequential Thinking
- **思維導航者**：序列化思考、決策分支管理
- **結構化推理**：複雜問題的系統化分析
- **思維可視化**：清晰展示思考過程

## 🛠️ 技術架構

### 容器化部署
- **Docker 映像優化**：多階段建置減少映像大小
- **資源管理**：智能的 CPU 和記憶體分配
- **網路隔離**：安全的服務間通信

### 監控與運維
- **健康檢查**：每個服務都內建健康檢查端點
- **日誌聚合**：統一的日誌收集和分析
- **性能監控**：即時的資源使用監控

### 安全與權限
- **API 金鑰管理**：安全的憑證儲存和使用
- **網路安全**：服務間的加密通信
- **訪問控制**：基於角色的權限管理

## 📋 系統需求

### 最小需求
- **OS**: Ubuntu 18.04+ / CentOS 7+ / macOS 10.15+
- **RAM**: 4GB
- **CPU**: 2 核心
- **Storage**: 10GB
- **Docker**: 20.10.0+

### 推薦配置
- **RAM**: 16GB+
- **CPU**: 8 核心+
- **Storage**: 50GB+ SSD
- **Network**: 穩定的網際網路連接

## 🔧 安裝與使用

### 快速開始
```bash
# 下載自解壓安裝包
wget bigdipper-mcp-installer-1.0.0-installer.sh

# 執行安裝
chmod +x bigdipper-mcp-installer-1.0.0-installer.sh
./bigdipper-mcp-installer-1.0.0-installer.sh

# 註冊 MCP Servers
./register_bigdipper_mcp.sh

# 驗證安裝
./utils/test-validator.sh
```

### 管理指令
```bash
bigdipper status    # 查看狀態
bigdipper logs      # 查看日誌
bigdipper restart   # 重啟服務
bigdipper monitor   # 監控面板
```

## 🐛 已知問題

1. **macOS 上的 Docker Desktop 記憶體限制**
   - 解決方案：增加 Docker Desktop 的記憶體配額到至少 8GB

2. **某些 Linux 發行版的防火牆設定**
   - 解決方案：開放必要端口或使用 `--skip-checks` 參數

3. **Context7 MCP 在某些網路環境下的連線問題**
   - 解決方案：檢查網路設定或使用備用配置

## 🔮 未來規劃

### v1.1.0（規劃中）
- **更多 AI 模型支援**：整合 Mistral、Cohere 等模型
- **增強的監控面板**：更豐富的性能指標和告警
- **多語言支援**：界面和文檔的國際化

### v1.2.0（規劃中）
- **雲端部署支援**：AWS、GCP、Azure 一鍵部署
- **集群模式**：高可用性和負載均衡
- **插件系統**：第三方 MCP Server 的動態載入

## 🙏 致謝

感謝以下開源專案和社群的貢獻：
- **Model Context Protocol (MCP)**：核心協議標準
- **Docker & Docker Compose**：容器化技術
- **Anthropic Claude**：AI 能力支援
- **開源社群**：各種優秀的工具和函式庫

---

**發布日期**: 2025-06-26  
**版本**: 1.0.0  
**維護團隊**: 北斗七星陣開發團隊
EOF
    
    log_success "發布說明建立完成: $release_file"
}

# 顯示打包結果
show_package_results() {
    echo
    log_success "🎉 打包完成！"
    echo
    
    echo -e "${CYAN}打包結果：${NC}"
    echo "=========="
    
    if [ -d "$DIST_DIR" ]; then
        echo "輸出目錄: $DIST_DIR"
        echo
        echo "生成的檔案："
        ls -lh "$DIST_DIR"
        echo
        
        local total_size=$(du -sh "$DIST_DIR" | cut -f1)
        echo "總大小: $total_size"
        echo
    fi
    
    echo -e "${GREEN}安裝指令：${NC}"
    echo "==========="
    echo
    echo "1. 自解壓安裝包："
    echo "   chmod +x $PACKAGE_NAME-$VERSION-installer.sh"
    echo "   ./$PACKAGE_NAME-$VERSION-installer.sh"
    echo
    echo "2. ZIP 壓縮包："
    echo "   unzip $PACKAGE_NAME-$VERSION.zip"
    echo "   cd $PACKAGE_NAME-$VERSION"
    echo "   ./start-installer.sh"
    echo
    echo "3. TAR.GZ 壓縮包："
    echo "   tar -xzf $PACKAGE_NAME-$VERSION.tar.gz"
    echo "   cd $PACKAGE_NAME-$VERSION"
    echo "   ./start-installer.sh"
    echo
    
    echo -e "${YELLOW}提醒：${NC}"
    echo "• 請將生成的安裝包分發給使用者"
    echo "• 建議使用 checksums.txt 驗證檔案完整性"
    echo "• 詳細安裝說明請參考 INSTALLATION.md"
    echo
}

# 清理臨時檔案
cleanup_temp_files() {
    log_step "清理臨時檔案..."
    
    rm -rf "$TEMP_DIR" 2>/dev/null || true
    
    log_success "清理完成"
}

# 主要打包流程
main() {
    show_package_banner
    
    log_package "開始建立北斗七星陣安裝包..."
    echo
    
    # 執行打包流程
    check_prerequisites
    prepare_package_files
    create_launcher
    create_self_extracting_installer
    create_zip_package
    create_tar_package
    create_checksums
    create_installation_guide
    create_release_notes
    show_package_results
    cleanup_temp_files
    
    log_success "✨ 安裝包建立完成！"
}

# 處理命令列參數
case "${1:-}" in
    --help|-h)
        echo "北斗七星陣安裝包打包工具"
        echo ""
        echo "用法: $0 [選項]"
        echo ""
        echo "選項:"
        echo "  --help, -h           顯示此幫助資訊"
        echo "  --version <版本>     指定版本號 (預設: $VERSION)"
        echo "  --name <名稱>        指定套件名稱 (預設: $PACKAGE_NAME)"
        echo "  --output <目錄>      指定輸出目錄 (預設: $DIST_DIR)"
        echo "  --clean              清理 build 目錄"
        echo ""
        echo "範例:"
        echo "  $0                   # 建立預設安裝包"
        echo "  $0 --version 1.1.0   # 指定版本號"
        echo "  $0 --clean           # 清理並重新打包"
        echo ""
        exit 0
        ;;
    --version)
        if [ -z "$2" ]; then
            log_error "請指定版本號"
            exit 1
        fi
        VERSION="$2"
        shift 2
        ;;
    --name)
        if [ -z "$2" ]; then
            log_error "請指定套件名稱"
            exit 1
        fi
        PACKAGE_NAME="$2"
        shift 2
        ;;
    --output)
        if [ -z "$2" ]; then
            log_error "請指定輸出目錄"
            exit 1
        fi
        DIST_DIR="$2"
        mkdir -p "$DIST_DIR"
        shift 2
        ;;
    --clean)
        log_info "清理 build 目錄..."
        rm -rf "$BUILD_DIR" "$DIST_DIR"
        mkdir -p "$BUILD_DIR" "$DIST_DIR"
        log_success "清理完成"
        ;;
esac

# 執行主流程
main