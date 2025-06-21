# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-06-21

### Added
- Initial release of Perplexity MCP Custom Server
- Full compliance with MCP protocol 2025-03-26 specification
- Complete JSON Schema draft 2020-12 compatibility
- Two main tools:
  - `perplexity_search_web` - Web search with citation support
  - `perplexity_deep_research` - Deep research on topics
- LRU cache mechanism for performance optimization
- Support for all Perplexity models (sonar, sonar-pro, sonar-deep-research)
- Comprehensive error handling
- TypeScript implementation with full type safety
- Unit tests with 100% coverage for core functionality
- Debug mode for troubleshooting

### Technical Details
- Built with @modelcontextprotocol/sdk v1.13.0
- Uses stdio transport for MCP communication
- Implements proper JSON-RPC 2.0 protocol
- Supports environment-based configuration