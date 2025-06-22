# MCP Server Development - 專案結構

此文件展示 MCP Server Development 專案的完整目錄結構。

## 專案概覽

```
MCP-Server-DEV/
├── README.md                    # 專案主文檔
├── MILESTONES.md               # 專案里程碑記錄
├── PROJECT_STRUCTURE.md        # 本文件
├── scripts/                    # 工具腳本
│   └── generate-tree.sh       # 生成專案結構的腳本
├── perplexity-mcp-custom/     # Perplexity MCP Server 實作
└── zen-mcp-server/            # Zen MCP Server (多模型 AI 協作)
```

## 詳細結構

### 根目錄
```
├── .
├── ..
├── .git
├── openmemory-mcp-config
├── perplexity-mcp-custom
├── scripts
├── serena-mcp-server
├── zen-mcp-config
├── zen-mcp-server
├── .DS_Store
├── .gitignore
├── BRANCHING_STRATEGY.md
├── GIT_HISTORY.md
├── MILESTONES.md
├── PROJECT_STRUCTURE.md
├── README.md
├── RESEARCH_REPORT_MCP_SERVERS_ANALYSIS.md
```

### perplexity-mcp-custom 詳細結構

```
.
./.DS_Store
./.env
./.env.example
./.env.test
./.eslintrc.json
./.prettierrc
./bin
./bin/perplexity-mcp.js
./CHANGELOG.md
./docs
./docs/ARCHITECTURE_V2.md
./docs/DEVELOPMENT_PLAN.md
./docs/FEASIBILITY_STUDY.md
./docs/ROADMAP_V2.md
./docs/TECHNICAL_SPEC_V2.md
./docs/TECHNICAL_SPEC.md
./ENVIRONMENT-VALIDATION.md
./examples
./examples/basic-usage.js
./LICENSE
./package-lock.json
./package.json
./PRO-SEARCH-GUIDE.md
./README.md
./src
./src/.DS_Store
./src/api
./src/api/client.ts
./src/index.ts
./src/server
./src/server/index.ts
./src/tools
./src/tools/schemas.ts
./src/types
./src/types/index.ts
./src/utils
./src/utils/cache.ts
./test-all-models.js
./test-api-correct.js
./test-api-direct.js
./test-deep-research.js
./test-env-direct.js
./test-env-validation.js
./test-search-final.js
./test-search.js
./test-server.js
./test-simple.js
./test-validation.js
./tests
./tests/.DS_Store
./tests/integration
./tests/unit
./tests/unit/cache.test.ts
./tests/unit/schemas.test.ts
./tsconfig.json
./tsup.config.ts
./verify-api.js
./vitest.config.ts
```

#### 統計資訊
- TypeScript 檔案:       11
- JavaScript 檔案:       15
- Python 檔案:        1
- Markdown 文檔:      449

### zen-mcp-server 詳細結構

```
.
./.claude
./.claude/settings.local.json
./.docker_cleaned
./.DS_Store
./.env
./.env.example
./claude_config_example.json
./CLAUDE.md
./code_quality_checks.sh
./communication_simulator_test.py
./conf
./conf/custom_models.json
./config.py
./docs
./docs/adding_providers.md
./docs/adding_tools.md
./docs/advanced-usage.md
./docs/ai_banter.md
./docs/ai-collaboration.md
./docs/configuration.md
./docs/context-revival.md
./docs/contributions.md
./docs/custom_models.md
./docs/logging.md
./docs/testing.md
./docs/tools
./docs/tools/analyze.md
./docs/tools/chat.md
./docs/tools/codereview.md
./docs/tools/consensus.md
./docs/tools/debug.md
./docs/tools/listmodels.md
./docs/tools/planner.md
./docs/tools/precommit.md
./docs/tools/refactor.md
./docs/tools/testgen.md
./docs/tools/thinkdeep.md
./docs/tools/tracer.md
./docs/tools/version.md
./docs/troubleshooting.md
./examples
./examples/claude_config_macos.json
./examples/claude_config_wsl.json
./LICENSE
./providers
./providers/__init__.py
./providers/base.py
./providers/custom.py
./providers/gemini.py
./providers/openai_compatible.py
./providers/openai_provider.py
./providers/openrouter_registry.py
./providers/openrouter.py
./providers/registry.py
./providers/xai.py
./pyproject.toml
./pytest.ini
./README.md
./requirements-dev.txt
./requirements.txt
./run-server.sh
./scripts
./scripts/bump_version.py
./server.py
./simulator_tests
./simulator_tests/__init__.py
./simulator_tests/base_test.py
./simulator_tests/conversation_base_test.py
./simulator_tests/log_utils.py
./simulator_tests/test_analyze_validation.py
./simulator_tests/test_basic_conversation.py
./simulator_tests/test_codereview_validation.py
./simulator_tests/test_consensus_conversation.py
./simulator_tests/test_consensus_stance.py
./simulator_tests/test_consensus_three_models.py
./simulator_tests/test_content_validation.py
./simulator_tests/test_conversation_chain_validation.py
./simulator_tests/test_cross_tool_comprehensive.py
./simulator_tests/test_cross_tool_continuation.py
./simulator_tests/test_debug_certain_confidence.py
./simulator_tests/test_debug_validation.py
./simulator_tests/test_line_number_validation.py
./simulator_tests/test_model_thinking_config.py
./simulator_tests/test_o3_model_selection.py
./simulator_tests/test_o3_pro_expensive.py
./simulator_tests/test_ollama_custom_url.py
./simulator_tests/test_openrouter_fallback.py
./simulator_tests/test_openrouter_models.py
./simulator_tests/test_per_tool_deduplication.py
./simulator_tests/test_planner_continuation_history.py
./simulator_tests/test_planner_validation_old.py
./simulator_tests/test_planner_validation.py
./simulator_tests/test_precommitworkflow_validation.py
./simulator_tests/test_refactor_validation.py
./simulator_tests/test_testgen_validation.py
./simulator_tests/test_thinkdeep_validation.py
./simulator_tests/test_token_allocation_validation.py
./simulator_tests/test_vision_capability.py
./simulator_tests/test_xai_models.py
./systemprompts
./systemprompts/__init__.py
./systemprompts/analyze_prompt.py
./systemprompts/chat_prompt.py
./systemprompts/codereview_prompt.py
./systemprompts/consensus_prompt.py
./systemprompts/debug_prompt.py
./systemprompts/planner_prompt.py
./systemprompts/precommit_prompt.py
./systemprompts/refactor_prompt.py
./systemprompts/testgen_prompt.py
./systemprompts/thinkdeep_prompt.py
./systemprompts/tracer_prompt.py
./test_mcp.sh
./test_zen_wrapper.sh
./tests
./tests/__init__.py
./tests/conftest.py
./tests/mock_helpers.py
./tests/test_alias_target_restrictions.py
./tests/test_auto_mode_comprehensive.py
./tests/test_auto_mode_custom_provider_only.py
./tests/test_auto_mode_provider_selection.py
./tests/test_auto_mode.py
./tests/test_auto_model_planner_fix.py
./tests/test_buggy_behavior_prevention.py
./tests/test_claude_continuation.py
./tests/test_collaboration.py
./tests/test_config.py
./tests/test_consensus.py
./tests/test_conversation_field_mapping.py
./tests/test_conversation_file_features.py
./tests/test_conversation_history_bug.py
./tests/test_conversation_memory.py
./tests/test_conversation_missing_files.py
./tests/test_cross_tool_continuation.py
./tests/test_custom_provider.py
./tests/test_debug.py
./tests/test_directory_expansion_tracking.py
./tests/test_file_protection.py
./tests/test_gemini_token_usage.py
./tests/test_image_support_integration.py
./tests/test_intelligent_fallback.py
./tests/test_large_prompt_handling.py
./tests/test_line_numbers_integration.py
./tests/test_listmodels_restrictions.py
./tests/test_listmodels.py
./tests/test_model_enumeration.py
./tests/test_model_restrictions.py
./tests/test_o3_temperature_fix_simple.py
./tests/test_old_behavior_simulation.py
./tests/test_openai_compatible_token_usage.py
./tests/test_openai_provider.py
./tests/test_openrouter_provider.py
./tests/test_openrouter_registry.py
./tests/test_per_tool_model_defaults.py
./tests/test_planner.py
./tests/test_precommit_workflow.py
./tests/test_prompt_regression.py
./tests/test_provider_routing_bugs.py
./tests/test_providers.py
./tests/test_rate_limit_patterns.py
./tests/test_refactor.py
./tests/test_server.py
./tests/test_special_status_parsing.py
./tests/test_thinking_modes.py
./tests/test_tools.py
./tests/test_tracer.py
./tests/test_utils.py
./tests/test_workflow_file_embedding.py
./tests/test_workflow_metadata.py
./tests/test_xai_provider.py
./tests/triangle.png
./tools
./tools/__init__.py
./tools/.DS_Store
./tools/analyze.py
./tools/base.py
./tools/chat.py
./tools/codereview.py
./tools/consensus.py
./tools/debug.py
./tools/listmodels.py
./tools/models.py
./tools/planner.py
./tools/precommit.py
./tools/refactor.py
./tools/shared
./tools/shared/__init__.py
./tools/shared/base_models.py
./tools/shared/base_tool.py
./tools/simple
./tools/simple/__init__.py
./tools/simple/base.py
./tools/testgen.py
./tools/thinkdeep.py
./tools/tracer.py
./tools/workflow
./tools/workflow/__init__.py
./tools/workflow/base.py
./tools/workflow/workflow_mixin.py
./utils
./utils/__init__.py
./utils/.DS_Store
./utils/conversation_memory.py
./utils/file_types.py
./utils/file_utils.py
./utils/model_context.py
./utils/model_restrictions.py
./utils/security_config.py
./utils/storage_backend.py
./utils/token_utils.py
./zen-mcp-config
```

#### 統計資訊
- TypeScript 檔案:        0
- JavaScript 檔案:        0
- Python 檔案:      151
- Markdown 文檔:       28

## 關鍵目錄說明

### perplexity-mcp-custom/
Perplexity AI 的 MCP Server 實作，提供：
- 完整的 Perplexity API 整合
- JSON Schema 2020-12 相容性
- 豐富的測試腳本和文檔

### zen-mcp-server/
多模型 AI 協作的 MCP Server，特點：
- 支援多個 AI 提供者（Gemini、OpenAI、Ollama 等）
- 豐富的開發工具（debug、analyze、refactor 等）
- 完整的測試框架和模擬器

## 維護說明

此文件由 `scripts/generate-tree.sh` 自動生成。要更新結構：

```bash
./scripts/generate-tree.sh
```

最後更新時間：$(date '+%Y-%m-%d %H:%M:%S')

## 專案依賴關係

### perplexity-mcp-custom 依賴
- @modelcontextprotocol/sdk (MCP 核心)
- dotenv (環境變數管理)
- zod (資料驗證)

### zen-mcp-server 依賴
主要 Python 套件：
- Python 3.9+ 
- MCP SDK
- 各種 AI 提供者的客戶端庫

詳細依賴請查看各專案的 package.json 或 requirements.txt。
