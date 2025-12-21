# AI Assistant Configuration

This repository uses multiple AI coding assistants with shared context from a centralized documentation hub.

## Documentation Location

All AI assistant context is centralized in **[`docs/ai-context/`](docs/ai-context/)**:

- [README.md](docs/ai-context/README.md) - Overview and navigation
- [ARCHITECTURE.md](docs/ai-context/ARCHITECTURE.md) - GitOps architecture, key decisions, and constraints
- [DOMAIN.md](docs/ai-context/DOMAIN.md) - Business rules, entity relationships, and invariants
- [WORKFLOWS.md](docs/ai-context/WORKFLOWS.md) - Operational workflows and procedures
- [TOOLS.md](docs/ai-context/TOOLS.md) - Tool usage patterns and discovery commands
- [CONVENTIONS.md](docs/ai-context/CONVENTIONS.md) - Coding standards and project guidelines

This centralized approach provides:

- ✅ Single source of truth for all AI tools
- ✅ No duplication across tool-specific directories
- ✅ Easy updates - change once, all tools benefit
- ✅ Version controlled and team-friendly
- ✅ Future-proof for new AI assistants

## 🔌 MCP Server Configuration

Model Context Protocol (MCP) servers are configured in the root **[`.mcp.json`](.mcp.json)** file, which is shared across:

- ✅ VS Code MCP extensions
- ✅ Claude Code
- ✅ Any other tool supporting the `.mcp.json` standard

**Available MCP Servers:**

- **github** - Repository querying and code analysis
- **mermaid** - Validate and render Mermaid diagrams (via `@probelabs/maid-mcp`)

This provides a single source of truth for MCP server configuration across all compatible tools.
