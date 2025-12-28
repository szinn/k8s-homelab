---
description: Navigation hub for AI context documentation with philosophy overview and document structure
tags: ["Navigation", "DocumentStructure", "AIContext"]
audience: ["LLMs", "Humans"]
categories: ["Documentation[100%]", "Navigation[95%]"]
---

# AI Context Documentation

This directory contains the single source of truth for AI assistant context across multiple tools (Claude Code, Cursor, GitHub Copilot, and Gemini).

## Critical Invariant

**This repository manages TWO independent Kubernetes clusters**:

- **Main cluster** (`kubernetes/main/`) - Production workloads on physical hardware
- **Staging cluster** (`kubernetes/staging/`) - Testing workloads on Proxmox

Clusters do NOT share code. Always specify which cluster you're working on.

## Read These First

**New to this repository?** Read in order:

1. **[Ethos.md](Ethos.md)** - Documentation philosophy (hard rules, strong guidance, values)
2. **[ARCHITECTURE.md](ARCHITECTURE.md)** - Dual-cluster GitOps architecture overview

**Writing documentation?** Read:

1. **[writing-documentation.md](writing-documentation.md)** - Wisdom triggers philosophy
2. **[writing-capsules.md](writing-capsules.md)** - Capsule format specification
3. **[mermaid-diagram-guide.md](mermaid-diagram-guide.md)** - Diagram best practices

## Document Map

### Foundation (Philosophy)

| Document                                             | Purpose                                                                         |
| ---------------------------------------------------- | ------------------------------------------------------------------------------- |
| [Ethos.md](Ethos.md)                                 | Hard rules, strong guidance, values for documentation                           |
| [PLANNING.md](PLANNING.md)                           | Collaborative planning lifecycle: Idea → Planning → Risk → Execution → Incident |
| [writing-documentation.md](writing-documentation.md) | Wisdom triggers, token economics, two-tier architecture                         |
| [writing-capsules.md](writing-capsules.md)           | Invariant->Example->Depth format specification                                  |
| [mermaid-diagram-guide.md](mermaid-diagram-guide.md) | Diagram types, accessibility, universal rules                                   |

### System Context

| Document                           | Purpose                                              |
| ---------------------------------- | ---------------------------------------------------- |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Dual-cluster GitOps architecture, key decisions      |
| [NETWORKING.md](NETWORKING.md)     | Traffic flows, DNS, Envoy Gateway, network isolation |
| [DOMAIN.md](DOMAIN.md)             | Business rules, state machines, entity relationships |
| [WORKFLOWS.md](WORKFLOWS.md)       | Operational workflows for both clusters              |
| [TOOLS.md](TOOLS.md)               | Task commands, kubectl, flux, talosctl patterns      |
| [CONVENTIONS.md](CONVENTIONS.md)   | Naming standards, file structure, commit guidelines  |

---

## Documentation Philosophy

This knowledge base follows the **wisdom triggers** approach:

### Hard Rules (Never Violate)

- **Only record what you can verify** - Wrong information is worse than missing
- **When in doubt, omit** - Missing prompts questions; wrong causes failures
- **Never use actual domain names or secrets** - Always use `${SECRET_DOMAIN}` placeholders
- **Always specify which cluster** - Main, staging, or both (never assume)

### Strong Guidance

- **Document shape, not detail** - Patterns over implementations
- **Focus on why, not just what** - Principles over procedures
- **Provide trails, not destinations** - Link to manifests, don't duplicate

### Capsule Format

Distill concepts into stable, minimal truths:

```markdown
### Capsule: ConceptName

**Invariant**
Core truth in <=30 tokens, timeless, no versions

**Example**
Concrete instance in <=5 lines

**Depth**

- Distinction: How this differs from similar concepts
- Trade-off: What you gain vs lose
- NotThis: Common misconceptions
- SeeAlso: Related capsule names
```

---

## Purpose

This centralized documentation:

- Eliminates duplication across `.claude/`, `.cursor/`, `.codex/`, and `.github/` directories
- Provides consistent context to all AI coding assistants
- Makes updates easier - change once, propagate to all tools
- Optimizes for AI comprehension with capsules and frontmatter

## Tool-Specific Configurations

Each AI tool references these files using their native import mechanism:

| Tool           | Config Location                   | Import Syntax                  |
| -------------- | --------------------------------- | ------------------------------ |
| Claude Code    | `.claude/CLAUDE.md`               | `@docs/ai-context/filename.md` |
| Cursor         | `.cursor/rules/index.mdc`         | `@docs/ai-context/filename.md` |
| GitHub Copilot | `.github/copilot-instructions.md` | Manual links                   |
| Gemini         | IDE integration                   | Reads project files            |

---

## Adding New Documentation

When adding new documentation:

1. **Read [Ethos.md](Ethos.md)** - Understand the philosophy
2. **Read [writing-documentation.md](writing-documentation.md)** - Understand the format
3. **Add frontmatter** - description, tags, audience, categories
4. **Use capsules** for key concepts
5. **Follow [mermaid-diagram-guide.md](mermaid-diagram-guide.md)** for diagrams
6. **Link, don't duplicate** - Point to manifests and configs

### Frontmatter Template

```yaml
---
description: One-sentence value proposition
tags: ["CamelCaseConcepts", "MoreTags"]
audience: ["LLMs", "Humans"]
categories: ["PrimaryType[100%]", "SecondaryType[85%]"]
---
```

---

## Success Metrics

Documentation succeeds when:

- Readers grasp concepts in seconds, not minutes
- AI finds and extracts exactly what's needed
- New contributors understand where things fit
- Updates preserve meaning while adding detail
