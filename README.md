# 🌟 北斗七星並行影片分析系統

[![Version](https://img.shields.io/badge/version-v1.0.0-brightgreen)](https://github.com/phoenix581228/BigDipper-Video-Analysis/releases)
[![Test Coverage](https://img.shields.io/badge/tests-100%25-brightgreen)](./tests/)
[![License](https://img.shields.io/badge/license-MIT-blue)](./LICENSE)
[![Python](https://img.shields.io/badge/python-3.8+-blue)](https://python.org)

革命性的並行路徑影片分析架構，解決傳統批量處理的「黑洞」問題，提供智能、互動、透明的影片場記分析體驗。

## ✨ 核心特色

- 🛤️ **並行路徑架構** - 三條路徑適應不同使用場景
- 💰 **智能成本控制** - 透明化費用管理與預算控制
- 🔄 **真正互動式處理** - 分組進度可見，可隨時中斷恢復
- 🎯 **統一CLI介面** - 所有功能通過單一命令行存取
- 💾 **狀態持久化** - 完整的進度追蹤與會話管理
- 🧪 **自動化測試** - 100%測試覆蓋率確保穩定性

## 🚀 快速開始

### 安裝要求

- Python 3.8+
- Google Gemini API 金鑰
- Node.js (用於MCP服務)

### 安裝步驟

```bash
# 克隆專案
git clone https://github.com/phoenix581228/BigDipper-Video-Analysis.git
cd BigDipper-Video-Analysis

# 安裝依賴
pip install -r requirements.txt

# 設置環境變數
export GOOGLE_API_KEY="your_gemini_api_key_here"
export GEMINI_MODEL="gemini-1.5-pro"

# 執行系統測試
python tests/automated_testing.py
```

## 🛤️ 三大並行路徑

### 路徑A - AI自動識別模式 🤖

適合已知內容類型的批量處理：

```bash
# 智能預覽內容
python cli/cli_router.py preview /path/to/videos --samples 3

# 自動處理模式
python cli/cli_router.py auto /path/to/videos --cost-limit 5.0
```

### 路徑B - 用戶引導模式 🎯

適合需要人工確認的互動處理：

```bash
# 引導處理模式
python cli/cli_router.py guided /path/to/videos --group-size 3 --interactive
```

### 路徑C - 通用分析模式 🔄

適合保守設定和成本控制：

```bash
# 通用低成本模式
python cli/cli_router.py universal /path/to/videos --low-cost
```

## 💰 成本控制系統

```bash
# 查看成本狀態
python cli/cli_router.py cost-status --history

# 系統狀態檢查
python cli/cli_router.py status

# 設置成本上限
python cli/cli_router.py batch /path/to/videos --cost-limit 10.0
```

## 📊 進度追蹤與恢復

系統自動儲存處理狀態，支援中斷後恢復：

```bash
# 啟動互動式處理
python cli/progress_tracker.py

# 恢復中斷的會話
python cli/progress_tracker.py --session-id session_20250629_123456

# 查看會話列表
python cli/progress_tracker.py --list-sessions
```

## 📦 批量自定義處理

```bash
# 自定義批量處理
python cli/cli_router.py batch /path/to/videos \
  --model pro \
  --analysis comprehensive \
  --concurrent 3 \
  --cost-limit 10.0
```

## 🧪 測試與驗證

```bash
# 執行完整測試套件
python tests/automated_testing.py

# 快速連接測試
python tests/test_connection.py

# 功能性測試
python tests/test_full_functionality.py
```

## 📁 專案結構

```
BigDipper-Video-Analysis/
├── src/                    # 核心MCP服務器
│   └── gemini_mcp_server.py
├── cli/                    # 命令行介面
│   ├── cli_router.py
│   └── progress_tracker.py
├── processors/             # 並行處理器
│   └── parallel_video_processor.py
├── tests/                  # 測試套件
│   ├── automated_testing.py
│   └── test_*.py
├── docs/                   # 文檔
│   ├── FINAL_USAGE_GUIDE.md
│   └── integration_report_*.json
├── .taskmaster/           # TaskMaster配置
├── .github/               # GitHub配置
├── README.md
├── CHANGELOG.md
└── requirements.txt
```

## 🔧 架構特色

### Sequential Thinking 並行路徑突破

- **路徑A**: AI自動識別模式 - 智能內容檢測與自動處理
- **路徑B**: 用戶引導模式 - 互動確認與分組處理  
- **路徑C**: 通用分析模式 - 保守設定與降低成本

### 核心創新

1. **解決黑洞問題** - 真正的互動式分組處理
2. **成本透明化** - 完整成本管理與預算控制
3. **進度即時可見** - 實時進度追蹤與狀態報告
4. **系統統一性** - 單一CLI介面統管所有功能
5. **中斷恢復能力** - 狀態持久化與會話管理

## 🎯 使用建議

1. **首次使用**: 先用 `preview` 預覽內容類型
2. **小量測試**: 使用 `guided` 模式熟悉流程
3. **大量處理**: 根據預覽結果選擇最適合的路徑
4. **成本控制**: 經常檢查 `cost-status` 避免超支
5. **長時間處理**: 使用 `progress_tracker.py` 確保可恢復性

## 📞 支援與故障排除

- **系統狀態檢查**: `python cli/cli_router.py status`
- **測試系統健康**: `python tests/automated_testing.py`  
- **查看詳細日誌**: 檢查 `.progress_*.json` 和 `test_report_*.json`

## 🤝 貢獻指南

1. Fork 專案
2. 創建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交變更 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 開啟 Pull Request

## 📄 授權

本專案採用 MIT 授權 - 查看 [LICENSE](LICENSE) 檔案了解詳情。

## 👥 開發團隊

- **北斗七星 AI 協作架構** - 架構設計與實現
- **Claude Code** - 開發協作夥伴

## 🏆 致謝

感謝所有為北斗七星並行影片分析系統做出貢獻的開發者和使用者。

---

**版本**: v1.0.0 Final  
**建立時間**: 2025-06-29  
**更新時間**: 2025-06-29  

如有問題或建議，請在 [Issues](https://github.com/phoenix581228/BigDipper-Video-Analysis/issues) 中提出。