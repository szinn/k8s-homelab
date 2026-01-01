# Homelab Repository Context

GitOps-managed Kubernetes homelab using Flux and Talos.

## Read First

1. **@docs/ai-context/README.md** - Overview and navigation
2. **@docs/ai-context/Ethos.md** - Documentation philosophy
3. **@docs/ai-context/ARCHITECTURE.md** - System architecture
4. **@docs/ai-context/CONVENTIONS.md** - Coding standards

## Documentation

### System Context

- @docs/ai-context/ARCHITECTURE.md - Architecture, capsules, patterns
- @docs/ai-context/NETWORKING.md - Traffic flows, DNS, gateways, OIDC
- @docs/ai-context/DOMAIN.md - Rules, state machines, glossary
- @docs/ai-context/WORKFLOWS.md - How to deploy, update, troubleshoot
- @docs/ai-context/TOOLS.md - MCP servers, CLI commands
- @docs/ai-context/CONVENTIONS.md - Naming, structure, style

### Writing Guides

- @docs/ai-context/Ethos.md - Hard rules, guidance, values
- @docs/ai-context/PLANNING.md - Collaborative planning lifecycle
- @docs/ai-context/writing-documentation.md - Wisdom triggers
- @docs/ai-context/writing-capsules.md - Capsule format
- @docs/ai-context/mermaid-diagram-guide.md - Diagram rules

## Critical Invariants

### Clustes: Location of Source

There are two independent clusters:

main: root of the main cluster is @kubernetes/main
staging: root of the staging cluster is @kubernetes/staging

The clusters do not share code. When making changes, it is important
to know which cluster is being worked on. Make sure to know this in advance
of any planning or changes.

n### Capsule: GitOpsReconciliation

**Invariant**: Cluster state converges to match Git; Flux reverts manual changes.

### Capsule: MakejinjaTemplates

**Invariant**: Edit templates in `bootstrap/templates/`, run `task configure`; don't edit generated files.

### Capsule: AppTemplateChart

**Invariant**: Apps use `bjw-s/app-template` chart; vendor charts are exceptions.

## Quick Reference

| Task             | Command                           |
| ---------------- | --------------------------------- |
| Render templates | `task configure`                  |
| Validate         | `task kubernetes:kubeconform`     |
| Check status     | `flux get helmreleases -A`        |
| Force sync       | `task flux:reconcile`             |
| Find apps        | `ls kubernetes/apps/<namespace>/` |

## Directory Structure

```
bootstrap/templates/    # SOURCE - Jinja2 templates
kubernetes/apps/        # OUTPUT - Generated manifests
config.yaml             # SECRET - Template variables (not committed)
```

## Non-Obvious Truths

- **Makejinja delimiters**: `#{var}#` not `{{var}}` (avoids Helm conflicts)
- **Gateway API routing**: Use `route` not `ingress` for main traffic
- **Image pinning**: Always include `@sha256:` digest
- **SOPS files**: End in `.sops.yaml`, encrypted before commit
